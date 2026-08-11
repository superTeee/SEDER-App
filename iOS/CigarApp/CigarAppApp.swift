import SwiftUI
import UIKit
import GoogleSignIn

// MARK: - ProManager
//
// Én kilde til sannhet for «er brukeren Pro?».
// Pro = engangskjøp av SEDER Pro (StoreKit, speiles fra StoreManager)
// ELLER tidlig tester (livstids-Pro fra databasen). Ingen abonnement.
@MainActor
final class ProManager: ObservableObject {
    static let shared = ProManager()

    /// Livstids-Pro for tidlige testere (fra databasen).
    @Published var isFoundingMember = false
    /// Speiler StoreKit-eierskap av engangs-Pro (settes av StoreManager).
    @Published var storeOwnsPro = false

    /// Appens Pro-flagg — bruk denne overalt for å låse opp funksjoner.
    var isPro: Bool { storeOwnsPro || isFoundingMember }

    private init() {}
}

// Antall «grunnleggere» som får en egen velkomst ved lansering.
enum FoundingConfig {
    static let cap = 100
}


@main
struct CigarAppApp: App {

    @StateObject private var authService = AuthService()
    @StateObject private var pinService = PINService()
    @StateObject private var proManager = ProManager.shared

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

    // Lansering: founding-medlem-feiring (vises én gang etter onboarding)
    @AppStorage("hasSeenFoundingWelcome") private var hasSeenFoundingWelcome = false
    @State private var showFoundingWelcome = false
    @State private var foundingNumber = 0

    /// Tildel founding-nummer og vis feiringen én gang (ekskluderer tidlige testere).
    @MainActor private func checkFoundingWelcome() async {
        guard authService.isAuthenticated, !hasSeenFoundingWelcome else { return }
        do {
            if let n = try await ProfileService().claimFoundingNumber() {
                foundingNumber = n
                showFoundingWelcome = true
            } else {
                hasSeenFoundingWelcome = true   // tester/ekskludert — hopp over
            }
        } catch {
            // Nettverks-/serverfeil: la flagget stå, prøv igjen ved neste oppstart.
        }
    }

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
                    OnboardingProfileView(onComplete: {
                        showProfileOnboarding = false
                        Task { await checkFoundingWelcome() }
                    })
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
                        .environmentObject(proManager)
                        .fullScreenCover(isPresented: $showFoundingWelcome) {
                            FoundingWelcomeView(number: foundingNumber) {
                                hasSeenFoundingWelcome = true
                                showFoundingWelcome = false
                            }
                            .environmentObject(proManager)
                        }
                }
            }
            .onAppear {
                // Splashen legges i sitt eget vindu over appen ved første render.
                SplashOverlayWindow.shared.present()
                // Utforsk-dataene hentes mens splashen spiller, så siden er
                // ferdig utfylt før brukeren i det hele tatt ser den.
                ExploreStore.shared.preload()
                // SEDER Pro + tips (StoreKit 2) — last produkter og eierskap ved oppstart.
                StoreManager.shared.start()
                // Tell øktstarter (for å vite når bidra-skjermen kan poppe opp senere).
                SupportPromptManager.shared.appDidBecomeActive()
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
                // Tidlige testere har livstids-Pro uten kjøp.
                proManager.isFoundingMember = profile?.isFoundingMember ?? false
                profileCheckInProgress = false
                if !showProfileOnboarding { await checkFoundingWelcome() }
            }
            .preferredColorScheme(preferredScheme)
        }
    }
}

// MARK: - Founding-medlem-feiring (lansering)
struct FoundingWelcomeView: View {
    let number: Int
    var onClose: () -> Void

    private var isFounding: Bool { number <= FoundingConfig.cap }

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            VStack(spacing: 16) {
                Spacer()

                ZStack {
                    Circle().stroke(Color("Accent"), lineWidth: 1.5).frame(width: 96, height: 96)
                    Image(systemName: isFounding ? "rosette" : "checkmark.seal")
                        .font(.system(size: 40)).foregroundColor(Color("Accent"))
                }

                if isFounding {
                    Text("Gratulerer")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(Color("Accent"))
                    (Text("\(number)").font(.system(size: 44, weight: .bold)).foregroundColor(Color("TextPrimary"))
                     + Text(" / \(FoundingConfig.cap)").font(.system(size: 26, weight: .semibold)).foregroundColor(Color("TextSecondary")))
                    Text("Du er blant de \(FoundingConfig.cap) første medlemmene i SEDER")
                        .font(.subheadline).foregroundColor(Color("TextSecondary"))
                        .multilineTextAlignment(.center).padding(.horizontal, 40)
                } else {
                    Text("Velkommen til SEDER")
                        .font(.system(size: 24, weight: .bold)).foregroundColor(Color("TextPrimary"))
                    Text("Din digitale humidor og sigarjournal")
                        .font(.subheadline).foregroundColor(Color("TextSecondary"))
                        .multilineTextAlignment(.center).padding(.horizontal, 40)
                }

                Button { onClose() } label: {
                    Text("Kom i gang")
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(Color("Accent")).clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 28).padding(.top, 8)

                Spacer()
            }
        }
    }
}


struct SplashView: View {
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            VStack(spacing: 16) {
                Image("VitolaLogo")   // Ny SEDER-lockup (monogram + ordmerke)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 190, maxHeight: 140)
            }
        }
    }
}
