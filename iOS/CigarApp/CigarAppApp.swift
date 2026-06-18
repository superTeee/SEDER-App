import SwiftUI

@main
struct CigarAppApp: App {

    @StateObject private var authService = AuthService()
    @StateObject private var pinService = PINService()

    @AppStorage("hasVerifiedAge") private var hasVerifiedAge = false
    @State private var isUnlocked = false

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading {
                    // Splash/loading
                    SplashView()
                } else if !hasVerifiedAge {
                    // Aldersbekreftelse — vises kun én gang, uavhengig av innlogging
                    AgeGateView(onVerified: { hasVerifiedAge = true })
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
                Task { await authService.handleDeepLink(url) }
            }
            .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
                if !isAuthenticated {
                    // Ny innlogging skal kunne trigge PIN-skjermen på nytt
                    isUnlocked = false
                }
            }
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
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                Text("Vitola")
                    .font(.largeTitle.bold())
                    .foregroundColor(Color("TextPrimary"))
            }
        }
    }
}
