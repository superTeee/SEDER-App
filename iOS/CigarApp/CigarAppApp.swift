import SwiftUI
import GoogleSignIn
import RevenueCat

// MARK: - RevenueCat-konfigurasjon
//
// Alt Tom trenger å fylle inn står her. RevenueCat sin *public* SDK-nøkkel er
// trygg i kildekode (samme som Supabase anon key / Google client ID).
//
//  SLIK GJØR DU DET NÅR KONTOEN ER KLAR:
//  1. Opprett RevenueCat-konto → nytt prosjekt "SEDER".
//  2. Koble til App Store Connect (App-spesifikk delt hemmelighet).
//  3. Lag to produkter i App Store Connect:  seder_pro_yearly (449 kr/år),
//     seder_pro_monthly (59 kr/mnd). Legg dem i RevenueCat under ett
//     "Offering" (default) med pakketypene Annual + Monthly.
//  4. Lag et Entitlement med ID "pro" og knytt begge produktene til det.
//  5. Kopier "Apple"-API-nøkkelen (starter med appl_) inn under.
//
enum ProConfig {
    /// RevenueCat public SDK-nøkkel. NÅ: test-nøkkel (Test Store) for å verifisere
    /// kjøpsflyten uten App Store. BYTT til produksjonsnøkkelen (starter med "appl_")
    /// når appen er koblet til App Store Connect med ekte produkter.
    /// Trygg i kildekode (public SDK-nøkkel, som Supabase anon key).
    static let revenueCatAPIKey = "test_tweIdoRfwLwIBJdsiNPtcmXEJuQ"

    /// Entitlement-ID satt opp i RevenueCat (må matche identifieren nøyaktig).
    static let entitlementID = "SEDER Pro"

    /// Fallback-priser vist før ekte App Store-priser er lastet.
    static let fallbackYearly  = "449 kr / år"
    static let fallbackMonthly = "59 kr / mnd"

    static var isConfigured: Bool { !revenueCatAPIKey.contains("LIM_INN") }
}

// MARK: - ProManager
//
// Én kilde til sannhet for «er brukeren Pro?». Pro = aktivt RevenueCat-abonnement
// ELLER tidlig tester (livstids-Pro). Injiseres som EnvironmentObject.
@MainActor
final class ProManager: ObservableObject {
    static let shared = ProManager()

    @Published var isSubscriber = false       // aktivt RevenueCat-abonnement
    @Published var isFoundingMember = false   // livstids-Pro for tidlige testere
    @Published var offerings: Offerings?

    /// Appens Pro-flagg — bruk denne overalt for å låse opp funksjoner.
    var isPro: Bool { isSubscriber || isFoundingMember }

    private var configured = false
    private init() {}

    /// Kalles én gang ved oppstart.
    func configure() {
        guard ProConfig.isConfigured, !configured else { return }
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: ProConfig.revenueCatAPIKey)
        configured = true
        Task { await refresh() }
        Task { await loadOfferings() }
    }

    /// Oppdater abonnementsstatus fra RevenueCat.
    func refresh() async {
        guard configured else { return }
        let info = try? await Purchases.shared.customerInfo()
        isSubscriber = info?.entitlements[ProConfig.entitlementID]?.isActive == true
    }

    func loadOfferings() async {
        guard configured else { return }
        offerings = try? await Purchases.shared.offerings()
    }

    /// Kjøp en pakke. Returnerer true ved suksess (eller allerede Pro).
    func purchase(_ package: Package) async -> Bool {
        guard configured else { return false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            isSubscriber = result.customerInfo.entitlements[ProConfig.entitlementID]?.isActive == true
            return isSubscriber
        } catch { return false }
    }

    /// Gjenopprett tidligere kjøp.
    func restore() async -> Bool {
        guard configured else { return false }
        let info = try? await Purchases.shared.restorePurchases()
        isSubscriber = info?.entitlements[ProConfig.entitlementID]?.isActive == true
        return isSubscriber
    }
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
                        .environmentObject(proManager)
                }
            }
            .onAppear {
                // RevenueCat — konfigureres én gang (no-op til API-nøkkel er lagt inn).
                proManager.configure()
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
                // Tidlige testere har livstids-Pro uten kjøp.
                proManager.isFoundingMember = profile?.isFoundingMember ?? false
                await proManager.refresh()
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
