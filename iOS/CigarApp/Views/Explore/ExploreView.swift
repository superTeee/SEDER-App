import SwiftUI
import AVFoundation

// MARK: - ExploreView
// Browse alle sigarer: søk, merkeliste, avansert filter og skann-FAB

struct ExploreView: View {

    @StateObject private var cigarService = CigarService()
    @StateObject private var scanService  = ScanService()

    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var appShell: AppShell
    @Environment(\.colorScheme) private var colorScheme

    // Legg til egen sigar når søket ikke gir treff
    @State private var showAddCigarSheet = false
    @State private var showLoginSheet    = false
    @State private var createdCigar: Cigar?
    @State private var navigateToCreated = false

    // Søk
    @State private var searchQuery   = ""
    @FocusState private var searchFocused: Bool
    @State private var searchResults: [Cigar] = []
    @State private var isSearching   = false
    @State private var searchTask: Task<Void, Never>? = nil

    // Delt datalager. Fylles parallelt allerede mens splash-sekvensen spiller,
    // og overlever fane-bytter — derfor ingen ny henting hver gang viewet vises.
    @ObservedObject private var store = ExploreStore.shared

    private var allBrands: [BrandSummary]              { store.brands }
    private var flavorFilterOptions: [FlavorFilterOption] { store.flavorOptions }
    private var topCigars: [Cigar]                     { store.topCigars }
    private var featuredCigar: Cigar?                  { store.featuredCigar }
    private var isLoadingBrands: Bool                  { store.isLoadingBrands }
    private var isLoadingTop: Bool                     { store.isLoadingTop }
    private var isLoadingFeatured: Bool                { store.isLoadingFeatured }

    // Avansert filter
    @State private var showFilterSheet   = false
    @State private var filterWrapper:      [String] = []
    @State private var filterBinder:       [String] = []
    @State private var filterFiller:       [String] = []
    @State private var filterVitola:       [String] = []
    @State private var filterCountry:      [String] = []
    @State private var filterStrengthMin:        Double = 1.0
    @State private var filterStrengthMax:        Double = 5.0
    @State private var filterBodyMin:            Double = 1.0
    @State private var filterBodyMax:            Double = 5.0
    @State private var filterSweetnessMin:       Double = 1.0
    @State private var filterSweetnessMax:       Double = 5.0
    @State private var filterFlavorIntensityMin: Double = 1.0
    @State private var filterFlavorIntensityMax: Double = 5.0
    @State private var filterSmokingNotes: [String] = []
    @State private var filterSmokingTime:  [String] = []
    @State private var filterCrossSection: [String] = []
    @State private var filteredResults:    [Cigar]  = []
    @State private var hasAppliedFilter    = false
    @State private var filterResultCount:  Int?     = nil
    @State private var countTask: Task<Void, Never>? = nil

    // Nylige søk
    @AppStorage("recentCigarSearches") private var recentSearchesRaw = ""
    @State private var recentSearches: [String] = []

    // Scanner (band-bilde)
    @State private var showCameraPicker   = false
    @State private var showLibraryPicker  = false
    @State private var capturedImage: UIImage?
    @State private var navigateToResults  = false

    // Ingen treff → vennlig skjerm + manuell innlegging
    @State private var showManualAdd      = false
    @State private var showAddedConfirm   = false
    @State private var pendingHumidorCigar: Cigar? = nil
    @State private var isAddingToHumidor = false
    @AppStorage("humidorHasNew") private var humidorHasNew = false

    // Strekkode-scanner
    @State private var showBarcodeScan       = false
    @State private var barcodeFoundCigar:    Cigar?   = nil
    @State private var navigateToBarcode     = false

    // Kvittering-flyt (global, gjenbruker ReceiptService + ReceiptConfirmView)
    private let humidorService = HumidorService()
    private let receiptService = ReceiptService()
    private let tastingService = TastingService()
    @State private var humidors: [Humidor] = []
    @State private var receiptImage: UIImage?
    @State private var showReceiptCamera  = false
    @State private var showReceiptLibrary = false
    @State private var receiptResult: ReceiptParseResult?
    @State private var isParsingReceipt = false
    @State private var receiptError: String?
    @State private var showReceiptSource = false

    // Navigasjon
    @State private var selectedBrand: String? = nil

    // MARK: - Computed

    var hasActiveFilters: Bool {
        !filterWrapper.isEmpty || !filterBinder.isEmpty || !filterFiller.isEmpty ||
        !filterVitola.isEmpty  || !filterCountry.isEmpty ||
        filterStrengthMin > 1.0 || filterStrengthMax < 5.0 ||
        filterBodyMin > 1.0 || filterBodyMax < 5.0 ||
        filterSweetnessMin > 1.0 || filterSweetnessMax < 5.0 ||
        filterFlavorIntensityMin > 1.0 || filterFlavorIntensityMax < 5.0 ||
        !filterSmokingNotes.isEmpty || !filterSmokingTime.isEmpty || !filterCrossSection.isEmpty
    }

    private var profileFilterKey: String {
        "\(filterStrengthMin)-\(filterStrengthMax)-\(filterBodyMin)-\(filterBodyMax)" +
        "-\(filterSweetnessMin)-\(filterSweetnessMax)-\(filterFlavorIntensityMin)-\(filterFlavorIntensityMax)"
    }

    var showingSearch: Bool { !searchQuery.isEmpty }

    var brandSections: [(letter: String, brands: [BrandSummary])] {
        Dictionary(grouping: allBrands) { summary -> String in
            let first = summary.brand.first.map { String($0).uppercased() } ?? "#"
            return first.first?.isLetter == true ? first : "#"
        }
        .sorted { $0.key < $1.key }
        .map { (letter: $0.key,
                brands: $0.value.sorted { $0.brand.localizedStandardCompare($1.brand) == .orderedAscending }) }
    }

