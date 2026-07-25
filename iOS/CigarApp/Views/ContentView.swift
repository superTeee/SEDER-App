import SwiftUI

// MARK: - AppShell
// Liten app-koordinator som lar den globale skann-knappen og profil-avataren
// (som lever i ContentView / toolbars) styre resten av appen:
//  • showScan/pendingScan — åpner skann-arket globalt, kjører flyt på Utforsk
//  • showProfile — presenterer profilen modalt (avatar øverst til venstre)
//  • ownAvatarUrl/ownName — hentes én gang, brukes i avatar-knappen
enum ScanAction { case band, photo, receipt }

@MainActor
final class AppShell: ObservableObject {
    /// Presenterer skann-arket globalt (over gjeldende fane — ingen navigasjon).
    @Published var showScan = false
    /// Valgt skann-handling → Utforsk kjører riktig flyt (kamera/kvittering).
    @Published var pendingScan: ScanAction? = nil
    @Published var showProfile = false
    @Published var ownAvatarUrl: String?
    @Published var ownName: String = ""

    private let profileService = ProfileService()

    /// Åpner skann-arket der brukeren står (senter-knappen).
    func requestScan() { showScan = true }

    /// Henter egen avatar/navn til profil-knappen (kalles én gang ved oppstart).
    func loadOwnProfile(userId: UUID) async {
        if let p = try? await profileService.fetchOwnProfile(userId: userId) {
            ownAvatarUrl = p.avatarUrl
            ownName = p.displayName ?? ""
        }
    }
}

// MARK: - ContentView
// Egen tab-bar (SwiftUI TabView støtter ikke en overlappende senter-knapp):
// 4 faner (Utforsk · Aktivitet | Journal · Humidor) med en hevet, rund
// SKANN-knapp i midten. Profil er flyttet ut av tab-baren til en avatar
// øverst til venstre på hver hovedskjerm.
struct ContentView: View {

    @EnvironmentObject var authService: AuthService
    @StateObject private var appShell = AppShell()
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTab = 0   // åpner på Utforsk
    @AppStorage("humidorHasNew") private var humidorHasNew: Bool = false

    // Fane-taggene beholdes fra før (0=Utforsk, 3=Aktivitet, 2=Journal, 1=Humidor)
    private let exploreTag  = 0
    private let activityTag = 3
    private let journalTag  = 2
    private let humidorTag  = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            ExploreView()
                .tag(exploreTag)
                .toolbar(.hidden, for: .tabBar)

            ActivityView()
                .environmentObject(authService)
                .tag(activityTag)
                .toolbar(.hidden, for: .tabBar)

            JournalView()
                .tag(journalTag)
                .toolbar(.hidden, for: .tabBar)

            HumidorView()
                .tag(humidorTag)
                .toolbar(.hidden, for: .tabBar)
        }
        .tint(Color("Accent"))
        .environmentObject(appShell)
        // Egen tab-bar legges i safe-area-inset → innhold skyves aldri under baren
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customTabBar
        }
        .task {
            if let uid = authService.userId { await appShell.loadOwnProfile(userId: uid) }
        }
        .onChange(of: authService.userId) { uid in
            if let uid { Task { await appShell.loadOwnProfile(userId: uid) } }
        }
        .fullScreenCover(isPresented: $appShell.showProfile) {
            ProfileView(onClose: { appShell.showProfile = false })
                .environmentObject(authService)
                .environmentObject(appShell)
        }
        // Skann-arket presenteres globalt (over gjeldende fane). Først når et valg
        // gjøres bytter vi til Utforsk og kjører flyten der (kamera/kvittering).
        .sheet(isPresented: $appShell.showScan) {
            ScanSheet(
                onBand:    { appShell.pendingScan = .band },
                onPhoto:   { appShell.pendingScan = .photo },
                onReceipt: { appShell.pendingScan = .receipt }
            )
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: appShell.pendingScan) { action in
            if action != nil { selectedTab = exploreTag }
        }
    }

    // MARK: - Egen tab-bar

    // Opak bar-farge (hvit i light, mørkt kort i dark) — tydelig atskilt fra
    // den beige sidebakgrunnen slik at innhold ikke skinner gjennom.
    private var barFill: Color {
        colorScheme == .light ? .white : Color("Card")
    }

    private var customTabBar: some View {
        ZStack {
            // Fanene
            HStack(spacing: 0) {
                tabButton(tag: exploreTag,  title: "Utforsk",   image: "tab_explore")
                tabButton(tag: activityTag, title: "Aktivitet", image: "tab_feed")

                // Hull til senter-knappen (smalere → fanene 4px nærmere skann-knappen)
                Color.clear.frame(width: 66)

                tabButton(tag: journalTag,  title: "Journal",   image: "tab_journal")
                tabButton(tag: humidorTag,  title: "Humidor",   image: "tab_humidor", showBadge: humidorHasNew)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .padding(.horizontal, 8)   // trekk fanene litt nærmere senter-knappen

            // Hevet senter-knapp: SKANN
            scanCenterButton
                .offset(y: -16)
        }
        .background(
            barFill
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: -2)
                .overlay(
                    Rectangle()
                        .fill(Color("TextSecondary").opacity(0.10))
                        .frame(height: 0.5),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(tag: Int, title: String, image: String, showBadge: Bool = false) -> some View {
        let selected = selectedTab == tag
        return Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(image)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                    if showBadge {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 5, y: -2)
                    }
                }
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(selected ? Color("Accent") : Color("TextSecondary").opacity(0.6))
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var scanCenterButton: some View {
        Button {
            appShell.requestScan()         // åpne skann-arket der brukeren står
        } label: {
            ZStack {
                Circle()
                    .fill(Color("Accent"))
                    .frame(width: 60, height: 60)
                    .shadow(color: Color("Accent").opacity(0.35), radius: 8, x: 0, y: 3)

                // Skann-ikon: søker-ramme + horisontal skann-strek
                ZStack {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 27, weight: .light))
                    Capsule()
                        .frame(width: 19, height: 2)
                }
                .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Skann")
    }
}

// MARK: - ProfileAvatarButton
// Avatar-knappen som ligger øverst til venstre på hovedskjermene og åpner
// profilen. Leser cachet avatar/navn fra AppShell.
struct ProfileAvatarButton: View {
    @EnvironmentObject var appShell: AppShell

    var body: some View {
        Button {
            appShell.showProfile = true
        } label: {
            AvatarView(url: appShell.ownAvatarUrl, name: appShell.ownName, size: 30)
        }
        .buttonStyle(.plain)   // fjern iOS-standard rund knappe-bakgrunn/kant i toolbaren
        .accessibilityLabel("Profil")
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
