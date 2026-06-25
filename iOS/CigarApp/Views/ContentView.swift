import SwiftUI

// MARK: - ContentView
// Tab-navigasjon: Scan | Min humidor | Journal | Venner | Profil

struct ContentView: View {

    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {

            // Tab 0: Scan
            ScanView()
                .tabItem {
                    Label("Scan", systemImage: "camera.viewfinder")
                }
                .tag(0)

            // Tab 1: Humidor
            HumidorView()
                .tabItem {
                    Label("Min humidor", systemImage: "archivebox.fill")
                }
                .tag(1)

            // Tab 2: Journal (røykelogg)
            JournalView()
                .tabItem {
                    Label("Journal", systemImage: "book.closed.fill")
                }
                .tag(2)

            // Tab 3: Venner
            VennerView()
                .tabItem {
                    Label("Venner", systemImage: "person.2.fill")
                }
                .tag(3)

            // Tab 4: Profil
            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.crop.circle")
                }
                .tag(4)
        }
        .accentColor(Color("Accent"))
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