    /// 80 treff spredt utover i én liste er uleselig. Gruppert på merke er det
    /// 14 overskrifter å skumme, og merkenavnet står én gang i stedet for 80.
    /// Alfabetisk, samme rekkefølge som merkelisten — brukeren vet hvor ting er.
    private func groupedByBrand(_ cigars: [Cigar]) -> [(brand: String, cigars: [Cigar])] {
        Dictionary(grouping: cigars, by: \.brand)
            .map { (brand: $0.key, cigars: $0.value.sorted { lhs, rhs in
                (lhs.series ?? lhs.vitola ?? "").localizedStandardCompare(rhs.series ?? rhs.vitola ?? "") == .orderedAscending
            }) }
            .sorted { $0.brand.localizedStandardCompare($1.brand) == .orderedAscending }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color("Background").ignoresSafeArea()

                VStack(spacing: 0) {
                    // — Søkefelt + filter-knapp
                    HStack(spacing: 10) {
                        searchBar
                        filterButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    // — Innhold
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            if showingSearch || hasAppliedFilter {
                                searchResultsContent
                            } else {
                                browseContent
                            }
                        }
                        .padding(.bottom, 24)
                    }
                    .scrollDismissesKeyboard(.immediately) // dra/scroll lukker tastaturet
                    .contentMargins(.bottom, 60, for: .scrollContent) // klarering for egen tab-bar
                }
            }
            .navigationTitle("Utforsk")
            .navigationBarTitleDisplayMode(.inline)   // liten sentrert tittel
            .toolbarBackground(Color("Background"), for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            // --- Sheets & navigasjon ---
            .sheet(isPresented: $showFilterSheet) {
                AdvancedFilterSheet(
                    wrapperCountry:      $filterWrapper,
                    binder:              $filterBinder,
                    filler:              $filterFiller,
                    vitola:              $filterVitola,
                    countryOrigin:       $filterCountry,
                    strengthMin:         $filterStrengthMin,
                    strengthMax:         $filterStrengthMax,
                    bodyMin:             $filterBodyMin,
                    bodyMax:             $filterBodyMax,
                    sweetnessMin:        $filterSweetnessMin,
                    sweetnessMax:        $filterSweetnessMax,
                    flavorIntensityMin:  $filterFlavorIntensityMin,
                    flavorIntensityMax:  $filterFlavorIntensityMax,
                    smokingNotes:        $filterSmokingNotes,
                    smokingTime:         $filterSmokingTime,
                    crossSection:        $filterCrossSection,
                    resultCount:         $filterResultCount,
                    flavorOptions:       flavorFilterOptions.map(\.label),
                    onApply: {
                        showFilterSheet = false
                        Task { await applyFilters() }
                    },
                    onReset: {
                        resetFilters()
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(true)
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
                        Task { await scanService.scanBandImage(image) }
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToResults) {
                ResultsView(results: scanService.scanResults, ocrText: scanService.extractedText, onScanNext: { startNewScan() })
            }
            .navigationDestination(isPresented: $navigateToBarcode) {
                if let cigar = barcodeFoundCigar {
                    CigarDetailViewDesign(cigar: cigar)
                }
            }
            .navigationDestination(isPresented: $navigateToCreated) {
                if let cigar = createdCigar {
                    CigarDetailViewDesign(cigar: cigar)
                }
            }
            .sheet(isPresented: $showAddCigarSheet) {
                AddCigarSheet(prefillBrand: searchQuery) { cigar in
                    // Sigaren er din med én gang — gå rett til den.
                    createdCigar = cigar
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        navigateToCreated = true
                    }
                }
                .environmentObject(authService)
            }
            .sheet(isPresented: $showLoginSheet) { AuthView() }
            .fullScreenCover(isPresented: $showBarcodeScan) {
                BarcodeScanView { cigar in
                    // Liten delay slik at fullScreenCover rekker å lukke seg før navigering
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        barcodeFoundCigar = cigar
                        navigateToBarcode = true
                    }
                }
            }
            // Skann-arket presenteres globalt fra ContentView; her kjører vi kun
            // riktig flyt når brukeren har valgt (via appShell.pendingScan).
            .onChange(of: appShell.pendingScan) { action in
                guard let action else { return }
                switch action {
                case .band:    showCameraPicker = true
                case .photo:   showLibraryPicker = true
                case .receipt: showReceiptSource = true
                }
                appShell.pendingScan = nil
            }
            // Kvittering-flyt
            .sheet(isPresented: $showReceiptSource) {
                ReceiptSourceSheet(
                    onCamera: { showReceiptCamera = true },
                    onLibrary: { showReceiptLibrary = true }
                )
                .presentationDetents([.height(230)])
            }
            .sheet(isPresented: $showReceiptCamera) {
                ImagePicker(image: $receiptImage, sourceType: .camera) {
                    if let img = receiptImage { Task { await parseReceipt(img) } }
                }
            }
            .sheet(isPresented: $showReceiptLibrary) {
                ImagePicker(image: $receiptImage, sourceType: .photoLibrary) {
                    if let img = receiptImage { Task { await parseReceipt(img) } }
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
            .overlay {
                if isParsingReceipt {
                    ZStack {
                        Color.black.opacity(0.35).ignoresSafeArea()
                        VStack(spacing: 14) {
                            ProgressView().tint(Color("TextPrimary")).scaleEffect(1.3)
                            Text("Leser kvitteringen…")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Color("TextPrimary"))
                        }
                        .padding(28)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color("Card")))
                    }
                }
            }
            .alert("Kunne ikke lese kvitteringen", isPresented: .constant(receiptError != nil)) {
                Button("OK") { receiptError = nil }
            } message: {
                Text(receiptError ?? "")
            }
            .fullScreenCover(isPresented: $scanService.needsShapePhoto) {
                ShapeConfirmView(scanService: scanService)
            }
            .fullScreenCover(isPresented: $scanService.needsWrapperPhoto) {
                WrapperConfirmView(scanService: scanService)
            }
            // Ingen treff → vennlig skjerm med prøv-på-nytt / legg inn manuelt
            .fullScreenCover(isPresented: $scanService.noMatch) {
                NoMatchView(
                    image: capturedImage,
                    ocrText: scanService.extractedText,
                    outcome: scanService.bandTextOutcome,
                    onRetry: {
                        scanService.noMatch = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showCameraPicker = true }
                    },
                    onManualAdd: {
                        scanService.noMatch = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showManualAdd = true }
                    }
                )
            }
            .sheet(isPresented: $showManualAdd) {
                // Samme skjerm som ellers i appen (AddCigarSheet).
                AddCigarSheet(prefillNote: scanPrefillNote) { cigar in
                    // Lukk arket, så la brukeren VELGE humidor før vi legger til.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        pendingHumidorCigar = cigar
                    }
                }
                .environmentObject(authService)
            }
            // Velg humidor (+ antall/dato) før vi legger sigaren til — samme ark
            // som fra sigar-detalj, så brukeren bestemmer HVOR den skal.
            .sheet(item: $pendingHumidorCigar) { cigar in
                AddToHumidorSheet(cigar: cigar, userId: authService.userId) { chosenCigar, purchasedAt, addedAt, qty, humidorId, store, price, photoData in
                    finalizeManualScanAdd(chosenCigar, purchasedAt: purchasedAt, addedAt: addedAt,
                                          quantity: qty, humidorId: humidorId, store: store, price: price, photo: photoData)
                }
                .environmentObject(authService)
            }
            // Spinner mens sigaren legges til (add + evt. bilde-opplasting).
            .overlay(alignment: .center) {
                if isAddingToHumidor {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView().tint(Color("TextPrimary")).scaleEffect(1.3)
                            Text("Legger til …")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Color("TextPrimary"))
                        }
                        .padding(26)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color("Card")))
                    }
                }
            }
            // Bekreftelse med grønt check-ikon (erstatter system-alerten).
            .overlay(alignment: .bottom) {
                if showAddedConfirm {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Lagt i humidoren").fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .background(Color("Accent"))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
                    .padding(.bottom, 100)   // klar tab-baren (60pt + safe area)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                            withAnimation { showAddedConfirm = false }
                        }
                    }
                }
            }
            .navigationDestination(for: String.self) { brand in
                BrandCigarsView(brand: brand)
            }
            .onChange(of: scanService.scanResults) { results in
                guard !results.isEmpty,
                      !scanService.needsShapePhoto,
                      !scanService.needsWrapperPhoto else { return }
                navigateToResults = true
            }
            .onChange(of: scanService.needsShapePhoto) { needsPhoto in
                guard !needsPhoto, !scanService.scanResults.isEmpty else { return }
                navigateToResults = true
            }
            .onChange(of: scanService.needsWrapperPhoto) { needsPhoto in
                guard !needsPhoto, !scanService.scanResults.isEmpty else { return }
                navigateToResults = true
            }
            .alert("Feil", isPresented: .constant(scanService.errorMessage != nil)) {
                Button("OK") { scanService.errorMessage = nil }
            } message: {
                Text(scanService.errorMessage ?? "")
            }
            .onAppear {
                recentSearches = loadRecent()
                // Er som regel allerede ferdig — starter under splashen.
                store.preload()
                // Nytt døgn? Beregn dagens utvalgte på nytt.
                store.refreshFeaturedIfNewDay()
            }
            .onChange(of: searchQuery) { query in
                searchTask?.cancel()
                if query.isEmpty {
                    searchResults = []
                    isSearching   = false
                    return
                }
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 350_000_000) // 350 ms debounce
                    guard !Task.isCancelled else { return }
                    await performSearch(query: query)
                }
            }
            .modifier(FilterChangeModifier(
                fw: filterWrapper, fb: filterBinder, ff: filterFiller,
                fv: filterVitola, fc: filterCountry,
                profileKey: profileFilterKey,
                fn: filterSmokingNotes, ft: filterSmokingTime, fcs: filterCrossSection,
                action: scheduleCountUpdate
            ))
        }

        // Scanner loading overlay (over hele skjermen)
        .overlay {
            if scanService.isScanning {
                ScanningOverlay()
            }
        }
    }

    // MARK: - Søkefelt

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(.secondaryLabel))
            TextField("Søk etter sigar eller merke…", text: $searchQuery)
                .submitLabel(.search)
                .focused($searchFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Ferdig") { searchFocused = false }
                            .fontWeight(.semibold)
                    }
                }
                .onSubmit {
                    if !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                        saveRecent(searchQuery.trimmingCharacters(in: .whitespaces))
                        recentSearches = loadRecent()
                    }
                }
            if !searchQuery.isEmpty {
                Button {
                    searchQuery   = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 50)
        .background(colorScheme == .light ? Color.white : Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color("TextSecondary").opacity(searchFocused ? 0.25 : 0.12), lineWidth: 1)
        )
    }

    // MARK: - Filter-knapp (toolbar)

    private var filterButton: some View {
        Button {
            showFilterSheet = true
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)   // match søkefeltets høyde
                .background(Color("Accent"))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(alignment: .topTrailing) {
                    if hasActiveFilters {
                        Circle()
                            .fill(.white)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().fill(Color("Accent")).frame(width: 6, height: 6))
                            .offset(x: 3, y: -3)
                    }
                }
        }
        .accessibilityLabel("Avansert søk")
    }

    // Les kvittering: hent humidorer (trengs i bekreft-arket) + parse + åpne ark.
    // Forhåndsutfylt notat til manuell innlegging fra et mislykket skann.
    private var scanPrefillNote: String {
        let t = scanService.extractedText
        return t.isEmpty ? "" : "Fra skann: \(String(t.prefix(200)))"
    }

    // Manuell innlegging etter et skann uten treff: lær av skannet (OCR + bånd-bilde)
    // og legg sigaren i første humidor. Trukket ut av view-body for å unngå at
    // Swift-type-sjekkeren bruker for lang tid på et stort uttrykk.
    // Manuell innlegging etter et skann uten treff — ETTER at brukeren har valgt
    // humidor. Legger til umiddelbart, fester skann-bildet på oppføringen, setter
    // rød badge og bekrefter med en gang. Selve læringen (bilde-embedding, 6–7 s)
    // kjøres ETTERPÅ i bakgrunnen, så bekreftelsen ikke henger.
    private func finalizeManualScanAdd(_ cigar: Cigar, purchasedAt: Date, addedAt: Date,
                                       quantity: Int, humidorId: UUID?, store: String, price: Double?,
                                       photo: Data? = nil) {
        guard let userId = authService.userId else { return }
        isAddingToHumidor = true
        let ocr = scanService.extractedText
        let scanImg = capturedImage
        // Brukerens valgte bilde vinner over skann-bildet (kan legges inn uten skann).
        let entryPhoto = photo ?? scanImg?.jpegData(compressionQuality: 0.9)
        let band = photo ?? scanImg?.jpegData(compressionQuality: 0.8)
        Task {
            // 1) Legg i den VALGTE humidoren
            let entry = try? await humidorService.addToHumidor(
                cigarId: cigar.id, userId: userId, humidorId: humidorId, quantity: quantity,
                purchasedAt: purchasedAt, addedToHumidorAt: addedAt, store: store, purchasePrice: price)

            // 2) Bildet blir oppføringens bilde (vises på detalj) hvis vi har det
            //    og oppføringen ikke har bilde fra før.
            if let entry, let data = entryPhoto, (entry.photoURL ?? "").isEmpty {
                _ = try? await humidorService.uploadPhoto(
                    entryId: entry.id, userId: userId, imageData: data)
            }

            // 3) Rød badge på humidor-fanen + bekreftelse — UMIDDELBART.
            await MainActor.run {
                isAddingToHumidor = false
                humidorHasNew = true
                withAnimation { showAddedConfirm = true }
            }

            // 4) Lær av skannet i bakgrunnen (bånd-bilde → embedding). Blokkerer ikke UI.
            let hasText = !ocr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if hasText || band != nil {
                await tastingService.resolveScan(
                    ocrText: ocr, cigarId: cigar.id, userId: userId, bandImage: band)
            }
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
                receiptError = "Fant ingen sigarer på kvitteringen. Prøv et tydeligere bilde."
            } else {
                receiptResult = result
            }
        } catch {
            isParsingReceipt = false
            receiptError = "Klarte ikke å lese kvitteringen. Sjekk nettforbindelsen og prøv igjen."
        }
        receiptImage = nil
    }

    // MARK: - Brukernes topp 3

    private var topFiveSection: some View {
        Group {
            if topCigars.isEmpty {
                // Skjelett med nøyaktig samme høyde som tre ferdige rader,
                // så innholdet under ikke hopper når dataene lander.
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { index in
                        SkeletonRow()
                        if index < 2 { Divider().padding(.leading, 56) }
                    }
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(topCigars.enumerated()), id: \.element.id) { index, cigar in
                        NavigationLink(destination: CigarDetailViewDesign(cigar: cigar)) {
                            TopCigarRow(rank: index + 1, cigar: cigar)
                        }
                        .buttonStyle(.plain)
                        .cigarQuickActions(cigar)
                        if index < topCigars.count - 1 {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
            }
        }
        .background(Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Dagens utvalgte

    @ViewBuilder
    private var featuredSection: some View {
        sectionHeader("Dagens utvalgte")

        Group {
            if let cigar = featuredCigar {
                NavigationLink(destination: CigarDetailViewDesign(cigar: cigar)) {
                    featuredCard(cigar: cigar)
                }
                .buttonStyle(.plain)
                .cigarQuickActions(cigar)
            } else {
                // Samme høyde som det ferdige kortet (52 pt ikon + 2×14 padding).
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color("Card"))
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color("Accent").opacity(0.25), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func featuredCard(cigar: Cigar) -> some View {
        HStack(spacing: 14) {
            // Ikon-boks
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("Accent").opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: "flame.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color("Accent"))
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(cigar.brand)
                    .font(.subheadline.bold())
                    .foregroundColor(Color(.label))
                if let series = cigar.series {
                    Text(series)
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                        .lineLimit(1)
                }
                if let vitola = cigar.vitola ?? cigar.commonFormat {
                    Text(vitola)
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }

            Spacer()

            // Score-badge (samkjørt)
            if let rating = cigar.avgRating {
                ScoreBadge(text: String(format: "%.0f", rating * 10), size: 15)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color("Accent").opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Browse-innhold (ingen søk, ingen filter)

    @ViewBuilder
    private var browseContent: some View {
        // Nylige søk
        if !recentSearches.isEmpty {
            sectionHeader("Siste søk")

            VStack(spacing: 0) {
                ForEach(recentSearches, id: \.self) { term in
                    HStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 15))
                            .foregroundColor(Color(.secondaryLabel))
                            .frame(width: 20)
                        Text(term)
                            .font(.system(size: 15))
                            .foregroundColor(Color(.label))
                        Spacer()
                        Button {
                            removeRecent(term)
                            recentSearches = loadRecent()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundColor(Color(.secondaryLabel))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        searchQuery = term
                    }

                    if term != recentSearches.last {
                        Divider().padding(.leading, 48)
                    }
                }
            }
            .background(Color("Card"))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }

        // Topp 3 sigarer — headeren står alltid, så layouten er stabil.
        sectionHeader("Høyest vurderte")
        topFiveSection

        // Dagens utvalgte
        featuredSection

        // Alfabetisk merkeliste
        sectionHeader("Alle merker")

        if isLoadingBrands {
            HStack {
                Spacer()
                ProgressView()
                    .padding(.vertical, 40)
                Spacer()
            }
        } else {
            ForEach(brandSections, id: \.letter) { section in
                // Bokstav-header
                Text(section.letter)
                    .font(.footnote.bold())
                    .foregroundColor(Color(.secondaryLabel))
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                VStack(spacing: 0) {
                    ForEach(section.brands) { brand in
                        NavigationLink(value: brand.brand) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(brand.brand)
                                        .foregroundColor(Color(.label))
                                    Text(brand.subtitle)
                                        .font(.caption)
                                        .foregroundColor(Color(.secondaryLabel))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            .contentShape(Rectangle())   // hele raden trykkbar
                        }
                        .buttonStyle(.plain)

                        if brand.id != section.brands.last?.id {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .background(Color("Card"))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            }
        }
    }

    // MARK: - Søkeresultater / filterresultater

    @ViewBuilder
    private var searchResultsContent: some View {
        let results = hasAppliedFilter && !showingSearch ? filteredResults : searchResults

        if isSearching {
            HStack {
                Spacer()
                ProgressView()
                    .padding(.vertical, 40)
                Spacer()
            }
        } else if results.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 36))
                    .foregroundColor(Color(.tertiaryLabel))
                Text("Ingen treff")
                    .font(.headline)
                    .foregroundColor(Color(.secondaryLabel))
                Text("Prøv et annet søk eller juster filtrene")
                    .font(.subheadline)
                    .foregroundColor(Color(.tertiaryLabel))
                    .multilineTextAlignment(.center)

                // Mangler sigaren, skal ikke brukeren bli stående fast.
                Button {
                    guard authService.userId != nil else { showLoginSheet = true; return }
                    showAddCigarSheet = true
                } label: {
                    Label("Legg til sigaren selv", systemImage: "plus.circle")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .background(Color("Accent"))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
            .padding(.horizontal, 32)
        } else {
            let sections = groupedByBrand(results)

            // Tydelig treff-indikator (ikke den svake footnote-labelen).
            HStack {
                Text(searchQuery.isEmpty
                     ? "\(results.count) resultater"
                     : "Resultater for «\(searchQuery)» (\(results.count))")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(.label))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            ForEach(sections, id: \.brand) { section in
                brandResultHeader(section.brand, count: section.cigars.count)

                VStack(spacing: 0) {
                    ForEach(section.cigars) { cigar in
                        NavigationLink(destination: CigarDetailViewDesign(cigar: cigar)) {
                            ExploreResultRow(cigar: cigar, showsBrand: false, searchQuery: showingSearch ? searchQuery : "")
                        }
                        .cigarQuickActions(cigar)
                        if cigar.id != section.cigars.last?.id {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .background(Color("Card"))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.footnote.bold())
            .foregroundColor(Color(.secondaryLabel))
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Merkeoverskrift over en gruppe treff. Tallet til høyre forteller brukeren
    /// hvor tyngdepunktet i treffet ligger — noe filteret aldri sa.
    private func brandResultHeader(_ brand: String, count: Int) -> some View {
        HStack {
            Text(brand.uppercased())
                .font(.footnote.bold())
                .foregroundColor(Color(.secondaryLabel))
            Spacer()
            Text("\(count)")
                .font(.footnote)
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    // Hentingene bor nå i ExploreStore (parallelt, startet under splashen).

    // Pop hele scan-stakken tilbake til Utforsk og åpne kameraet på nytt,
    // slik at man kan legge inn flere sigarer på rad uten å trykke back-back-back.
    private func startNewScan() {
        navigateToResults = false          // pop ResultsView (+ CigarDetailView) til rot
        scanService.scanResults = []
        scanService.extractedText = ""
        capturedImage = nil
        // Liten delay så navigasjons-poppen rekker å fullføre før kamera-arket åpnes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            showCameraPicker = true
        }
    }

    private func performSearch(query: String) async {
        isSearching = true
        defer { isSearching = false }
        do {
            searchResults = try await cigarService.searchCigars(query: query)
        } catch {
            print("Søkefeil: \(error)")
            searchResults = []
        }
    }

    // Oversetter valgte smaksnote-etiketter til grupper av faktiske DB-notater.
    private var selectedFlavorNoteGroups: [[String]] {
        filterSmokingNotes.compactMap { label in
            flavorFilterOptions.first { $0.label == label }?.dbNotes
        }
    }

    private func applyFilters() async {
        isSearching = true
        defer { isSearching = false }
        do {
            filteredResults = try await cigarService.fetchCigarsFiltered(
                wrapperCountry:      filterWrapper,
                binder:              filterBinder,
                filler:              filterFiller,
                commonFormat:        filterVitola,
                countryOrigin:       filterCountry,
                strengthRange:       filterStrengthMin > 1.0 || filterStrengthMax < 5.0 ? filterStrengthMin...filterStrengthMax : nil,
                bodyRange:           filterBodyMin > 1.0 || filterBodyMax < 5.0 ? filterBodyMin...filterBodyMax : nil,
                sweetnessRange:      filterSweetnessMin > 1.0 || filterSweetnessMax < 5.0 ? filterSweetnessMin...filterSweetnessMax : nil,
                flavorIntensityRange: filterFlavorIntensityMin > 1.0 || filterFlavorIntensityMax < 5.0 ? filterFlavorIntensityMin...filterFlavorIntensityMax : nil,
                smokingNotes:        filterSmokingNotes,
                flavorNoteGroups:    selectedFlavorNoteGroups,
                crossSection:        filterCrossSection
            )
            hasAppliedFilter = true
        } catch {
            print("Filterfeil: \(error)")
        }
    }

    private func resetFilters() {
        filterWrapper            = []
        filterBinder             = []
        filterFiller             = []
        filterVitola             = []
        filterCountry            = []
        filterStrengthMin        = 1.0
        filterStrengthMax        = 5.0
        filterBodyMin            = 1.0
        filterBodyMax            = 5.0
        filterSweetnessMin       = 1.0
        filterSweetnessMax       = 5.0
        filterFlavorIntensityMin = 1.0
        filterFlavorIntensityMax = 5.0
        filterSmokingNotes       = []
        filterSmokingTime        = []
        filterCrossSection       = []
        filteredResults          = []
        filterResultCount        = nil
        hasAppliedFilter         = false
    }

    private func scheduleCountUpdate() {
        countTask?.cancel()
        countTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await updateFilterCount()
        }
    }

    @MainActor
    private func updateFilterCount() async {
        guard hasActiveFilters else {
            filterResultCount = nil
            return
        }
        do {
            // Teller i databasen. Å telle radene vi faktisk laster ville gitt
            // samme tall for alle filtre som treffer mer enn takgrensen.
            filterResultCount = try await cigarService.countCigarsFiltered(
                wrapperCountry:      filterWrapper,
                binder:              filterBinder,
                filler:              filterFiller,
                commonFormat:        filterVitola,
                countryOrigin:       filterCountry,
                strengthRange:       filterStrengthMin > 1.0 || filterStrengthMax < 5.0 ? filterStrengthMin...filterStrengthMax : nil,
                bodyRange:           filterBodyMin > 1.0 || filterBodyMax < 5.0 ? filterBodyMin...filterBodyMax : nil,
                sweetnessRange:      filterSweetnessMin > 1.0 || filterSweetnessMax < 5.0 ? filterSweetnessMin...filterSweetnessMax : nil,
                flavorIntensityRange: filterFlavorIntensityMin > 1.0 || filterFlavorIntensityMax < 5.0 ? filterFlavorIntensityMin...filterFlavorIntensityMax : nil,
                smokingNotes:        filterSmokingNotes,
                flavorNoteGroups:    selectedFlavorNoteGroups,
                crossSection:        filterCrossSection
            )
        } catch {
            filterResultCount = nil
        }
    }

    // MARK: - Nylige søk (UserDefaults via AppStorage)

    private func loadRecent() -> [String] {
        recentSearchesRaw.split(separator: "§").map(String.init).filter { !$0.isEmpty }
    }

    private func saveRecent(_ term: String) {
        var list = loadRecent()
        list.removeAll { $0.lowercased() == term.lowercased() }
        list.insert(term, at: 0)
        if list.count > 10 { list = Array(list.prefix(10)) }
        recentSearchesRaw = list.joined(separator: "§")
    }

    private func removeRecent(_ term: String) {
        var list = loadRecent()
        list.removeAll { $0 == term }
        recentSearchesRaw = list.joined(separator: "§")
    }
}

// MARK: - FlavorFilterOption
// Ett smaksnote-filtervalg, utledet fra faktiske flavor_notes i databasen.
// label = norsk visningsnavn (f.eks. «Kakao»), dbNotes = rå-notatene som
// mapper til samme ikon-familie (brukes til overlaps-filtrering).
struct FlavorFilterOption: Identifiable, Hashable {
    let label: String
    let iconFamily: String
    let dbNotes: [String]
    var id: String { iconFamily }
}

// MARK: - ExploreResultRow

struct ExploreResultRow: View {
    let cigar: Cigar

    /// Står raden under en merkeoverskrift, er merkenavnet allerede sagt.
    /// Da bruker raden plassen på serie og mål i stedet for å gjenta det.
    var showsBrand: Bool = true

    /// Gjeldende søkeord — brukes til å vise «Smak: X» når treffet kom via smaksnote.
    var searchQuery: String = ""

    /// Norsk smaksnote-etikett hvis søkeordet matcher en smaksfamilie sigaren har.
    private var flavorMatch: String? {
        let q = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        guard q.count >= 2 else { return nil }
        let families = FlavorIcon.label.filter { $0.value.lowercased().contains(q) }.map { $0.key }
        guard !families.isEmpty else { return nil }
        let hitFamilies = Set((cigar.flavorNotes ?? []).compactMap { FlavorIcon.name(for: $0) })
            .intersection(families)
        guard let fam = hitFamilies.first else { return nil }
        return FlavorIcon.displayLabel(for: fam)
    }

    private var title: String {
        showsBrand ? cigar.brand : (cigar.series ?? cigar.vitola ?? cigar.brand)
    }

    /// Den spesifikke vitolaen som egen linje — men bare når den ikke allerede
    /// er tittelen, og ikke når den er identisk med formatet (da sier chip-en det).
    private var vitolaLine: String? {
        guard cigar.series != nil, let vitola = cigar.vitola else { return nil }
        if vitola.caseInsensitiveCompare(cigar.commonFormat ?? "") == .orderedSame { return nil }
        return vitola
    }

    /// «Robusto · 50 × 4.9"» — formatnavnet koblet til målene, så et format
    /// som «Robusto» blir konkret for de som ikke vet hva det betyr.
    private var formatChip: String? {
        let parts = [cigar.commonFormat, cigar.dimensionsLabel].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(Color(.label))

                if showsBrand, let series = cigar.series {
                    Text(series)
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }
                if let vitolaLine {
                    Text(vitolaLine)
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }

                // Format-chip: navn + mål, så «Robusto» blir konkret.
                if let formatChip {
                    Text(formatChip)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color("Accent").opacity(0.12))
                        .foregroundColor(Color("Accent"))
                        .clipShape(Capsule())
                        .padding(.top, 1)
                }

                // «Smak: X» når treffet kom via smaksnote.
                if let flavorMatch {
                    Text("Smak: \(flavorMatch)")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(Color("Accent"))
                        .padding(.top, 1)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())   // hele raden er trykkbar, ikke bare teksten
    }
}

// MARK: - AdvancedFilterSheet

struct AdvancedFilterSheet: View {

    @Environment(\.dismiss) private var dismiss

    @Binding var wrapperCountry:     [String]
    @Binding var binder:             [String]
    @Binding var filler:             [String]
    @Binding var vitola:             [String]
    @Binding var countryOrigin:      [String]
    @Binding var strengthMin:        Double
    @Binding var strengthMax:        Double
    @Binding var bodyMin:            Double
    @Binding var bodyMax:            Double
    @Binding var sweetnessMin:       Double
    @Binding var sweetnessMax:       Double
    @Binding var flavorIntensityMin: Double
    @Binding var flavorIntensityMax: Double
    @Binding var smokingNotes:       [String]
    @Binding var smokingTime:        [String]
    @Binding var crossSection:       [String]
    @Binding var resultCount:        Int?

    // Dynamiske smaksnote-valg (norske etiketter) utledet fra databasen
    var flavorOptions: [String] = []

    var onApply: () -> Void
    var onReset: () -> Void

    @State private var showAllOrigin   = false
    @State private var showAllVitola   = false
    @State private var showAllWrapper  = false
    @State private var showAllBinder   = false
    @State private var showAllFiller   = false
    @State private var showAllNotes    = false
    @State private var showAllSection  = false
    @State private var showVitolaGuide = false
    @State private var showWrapperGuide = false

    private let initialCount = 6

    private let crossSectionOptions = ["Box Pressed", "Oval", "Hexagonal"]
    private let originOptions   = ["Nicaragua", "Dominican Republic", "Honduras", "Cuba", "Mexico", "Ecuador", "Peru", "Costa Rica", "Panama", "USA"]
    private let vitolaOptions   = ["Toro", "Robusto", "Gordo", "Corona Gorda", "Churchill", "Corona", "Lancero", "Torpedo", "Belicoso", "Figurado", "Panatela", "Petit Corona"]
    // Typiske mål per format (ringmål × lengde) — en pekepinn, ikke en fasit.
    // Figurado utelates: det er en form-familie, ikke ett bestemt mål.
    private let vitolaSizes: [String: String] = [
        "Toro": "50 × 6\"", "Robusto": "50 × 5\"", "Gordo": "60 × 6\"",
        "Corona Gorda": "46 × 5.6\"", "Churchill": "48 × 7\"", "Corona": "42 × 5.5\"",
        "Lancero": "38 × 7.5\"", "Torpedo": "52 × 6.1\"", "Belicoso": "52 × 5.5\"",
        "Panatela": "38 × 6\"", "Petit Corona": "42 × 4.5\""
    ]
    private let wrapperOptions  = ["Connecticut Shade", "Ecuador Connecticut", "San Andrés", "Cameroon", "Sumatra", "Broadleaf", "Habano", "Colorado Claro", "Maduro", "Corojo"]
    private let binderOptions   = ["Nicaraguan", "Dominican", "Honduran", "Mexican San Andrés", "Ecuadorian", "Connecticut", "Sumatran", "Cameroon"]
    private let fillerOptions   = ["Nicaraguan", "Dominican Republic", "Honduras", "Cuba", "Mexico", "Ecuador", "Peru", "Pennsylvania"]
    private let smokingTimeOpts = ["Under 45 min", "45–90 min", "90 min+"]

    @Environment(\.colorScheme) private var colorScheme

    private var chipSelectedBg: Color { Color(hex: "#E0D2BA") }
    // Samme farge som smaksnote-ikonene: #8F7B51 i lys modus, accent i mørk.
    private var chipStroke: Color { colorScheme == .dark ? Color("Accent") : Color(hex: "#8F7B51") }

    private var ctaText: String {
        if let count = resultCount {
            return "Vis \(count) resultater"
        }
        return "Vis resultater"
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──
            ZStack {
                Text("Avansert søk")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(.label))
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .padding(.trailing, 16)
                }
            }
            .frame(height: 54)
            .background(Color("Card"))

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    // 24px ekstra luft mellom sheet-tittelen og første seksjon.
                    Spacer().frame(height: 24)
                    // Vitola først: formatet er det folk velger etter — hvor lang
                    // tid de har, ikke hvilket land dekkbladet kommer fra.
                    chipSection(title: "FORM / VITOLA",  options: vitolaOptions,  selection: $vitola,         showAll: $showAllVitola,
                                subtitles: vitolaSizes,
                                infoAction: { showVitolaGuide = true })
                    sectionDivider()
                    crossSectionFilterSection
                    sectionDivider()
                    chipSection(title: "OPPHAV",  options: originOptions,  selection: $countryOrigin,  showAll: $showAllOrigin)
                    sectionDivider()
                    chipSection(title: "WRAPPER", options: wrapperOptions, selection: $wrapperCountry, showAll: $showAllWrapper,
                                infoAction: { showWrapperGuide = true })
                    sectionDivider()
                    chipSection(title: "BINDER",  options: binderOptions,  selection: $binder,         showAll: $showAllBinder)
                    sectionDivider()
                    chipSection(title: "FILLER",  options: fillerOptions,  selection: $filler,         showAll: $showAllFiller)
                    sectionDivider()
                    profileSlidersSection
                    if !flavorOptions.isEmpty {
                        sectionDivider()
                        chipSection(title: "SMAKSNOTER", options: flavorOptions, selection: $smokingNotes, showAll: $showAllNotes)
                    }
                }
            }
            .background(Color("Card"))

            // ── Bottom CTA ──
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 14) {
                    Button {
                        onReset()
                        dismiss()
                    } label: {
                        Text("Tilbakestill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(.secondaryLabel))
                    }

                    Button { onApply() } label: {
                        Text(ctaText)
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color("Accent"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .animation(.easeInOut(duration: 0.15), value: ctaText)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(Color("Card"))
        }
        .padding(.horizontal, 8)          // 8px luft på hver side av arket
        .frame(maxWidth: .infinity)
        .background(Color("Card"))
        .sheet(isPresented: $showVitolaGuide) {
            VitolaGuideSheet()
        }
        .sheet(isPresented: $showWrapperGuide) {
            WrapperGuideSheet()
        }
    }

    // ── Tverrsnitt (box pressed / oval / hexagonal) ──
    private var crossSectionFilterSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TVERRSNITT")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.secondaryLabel))
                .padding(.horizontal, 16)
                .padding(.top, 16)

            // Samme chip som de andre seksjonene — én definisjon, ett utseende.
            MultiChipFlowLayout(
                options: crossSectionOptions,
                selection: $crossSection,
                selectedBg: chipSelectedBg,
                strokeColor: chipStroke
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
    }

    private func sectionDivider() -> some View {
        // +10px luft mellom hver filterkategori (5 over + 5 under)
        Divider().padding(.horizontal, 16).padding(.vertical, 5)
    }

    // ── Multi-select chip section med expand ──
    private func chipSection(
        title: String,
        options: [String],
        selection: Binding<[String]>,
        showAll: Binding<Bool>,
        subtitles: [String: String] = [:],
        infoAction: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.secondaryLabel))
                // «i»-knapp: åpner en grafisk oversikt over formatene.
                if let infoAction {
                    Button(action: infoAction) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundColor(Color("Accent"))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            MultiChipFlowLayout(
                options: showAll.wrappedValue ? options : Array(options.prefix(initialCount)),
                selection: selection,
                selectedBg: chipSelectedBg,
                strokeColor: chipStroke,
                subtitles: subtitles
            )
            .padding(.horizontal, 16)

            if options.count > initialCount {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showAll.wrappedValue.toggle() }
                } label: {
                    Text(showAll.wrappedValue ? "Vis færre ↑" : "Se alle ↓")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("Accent"))
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)   // 4px mer luft ned til chipsene
                .padding(.bottom, 14)
            } else {
                Spacer().frame(height: 14)
            }
        }
    }

    // ── Profilslidere (Styrke / Kropp / Sødme / Smaksintensitet) ──
    private var profileSlidersSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("PROFIL")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.secondaryLabel))
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 4)

            ProfileRangeSlider(label: "Styrke",          low: $strengthMin,        high: $strengthMax)
            Divider().padding(.horizontal, 16)
            ProfileRangeSlider(label: "Kropp",           low: $bodyMin,            high: $bodyMax)
            Divider().padding(.horizontal, 16)
            ProfileRangeSlider(label: "Sødme",           low: $sweetnessMin,       high: $sweetnessMax)
            Divider().padding(.horizontal, 16)
            ProfileRangeSlider(label: "Smaksintensitet", low: $flavorIntensityMin, high: $flavorIntensityMax)
        }
        .padding(.bottom, 6)
    }

    // ── Røyketid (multi-select) ──
    private var smokingTimeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("VARIGHET")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.secondaryLabel))
                .padding(.horizontal, 16)
                .padding(.top, 16)

            HStack(spacing: 8) {
                ForEach(smokingTimeOpts, id: \.self) { opt in
                    let isSelected = smokingTime.contains(opt)
                    Text(opt)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(isSelected ? chipSelectedBg : Color.clear)
                        .foregroundColor(Color(.label))
                        .overlay(Capsule().stroke(isSelected ? Color.clear : chipStroke, lineWidth: 1))
                        .clipShape(Capsule())
                        .onTapGesture {
                            if isSelected { smokingTime.removeAll { $0 == opt } }
                            else { smokingTime.append(opt) }
                        }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
    }
}

