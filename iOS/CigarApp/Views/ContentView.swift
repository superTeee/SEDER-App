import SwiftUI

// MARK: - ContentView
// Tab-navigasjon med iOS native TabView.
// iOS håndterer automatisk outlined (unselected) og fill-variant (selected).
// MERK: configureWithDefaultBackground() (ikke Opaque) bevarer iOS-standard
// ikon-rendering der unselected = outline og selected = fill.

struct ContentView: View {

    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 1
    @AppStorage("humidorHasNew") private var humidorHasNew: Bool = false

    init() {
        let bgColor = UIColor(red: 0.949, green: 0.941, blue: 0.914, alpha: 1.0) // #F2F0E9

        // Bruk DefaultBackground for å beholde standard ikon-rendering (outline/fill)
        let tabApp = UITabBarAppearance()
        tabApp.configureWithDefaultBackground()
        tabApp.backgroundColor = bgColor

        UITabBar.appearance().standardAppearance = tabApp
        UITabBar.appearance().scrollEdgeAppearance = tabApp
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ExploreView()
                .tabItem { Label("Utforsk", systemImage: "magnifyingglass") }
                .tag(0)

            HumidorView()
                .tabItem { Label("Min humidor", systemImage: "archivebox") }
                .badge(humidorHasNew ? 1 : 0)
                .tag(1)

            JournalView()
                .tabItem { Label("Journal", systemImage: "book.closed") }
                .tag(2)

            FeedView()
                .environmentObject(authService)
                .tabItem { Label("Feed", systemImage: "newspaper") }
                .tag(3)

            ProfileView()
                .tabItem { Label("Profil", systemImage: "person.crop.circle") }
                .tag(4)
        }
        .accentColor(Color("Accent"))
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
