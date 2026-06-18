import SwiftUI

// MARK: - AuthView
// Innlogging — presenteres som sheet når brukeren faktisk trenger en konto
// (f.eks. for å lagre en sigar i humidoren). Aldersbekreftelsen ligger nå i
// AgeGateView og vises kun én gang, uavhengig av innlogging.

struct AuthView: View {

    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    // Epost/passord (for testing)
    @State private var email = ""
    @State private var password = ""
    @State private var showEmailLogin = false

    /// Kalles i tillegg til at sheet-en lukkes, slik at f.eks. CigarDetailView
    /// kan fortsette en avbrutt "legg i humidor"-handling rett etter innlogging.
    var onSuccess: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo
                VStack(spacing: 8) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    Text("Logg inn")
                        .font(.title.bold())
                        .foregroundColor(Color("TextPrimary"))
                    Text("for å lagre sigarer i humidoren din")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                }

                Spacer()

                LoginOptionsView(
                    showEmailLogin: $showEmailLogin,
                    email: $email,
                    password: $password,
                    isSigningIn: $isSigningIn,
                    errorMessage: $errorMessage,
                    onAppleSignIn: signInWithApple,
                    onGoogleSignIn: signInWithGoogle,
                    onEmailSignIn: signInWithEmail
                )

                Spacer()
            }
            .padding(.top, 24)
        }
    }

    private func signInWithApple() {
        isSigningIn = true
        Task {
            do {
                try await authService.signInWithApple()
                handleSuccess()
            } catch {
                errorMessage = "Apple-innlogging feilet: \(error.localizedDescription)"
            }
            isSigningIn = false
        }
    }

    private func signInWithGoogle() {
        isSigningIn = true
        Task {
            do {
                try await authService.signInWithGoogle()
                handleSuccess()
            } catch {
                errorMessage = "Google-innlogging feilet: \(error.localizedDescription)"
            }
            isSigningIn = false
        }
    }

    private func signInWithEmail() {
        isSigningIn = true
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                handleSuccess()
            } catch {
                // Prøv å registrere ny bruker
                do {
                    try await authService.signUp(email: email, password: password)
                    handleSuccess()
                } catch {
                    errorMessage = "Innlogging feilet: \(error.localizedDescription)"
                }
            }
            isSigningIn = false
        }
    }

    private func handleSuccess() {
        onSuccess?()
        dismiss()
    }
}

// MARK: - Innloggingsalternativer
struct LoginOptionsView: View {
    @Binding var showEmailLogin: Bool
    @Binding var email: String
    @Binding var password: String
    @Binding var isSigningIn: Bool
    @Binding var errorMessage: String?
    var onAppleSignIn: () -> Void
    var onGoogleSignIn: () -> Void
    var onEmailSignIn: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Apple Sign In
            Button(action: onAppleSignIn) {
                HStack {
                    Image(systemName: "applelogo")
                    Text("Fortsett med Apple")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.primary)
                .foregroundColor(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Google Sign In
            Button(action: onGoogleSignIn) {
                HStack {
                    Image(systemName: "globe")
                    Text("Fortsett med Google")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("Surface"))
                .foregroundColor(Color("TextPrimary"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("TextSecondary").opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // E-post alternativ (testing/beta)
            if showEmailLogin {
                VStack(spacing: 8) {
                    TextField("E-post", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Passord", text: $password)
                        .textFieldStyle(.roundedBorder)

                    Button(action: onEmailSignIn) {
                        Text(isSigningIn ? "Logger inn..." : "Logg inn / Registrer")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Accent"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isSigningIn)
                }
            } else {
                Button(action: { showEmailLogin = true }) {
                    Text("Bruk e-post i stedet")
                        .font(.subheadline)
                        .foregroundColor(Color("Accent"))
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
    }
}