// MARK: - VitolaGuideSheet
//
// Grafisk oversikt over de vanligste formatene. Silhuettene er tegnet i SAMME
// målestokk (samme punkter-per-tomme for både lengde og tykkelse), så en Lancero
// faktisk ser lang og tynn ut ved siden av en tjukk, kort Gordo. Det er poenget:
// tall forteller lite til den som ikke kjenner formatene — proporsjoner gjør det.

struct VitolaGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    private struct Vitola: Identifiable {
        let name: String
        let ring: Int
        let length: Double
        let pointed: Bool     // spiss hode (Torpedo/Belicoso)
        var id: String { name }
        var maal: String { "\(ring) × \(length.formatted(.number.precision(.fractionLength(0...1))))\"" }
    }

    // Sortert lengst → kortest, så det leses som en størrelsestabell.
    private let vitolaer: [Vitola] = [
        .init(name: "Lancero",      ring: 38, length: 7.5, pointed: false),
        .init(name: "Churchill",    ring: 48, length: 7.0, pointed: false),
        .init(name: "Torpedo",      ring: 52, length: 6.1, pointed: true),
        .init(name: "Toro",         ring: 50, length: 6.0, pointed: false),
        .init(name: "Panatela",     ring: 38, length: 6.0, pointed: false),
        .init(name: "Gordo",        ring: 60, length: 6.0, pointed: false),
        .init(name: "Corona Gorda", ring: 46, length: 5.6, pointed: false),
        .init(name: "Belicoso",     ring: 52, length: 5.5, pointed: true),
        .init(name: "Corona",       ring: 42, length: 5.5, pointed: false),
        .init(name: "Robusto",      ring: 50, length: 5.0, pointed: false),
        .init(name: "Petit Corona", ring: 42, length: 4.5, pointed: false)
    ]

    private let ppi: CGFloat = 20             // punkter per tomme (samme for begge akser)
    private let maxLength: CGFloat = 7.5
    private var tobacco: Color { Color(hex: "#8F7B51") }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Formatet er ringmål (tykkelse i 1/64\") × lengde. Her er de vanligste, tegnet i samme målestokk så du ser forskjellen. Foten (venstre) klippes rett, hodet (høyre) er avrundet. Målene er typiske — enkeltsigarer varierer.")
                        .font(.footnote)
                        .foregroundColor(Color(.secondaryLabel))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 18)

                    ForEach(vitolaer) { v in
                        HStack(spacing: 14) {
                            // Silhuett — venstrejustert i fast bredde så teksten flukter.
                            CigarSilhouette(pointed: v.pointed)
                                .fill(tobacco)
                                .frame(width: CGFloat(v.length) * ppi,
                                       height: CGFloat(v.ring) / 64 * ppi)
                                .frame(width: maxLength * ppi, height: 26, alignment: .leading)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(v.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Color(.label))
                                Text(v.maal)
                                    .font(.caption)
                                    .foregroundColor(Color(.secondaryLabel))
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 9)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color("Background"))
            .navigationTitle("SEDER-guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lukk") { dismiss() }
                }
            }
        }
    }
}

