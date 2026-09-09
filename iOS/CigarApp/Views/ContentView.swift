import SwiftUI

// MARK: - AppShell
// Global coordinator for scanning and shared app state.
enum ScanAction { case band, photo, receipt }

extension Notification.Name {
    /// Sent when a log entry is completed -> switch to Logg.
    static let didLogTasting = Notification.Name("didLogTasting")
}

@MainActor
final class AppShell: ObservableObject {
    @Published var showScan = false
    @Published var pendingScan: ScanAction? = nil
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
// Review-safe information architecture:
// Søk · Logg | [Skann FAB] | Humidor · Innstillinger
//
// Profil and Aktivitet are intentionally removed from primary navigation.
// Scan remains a global FAB because identification is a core utility action.
struct ContentView: View {

    @EnvironmentObject var authService: AuthService
    @StateObject private var appShell = AppShell()
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTab = 0
    @AppStorage("humidorHasNew") private var humidorHasNew: Bool = false

    private let searchTag   = 0
    private let logTag      = 2
    private let humidorTag  = 1
    private let settingsTag = 4

    var body: some View {
        TabView(selection: $selectedTab) {
            ExploreView()
                .tag(searchTag)
                .toolbar(.hidden, for: .tabBar)

            JournalView()
                .tag(logTag)
                .toolbar(.hidden, for: .tabBar)

            HumidorView()
                .tag(humidorTag)
                .toolbar(.hidden, for: .tabBar)

            SettingsRootView()
                .environmentObject(authService)
                .tag(settingsTag)
                .toolbar(.hidden, for: .tabBar)
        }
        .tint(Color("Accent"))
        .environmentObject(appShell)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customTabBar
        }
        .task {
            if let uid = authService.userId {
                await appShell.loadOwnProfile(userId: uid)
            }
        }
        .onChange(of: authService.userId) { uid in
            if let uid {
                Task { await appShell.loadOwnProfile(userId: uid) }
            }
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
            // ExploreView currently owns the scan/receipt flows.
            // Keep routing there while its visible content is being simplified.
            if action != nil { selectedTab = searchTag }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didLogTasting)) { _ in
            selectedTab = logTag
        }
    }

    // MARK: - Custom tab bar

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

// MARK: - SettingsRootView
// A neutral utility/settings destination replacing the previous profile tab.
// Profile/taste-preference content is intentionally not part of the primary IA.
struct SettingsRootView: View {
    @EnvironmentObject var authService: AuthService
    @AppStorage("appearance") private var appearance = "system"
    @State private var showSignOutConfirm = false

    var body: some View {
        NavigationStack {
            List {
                if let email = authService.currentUser?.email {
                    Section("Konto") {
                        LabeledContent("Innlogget som", value: email)
                    }
                }

                Section("Utseende") {
                    Picker("Tema", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Mørk").tag("dark")
                        Text("Lys").tag("light")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Om SEDER") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Helse og formål")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Tobakk innebærer helserisiko. SEDER selger ingen produkter, formidler ingen kjøp og oppfordrer ikke til bruk. Appen er et referanse-, lagrings- og registreringsverktøy for voksne som ønsker å holde oversikt over en egen samling.")
                            .font(.system(size: 13))
                            .foregroundColor(Color("TextSecondary"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)

                    Link("Vilkår for bruk", destination: URL(string: "https://sederappen.no/terms.html")!)
                    Link("Personvern", destination: URL(string: "https://sederappen.no/privacy.html")!)
                }

                if authService.userId != nil {
                    Section {
                        Button("Logg ut", role: .destructive) {
                            showSignOutConfirm = true
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color("Background"))
            .navigationTitle("Innstillinger")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Logg ut?", isPresented: $showSignOutConfirm) {
                Button("Avbryt", role: .cancel) {}
                Button("Logg ut", role: .destructive) {
                    Task { try? await authService.signOut() }
                }
            }
        }
    }
}

// Kept for compatibility with screens that still reference the avatar helper.
// It is no longer exposed from the primary navigation.
struct ProfileAvatarButton: View {
    @EnvironmentObject var appShell: AppShell

    var body: some View {
        AvatarView(url: appShell.ownAvatarUrl, name: appShell.ownName, size: 30)
            .accessibilityHidden(true)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
