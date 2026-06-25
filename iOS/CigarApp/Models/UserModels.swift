import Foundation

// MARK: - Profile
// Matcher "profiles"-tabellen i Supabase

struct Profile: Codable, Identifiable {
    let id: UUID
    let displayName: String?
    let friendCode: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case friendCode  = "friend_code"
        case createdAt   = "created_at"
    }
}

// MARK: - HumidorEntry
// Matcher "humidor"-tabellen i Supabase

struct HumidorEntry: Identifiable, Encodable {
    let id: UUID
    let userId: UUID
    let cigarId: UUID
    var quantity: Int
    let purchaseDate: Date?
    let addedToHumidorAt: Date?
    let purchasePrice: Double?
    let storageNotes: String?
    let createdAt: Date?
    var photoURL: String?
    var cigar: Cigar?

    enum CodingKeys: String, CodingKey {
        case id
        case userId             = "user_id"
        case cigarId            = "cigar_id"
        case quantity
        case purchaseDate       = "purchase_date"
        case addedToHumidorAt   = "added_to_humidor_at"
        case purchasePrice      = "purchase_price"
        case storageNotes       = "storage_notes"
        case createdAt          = "created_at"
        case photoURL           = "photo_url"
        case cigar              = "cigars"
    }
}

// Tilpasset Decodable-implementasjon som håndterer Postgres DATE-format ("yyyy-MM-dd")
// OG vanlig TIMESTAMPTZ ISO 8601-format. Uten dette krasjer dekodingen for alle
// humidor-rader som har purchase_date satt (hele listen ser tom ut).
extension HumidorEntry: Decodable {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(UUID.self,    forKey: .id)
        userId          = try c.decode(UUID.self,    forKey: .userId)
        cigarId         = try c.decode(UUID.self,    forKey: .cigarId)
        quantity        = try c.decode(Int.self,     forKey: .quantity)
        addedToHumidorAt = try c.decodeIfPresent(Date.self,   forKey: .addedToHumidorAt)
        purchasePrice   = try c.decodeIfPresent(Double.self,  forKey: .purchasePrice)
        storageNotes    = try c.decodeIfPresent(String.self,  forKey: .storageNotes)
        createdAt       = try c.decodeIfPresent(Date.self,    forKey: .createdAt)
        photoURL        = try c.decodeIfPresent(String.self,  forKey: .photoURL)
        cigar           = try c.decodeIfPresent(Cigar.self,   forKey: .cigar)

        // purchase_date er DATE i Postgres → returneres som "yyyy-MM-dd".
        // Swift Supabase SDK forventer ISO 8601 med tid → kaster feil.
        // Løsning: dekod som String og parse manuelt.
        if let raw = try c.decodeIfPresent(String.self, forKey: .purchaseDate) {
            purchaseDate = HumidorEntry.parseFlexDate(raw)
        } else {
            purchaseDate = nil
        }
    }

    /// Prøver ISO 8601 fullt format først, deretter dato-kun "yyyy-MM-dd".
    private static func parseFlexDate(_ s: String) -> Date? {
        // ISO 8601 med fraksjonssekunder (TIMESTAMPTZ)
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: s) { return d }
        // ISO 8601 uten fraksjonssekunder
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: s) { return d }
        // Postgres DATE-format
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(secondsFromGMT: 0)
        return fmt.date(from: s)
    }
}

// For å opprette ny humidor-oppføring
struct NewHumidorEntry: Encodable {
    let userId: UUID
    let cigarId: UUID
    let quantity: Int
    let purchaseDate: Date?
    let addedToHumidorAt: Date?
    let purchasePrice: Double?
    let storageNotes: String?

    enum CodingKeys: String, CodingKey {
        case userId             = "user_id"
        case cigarId            = "cigar_id"
        case quantity
        case purchaseDate       = "purchase_date"
        case addedToHumidorAt   = "added_to_humidor_at"
        case purchasePrice      = "purchase_price"
        case storageNotes       = "storage_notes"
    }
}

// MARK: - TastingLog
// Matcher "tasting_logs"-tabellen i Supabase
// Brukes til journal over røkte sigarer

struct TastingLog: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let cigarId: UUID
    let humidorEntryId: UUID?      // Koblet humidor-oppføring (for antall-sporing)
    let smokedAt: Date
    var rating: Int?               // 0–100 personlig score (Cigar Aficionado-skala)
    var smokeAgain: Bool?          // Ville røkt igjen? true=ja, false=nei, nil=kanskje/ikke satt
    var drawRating: Int?           // 1–5 sub-rating: trekk
    var burnRating: Int?           // 1–5 sub-rating: brenning
    var flavorRating: Int?         // 1–5 sub-rating: smak
    var personalNotes: String?     // Fritekst-kommentar
    let createdAt: Date?

    var cigar: Cigar?

    enum CodingKeys: String, CodingKey {
        case id
        case userId             = "user_id"
        case cigarId            = "cigar_id"
        case humidorEntryId     = "humidor_entry_id"
        case smokedAt           = "smoked_at"
        case rating
        case smokeAgain         = "smoke_again"
        case drawRating         = "draw_rating"
        case burnRating         = "burn_rating"
        case flavorRating       = "flavor_rating"
        case personalNotes      = "personal_notes"
        case createdAt          = "created_at"
        case cigar              = "cigars"
    }

    // Hjelpefunksjon: label for 0-100 score
    var scoreLabel: String? {
        guard let r = rating else { return nil }
        switch r {
        case 95...100: return "Exceptional"
        case 90...94:  return "Excellent"
        case 85...89:  return "Very good"
        case 80...84:  return "Good"
        case 70...79:  return "Average"
        default:       return "Not for me"
        }
    }
}

struct NewTastingLog: Encodable {
    let userId: UUID
    let cigarId: UUID
    let humidorEntryId: UUID?
    let smokedAt: Date
    let rating: Int?
    let smokeAgain: Bool?
    let drawRating: Int?
    let burnRating: Int?
    let flavorRating: Int?
    let personalNotes: String?

    enum CodingKeys: String, CodingKey {
        case userId             = "user_id"
        case cigarId            = "cigar_id"
        case humidorEntryId     = "humidor_entry_id"
        case smokedAt           = "smoked_at"
        case rating
        case smokeAgain         = "smoke_again"
        case drawRating         = "draw_rating"
        case burnRating         = "burn_rating"
        case flavorRating       = "flavor_rating"
        case personalNotes      = "personal_notes"
    }
}