// MARK: - WrapperGuideSheet
//
// Dekkbladet er det ytterste bladet på sigaren, og står for en stor del av smaken.
// Her forklarer vi de vanligste typene: opphav, typiske smaksnoter og et kort
// kjennetegn. Fargeprøven til venstre er en pekepinn på hvor lyst/mørkt bladet er.

struct WrapperGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private struct Wrap: Identifiable {
        let name: String
        let origin: String
        let notes: String
        let info: String
        let hex: String      // omtrentlig farge på dekkbladet
        var id: String { name }
    }

    // Lyst → mørkt, så listen leses som en fargeskala fra mild til kraftig.
    private let wrappers: [Wrap] = [
        .init(name: "Connecticut Shade",
              origin: "USA (Connecticut) / Ecuador",
              notes: "Mild, kremet, nøtter, gress, hvit pepper",
              info: "Skyggedyrket under duk for et tynt, lyst og silkeaktig blad. Det mildeste alternativet — et trygt valg til morgenkaffen og for nybegynnere.",
              hex: "#D8B98A"),
        .init(name: "Ecuador Connecticut",
              origin: "Ecuador (Connecticut-frø)",
              notes: "Mild–medium, kremet, nøtter, lett sødme",
              info: "Connecticut-frø dyrket under Ecuadors naturlige skydekke. Litt fyldigere og mer smaksrikt enn ekte Connecticut Shade, men fortsatt mildt.",
              hex: "#C8A56A"),
        .init(name: "Colorado Claro",
              origin: "Fargenyanse (variabelt opphav)",
              notes: "Balansert, nøtter, sedertre, mild sødme",
              info: "Egentlig en fargebeskrivelse (lys rødbrun), ikke et sted. Kjennetegner et middels modent, godt balansert dekkblad.",
              hex: "#B07A46"),
        .init(name: "Cameroon",
              origin: "Kamerun / Vest-Afrika",
              notes: "Krydder, sort pepper, kakao, tørket frukt",
              info: "Sjeldent og lunefullt å dyrke. Kjent for en distinkt krydret sødme og et fint, kornete utseende.",
              hex: "#8A4E26"),
        .init(name: "Habano",
              origin: "Nicaragua / Ecuador (cubansk frø)",
              notes: "Pepper, krydder, sedertre, fyldig, kraftig",
              info: "Cubansk-frø-dekkblad dyrket utenfor Cuba. Kraftfullt og krydret — ryggraden i mange fyldige sigarer.",
              hex: "#7A3E1F"),
        .init(name: "Corojo",
              origin: "Honduras / Nicaragua (cubansk sort)",
              notes: "Pepper, krydder, lær, kraftig, tørr finish",
              info: "Klassisk cubansk sort, i dag mest dyrket i Honduras og Nicaragua. Krydret og robust.",
              hex: "#733A1C"),
        .init(name: "Sumatra",
              origin: "Ecuador / Indonesia (Sumatra)",
              notes: "Medium, jord, krydder, lær, lett sødme",
              info: "Mørkt, litt krydret blad. Ecuador-dyrket Sumatra er mildere; indonesisk er kraftigere.",
              hex: "#5E3A1E"),
        .init(name: "San Andrés",
              origin: "Mexico (San Andrés-dalen)",
              notes: "Mørk sjokolade, kaffe, jord, pepper, sødme",
              info: "Meksikansk maduro-blad, ofte solmodnet og ekstra fermentert. Rikt og mørkt.",
              hex: "#3E2617"),
        .init(name: "Broadleaf",
              origin: "USA (Connecticut Broadleaf)",
              notes: "Mørk sjokolade, kaffe, karamell, pepprig finish",
              info: "Robust, tykt blad som fermenteres til en mørk maduro med naturlig sødme. En klassiker i maduro-sigarer.",
              hex: "#2E1B10"),
        .init(name: "Maduro",
              origin: "Metode (ofte Broadleaf / San Andrés)",
              notes: "Sjokolade, kaffe, karamell, espresso, sødme",
              info: "«Maduro» betyr moden. Lengre fermentering med varme og trykk gir et mørkt, søtt og fyldig blad — en metode, ikke et opphav.",
              hex: "#241511")
    ]

    private var accent: Color { colorScheme == .dark ? Color("Accent") : Color(hex: "#8F7B51") }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Dekkbladet er sigarens ytterste blad og står for mye av smaken. Her er de vanligste typene — fra lyst og mildt til mørkt og kraftig — med opphav, typiske smaksnoter og et kort kjennetegn. Fargen er en pekepinn, ikke en fasit.")
                        .font(.footnote)
                        .foregroundColor(Color(.secondaryLabel))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                    ForEach(wrappers) { w in
                        VStack(alignment: .leading, spacing: 9) {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(Color(hex: w.hex))
                                    .frame(width: 36, height: 36)
                                    .overlay(RoundedRectangle(cornerRadius: 7)
                                        .stroke(Color(.separator), lineWidth: 0.5))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(w.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Color(.label))
                                    Text(w.origin)
                                        .font(.caption)
                                        .foregroundColor(Color(.secondaryLabel))
                                }
                                Spacer(minLength: 0)
                            }

                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "circle.hexagongrid.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(accent)
                                    .padding(.top, 1)
                                Text(w.notes)
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(accent)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Text(w.info)
                                .font(.footnote)
                                .foregroundColor(Color(.secondaryLabel))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color("Card")))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color("Background"))
            .navigationTitle("Dekkblad-guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lukk") { dismiss() }
                }
            }
        }
    }
}

