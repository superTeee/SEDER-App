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

    // E-post/passord (for testing)
    func signIn(email: String, password: String) async throws {
        let session = try await supabase.auth.signIn(email: email, password: password)
        currentUser = session.user
        isAuthenticated = true
    }

    // Registrer ny bruker
    func signUp(email: String, password: String) async throws {
        let response = try await supabase.auth.signUp(email: email, password: password)
        currentUser = response.user
        isAuthenticated = true
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
