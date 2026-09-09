import SwiftUI
import UIKit

// MARK: - AppShell

enum ScanAction { case band, photo, receipt }

extension Notification.Name {
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
// App Review build IA:
// Søk · Logg | [Skann FAB] | Humidor · Innstillinger
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
            ReviewSearchView()
                .tag(searchTag)
                .toolbar(.hidden, for: .tabBar)

            ReviewLogView()
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

// MARK: - ReviewSearchView
// Neutral reference/search surface. No featured, top-rated, favorites or wishlist content.
struct ReviewSearchView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var appShell: AppShell
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var cigarService = CigarService()
    @StateObject private var scanService = ScanService()

    @State private var query = ""
    @State private var results: [Cigar] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    @State private var showCameraPicker = false
    @State private var showLibraryPicker = false
    @State private var capturedImage: UIImage?
    @State private var cropRequest: CropRequest?
    @State private var navigateToResults = false

    private let humidorService = HumidorService()
    private let receiptService = ReceiptService()
    @State private var humidors: [Humidor] = []
    @State private var receiptImage: UIImage?
    @State private var showReceiptSource = false
    @State private var showReceiptCamera = false
    @State private var showReceiptLibrary = false
    @State private var receiptResult: ReceiptParseResult?
    @State private var isParsingReceipt = false
    @State private var receiptError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                    if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        emptySearchState
                    } else if isSearching {
                        Spacer()
                        ProgressView("Søker…")
                        Spacer()
                    } else {
                        resultList
                    }
                }
            }
            .navigationTitle("Søk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("Background"), for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .navigationDestination(isPresented: $navigateToResults) {
                ResultsView(
                    results: scanService.scanResults,
                    ocrText: scanService.extractedText,
                    bandImage: capturedImage,
                    onScanNext: { startNewScan() }
                )
            }
            .sheet(isPresented: $showCameraPicker) {
                ImagePicker(image: $capturedImage, sourceType: .camera) {
                    if let image = capturedImage {
                        Task { await scanService.scanBandImage(image) }
                    }
                }
            }
            .sheet(isPresented: $showLibraryPicker) {
                ImagePicker(image: $capturedImage, sourceType: .photoLibrary) {
                    if let image = capturedImage {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            cropRequest = CropRequest(image: image, ratio: nil)
                        }
                    }
                }
            }
            .fullScreenCover(item: $cropRequest) { req in
                ImageCropper(image: req.image) { cropped in
                    cropRequest = nil
                    capturedImage = cropped
                    Task { await scanService.scanBandImage(cropped) }
                } onCancel: {
                    cropRequest = nil
                }
            }
            .fullScreenCover(isPresented: $scanService.needsShapePhoto) {
                ShapeConfirmView(scanService: scanService)
            }
            .fullScreenCover(isPresented: $scanService.needsWrapperPhoto) {
                WrapperConfirmView(scanService: scanService)
            }
            .sheet(isPresented: $showReceiptSource) {
                ReceiptSourceSheet(
                    onCamera: { showReceiptCamera = true },
                    onLibrary: { showReceiptLibrary = true }
                )
                .presentationDetents([.height(230)])
            }
            .sheet(isPresented: $showReceiptCamera) {
                ImagePicker(image: $receiptImage, sourceType: .camera) {
                    if let image = receiptImage {
                        Task { await parseReceipt(image) }
                    }
                }
            }
            .sheet(isPresented: $showReceiptLibrary) {
                ImagePicker(image: $receiptImage, sourceType: .photoLibrary) {
                    if let image = receiptImage {
                        Task { await parseReceipt(image) }
                    }
                }
            }
            .sheet(item: $receiptResult) { result in
                ReceiptConfirmView(
                    result: result,
                    humidors: humidors,
                    userId: authService.userId ?? UUID(),
                    onFinished: {}
                )
                .environmentObject(authService)
            }
            .alert("Ingen treff", isPresented: $scanService.noMatch) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Vi fant ingen sikker match. Prøv et tydeligere bilde av sigarbåndet.")
            }
            .alert("Feil", isPresented: Binding(
                get: { scanService.errorMessage != nil },
                set: { if !$0 { scanService.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { scanService.errorMessage = nil }
            } message: {
                Text(scanService.errorMessage ?? "")
            }
            .alert("Kunne ikke lese kvitteringen", isPresented: Binding(
                get: { receiptError != nil },
                set: { if !$0 { receiptError = nil } }
            )) {
                Button("OK", role: .cancel) { receiptError = nil }
            } message: {
                Text(receiptError ?? "")
            }
            .overlay {
                if scanService.isScanning || isParsingReceipt {
                    ZStack {
                        Color.black.opacity(0.30).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView().tint(.white)
                            Text(isParsingReceipt ? "Leser kvitteringen…" : "Identifiserer…")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .onChange(of: appShell.pendingScan) { action in
                guard let action else { return }
                switch action {
                case .band: showCameraPicker = true
                case .photo: showLibraryPicker = true
                case .receipt: showReceiptSource = true
                }
                appShell.pendingScan = nil
            }
            .onChange(of: scanService.scanResults) { newResults in
                guard !newResults.isEmpty,
                      !scanService.needsShapePhoto,
                      !scanService.needsWrapperPhoto else { return }
                navigateToResults = true
            }
            .onChange(of: scanService.needsShapePhoto) { needsPhoto in
                if !needsPhoto && !scanService.scanResults.isEmpty { navigateToResults = true }
            }
            .onChange(of: scanService.needsWrapperPhoto) { needsPhoto in
                if !needsPhoto && !scanService.scanResults.isEmpty { navigateToResults = true }
            }
            .onChange(of: query) { newValue in
                scheduleSearch(newValue)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color("TextSecondary"))
            TextField("Søk etter merke, serie eller vitola…", text: $query)
                .submitLabel(.search)
            if !query.isEmpty {
                Button {
                    query = ""
                    results = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color("TextSecondary"))
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 50)
        .background(colorScheme == .light ? Color.white : Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color("TextSecondary").opacity(0.12), lineWidth: 1)
        )
    }

    private var emptySearchState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 42, weight: .light))
                .foregroundColor(Color("TextSecondary").opacity(0.55))
            Text("Søk i sigarkatalogen")
                .font(.headline)
                .foregroundColor(Color("TextPrimary"))
            Text("Finn registrert produktinformasjon om merke, serie, format og opprinnelse.")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if results.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 34))
                            .foregroundColor(Color("TextSecondary").opacity(0.55))
                        Text("Ingen treff")
                            .font(.headline)
                        Text("Prøv et annet søk.")
                            .font(.subheadline)
                            .foregroundColor(Color("TextSecondary"))
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(results) { cigar in
                        NavigationLink(destination: CigarDetailViewDesign(cigar: cigar)) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(cigar.brand)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color("TextPrimary"))
                                    let subtitle = [cigar.series, cigar.vitola ?? cigar.commonFormat]
                                        .compactMap { $0 }
                                        .filter { !$0.isEmpty }
                                        .joined(separator: " · ")
                                    if !subtitle.isEmpty {
                                        Text(subtitle)
                                            .font(.subheadline)
                                            .foregroundColor(Color("TextSecondary"))
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Color("TextSecondary").opacity(0.5))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                            .background(Color("Card"))
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 80)
        }
    }

    private func scheduleSearch(_ raw: String) {
        searchTask?.cancel()
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            isSearching = false
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await performSearch(trimmed)
        }
    }

    @MainActor
    private func performSearch(_ text: String) async {
        isSearching = true
        defer { isSearching = false }
        do {
            results = try await cigarService.searchCigars(query: text)
        } catch {
            results = []
        }
    }

    private func startNewScan() {
        navigateToResults = false
        scanService.scanResults = []
        scanService.extractedText = ""
        capturedImage = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            showCameraPicker = true
        }
    }

    private func parseReceipt(_ image: UIImage) async {
        isParsingReceipt = true
        receiptError = nil
        do {
            if let userId = authService.userId, humidors.isEmpty {
                humidors = (try? await humidorService.fetchHumidors(userId: userId)) ?? []
            }
            let result = try await receiptService.parseReceipt(image: image)
            isParsingReceipt = false
            if result.matched.isEmpty && result.unmatched.isEmpty {
                receiptError = "Fant ingen registrerbare sigarer på kvitteringen. Prøv et tydeligere bilde."
            } else {
                receiptResult = result
            }
        } catch {
            isParsingReceipt = false
            receiptError = "Klarte ikke å lese kvitteringen. Sjekk nettforbindelsen og prøv igjen."
        }
        receiptImage = nil
    }
}