// Cigarsilhuett: RETT KLIPT fot til venstre (enden du tenner), avrundet eller
// spisst hode til høyre (enden i munnen). De aller fleste sigarer klippes rett i
// foten — derfor er den en rett vertikal kant, ikke avrundet.
struct CigarSilhouette: Shape {
    var pointed: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = rect.height / 2
        let head = rect.height          // hvor langt spissen strekker seg inn

        p.move(to: CGPoint(x: rect.minX, y: rect.minY))   // topp av den rette foten

        if pointed {
            p.addLine(to: CGPoint(x: rect.maxX - head, y: rect.minY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                           control: CGPoint(x: rect.maxX - head * 0.35, y: rect.minY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX - head, y: rect.maxY),
                           control: CGPoint(x: rect.maxX - head * 0.35, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
            p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.midY), radius: r,
                     startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }

        p.closeSubpath()   // rett fot: vertikal kant tilbake til start
        return p
    }
}

// MARK: - MultiChipFlowLayout (multi-select, wrapping rows)

// MARK: - FilterChip
//
// Chipen bytter tekstvekt når den velges. Halvfet tekst er bredere enn vanlig,
// så hvis vi lot bredden følge vekten ville chipen hoppet i størrelse ved trykk
// — og raden ville plutselig blitt for bred og brukket teksten i to linjer.
//
// Løsning: en usynlig halvfet kopi setter bredden, og den synlige teksten
// tegnes oppå. Chipen er da alltid like bred, valgt eller ikke.

struct FilterChip: View {
    let title: String
    /// Valgfri størrelse, f.eks. «50 × 5"». Vises dempet etter navnet, så et
    /// format som «Robusto» blir konkret for de som ikke kjenner formatene.
    var subtitle: String? = nil
    let isSelected: Bool
    let selectedBg: Color
    let strokeColor: Color

