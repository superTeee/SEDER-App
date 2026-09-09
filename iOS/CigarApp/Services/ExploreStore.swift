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

    // MARK: - Kuraterte katalogfiltre

    /// Rå katalogdata skal være detaljerte, men filteret skal ikke eksponere
    /// 100+ skrivemåter av det samme. Disse listene er bevisst korte og stabile.
    private static let binderOrder = [
        "Nicaragua", "Dominican Republic", "Honduras", "Cuba", "Mexico", "Ecuador",
        "United States", "Indonesia", "Brazil", "Cameroon", "Peru", "Costa Rica"
    ]

    private static let fillerOrder = [
        "Nicaragua", "Dominican Republic", "Honduras", "Cuba", "United States", "Peru",
        "Mexico", "Brazil", "Costa Rica", "Colombia", "Ecuador", "Paraguay"
    ]

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
    }

    private static func containsAny(_ value: String, _ needles: [String]) -> Bool {
        needles.contains { value.contains($0) }
    }

    /// Ett råfelt kan være en blend (f.eks. «Dominican and Nicaraguan»), og skal
    /// da kunne finnes fra begge relevante filtervalg. Vi gjetter ikke på generiske
    /// bladnavn som «Sumatra», «Corojo» eller «Habano» når opprinnelsen ikke står der.
    private static func binderCategories(for raw: String) -> [String] {
        let v = normalized(raw)
        var result: [String] = []

        if containsAny(v, ["nicarag", "aganorsa", "jalapa", "esteli", "condega", "ometepe", "quilali"]) {
            result.append("Nicaragua")
        }
        if containsAny(v, ["dominican", "piloto", "olor dominicano", "la vega especial"]) {
            result.append("Dominican Republic")
        }
        if containsAny(v, ["hondur", "jamastran", "olancho"]) {
            result.append("Honduras")
        }
        if v == "cuba" || v == "cuban" || v.contains("habana vuelta arriba") || v.hasPrefix("hva (") {
            result.append("Cuba")
        }
        if containsAny(v, ["mexic", "san andres"]) {
            result.append("Mexico")
        }
        if v.contains("ecuador") {
            result.append("Ecuador")
        }
        if containsAny(v, ["united states", "u.s.", "usa", "pennsylvania", "american havana"]) ||
            v == "connecticut broadleaf" || v == "connecticut shade" {
            result.append("United States")
        }
        if containsAny(v, ["indonesia", "indonesian", "besuki", "bezuki"]) {
            result.append("Indonesia")
        }
        if containsAny(v, ["brazil", "mata fina", "arapiraca"]) {
            result.append("Brazil")
        }
        if v.contains("cameroon") {
            result.append("Cameroon")
        }
        if v.contains("peru") {
            result.append("Peru")
        }
        if v.contains("costa rica") {
            result.append("Costa Rica")
        }
        return result
    }

    private static func fillerCategories(for raw: String) -> [String] {
        let v = normalized(raw)
        var result: [String] = []

        if containsAny(v, ["nicarag", "aganorsa", "jalapa", "esteli", "condega", "ometepe", "pueblo nuevo", "masatepe", "quilali"]) {
            result.append("Nicaragua")
        }
        if containsAny(v, ["dominican", "piloto", "olor", "andullo", "cubita mao"]) {
            result.append("Dominican Republic")
        }
        if containsAny(v, ["hondur", "jamastran", "la entrada", "olancho"]) {
            result.append("Honduras")
        }
        if v == "cuba" || v == "cuban" {
            result.append("Cuba")
        }
        if containsAny(v, ["united states", "u.s.", "usa", "pennsylvania"]) ||
            v == "connecticut broadleaf" || v == "american" {
            result.append("United States")
        }
        if v.contains("peru") || v.contains("peruvian") {
            result.append("Peru")
        }
        if containsAny(v, ["mexic", "san andres"]) {
            result.append("Mexico")
        }
        if containsAny(v, ["brazil", "mata fina", "braganca", "fuma en corda"]) {
            result.append("Brazil")
        }
        if v.contains("costa rica") || v.contains("costa rican") {
            result.append("Costa Rica")
        }
        if v.contains("colombia") || v.contains("colombian") {
            result.append("Colombia")
        }
        if v.contains("ecuador") {
            result.append("Ecuador")
        }
        if v.contains("paraguay") {
            result.append("Paraguay")
        }
        return result
    }

    private static func curatedOptions(
        from options: [CatalogFilterOption],
        order: [String],
        categories: (String) -> [String]
    ) -> [CatalogFilterOption] {
        let rawValues = Set(options.flatMap(\.values))
        var grouped: [String: Set<String>] = [:]

        for raw in rawValues {
            for category in categories(raw) where order.contains(category) {
                grouped[category, default: []].insert(raw)
            }
        }

        return order.compactMap { label in
            guard let values = grouped[label], !values.isEmpty else { return nil }
            return CatalogFilterOption(label: label, values: values.sorted())
        }
    }

    /// Noen DB-notater er bare alternative skrivemåter av en eksisterende ikonfamilie.
    /// De mappes her uten å endre rådataene. Generiske kvalitetsord holdes ute av
    /// smaksfilteret; de hører hjemme i profil/rating, ikke som egne smaker.
    private static func flavorFamily(for raw: String) -> String? {
        let v = normalized(raw)

        let nonFlavorDescriptors: Set<String> = [
            "sweetness", "sweet", "natural sweetness", "gentle sweetness", "mild sweetness",
            "full-bodied", "balanced", "complex", "rich", "smooth"
        ]
        if nonFlavorDescriptors.contains(v) { return nil }

        if let existing = FlavorIcon.name(for: raw) { return existing }

        switch v {
        case "baking spice", "warm spice", "silky spice", "subtle spice", "nutmeg", "licorice":
            return "spice"
        case "cherry", "dark cherry", "dried cherry", "fig", "sweet figs":
            return "fruit"
        case "herbal", "herbaceous", "dried herbs", "vegetal":
            return "herbal"
        case "smoke", "fire", "ash":
            return "tobacco"
        case "mocha", "dark espresso", "dark roast coffee", "creamy coffee":
            return "coffee"
        case "malt", "graham", "graham cracker", "baked bread":
            return "toast"
        case "brown sugar", "raw sugar", "sugar dust":
            return "sugar"
        case "buttery smooth", "creamy", "malted milk":
            return "cream"
        case "cacao":
            return "cocoa"
        case "charred wood", "dark wood":
            return "wood"
        case "salt":
            return "minerals"
        case "toasted almond", "cashew", "light nuttiness":
            return "nuts"
        case "barnyard":
            return "earth"
        case "dark cedar", "light cedar":
            return "cedar"
        default:
            return nil
        }
    }

    private static func flavorLabel(for family: String) -> String {
        switch family {
        case "herbal": return "Urter"
        case "sugar": return "Sukker"
        default: return FlavorIcon.displayLabel(for: family)
        }
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
            let rawCatalog = try await cigarService.fetchCatalogFilterOptions()
            var catalog = rawCatalog

            // Binder/filler: behold eksakte DB-strenger som matchverdier, men vis kun
            // de vanligste, forståelige opprinnelseskategoriene i avansert søk.
            catalog.binders = Self.curatedOptions(
                from: rawCatalog.binders,
                order: Self.binderOrder,
                categories: Self.binderCategories
            )
            catalog.fillers = Self.curatedOptions(
                from: rawCatalog.fillers,
                order: Self.fillerOrder,
                categories: Self.fillerCategories
            )

            // Smaksnoter: synonymer samles i meningsfulle familier i stedet for at
            // rå stavevarianter eksponeres som egne chips. Sukker holdes bevisst
            // separat fra honning fordi de er forskjellige smaksnoter.
            var byFamily: [String: [String]] = [:]
            for note in rawCatalog.notes {
                let clean = note.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !clean.isEmpty, let family = Self.flavorFamily(for: clean) else { continue }
                byFamily[family, default: []].append(note)
            }

            catalogFilters = catalog
            filtersLoadedAt = Date()
            flavorOptions = byFamily
                .map { family, notes in
                    FlavorFilterOption(
                        label: Self.flavorLabel(for: family),
                        iconFamily: family,
                        dbNotes: Array(Set(notes)).sorted()
                    )
                }
                .sorted { lhs, rhs in
                    let order = [
                        "Sedertre", "Tre", "Jord", "Lær", "Pepper", "Krydder", "Kanel",
                        "Kakao", "Kaffe", "Toast", "Nøtter", "Kremete", "Sukker", "Honning", "Vanilje",
                        "Frukt", "Sitrus", "Blomst", "Høy", "Mineral", "Mynte", "Tobakk",
                        "Whisky", "Urter"
                    ]
                    return (order.firstIndex(of: lhs.label) ?? 999) < (order.firstIndex(of: rhs.label) ?? 999)
                }
        } catch {
            filterError = "Kunne ikke oppdatere filtrene. Kontroller forbindelsen og prøv igjen."
        }
    }
}
