import SwiftUI

// MARK: - ContentView
// Tab-navigasjon: Scan | Humidor | Profil
// Vises uavhengig av innloggingsstatus — Humidor-tab og lagring krever
// innlogging, men det håndteres internt i HumidorView/CigarDetailView.

struct ContentView: View {

    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {

            // Tab 1: Scan
            ScanView()
                .tabItem {
                    Label("Scan", systemImage: "camera.viewfinder")
                }
                .tag(0)

            // Tab 2: Humidor
            HumidorView()
                .tabItem {
                    Label("Min humidor", systemImage: "archivebox.fill")
                }
                .tag(1)

            // Tab 3: Profil
            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.crop.circle")
                }
                .tag(2)
        }
        .accentColor(Color("Accent"))
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