    /// Navnet + (evt.) størrelsen som én linje. `bold` styrer navnets vekt —
    /// den usynlige kopien bruker alltid halvfet så bredden ikke hopper ved trykk.
    private func label(bold: Bool) -> Text {
        var text = Text(title)
            .font(.system(size: 15, weight: bold ? .semibold : .regular))
            .foregroundColor(Color(.label))
        if let subtitle {
            text = text + Text("  \(subtitle)")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
        }
        return text
    }

    var body: some View {
        label(bold: true)
            .lineLimit(1)
            .fixedSize()
            .hidden()
            .overlay(
                label(bold: isSelected)
                    .lineLimit(1)
                    .fixedSize()
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? selectedBg : Color.clear)
            .overlay(Capsule().stroke(isSelected ? Color.clear : strokeColor, lineWidth: 1))
            .clipShape(Capsule())
            .contentShape(Capsule())
    }
}

// MARK: - ChipFlowLayout
//
// Erstatter en tidligere bredde-gjetning (`tegn × 8pt`). Den bommet på lange
// navn som «Dominican Republic», pakket raden for tett, og lot SwiftUI løse
// overfyllingen ved å brekke teksten. Denne spør hver chip hvor bred den er.

struct ChipFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct MultiChipFlowLayout: View {
    let options: [String]
    @Binding var selection: [String]
    let selectedBg: Color
    var strokeColor: Color = Color(red: 202/255, green: 189/255, blue: 162/255)
    /// Valgfri størrelse per valg (kun VITOLA bruker den i dag).
    var subtitles: [String: String] = [:]

