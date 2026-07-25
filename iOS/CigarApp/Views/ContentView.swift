import SwiftUI

// MARK: - AppShell
// Liten app-koordinator som lar den globale skann-knappen og profil-avataren
// (som lever i ContentView / toolbars) styre resten av appen:
//  • scanTrigger — bumpes for å be Utforsk om å åpne skann-arket
//  • showProfile — presenterer profilen modalt (avatar øverst til venstre)
//  • ownAvatarUrl/ownName — hentes én gang, brukes i avatar-knappen
@MainActor
final class AppShell: ObservableObject {
    @Published var scanTrigger = 0
    @Published var showProfile = false
    @Published var ownAvatarUrl: String?
    @Published var ownName: String = ""

    private let profileService = ProfileService()

    /// Ber Utforsk-fanen åpne skann-arket (senter-knappen).
    func requestScan() { scanTrigger += 1 }

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
    }

    // MARK: - Egen tab-bar

    private var customTabBar: some View {
        ZStack {
            // Bakgrunn + fanene
            HStack(spacing: 0) {
                tabButton(tag: exploreTag,  title: "Utforsk",   image: "tab_explore")
                tabButton(tag: activityTag, title: "Aktivitet", image: "tab_feed")

                // Hull til senter-knappen
                Color.clear.frame(width: 64)

                tabButton(tag: journalTag,  title: "Journal",   image: "tab_journal")
                tabButton(tag: humidorTag,  title: "Humidor",   image: "tab_humidor", showBadge: humidorHasNew)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Color("Background")
                    .overlay(
                        Rectangle()
                            .fill(Color("TextSecondary").opacity(0.12))
                            .frame(height: 0.5),
                        alignment: .top
                    )
                    .ignoresSafeArea(edges: .bottom)
            )

            // Hevet senter-knapp: SKANN
            scanCenterButton
                .offset(y: -20)
        }
    }

    private func tabButton(tag: Int, title: String, image: String, showBadge: Bool = false) -> some View {
        let selected = selectedTab == tag
        return Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    Image(image)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    if showBadge {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 7, height: 7)
                            .offset(x: 5, y: -2)
                    }
                }
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(selected ? Color("Accent") : Color("TextSecondary").opacity(0.55))
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var scanCenterButton: some View {
        Button {
            selectedTab = exploreTag       // skann-flyten lever på Utforsk
            appShell.requestScan()         // be Utforsk åpne skann-arket
        } label: {
            ZStack {
                Circle()
                    .fill(Color("Accent"))
                    .frame(width: 58, height: 58)
                    .shadow(color: Color("Accent").opacity(0.35), radius: 8, x: 0, y: 3)
                Image(systemName: "viewfinder")
                    .font(.system(size: 24, weight: .semibold))
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
                .overlay(Circle().stroke(Color("TextSecondary").opacity(0.15), lineWidth: 0.5))
        }
        .accessibilityLabel("Profil")
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
