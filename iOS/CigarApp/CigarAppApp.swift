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
            .onAppear {
                // Splashen legges i sitt eget vindu over appen ved første render.
                SplashOverlayWindow.shared.present()
                // Utforsk-dataene hentes mens splashen spiller, så siden er
                // ferdig utfylt før brukeren i det hele tatt ser den.
                ExploreStore.shared.preload()
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
                Text("SEDER")
                    .font(.largeTitle.bold())
                    .foregroundColor(Color("TextPrimary"))
            }
        }
    }
}
