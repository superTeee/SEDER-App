import SwiftUI

// MARK: - ContentView
// Tab-navigasjon med iOS native TabView.
// iOS håndterer automatisk outlined (unselected) og fill-variant (selected).
// MERK: configureWithDefaultBackground() (ikke Opaque) bevarer iOS-standard
// ikon-rendering der unselected = outline og selected = fill.

struct ContentView: View {

    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0   // åpner på Utforsk
    @AppStorage("humidorHasNew") private var humidorHasNew: Bool = false

    init() {
        // Adaptiv bakgrunn: følger Background-asset (lys #F2F0E9 / mørk #131211)
        let tabApp = UITabBarAppearance()
        tabApp.configureWithDefaultBackground()
        tabApp.backgroundColor = UIColor(named: "Background")

        // Tydelig forskjell på valgt vs. uvalgt: valgt = Accent, uvalgt = dempet grå
        let accent = UIColor(named: "Accent") ?? .systemBrown
        let inactive = (UIColor(named: "TextSecondary") ?? .secondaryLabel).withAlphaComponent(0.5)
        let item = UITabBarItemAppearance()
        item.selected.iconColor = accent
        item.selected.titleTextAttributes = [
            .foregroundColor: accent,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        item.normal.iconColor = inactive
        item.normal.titleTextAttributes = [.foregroundColor: inactive]
        tabApp.stackedLayoutAppearance = item
        tabApp.inlineLayoutAppearance = item
        tabApp.compactInlineLayoutAppearance = item

        UITabBar.appearance().standardAppearance = tabApp
        UITabBar.appearance().scrollEdgeAppearance = tabApp
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .environmentObject(authService)
                .tabItem { Label("Feed", image: "tab_feed") }
                .tag(3)

            ExploreView()
                .tabItem { Label("Utforsk", image: "tab_explore") }
                .tag(0)

            HumidorView()
                .tabItem { Label("Humidor", image: "tab_humidor") }
                .badge(humidorHasNew ? 1 : 0)
                .tag(1)

            JournalView()
                .tabItem { Label("Journal", image: "tab_journal") }
                .tag(2)

            ProfileView()
                .tabItem { Label("Profil", image: "tab_profile") }
                .tag(4)
        }
        .accentColor(Color("Accent"))
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
