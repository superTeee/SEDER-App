import SwiftUI

@main
struct CigarAppApp: App {

    @StateObject private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            if authService.isLoading {
                // Splash/loading
                SplashView()
            } else if authService.isAuthenticated {
                // Hoved-app
                ContentView()
                    .environmentObject(authService)
            } else {
                // Innlogging
                AuthView()
                    .environmentObject(authService)
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
                Image(systemName: "leaf.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color("Accent"))
                Text("Vitola")
                    .font(.largeTitle.bold())
            }
        }
    }
}