    var body: some View {
        // 10 = 8 + 2: 2px mer luft mellom chips, både i raden og mellom radene.
        ChipFlowLayout(spacing: 10) {
            ForEach(options, id: \.self) { opt in
                let isSelected = selection.contains { $0.lowercased() == opt.lowercased() }
                FilterChip(title: opt,
                           subtitle: subtitles[opt],
                           isSelected: isSelected,
                           selectedBg: selectedBg,
                           strokeColor: strokeColor)
                    .onTapGesture {
                        if isSelected { selection.removeAll { $0.lowercased() == opt.lowercased() } }
                        else { selection.append(opt) }
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


// MARK: - ProfileRangeSlider
// Two-thumb range slider for 1–5 scale, stepping in 0.5 increments.

struct ProfileRangeSlider: View {
    let label: String
    @Binding var low: Double
    @Binding var high: Double

    private let rangeMin: Double = 1.0
    private let rangeMax: Double = 5.0
    private let step: Double     = 0.5
    private let thumbSize: CGFloat  = 26
    private let trackHeight: CGFloat = 4

    @State private var lastLow:  Double = 1.0
    @State private var lastHigh: Double = 5.0

    private var isActive: Bool { low > rangeMin || high < rangeMax }

    private func fraction(_ v: Double) -> Double {
        (v - rangeMin) / (rangeMax - rangeMin)
    }

    private func snapped(_ v: Double) -> Double {
        let s = (v / step).rounded() * step
        return Swift.max(rangeMin, Swift.min(rangeMax, s))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label.uppercased())
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.secondaryLabel))
                Spacer()
                if isActive {
                    Text(String(format: "%.1f – %.1f", low, high))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color("Accent"))
                } else {
                    Text("Alle")
                        .font(.system(size: 13))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }

            GeometryReader { geo in
                let w = geo.size.width
                let trackW = w - thumbSize
                let loX = fraction(low)  * trackW
                let hiX = fraction(high) * trackW

                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: trackHeight)
                        .padding(.horizontal, thumbSize / 2)

                    // Active fill between thumbs
                    Capsule()
                        .fill(Color("Accent"))
                        .frame(width: Swift.max(0, hiX - loX), height: trackHeight)
                        .offset(x: loX + thumbSize / 2)

                    // Low thumb
                    Circle()
                        .fill(Color("Accent"))
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
                        .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1.5))
                        .offset(x: loX)
                        .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                let baseFrac = fraction(lastLow)
                                let newFrac  = Swift.max(0, Swift.min(1, baseFrac + v.translation.width / trackW))
                                let cand     = snapped(newFrac * (rangeMax - rangeMin) + rangeMin)
                                if cand + step <= high { low = cand }
                            }
                            .onEnded { _ in lastLow = low }
                        )

                    // High thumb
                    Circle()
                        .fill(Color("Accent"))
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
                        .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1.5))
                        .offset(x: hiX)
                        .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                let baseFrac = fraction(lastHigh)
                                let newFrac  = Swift.max(0, Swift.min(1, baseFrac + v.translation.width / trackW))
                                let cand     = snapped(newFrac * (rangeMax - rangeMin) + rangeMin)
                                if cand - step >= low { high = cand }
                            }
                            .onEnded { _ in lastHigh = high }
                        )
                }
            }
            .frame(height: thumbSize)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - FilterChangeModifier
