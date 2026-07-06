import SwiftUI
import GoogleSignIn

@main
struct CigarAppApp: App {

    @StateObject private var authService = AuthService()
    @StateObject private var pinService = PINService()

    init() {
        // Konfigurer Google Sign In med iOS client ID
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: "1080195891334-sssk6g0avcs1rdr2srbhi9faedchqilo.apps.googleusercontent.com",
            serverClientID: "1080195891334-h41au7e13un40gn6tg101e4jbbjsj8ut.apps.googleusercontent.com"
        )
    }

    @AppStorage("hasVerifiedAge")      private var hasVerifiedAge      = false
    @AppStorage("hasAcceptedPrivacy")  private var hasAcceptedPrivacy  = false
    @AppStorage("appearance")          private var appearance          = "system"
    @State private var isUnlocked = false
    @State private var showProfileOnboarding = false
    @State private var profileCheckInProgress = false

    // Lys/mørk-modus valgt i innstillinger. nil = følg systemet.
    private var preferredScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading || profileCheckInProgress {
                    // Splash/loading (inkl. profil-sjekk etter innlogging)
                    SplashView()
                } else if !hasVerifiedAge {
                    // Aldersbekreftelse — vises kun én gang
                    AgeGateView(onVerified: { hasVerifiedAge = true })
                } else if !hasAcceptedPrivacy {
                    // Personvernerklæring — må godtas én gang etter aldersbekreftelse
                    PrivacyConsentView(onAccepted: { hasAcceptedPrivacy = true })
                } else if showProfileOnboarding {
                    // Første gangs innlogging — samle visningsnavn
                    OnboardingProfileView(onComplete: { showProfileOnboarding = false })
                        .environmentObject(authService)
                } else if pinService.isPINSet && authService.isAuthenticated && !isUnlocked {
                    // Rask opplåsing med 4-sifret kode (kun når en sesjon faktisk finnes)
                    PINUnlockView(onUnlock: { isUnlocked = true })
                        .environmentObject(authService)
                        .environmentObject(pinService)
                } else {
                    // Hoved-app — tilgjengelig uten innlogging (scan/søk).
                    // Innlogging kreves kun når man vil lagre i humidoren,
                    // og presenteres da som sheet fra HumidorView/CigarDetailView/ProfileView.
                    ContentView()
                        .environmentObject(authService)
                        .environmentObject(pinService)
                }
            }
            .onOpenURL { url in
                // Google Sign In URL-callback
                GIDSignIn.sharedInstance.handle(url)
                Task { await authService.handleDeepLink(url) }
            }
            .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
                if !isAuthenticated {
                    isUnlocked = false
                    showProfileOnboarding = false
                }
            }
            .task(id: authService.isAuthenticated) {
                guard authService.isAuthenticated, let userId = authService.userId else { return }
                profileCheckInProgress = true
                let profile = try? await ProfileService().fetchOwnProfile(userId: userId)
                let name = profile?.displayName ?? ""
                showProfileOnboarding = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                profileCheckInProgress = false
            }
            .preferredColorScheme(preferredScheme)
        }
    }
}

// MARK: - OnboardingProfileView
// Vises én gang etter første innlogging hvis brukeren ikke har satt visningsnavn.
// Viser innlogget e-post (read-only) og samler et visningsnavn som lagres til profiles.

struct OnboardingProfileView: View {

    @EnvironmentObject var authService: AuthService
    var onComplete: () -> Void

    @State private var nameText = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let profileService = ProfileService()

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 0) {

                VStack(spacing: 12) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.bottom, 4)

                    Text("Velkommen til Vitola")
                        .font(.title2.bold())
                        .foregroundColor(Color("TextPrimary"))

                    Text("Sett opp profilen din for å komme i gang")
                        .font(.subheadline)
                        .foregroundColor(Color("TextSecondary"))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 72)
                .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 14) {

                    // E-post — vises read-only så brukeren ser hvilken konto
                    if let email = authService.currentUser?.email {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(Color("TextSecondary"))
                                .frame(width: 20)
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(Color("TextSecondary"))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color("Card"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Navn
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Visningsnavn")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color("TextSecondary"))
                            .padding(.leading, 4)

                        HStack(spacing: 10) {
                            Image(systemName: "person.fill")
                                .foregroundColor(Color("TextSecondary"))
                                .frame(width: 20)
                            TextField("Hva vil du hete?", text: $nameText)
                                .font(.body)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.words)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color("Card"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 4)
                    }

                    Button(action: save) {
                        Group {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Kom i gang")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(nameIsValid ? Color("Accent") : Color("TextSecondary").opacity(0.25))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!nameIsValid || isSaving)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
            }
        }
        .onAppear {
            if let pending = authService.pendingDisplayName, !pending.isEmpty {
                nameText = pending
            }
        }
    }

    private var nameIsValid: Bool {
        !nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        guard let uid = authService.userId, nameIsValid else { return }
        let name = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        isSaving = true
        Task {
            do {
                try await profileService.updateProfile(userId: uid, displayName: name, city: nil)
                authService.pendingDisplayName = nil
                onComplete()
            } catch {
                errorMessage = "Kunne ikke lagre: \(error.localizedDescription)"
            }
            isSaving = false
        }
    }
}

// MARK: - Splash View
struct SplashView: View {
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            VStack(spacing: 16) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Text("Vitola")
                    .font(.largeTitle.bold())
                    .foregroundColor(Color("TextPrimary"))
            }
        }
    }
}
