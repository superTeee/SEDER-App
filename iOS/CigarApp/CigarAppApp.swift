import SwiftUI
import UIKit
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

    /// Lanseringskampanje: de N første nye medlemmene får rabattkoden.
    static let foundingCode = "SEDER100"
    static let foundingCap  = 100

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

    /// Kun for testing i debug-builds: behandle meg som gratisbruker, så paywallen
    /// vises selv om jeg er tidlig tester. Et ekte (test-)kjøp slår fortsatt på Pro.
    /// Er alltid false i release (ingen UI flipper den der).
    @Published var debugForceFree = false

    /// Appens Pro-flagg — bruk denne overalt for å låse opp funksjoner.
    var isPro: Bool { isSubscriber || (isFoundingMember && !debugForceFree) }

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

    /// Åpne Apples ark for å løse inn en kampanje-/tilbudskode (f.eks. lanseringstilbud).
    func redeemPromoCode() {
        guard configured else { return }
        Purchases.shared.presentCodeRedemptionSheet()
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

    // Lansering: founding-medlem-feiring (vises én gang etter onboarding)
    @AppStorage("hasSeenFoundingWelcome") private var hasSeenFoundingWelcome = false
    @State private var showFoundingWelcome = false
    @State private var foundingNumber = 0

    /// Tildel founding-nummer og vis feiringen én gang (ekskluderer tidlige testere).
    @MainActor private func checkFoundingWelcome() async {
        guard authService.isAuthenticated, !hasSeenFoundingWelcome else { return }
        if let n = await ProfileService().claimFoundingNumber() {
            foundingNumber = n
            showFoundingWelcome = true
        } else {
            hasSeenFoundingWelcome = true   // tester/ekskludert — hopp over
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
    @EnvironmentObject private var proManager: ProManager
    @State private var copied = false

    private var isFounding: Bool { number <= ProConfig.foundingCap }

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
                     + Text(" / \(ProConfig.foundingCap)").font(.system(size: 26, weight: .semibold)).foregroundColor(Color("TextSecondary")))
                    Text("Du er blant de \(ProConfig.foundingCap) første medlemmene i SEDER")
                        .font(.subheadline).foregroundColor(Color("TextSecondary"))
                        .multilineTextAlignment(.center).padding(.horizontal, 40)

                    Button { copyCode() } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DIN FOUNDING-KODE")
                                .font(.system(size: 11, weight: .semibold)).tracking(0.5)
                                .foregroundColor(Color("TextSecondary"))
                            HStack {
                                Text(ProConfig.foundingCode)
                                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Color("TextPrimary"))
                                Spacer()
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                    .foregroundColor(Color("Accent"))
                            }
                            Text("100 kr av første år · 349 kr")
                                .font(.system(size: 12)).foregroundColor(Color("TextSecondary"))
                        }
                        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color("Card")).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain).padding(.horizontal, 28).padding(.top, 6)

                    Button { copyCode(); proManager.redeemPromoCode() } label: {
                        Text("Bruk koden nå")
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(Color("Accent")).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 28).padding(.top, 4)

                    Button("Kanskje senere") { onClose() }
                        .font(.system(size: 14)).foregroundColor(Color("TextSecondary")).padding(.top, 2)
                } else {
                    Text("Velkommen til SEDER")
                        .font(.system(size: 24, weight: .bold)).foregroundColor(Color("TextPrimary"))
                    Text("Din digitale humidor og sigarjournal")
                        .font(.subheadline).foregroundColor(Color("TextSecondary"))
                        .multilineTextAlignment(.center).padding(.horizontal, 40)
                    Button { onClose() } label: {
                        Text("Kom i gang")
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(Color("Accent")).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 28).padding(.top, 8)
                }

                Spacer()
            }
        }
    }

    private func copyCode() {
        UIPasteboard.general.string = ProConfig.foundingCode
        withAnimation { copied = true }
    }
}

// MARK: - Splash View
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
