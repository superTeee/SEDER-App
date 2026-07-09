import SwiftUI
import AVFoundation

// MARK: - ExploreView
// Browse alle sigarer: søk, merkeliste, avansert filter og skann-FAB

struct ExploreView: View {

    @StateObject private var cigarService = CigarService()
    @StateObject private var scanService  = ScanService()

    // Søk
    @State private var searchQuery   = ""
    @FocusState private var searchFocused: Bool
    @State private var searchResults: [Cigar] = []
    @State private var isSearching   = false
    @State private var searchTask: Task<Void, Never>? = nil

    // Delt datalager. Fylles parallelt allerede mens splash-sekvensen spiller,
    // og overlever fane-bytter — derfor ingen ny henting hver gang viewet vises.
    @ObservedObject private var store = ExploreStore.shared

    private var allBrands: [String]                    { store.brands }
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

    // Strekkode-scanner
    @State private var showBarcodeScan       = false
    @State private var barcodeFoundCigar:    Cigar?   = nil
    @State private var navigateToBarcode     = false

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

    var brandSections: [(letter: String, brands: [String])] {
        Dictionary(grouping: allBrands) { brand -> String in
            let first = brand.first.map { String($0).uppercased() } ?? "#"
            return first.first?.isLetter == true ? first : "#"
        }
        .sorted { $0.key < $1.key }
        .map { (letter: $0.key, brands: $0.value.sorted()) }
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
                        .padding(.bottom, 100) // plass til FAB
                    }
                    .scrollDismissesKeyboard(.immediately) // dra/scroll lukker tastaturet
                }

                // — FAB: Skann sigar
                scanFAB
            }
            .navigationTitle("Utforsk")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color("Background"), for: .navigationBar)
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
            .fullScreenCover(isPresented: $showBarcodeScan) {
                BarcodeScanView { cigar in
                    // Liten delay slik at fullScreenCover rekker å lukke seg før navigering
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        barcodeFoundCigar = cigar
                        navigateToBarcode = true
                    }
                }
            }
            .fullScreenCover(isPresented: $scanService.needsShapePhoto) {
                ShapeConfirmView(scanService: scanService)
            }
            .fullScreenCover(isPresented: $scanService.needsWrapperPhoto) {
                WrapperConfirmView(scanService: scanService)
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
        .padding(.vertical, 10)
        .background(Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Filter-knapp (toolbar)

    private var filterButton: some View {
        Button {
            showFilterSheet = true
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
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

    // MARK: - FAB

    private var scanFAB: some View {
        Menu {
            Button {
                showBarcodeScan = true
            } label: {
                Label("Skann strekkode", systemImage: "barcode.viewfinder")
            }
            Button {
                showCameraPicker = true
            } label: {
                Label("Skann magebeltet", systemImage: "camera.fill")
            }
            Button {
                showLibraryPicker = true
            } label: {
                Label("Bilde fra kamerarull", systemImage: "photo.on.rectangle")
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 16, weight: .semibold))
                Text("Skann sigar")
                    .font(.system(size: 15, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color("Accent"))
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(color: Color("Accent").opacity(0.35), radius: 10, x: 0, y: 4)
        }
        .menuOrder(.fixed)
        .padding(.trailing, 20)
        .padding(.bottom, 24)
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
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }

            Spacer()

            // Rating-badge
            if let rating = cigar.avgRating {
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color("Accent"))
                    Text("score")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color("Accent").opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
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
                            .foregroundColor(Color(.secondaryLabel))
                            .frame(width: 20)
                        Text(term)
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
        sectionHeader("Brukernes topp 3")
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
                    ForEach(section.brands, id: \.self) { brand in
                        NavigationLink(value: brand) {
                            HStack {
                                Text(brand)
                                    .foregroundColor(Color(.label))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                        }

                        if brand != section.brands.last {
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
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
            .padding(.horizontal, 32)
        } else {
            sectionHeader("\(results.count) treff")

            VStack(spacing: 0) {
                ForEach(results) { cigar in
                    NavigationLink(destination: CigarDetailViewDesign(cigar: cigar)) {
                        ExploreResultRow(cigar: cigar)
                    }
                    .cigarQuickActions(cigar)
                    if cigar.id != results.last?.id {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Color("Card"))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 16)
            .padding(.top, 4)
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

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
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
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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

    private let initialCount = 6

    private let crossSectionOptions = ["Box Pressed", "Oval", "Hexagonal"]
    private let originOptions   = ["Nicaragua", "Dominican Republic", "Honduras", "Cuba", "Mexico", "Ecuador", "Peru", "Costa Rica", "Panama", "USA"]
    private let vitolaOptions   = ["Toro", "Robusto", "Gordo", "Corona Gorda", "Churchill", "Corona", "Lancero", "Torpedo", "Belicoso", "Figurado", "Panatela", "Petit Corona"]
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
                    crossSectionFilterSection
                    sectionDivider()
                    chipSection(title: "OPPHAV",  options: originOptions,  selection: $countryOrigin,  showAll: $showAllOrigin)
                    sectionDivider()
                    chipSection(title: "VITOLA",  options: vitolaOptions,  selection: $vitola,         showAll: $showAllVitola)
                    sectionDivider()
                    chipSection(title: "WRAPPER", options: wrapperOptions, selection: $wrapperCountry, showAll: $showAllWrapper)
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
    }

    // ── Tverrsnitt (box pressed / oval / hexagonal) ──
    private var crossSectionFilterSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TVERRSNITT")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(.secondaryLabel))
                .padding(.horizontal, 16)
                .padding(.top, 16)

            HStack(spacing: 8) {
                ForEach(crossSectionOptions, id: \.self) { opt in
                    let isSelected = crossSection.contains(opt)
                    Text(opt)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(isSelected ? chipSelectedBg : Color.clear)
                        .foregroundColor(Color(.label))
                        .overlay(Capsule().stroke(isSelected ? Color.clear : chipStroke, lineWidth: 1))
                        .clipShape(Capsule())
                        .onTapGesture {
                            if isSelected { crossSection.removeAll { $0 == opt } }
                            else { crossSection.append(opt) }
                        }
                }
                Spacer(minLength: 0)
            }
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
        showAll: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(.secondaryLabel))
                .padding(.horizontal, 16)
                .padding(.top, 16)

            MultiChipFlowLayout(
                options: showAll.wrappedValue ? options : Array(options.prefix(initialCount)),
                selection: selection,
                selectedBg: chipSelectedBg,
                strokeColor: chipStroke
            )
            .padding(.horizontal, 16)

            if options.count > initialCount {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showAll.wrappedValue.toggle() }
                } label: {
                    Text(showAll.wrappedValue ? "Vis færre ↑" : "Se alle ↓")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color("Accent"))
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)   // litt mer luft ned til chipsene
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
                .font(.system(size: 12, weight: .semibold))
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
            Text("RØYKETID")
                .font(.system(size: 12, weight: .semibold))
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

// MARK: - MultiChipFlowLayout (multi-select, wrapping rows)

struct MultiChipFlowLayout: View {
    let options: [String]
    @Binding var selection: [String]
    let selectedBg: Color
    var strokeColor: Color = Color(red: 202/255, green: 189/255, blue: 162/255)

    var body: some View {
        // Innhold ligger 8px (ark) + 16px (seksjon) inne på hver side.
        let rows = computeRows(screenWidth: UIScreen.main.bounds.width - 48)
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rows.indices, id: \.self) { rowIdx in
                HStack(spacing: 8) {
                    ForEach(rows[rowIdx], id: \.self) { opt in
                        let isSelected = selection.contains(where: { $0.lowercased() == opt.lowercased() })
                        Text(opt)
                            .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(isSelected ? selectedBg : Color.clear)
                            .foregroundColor(Color(.label))
                            .overlay(Capsule().stroke(isSelected ? Color.clear : strokeColor, lineWidth: 1))
                            .clipShape(Capsule())
                            .onTapGesture {
                                if isSelected { selection.removeAll { $0.lowercased() == opt.lowercased() } }
                                else { selection.append(opt) }
                            }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func computeRows(screenWidth: CGFloat) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var rowWidth: CGFloat = 0
        for opt in options {
            let chipW = CGFloat(opt.count) * 8 + 28 + 8
            if rowWidth + chipW > screenWidth && !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = [opt]
                rowWidth = chipW
            } else {
                currentRow.append(opt)
                rowWidth += chipW
            }
        }
        if !currentRow.isEmpty { rows.append(currentRow) }
        return rows
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
                    .font(.system(size: 12, weight: .semibold))
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
            }
        }
        .navigationTitle(brand)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color("Background"), for: .navigationBar)
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
        return String(format: "%.1f", score)
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
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }

            Spacer()

            // Score-badge
            if !scoreText.isEmpty {
                Text(scoreText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("Accent"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color("Accent").opacity(0.1))
                    .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - BrandCigarRow

struct BrandCigarRow: View {
    let cigar: Cigar

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let vitola = cigar.vitola {
                Text(vitola)
                    .font(.subheadline)
            }
            HStack(spacing: 8) {
                if let format = cigar.commonFormat {
                    Text(format)
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
                if let wrapper = cigar.wrapperCountry {
                    // Skilletegn kun når det finnes et format foran — ellers
                    // blir "·" stående alene foran wrapper/origin.
                    if cigar.commonFormat != nil {
                        Text("·")
                            .font(.caption)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    Text(wrapper)
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
        }
        .padding(.vertical, 2)
    }
}