// Bundles all filter-state onChange handlers into one modifier to keep
// ExploreView.body's modifier chain short enough for the Swift type-checker.

private struct FilterChangeModifier: ViewModifier {
    let fw: [String]
    let fb: [String]
    let ff: [String]
    let fv: [String]
    let fc: [String]
    let profileKey: String
    let fn: [String]
    let ft: [String]
    let fcs: [String]
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: fw)         { _ in action() }
            .onChange(of: fb)         { _ in action() }
            .onChange(of: ff)         { _ in action() }
            .onChange(of: fv)         { _ in action() }
            .onChange(of: fc)         { _ in action() }
            .onChange(of: profileKey) { _ in action() }
            .onChange(of: fn)         { _ in action() }
            .onChange(of: ft)         { _ in action() }
            .onChange(of: fcs)        { _ in action() }
    }
}

// MARK: - BrandCigarsView

struct BrandCigarsView: View {
    let brand: String
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var cigarService = CigarService()
    @State private var cigars: [Cigar] = []
    @State private var isLoading = true

    var groupedBySeries: [(series: String, cigars: [Cigar])] {
        let grouped = Dictionary(grouping: cigars) { $0.series ?? "Andre" }
        return grouped
            .sorted { $0.key < $1.key }
            .map { (series: $0.key, cigars: $0.value) }
    }

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else if cigars.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundColor(Color(.tertiaryLabel))
                    Text("Ingen sigarer funnet")
                        .foregroundColor(Color(.secondaryLabel))
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(groupedBySeries, id: \.series) { group in
                            // Serie-header: samme farge som tittel, ingen innrykk,
                            // venstrejustert med kortene.
                            Text(group.series)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color("TextPrimary"))
                                .tracking(-0.3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.top, 22)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                ForEach(group.cigars) { cigar in
                                    NavigationLink(destination: CigarDetailViewDesign(cigar: cigar)) {
                                        HStack {
                                            BrandCigarRow(cigar: cigar)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(Color(.tertiaryLabel))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }
                                    .buttonStyle(.plain)
                                    .cigarQuickActions(cigar)

                                    if cigar.id != group.cigars.last?.id {
                                        Divider().padding(.leading, 16)
                                    }
                                }
                            }
                            .background(Color("Card"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 40)
                }
                .contentMargins(.bottom, 60, for: .scrollContent) // klarering for egen tab-bar
            }
        }
        .navigationTitle(brand)
        .navigationBarTitleDisplayMode(.inline)   // liten sentrert tittel
        .toolbarBackground(Color("Background"), for: .navigationBar)
        .toolbarColorScheme(colorScheme, for: .navigationBar)
        .task {
            do {
                cigars    = try await cigarService.fetchCigarsByBrand(brand)
                isLoading = false
            } catch {
                isLoading = false
            }
        }
    }
}

// MARK: - TopCigarRow

// MARK: - SkeletonRow
// Plassholder med samme høyde som TopCigarRow (3 tekstlinjer + 2×12 padding),
// slik at Topp 3 ikke endrer høyde når dataene lander.

struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color(.tertiarySystemFill))
                .frame(width: 24, height: 24)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 120, height: 11)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.quaternarySystemFill))
                    .frame(width: 90, height: 10)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.quaternarySystemFill))
                    .frame(width: 60, height: 8)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 79)
    }
}

// MARK: - TopCigarRow

struct TopCigarRow: View {
    let rank: Int
    let cigar: Cigar

    private var rankLabel: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }

    private var scoreText: String {
        guard let score = cigar.avgRating else { return "" }
        // avg_rating lagres på 0–10; vis 0–100 som resten av appen (logg/deling).
        return String(format: "%.0f", score * 10)
    }

    var body: some View {
        HStack(spacing: 14) {
            // Rang
            Text(rankLabel)
                .font(rank <= 3 ? .title3 : .system(size: 17, weight: .bold))
                .frame(width: 32, alignment: .center)
                .foregroundColor(rank <= 3 ? .primary : Color(.tertiaryLabel))

            // Sigarinfo
            VStack(alignment: .leading, spacing: 2) {
                Text(cigar.brand)
                    .font(.subheadline.bold())
                    .foregroundColor(Color(.label))
                if let series = cigar.series {
                    Text(series)
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }
                if let vitola = cigar.vitola {
                    Text(vitola)
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }

            Spacer()

            // Score-badge (samkjørt)
            if !scoreText.isEmpty {
                ScoreBadge(text: scoreText)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())   // hele raden trykkbar
    }
}

// MARK: - BrandCigarRow

struct BrandCigarRow: View {
    let cigar: Cigar

    /// «Robusto · 50 × 4.9" · Cuba». Bygges av delene som faktisk finnes, så
    /// «·» aldri blir stående alene når et felt mangler.
    private var metaLine: String? {
        let parts = [cigar.commonFormat, cigar.dimensionsLabel, cigar.wrapperCountry]
            .compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let vitola = cigar.vitola {
                Text(vitola)
                    .font(.subheadline)
            }
            if let metaLine {
                Text(metaLine)
                    .font(.caption)
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)   // fyll bredden
        .padding(.vertical, 2)
        .contentShape(Rectangle())   // hele raden trykkbar
    }
}

// MARK: - ReceiptSourceSheet
// Bunn-ark for å velge kvittering-kilde (kamera / bibliotek). Erstatter en
// confirmationDialog som feilaktig dukket opp øverst på siden. Samme stil som ScanSheet.
struct ReceiptSourceSheet: View {

    var onCamera: () -> Void
    var onLibrary: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var sheetBackground: Color {
        colorScheme == .light ? .white : Color("Card")
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Fra kvittering")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color("TextPrimary"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                row(icon: "camera.fill", title: "Ta bilde av kvittering",
                    subtitle: "Bruk kameraet", action: onCamera)
                Rectangle()
                    .fill(Color("TextSecondary").opacity(0.12))
                    .frame(height: 0.5)
                    .padding(.leading, 72)
                row(icon: "photo.on.rectangle.angled", title: "Velg bilde fra bibliotek",
                    subtitle: "Fra kamerarull", action: onLibrary)
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(sheetBackground.ignoresSafeArea())
    }

    private func row(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { action() }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color("Accent").opacity(0.14))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(Color("Accent"))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color("TextPrimary"))
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color("TextSecondary"))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color("TextSecondary").opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
