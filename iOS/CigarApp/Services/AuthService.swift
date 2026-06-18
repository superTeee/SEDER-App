import Foundation
import Supabase
import AuthenticationServices

// MARK: - AuthService
// Håndterer innlogging og brukersesjoner

@MainActor
class AuthService: ObservableObject {

    @Published var currentUser: User? = nil
    @Published var isAuthenticated = false
    @Published var isLoading = true

    init() {
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

    // Sign In with Apple
    func signInWithApple() async throws {
        try await supabase.auth.signInWithOAuth(
            provider: .apple,
            redirectTo: URL(string: "cigarapp://auth/callback")
        )
        await checkSession()
    }

    // Sign In with Google
    func signInWithGoogle() async throws {
        try await supabase.auth.signInWithOAuth(
            provider: .google,
            redirectTo: URL(string: "cigarapp://auth/callback")
        )
        await checkSession()
    }

    // E-post/passord (for testing)
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
            redirectTo: URL(string: "cigarapp://auth/callback")
        )
        currentUser = response.user
        isAuthenticated = true
    }

    // Kalles fra .onOpenURL når brukeren trykker på lenken i bekreftelses-
    // eller passord-reset-e-posten, som sender dem tilbake til appen via
    // cigarapp://auth/callback
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

    var userId: UUID? {
        guard let id = currentUser?.id else { return nil }
        return UUID(uuidString: id.uuidString)
    }
}