// MARK: - ReviewLogView
// Neutral record view. Ratings, taste profile and recommendation signals are not shown.
struct ReviewLogView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) private var colorScheme

    @State private var logs: [TastingLog] = []
    @State private var isLoading = true
    @State private var selectedLog: TastingLog?
    @State private var showLogin = false

    private let tastingService = TastingService()

    var body: some View {
        NavigationStack {
            Group {
                if authService.userId == nil {
                    loggedOutState
                } else if isLoading {
                    ProgressView("Laster logg…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if logs.isEmpty {
                    emptyState
                } else {
                    logList
                }
            }
            .background(Color("Background"))
            .navigationTitle("Logg")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("Background"), for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .task { await loadLogs() }
            .refreshable { await loadLogs() }
            .sheet(item: $selectedLog) { log in
                NotesOnlyLogEditor(log: log) {
                    Task { await loadLogs() }
                }
                .environmentObject(authService)
            }
            .sheet(isPresented: $showLogin) {
                AuthView(onSuccess: { Task { await loadLogs() } })
            }
        }
    }

    private var logList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(logs) { log in
                    Button {
                        selectedLog = log
                    } label: {
                        VStack(alignment: .leading, spacing: 7) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(log.cigar?.brand ?? "Ukjent sigar")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color("TextPrimary"))
                                    let subtitle = [log.cigar?.series, log.cigar?.vitola]
                                        .compactMap { $0 }
                                        .filter { !$0.isEmpty }
                                        .joined(separator: " · ")
                                    if !subtitle.isEmpty {
                                        Text(subtitle)
                                            .font(.subheadline)
                                            .foregroundColor(Color("TextSecondary"))
                                    }
                                }
                                Spacer()
                                Text(log.smokedAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(Color("TextSecondary"))
                            }

                            if let notes = log.personalNotes,
                               !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundColor(Color("TextSecondary"))
                                    .lineLimit(3)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color("Card"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .padding(.bottom, 70)
        }
    }

    private var loggedOutState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 46))
                .foregroundColor(Color("TextSecondary").opacity(0.5))
            Text("Logg inn for å se registreringene dine")
                .font(.headline)
            Button("Logg inn") { showLogin = true }
                .buttonStyle(.borderedProminent)
                .tint(Color("Accent"))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 46))
                .foregroundColor(Color("TextSecondary").opacity(0.5))
            Text("Ingen registreringer ennå")
                .font(.headline)
            Text("Registreringer du oppretter vil vises her.")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @MainActor
    private func loadLogs() async {
        guard let userId = authService.userId else {
            isLoading = false
            logs = []
            return
        }
        isLoading = true
        logs = (try? await tastingService.fetchLogs(userId: userId)) ?? []
        isLoading = false
    }
}

