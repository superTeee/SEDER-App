import Foundation

// MARK: - Cigar
// Matcher "cigars"-tabellen i Supabase

struct Cigar: Codable, Identifiable, Hashable {
    let id: UUID
    let brand: String                // Brand family, f.eks. "Don Pepin Garcia"
    let manufacturer: String?        // Produsenten/huset, f.eks. "My Father Cigars"
    let series: String?
    let vitola: String?
    let commonFormat: String?        // Generisk vitola-kategori (Robusto/Toro/...), brukt i søk/OCR
    let wrapperCountry: String?
    let wrapperLeaf: String?
    let binder: String?
    let filler: [String]?
    let strength: Double?           // 0.5–5.0 (støtter desimaler, f.eks. 2.5)
    let body: Double?               // Fylde 0–5
    let sweetness: Double?          // Sødme 0–5
    let flavorIntensity: Double?    // Smaksintensitet 0–5
    let countryOrigin: String?
    let flavorNotes: [String]?
    let description: String?
    let bandImageUrl: String?
    let productImageUrl: String?
    let priceRange: String?
    let avgRating: Double?
    let ringGauge: Int?
    let lengthInches: Double?
    let shape: String?               // Parejo / Figurado / Torpedo etc.
    let crossSection: String?        // Tverrsnitt: Round / Box Pressed / Oval / Hexagonal
    let bodyType: String?            // Figurado-undertype (Torpedo/Belicoso/Perfecto/Salomon), null for Parejo
    let headType: String?            // f.eks. "Pointed" — null = standard/rundt
    let footType: String?            // f.eks. "Closed"/"Tapered" — null = standard/åpen
    let createdAt: Date?

    // Herkomst. Uten disse kunne ikke databasen skille en rad hentet fra
    // produsentens katalog fra en rad noen hadde gjettet seg fram til.
    let sourceUrl: String?          // Hvor spesifikasjonene kommer fra
    let verifiedAt: Date?           // Når de sist ble sjekket mot kilden

    // Egne sigarer. En privat rad (is_public = false) er brukerens egen, opprettet
    // fordi sigaren manglet i basen. Den virker i humidor og journal med én gang,
    // men er usynlig for alle andre til forslaget er godkjent.
    let createdBy: UUID?
    let isPublic: Bool?

    /// Er spesifikasjonene sjekket mot en kilde? Er de ikke det, skal appen si
    /// det til brukeren i stedet for å presentere gjetning som fakta.
    var isVerified: Bool { verifiedAt != nil }

    /// Privat rad som kun eieren ser.
    var isPrivate: Bool { isPublic == false }

    enum CodingKeys: String, CodingKey {
        case id
        case brand
        case manufacturer
        case series
        case vitola
        case commonFormat       = "common_format"
        case wrapperCountry     = "wrapper_country"
        case wrapperLeaf        = "wrapper_leaf"
        case binder
        case filler
        case strength
        case body
        case sweetness
        case flavorIntensity    = "flavor_intensity"
        case countryOrigin      = "country_origin"
        case flavorNotes        = "flavor_notes"
        case description
        case bandImageUrl       = "band_image_url"
        case productImageUrl    = "product_image_url"
        case priceRange         = "price_range"
        case avgRating          = "avg_rating"
        case ringGauge          = "ring_gauge"
        case lengthInches       = "length_inches"
        case shape
        case crossSection       = "cross_section"
        case bodyType           = "body_type"
        case headType           = "head_type"
        case footType           = "foot_type"
        case createdAt          = "created_at"
        case sourceUrl          = "source_url"
        case verifiedAt         = "verified_at"
        case createdBy          = "created_by"
        case isPublic           = "is_public"
    }

    // Hjelpefunksjoner
    var fullName: String {
        [brand, series, vitola].compactMap { $0 }.joined(separator: " ")
    }

    var strengthLabel: String {
        guard let s = strength else { return "Ukjent" }
        switch s {
        case ..<1.5: return "Mild"
        case 1.5..<2.5: return "Mild–Medium"
        case 2.5..<3.5: return "Medium"
        case 3.5..<4.5: return "Medium–Full"
        default: return "Full"
        }
    }

    var strengthColor: String {
        guard let s = strength else { return "gray" }
        switch s {
        case ..<2.5: return "green"
        case 2.5..<3.5: return "orange"
        default: return "red"
        }
    }
}

// MARK: - Scan Result
// Representerer ett treff fra AI/OCR-scanningen

