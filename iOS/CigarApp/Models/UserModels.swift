import Foundation

// MARK: - Profile
// Matcher "profiles"-tabellen i Supabase

struct Profile: Codable, Identifiable {
    let id: UUID
    let displayName: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case createdAt   = "created_at"
    }
}

// MARK: - HumidorEntry
// Matcher "humidor"-tabellen i Supabase

struct HumidorEntry: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let cigarId: UUID
    var quantity: Int
    let purchaseDate: Date?
    let purchasePrice: Double?
    let storageNotes: String?
    let createdAt: Date?
    var photoURL: String?
    var scoreConstruction: Int?  // 1–5
    var scoreDraw: Int?          // 1–5
    var scoreBurn: Int?          // 1–5
    var scoreFlavor: Int?        // 1–5

    // Joined data (via Supabase select med foreign key)
    var cigar: Cigar?

    enum CodingKeys: String, CodingKey {
        case id
        case userId             = "user_id"
        case cigarId            = "cigar_id"
        case quantity
        case purchaseDate       = "purchase_date"
        case purchasePrice      = "purchase_price"
        case storageNotes       = "storage_notes"
        case createdAt          = "created_at"
        case photoURL           = "photo_url"
        case scoreConstruction  = "score_construction"
        case scoreDraw          = "score_draw"
        case scoreBurn          = "score_burn"
        case scoreFlavor        = "score_flavor"
        case cigar              = "cigars"
    }

    // Snittscore av alle parametere som er satt (1–5). Nil hvis ingen er vurdert.
    var totalScore: Double? {
        let scores = [scoreConstruction, scoreDraw, scoreBurn, scoreFlavor].compactMap { $0 }
        guard !scores.isEmpty else { return nil }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }
}

// For å oppdatere stjerne-vurderinger på en humidor-oppføring
struct HumidorScoreUpdate: Encodable {
    let scoreConstruction: Int?
    let scoreDraw: Int?
    let scoreBurn: Int?
    let scoreFlavor: Int?

    enum CodingKeys: String, CodingKey {
        case scoreConstruction = "score_construction"
        case scoreDraw         = "score_draw"
        case scoreBurn         = "score_burn"
        case scoreFlavor       = "score_flavor"
    }
}

// For å opprette ny humidor-oppføring
struct NewHumidorEntry: Encodable {
    let userId: UUID
    let cigarId: UUID
    let quantity: Int
    let purchaseDate: Date?
    let purchasePrice: Double?
    let storageNotes: String?

    enum CodingKeys: String, CodingKey {
        case userId         = "user_id"
        case cigarId        = "cigar_id"
        case quantity
        case purchaseDate   = "purchase_date"
        case purchasePrice  = "purchase_price"
        case storageNotes   = "storage_notes"
    }
}

// MARK: - TastingLog
// Matcher "tasting_logs"-tabellen i Supabase

struct TastingLog: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let cigarId: UUID
    let smokedAt: Date
    var rating: Int?            // 1–10
    var perceivedStrength: Int? // 1–5
    var flavorNotes: [String]?
    var pairing: String?
    var personalNotes: String?
    var location: String?
    let createdAt: Date?

    var cigar: Cigar?

    enum CodingKeys: String, CodingKey {
        case id
        case userId             = "user_id"
        case cigarId            = "cigar_id"
        case smokedAt           = "smoked_at"
        case rating
        case perceivedStrength  = "perceived_strength"
        case flavorNotes        = "flavor_notes"
        case pairing
        case personalNotes      = "personal_notes"
        case location
        case createdAt          = "created_at"
        case cigar              = "cigars"
    }
}

struct NewTastingLog: Encodable {
    let userId: UUID
    let cigarId: UUID
    let smokedAt: Date
    let rating: Int?
    let perceivedStrength: Int?
    let flavorNotes: [String]?
    let pairing: String?
    let personalNotes: String?
    let location: String?

    enum CodingKeys: String, CodingKey {
        case userId             = "user_id"
        case cigarId            = "cigar_id"
        case smokedAt           = "smoked_at"
        case rating
        case perceivedStrength  = "perceived_strength"
        case flavorNotes        = "flavor_notes"
        case pairing
        case personalNotes      = "personal_notes"
        case location
    }
}
