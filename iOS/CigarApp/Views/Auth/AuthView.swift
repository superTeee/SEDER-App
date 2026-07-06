import SwiftUI
import AuthenticationServices  // For ASAuthorizationError.canceled

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

    // Vises kun når en NY bruker registrerer seg med e-post
    @State private var showCompleteProfile = false

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
                        .clipShape(RoundedRectangle(cornerRadius: 6))
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
        .fullScreenCover(isPresented: $showCompleteProfile) {
            if let uid = authService.userId {
                CompleteProfileView(email: email, userId: uid) {
                    showCompleteProfile = false
                    handleSuccess()
                }
            }
        }
    }

    private func signInWithGoogle() {
        isSigningIn = true
        Task {
            do {
                try await authService.signInWithGoogle()
                handleSuccess()
            } catch {
                let nsError = error as NSError
                // Kode 1 = brukeren avbrøt Google Sign-In
                if nsError.code != 1 || nsError.domain != "com.google.GIDSignIn" {
                    errorMessage = "Google-innlogging feilet: \(error.localizedDescription)"
                }
            }
            isSigningIn = false
        }
    }

    private func signInWithApple() {
        isSigningIn = true
        Task {
            do {
                try await authService.signInWithApple()
                handleSuccess()
            } catch {
                // Brukeren avbrøt = ikke vis feil
                let nsError = error as NSError
                if nsError.code != ASAuthorizationError.canceled.rawValue {
                    errorMessage = "Apple-innlogging feilet: \(error.localizedDescription)"
                }
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
                // Prøv å registrere ny bruker → vis "Fullfør profil"-skjermen
                do {
                    try await authService.signUp(email: email, password: password)
                    showCompleteProfile = true
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

    @State private var showPassword = false

    var body: some View {
        VStack(spacing: 12) {
            // Sign In with Apple
            Button(action: onAppleSignIn) {
                HStack(spacing: 8) {
                    Image(systemName: "applelogo")
                        .font(.body)
                    Text("Fortsett med Apple")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color("Card"))
                .foregroundColor(Color("TextPrimary"))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("TextSecondary").opacity(0.25), lineWidth: 0.5)
                )
            }
            .disabled(isSigningIn)

            // Sign In with Google
            Button(action: onGoogleSignIn) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 22, height: 22)
                        Text("G")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 0.26, green: 0.52, blue: 0.96))
                    }
                    Text("Fortsett med Google")
                        .fontWeight(.semibold)
                        .foregroundColor(Color("TextPrimary"))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color("Card"))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("TextSecondary").opacity(0.25), lineWidth: 0.5)
                )
            }
            .disabled(isSigningIn)

            // E-post alternativ (testing/beta)
            if showEmailLogin {
                VStack(spacing: 8) {
                    TextField("E-post", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    HStack {
                        Group {
                            if showPassword {
                                TextField("Passord", text: $password)
                            } else {
                                SecureField("Passord", text: $password)
                            }
                        }
                        .autocapitalization(.none)
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(Color("Card"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )

                    Button(action: onEmailSignIn) {
                        Text(isSigningIn ? "Logger inn..." : "Logg inn / Registrer")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Accent"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
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

// MARK: - CompleteProfileView
// Vises kun ved NY e-post-registrering. Brukeren fyller inn fornavn,
// etternavn og land (alt påkrevd). E-posten er allerede kjent og vises låst.
// Fornavn + etternavn lagres i display_name; land i country.
struct CompleteProfileView: View {

    let email: String
    let userId: UUID
    var onComplete: () -> Void

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var country = "Norge"
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let profileService = ProfileService()

    // Alfabetisk liste over land (norske navn), generert fra systemet.
    private static let countries: [String] = {
        let locale = Locale(identifier: "nb_NO")
        let names = Locale.Region.isoRegions
            .filter { $0.subRegions.isEmpty }            // faktiske land, ikke kontinenter
            .compactMap { locale.localizedString(forRegionCode: $0.identifier) }
        return Array(Set(names)).sorted()
    }()

    private var canSubmit: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !country.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(Color("TextSecondary"))
                        Text(email)
                            .foregroundColor(Color("TextSecondary"))
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(Color("TextSecondary"))
                    }
                } header: {
                    Text("E-post")
                } footer: {
                    Text("Fyll inn navnet ditt så vennene dine finner deg.")
                }

                Section("Navn") {
                    TextField("Fornavn", text: $firstName)
                        .textContentType(.givenName)
                    TextField("Etternavn", text: $lastName)
                        .textContentType(.familyName)
                }

                Section("Land") {
                    Picker("Land", selection: $country) {
                        ForEach(Self.countries, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.navigationLink)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button(action: save) {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Fullfør").fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .listRowBackground(canSubmit ? Color("Accent") : Color("Accent").opacity(0.4))
                    .foregroundColor(.white)
                    .disabled(!canSubmit || isSaving)
                }
            }
            .navigationTitle("Fullfør profilen")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(true)
        }
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                let name = "\(firstName.trimmingCharacters(in: .whitespaces)) \(lastName.trimmingCharacters(in: .whitespaces))"
                try await profileService.updateProfile(userId: userId, displayName: name, city: nil, country: country)
                onComplete()
            } catch {
                errorMessage = "Kunne ikke lagre profilen. Prøv igjen."
            }
            isSaving = false
        }
    }
}