struct ScanResult: Identifiable, Equatable {
    let id = UUID()
    let cigar: Cigar
    let confidence: Double      // 0.0 → 1.0
    let matchReason: String     // "Tekst: Davidoff Winston Churchill"

    var confidenceLabel: String {
        switch confidence {
        case 0.8...: return "Sterkt treff"
        case 0.5..<0.8: return "Mulig treff"
        default: return "Svakt treff"
        }
    }
}

// MARK: - FlavorIcon (note → ikon-asset)
// Generert fra smaksnote-databasen. Slår opp en smaksnote til et av
// FlavorIcons-assetene (template, tintes til Accent i UI). Case-insensitivt.
enum FlavorIcon {
    static let map: [String: String] = [
        "almond": "nuts",
        "almonds": "nuts",
        "anise": "cinnamon",
        "black pepper": "pepper",
        "butter": "cream",
        "caramel": "honey",
        "cardamom": "cinnamon",
        "cedar": "cedar",
        "chocolate": "cocoa",
        "cinnamon": "cinnamon",
        "citrus": "citrus",
        "cocoa": "cocoa",
        "coffee": "coffee",
        "cream": "cream",
        "dark chocolate": "cocoa",
        "dark cocoa": "cocoa",
        "dark earth": "earth",
        "dark fruit": "fruit",
        "dark roasted coffee": "coffee",
        "dark spice": "spice",
        "dark tobacco": "tobacco",
        "dried fruit": "fruit",
        "earth": "earth",
        "espresso": "coffee",
        "floral": "floral",
        "fruit": "fruit",
        "gentle earth": "earth",
        "gentle floral": "floral",
        "gentle pepper": "pepper",
        "gentle spice": "spice",
        "grass": "hay",
        "hay": "hay",
        "honey": "honey",
        "kremete": "cream",
        "leather": "leather",
        "light earth": "earth",
        "light floral": "floral",
        "light pepper": "pepper",
        "light spice": "spice",
        "light wood": "wood",
        "maple": "honey",
        "mild coffee": "coffee",
        "mild cream": "cream",
        "mild earth": "earth",
        "mild krydder": "spice",
        "mild pepper": "pepper",
        "mild spice": "spice",
        "mineral": "minerals",
        "minerals": "minerals",
        "mint": "mint",
        "minty": "mint",
        "molasses": "honey",
        "mynte": "mint",
        "natural sweetness": "honey",
        "nougat": "nuts",
        "nut": "nuts",
        "nuts": "nuts",
        "nøtter": "nuts",
        "oak": "wood",
        "paprika": "pepper",
        "pepper": "pepper",
        "peppermint": "mint",
        "roasted almonds": "nuts",
        "roasted aromas": "coffee",
        "roasted cashews": "nuts",
        "roasted coffee": "coffee",
        "roasted espresso": "coffee",
        "roasted nuts": "nuts",
        "sedertre": "cedar",
        "smoky wood": "wood",
        "soft spice": "spice",
        "spearmint": "mint",
        "spice": "spice",
        "sweet cream": "cream",
        "sweet earth": "earth",
        "sweet spice": "spice",
        "sweet spices": "spice",
        "toast": "toast",
        "toasted bread": "toast",
        "toasted cream": "cream",
        "toasted nuts": "nuts",
        "toasted wood": "wood",
        "tobacco": "tobacco",
        "vanilla": "vanilla",
        "whiskey": "whisky",
        "white pepper": "pepper",
        "wood": "wood",
    ]

    /// Returnerer ikon-navn for en smaksnote, eller nil hvis ukjent.
    static func name(for note: String) -> String? {
        map[note.lowercased().trimmingCharacters(in: .whitespaces)]
    }

    /// Norsk etikett per ikon-familie (appen er på norsk).
    static let label: [String: String] = [
        "cedar": "Sedertre", "cocoa": "Kakao", "leather": "Lær", "tobacco": "Tobakk",
        "cinnamon": "Kanel", "minerals": "Mineral", "whisky": "Whisky", "citrus": "Sitrus",
        "wood": "Tre", "pepper": "Pepper", "nuts": "Nøtter", "vanilla": "Vanilje",
        "earth": "Jord", "fruit": "Frukt", "floral": "Blomst", "hay": "Høy",
        "coffee": "Kaffe", "honey": "Honning", "toast": "Toast", "cream": "Kremete",
        "spice": "Krydder", "mint": "Mynte"
    ]

    /// Norsk visningsetikett for et ikon-navn.
    static func displayLabel(for icon: String) -> String {
        label[icon] ?? icon.capitalized
    }
}
