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
    let strength: Int?              // 1 (mild) → 5 (full)
    let countryOrigin: String?
    let flavorNotes: [String]?
    let description: String?
    let bandImageUrl: String?
    let productImageUrl: String?
    let priceRange: String?
    let avgRating: Double?
    let ringGauge: Int?
    let lengthInches: Double?
    let shape: String?               // Parejo / Box-Pressed / Figurado
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
        switch strength {
        case 1: return "Mild"
        case 2: return "Mild–Medium"
        case 3: return "Medium"
        case 4: return "Medium–Full"
        case 5: return "Full"
        default: return "Ukjent"
        }
    }

    var strengthColor: String {
        switch strength {
        case 1, 2: return "green"
        case 3: return "orange"
        case 4, 5: return "red"
        default: return "gray"
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
