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
