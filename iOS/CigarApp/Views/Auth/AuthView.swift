import SwiftUI

// MARK: - AuthView
// Aldersbekreftelse + innlogging

struct AuthView: View {

    @EnvironmentObject var authService: AuthService
    @State private var birthYear = ""
    @State private var showAgeError = false
    @State private var ageVerified = false
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    // Epost/passord (for testing)
    @State private var email = ""
    @State private var password = ""
    @State private var showEmailLogin = false

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo
                VStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 64))
                        .foregroundColor(Color("Accent"))
                    Text("Vitola")
                        .font(.largeTitle.bold())
                    Text("Din digitale humidor")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if !ageVerified {
                    // Aldersbekreftelse
                    AgeVerificationView(
                        birthYear: $birthYear,
                        showError: $showAgeError,
                        onVerify: verifyAge
                    )
                } else {
                    // Innlogging
                    LoginOptionsView(
                        showEmailLogin: $showEmailLogin,
                        email: $email,
                        password: $password,
                        isSigningIn: $isSigningIn,
                        errorMessage: $errorMessage,
                        onAppleSignIn: signInWithApple,
                        onEmailSignIn: signInWithEmail
                    )
                }

                Spacer()

                Text("Appen er kun for personer over 18 år.\nKjøp og promotering av tobakk er ikke en del av appen.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
    }

    private func verifyAge() {
        guard let year = Int(birthYear) else {
            showAgeError = true
            return
        }
        let currentYear = Calendar.current.component(.year, from: Date())
        let age = currentYear - year

        if age >= 18 {
            ageVerified = true
        } else {
            showAgeError = true
        }
    }

    private func signInWithApple() {
        isSigningIn = true
        Task {
            do {
                try await authService.signInWithApple()
            } catch {
                errorMessage = "Apple-innlogging feilet: \(error.localizedDescription)"
            }
            isSigningIn = false
        }
    }

    private func signInWithEmail() {
        isSigningIn = true
        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch {
                // Prøv å registrere ny bruker
                do {
                    try await authService.signUp(email: email, password: password)
                } catch {
                    errorMessage = "Innlogging feilet: \(error.localizedDescription)"
                }
            }
            isSigningIn = false
        }
    }
}

// MARK: - Aldersbekreftelse
struct AgeVerificationView: View {
    @Binding var birthYear: String
    @Binding var showError: Bool
    var onVerify: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Bekreft alder")
                .font(.title3.bold())
            Text("Du må være 18 år eller eldre for å bruke Vitola")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            TextField("Fødselsår (f.eks. 1990)", text: $birthYear)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)

            if showError {
                Text("Du må være over 18 år for å bruke appen.")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Button(action: onVerify) {
                Text("Bekreft")
                    .fontWeight(.semibold)
                    .frame(width: 200)
                    .padding()
                    .background(Color("Accent"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 24)
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
                        .foregroundColor(.secondary)
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
