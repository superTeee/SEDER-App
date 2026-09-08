import Foundation

// MARK: - ExploreStore
//
// Delt datalager for Utforsk-siden. Lever på tvers av fane-bytter, så dataene
// hentes bare én gang per app-start.
//
// Hvorfor: før lå alt som @State inne i ExploreView og ble hentet SEKVENSIELT
// i .task hver gang viewet dukket opp — først merkelisten (som er en stor,
// paginert henting), så smaksnotene, så Topp 3, så Dagens utvalgte. Hver seksjon
// poppet inn etter tur og dyttet innholdet under seg nedover.
//
// Nå: alle fire hentes PARALLELT, og de startes allerede når appen åpner —
// mens splash-sekvensen spiller. Da er dataene som regel på plass før brukeren
// i det hele tatt ser Utforsk-siden.

@MainActor
final class ExploreStore: ObservableObject {

    static let shared = ExploreStore()
    private init() {}

    // MARK: Data

    @Published private(set) var brands: [BrandSummary] = []
    @Published private(set) var catalogFilters = CatalogFilterOptions()
    @Published private(set) var isLoadingFilters = false
    @Published private(set) var filterError: String?
    private var filtersLoadedAt: Date?

    @Published private(set) var flavorOptions: [FlavorFilterOption] = []
    @Published private(set) var topCigars: [Cigar] = []
    @Published private(set) var featuredCigar: Cigar? = nil

    @Published private(set) var isLoadingBrands = false
    @Published private(set) var isLoadingTop = false
    @Published private(set) var isLoadingFeatured = false

    // MARK: Internt

    private let cigarService = CigarService()
    private var preloadTask: Task<Void, Never>?

    /// Hvilken dag i året «Dagens utvalgte» sist ble beregnet for.
    private var featuredDayOfYear: Int {
        get { UserDefaults.standard.integer(forKey: "featuredDayOfYear") }
        set { UserDefaults.standard.set(newValue, forKey: "featuredDayOfYear") }
    }

    private var today: Int {
        Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    }

    // MARK: - API

    /// Starter forhåndslasting. Trygg å kalle flere ganger — kjører bare én gang.
    func preload() {
        guard preloadTask == nil else { return }

        isLoadingBrands = true
        isLoadingTop = true
        isLoadingFeatured = true

        preloadTask = Task { [weak self] in
            guard let self else { return }
            // Alle fire samtidig. Topp 3 og Dagens utvalgte er små og lander først;
            // merkelisten er stor og får bruke den tiden den trenger.
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadTopCigars() }
                group.addTask { await self.loadFeaturedCigar() }
                group.addTask { await self.loadBrands() }
                group.addTask { await self.loadFilterOptions() }
            }
        }
    }

    /// Nytt døgn? Beregn «Dagens utvalgte» på nytt.
    func refreshFeaturedIfNewDay() {
        guard today != featuredDayOfYear else { return }
        Task { await loadFeaturedCigar() }
    }

    /// Slår opp de rå DB-notatene bak et filter-valg (etikett → notater).
    func dbNotes(forFlavorLabel label: String) -> [String]? {
        flavorOptions.first { $0.label == label }?.dbNotes
    }

    // MARK: - Hentinger

    private func loadTopCigars() async {
        defer { isLoadingTop = false }
        do {
            topCigars = try await cigarService.fetchTopRatedCigars(limit: 3)
        } catch {
            print("Feil ved lasting av topp-sigarer: \(error)")
        }
    }

    private func loadFeaturedCigar() async {
        isLoadingFeatured = true
        defer { isLoadingFeatured = false }
        let day = today
        do {
            // Prøv smakstilpasset valg først (ligner journalen, men ikke logget før)
            if let matched = try await cigarService.fetchTasteFeaturedCigar() {
                featuredCigar = matched
                featuredDayOfYear = day
                return
            }
            // Fallback: deterministisk rating-valg (ny bruker / for lite loggdata)
            let candidates = try await cigarService.fetchAboveAverageCigars()
            guard !candidates.isEmpty else { return }
            featuredCigar = candidates[(day - 1) % candidates.count]
            featuredDayOfYear = day
        } catch {
            print("Feil ved lasting av dagens utvalgte: \(error)")
        }
    }

    private func loadBrands() async {
        defer { isLoadingBrands = false }
        do {
            brands = try await cigarService.fetchBrandSummaries()
        } catch {
            print("Feil ved lasting av merker: \(error)")
        }
    }

    func loadFilterOptions(force: Bool = false) async {
        guard !isLoadingFilters else { return }
        if !force, let date = filtersLoadedAt, Date().timeIntervalSince(date) < 300 { return }
        isLoadingFilters = true
        filterError = nil
        defer { isLoadingFilters = false }
        do {
            let catalog = try await cigarService.fetchCatalogFilterOptions()
            let rawNotes = catalog.notes
            // Grupper rå-notatene på ikon-familie slik at hvert filtervalg
            // svarer til minst én ekte sigar. Notater uten ikon beholder navnet fra basen.
            var byFamily: [String: [String]] = [:]
            for note in rawNotes {
                let clean = note.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !clean.isEmpty else { continue }
                let family = FlavorIcon.name(for: note) ?? "raw:" + clean.lowercased()
                byFamily[family, default: []].append(note)
            }
            catalogFilters = catalog
            filtersLoadedAt = Date()
            flavorOptions = byFamily
                .map { FlavorFilterOption(label: $0.key.hasPrefix("raw:") ? String($0.key.dropFirst(4)) : FlavorIcon.displayLabel(for: $0.key),
                                          iconFamily: $0.key,
                                          dbNotes: $0.value) }
                .sorted { $0.label < $1.label }
        } catch {
            filterError = "Kunne ikke oppdatere filtrene. Kontroller forbindelsen og prøv igjen."
        }
    }
}
