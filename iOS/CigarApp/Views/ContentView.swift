import SwiftUI

// MARK: - ContentView
// Tab-navigasjon: Scan | Humidor | Historikk

struct ContentView: View {

    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0

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
                    Label("Humidor", systemImage: "archivebox.fill")
                }
                .tag(1)

            // Tab 3: Historikk
            HistoryView()
                .tabItem {
                    Label("Historikk", systemImage: "clock.fill")
                }
                .tag(2)
        }
        .accentColor(Color("Accent"))
    }
}

// MARK: - History View (placeholder)
struct HistoryView: View {
    var body: some View {
        NavigationStack {
            Text("Røykelogg kommer her")
                .foregroundColor(.secondary)
                .navigationTitle("Historikk")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
