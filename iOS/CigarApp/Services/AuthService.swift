import Foundation
import Supabase
import AuthenticationServices
import CryptoKit
import GoogleSignIn
import UIKit

// MARK: - AuthService
// Håndterer innlogging og brukersesjoner
// Støtter: Sign In with Apple + Sign In with Google → Supabase signInWithIdToken

@MainActor
class AuthService: NSObject, ObservableObject {

    @Published var currentUser: User? = nil
    @Published var isAuthenticated = false
    @Published var isLoading = true

    // Midlertidig lagring av navn fra Google/Apple for pre-fill i onboarding
    @Published var pendingDisplayName: String? = nil

    // Bro mellom ASAuthorizationControllerDelegate og async/await
    private var appleSignInContinuation: CheckedContinuation<ASAuthorization, Error>?
    private var currentNonce: String?

    override init() {
        super.init()
        Task { await checkSession() }
    }

    // Sjekk om bruker allerede er logget inn
    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            currentUser = session.user
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
        isLoading = false
    }

    // MARK: - Native Sign In with Apple
    func signInWithApple() async throws {
        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        // Bro til delegate-basert ASAuthorizationController
        let authorization = try await withCheckedThrowingContinuation { continuation in
            self.appleSignInContinuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = appleIDCredential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else {
            throw AuthError.invalidCredential
        }

        // Lagre navn fra Apple (kun tilgjengelig første gang)
        if let fullName = appleIDCredential.fullName {
            let name = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            if !name.isEmpty { pendingDisplayName = name }
        }

        try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )

        await checkSession()
    }

    // MARK: - Sign In with Google
    func signInWithGoogle() async throws {
        guard let presentingVC = topMostViewController() else {
            throw AuthError.noRootViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC)

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.invalidCredential
        }

        // Lagre navn fra Google for pre-fill i onboarding
        if let name = result.user.profile?.name, !name.isEmpty {
            pendingDisplayName = name
        }

        try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .google, idToken: idToken)
        )

        await checkSession()
    }

    // E-post/passord (for testing og fallback)
    func signIn(email: String, password: String) async throws {
        let session = try await supabase.auth.signIn(email: email, password: password)
        currentUser = session.user
        isAuthenticated = true
    }

    // Registrer ny bruker
    func signUp(email: String, password: String) async throws {
        let response = try await supabase.auth.signUp(
            email: email,
            password: password,
            redirectTo: URL(string: "vitola://auth/callback")
        )
        currentUser = response.user
        isAuthenticated = true
    }

    // Deep link-håndtering for e-postbekreftelse
    func handleDeepLink(_ url: URL) async {
        do {
            let session = try await supabase.auth.session(from: url)
            currentUser = session.user
            isAuthenticated = true
        } catch {
            print("Kunne ikke håndtere deep link: \(error)")
        }
    }

    // Logg ut
    func signOut() async throws {
        try await supabase.auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }

    // Slett konto permanent
    // Krever at delete_user()-funksjonen er opprettet i Supabase (se supabase/delete_user.sql)
    func deleteAccount() async throws {
        try await supabase.rpc("delete_user").execute()
        try await supabase.auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }

    // Finn den øverste presenterte view controlleren (unngår "already presenting"-krasj)
    private func topMostViewController() -> UIViewController? {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
                      ?? windowScene.windows.first?.rootViewController
        else { return nil }

        var top = rootVC
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }

    var userId: UUID? {
        guard let id = currentUser?.id else { return nil }
        return UUID(uuidString: id.uuidString)
    }

    // MARK: - Nonce helpers
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var r: UInt8 = 0
                _ = SecRandomCopyBytes(kSecRandomDefault, 1, &r)
                return r
            }
            randoms.forEach { r in
                if remaining == 0 { return }
                if r < charset.count {
                    result.append(charset[Int(r)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            self.appleSignInContinuation?.resume(returning: authorization)
            self.appleSignInContinuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            self.appleSignInContinuation?.resume(throwing: error)
            self.appleSignInContinuation = nil
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
            ?? UIWindow()
    }
}

// MARK: - Errors
enum AuthError: LocalizedError {
    case invalidCredential
    case noRootViewController

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Kunne ikke hente ID-token. Prøv igjen."
        case .noRootViewController:
            return "Kunne ikke presentere Google Sign-In. Prøv igjen."
        }
    }
}