struct NotesOnlyLogEditor: View {
    let log: TastingLog
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var date: Date
    @State private var notes: String
    @State private var isSaving = false
    @State private var showDeleteConfirm = false
    @State private var errorMessage: String?

    private let tastingService = TastingService()

    init(log: TastingLog, onComplete: @escaping () -> Void) {
        self.log = log
        self.onComplete = onComplete
        _date = State(initialValue: log.smokedAt)
        _notes = State(initialValue: log.personalNotes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Registrering") {
                    LabeledContent("Sigar", value: log.cigar?.displayName ?? "Ukjent sigar")
                    DatePicker("Dato", selection: $date, displayedComponents: .date)
                }

                Section("Notat") {
                    TextField("Egne notater…", text: $notes, axis: .vertical)
                        .lineLimit(4...8)
                }

                Section {
                    Button("Slett registrering", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
            .navigationTitle("Registrering")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lagre") { save() }
                        .disabled(isSaving)
                }
            }
            .alert("Slett registrering?", isPresented: $showDeleteConfirm) {
                Button("Avbryt", role: .cancel) {}
                Button("Slett", role: .destructive) { deleteEntry() }
            }
            .alert("Kunne ikke lagre", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true
        Task {
            do {
                try await tastingService.updateLog(
                    id: log.id,
                    smokedAt: date,
                    rating: log.rating,
                    smokeAgain: log.smokeAgain,
                    drawRating: log.drawRating,
                    burnRating: log.burnRating,
                    flavorRating: log.flavorRating,
                    personalNotes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes,
                    photoUrl: log.photoUrl
                )
                dismiss()
                onComplete()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }

    private func deleteEntry() {
        Task {
            do {
                try await tastingService.deleteLog(id: log.id)
                dismiss()
                onComplete()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - SettingsRootView
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

// Kept only for source compatibility with older screens. It no longer opens Profile.
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
