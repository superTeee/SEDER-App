import SwiftUI

// MARK: - AppShell

enum ScanAction { case band, photo, receipt }

extension Notification.Name {
    static let didLogTasting = Notification.Name("didLogTasting")
}

@MainActor
final class AppShell: ObservableObject {
    @Published var showScan = false
    @Published var pendingScan: ScanAction? = nil

    // Kept for source compatibility with legacy views. Profile is not exposed
    // anywhere in the review-safe primary navigation.
    @Published var showProfile = false
    @Published var ownAvatarUrl: String?
    @Published var ownName: String = ""

    private let profileService = ProfileService()

    func requestScan() { showScan = true }

    func loadOwnProfile(userId: UUID) async {
        if let p = try? await profileService.fetchOwnProfile(userId: userId) {
            ownAvatarUrl = p.avatarUrl
            ownName = p.displayName ?? ""
        }
    }
}

// MARK: - ContentView
// App Review build IA:
// Søk · Logg | [Skann FAB] | Humidor · Innstillinger
struct ContentView: View {

    @EnvironmentObject var authService: AuthService
    @StateObject private var appShell = AppShell()
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTab = 0
    @AppStorage("humidorHasNew") private var humidorHasNew: Bool = false

    private let searchTag   = 0
    private let logTag      = 1
    private let humidorTag  = 2
    private let settingsTag = 3

    var body: some View {
        TabView(selection: $selectedTab) {
            ReviewSearchView()
                .tag(searchTag)
                .toolbar(.hidden, for: .tabBar)

            ReviewLogView()
                .tag(logTag)
                .toolbar(.hidden, for: .tabBar)

            ReviewHumidorView()
                .tag(humidorTag)
                .toolbar(.hidden, for: .tabBar)

            SettingsRootView()
                .tag(settingsTag)
                .toolbar(.hidden, for: .tabBar)
        }
        .tint(Color("Accent"))
        .environmentObject(appShell)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customTabBar
        }
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
            if action != nil { selectedTab = searchTag }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didLogTasting)) { _ in
            selectedTab = logTag
        }
    }

    private var barFill: Color {
        colorScheme == .light ? .white : Color("Card")
    }

    private var customTabBar: some View {
        ZStack {
            HStack(spacing: 0) {
                tabButton(tag: searchTag, title: "Søk", image: "tab_explore")
                tabButton(tag: logTag, title: "Logg", image: "tab_journal")

                Color.clear.frame(width: 66)

                tabButton(tag: humidorTag, title: "Humidor", image: "tab_humidor", showBadge: humidorHasNew)
                tabButton(tag: settingsTag, title: "Innstillinger", systemImage: "gearshape")
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .padding(.horizontal, 12)

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

    private func tabButton(
        tag: Int,
        title: String,
        image: String? = nil,
        systemImage: String? = nil,
        showBadge: Bool = false
    ) -> some View {
        let selected = selectedTab == tag
        let inactive = Color("TextSecondary")

        return Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selected ? Color("Accent") : Color.clear)
                        .frame(width: 46, height: 34)

                    Group {
                        if let image {
                            Image(image)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                        } else if let systemImage {
                            Image(systemName: systemImage)
                                .font(.system(size: 23, weight: .regular))
                        }
                    }
                    .foregroundColor(selected ? .white : inactive)
                    .overlay(alignment: .topTrailing) {
                        if showBadge {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 4, y: -2)
                        }
                    }
                }
                .frame(height: 34)

                Text(title)
                    .font(.system(size: 10, weight: selected ? .semibold : .medium))
                    .foregroundColor(selected ? Color("Accent") : inactive)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var scanCenterButton: some View {
        Button {
            appShell.requestScan()
        } label: {
            ZStack {
                Circle()
                    .fill(Color("Accent"))
                    .frame(width: 60, height: 60)

                ZStack {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 27, weight: .regular))
                    Capsule().frame(width: 19, height: 2)
                }
                .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Skann")
    }
}

/// Kept for source compatibility with legacy views that still reference the old
/// avatar toolbar helper. Profile is intentionally not exposed in this build.
struct ProfileAvatarButton: View {
    var body: some View { EmptyView() }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
