import Foundation

// MARK: - UserStats
// Returnert av get_user_stats() RPC — aggregert innsikt over journalen.

struct UserStats: Codable {
    let totalLogged: Int
    let brandsTried: Int
    let avgScore: Int?
    let strengthAvg: Double?
    let humidorValue: Double
    let topBrands: [TopBrand]
    let scoreSeries: [ScorePoint]

    enum CodingKeys: String, CodingKey {
        case totalLogged  = "total_logged"
        case brandsTried  = "brands_tried"
        case avgScore     = "avg_score"
        case strengthAvg  = "strength_avg"
        case humidorValue = "humidor_value"
        case topBrands    = "top_brands"
        case scoreSeries  = "score_series"
    }
}

struct TopBrand: Codable, Identifiable {
    let brand: String
    let n: Int
    var id: String { brand }
}

struct ScorePoint: Codable, Identifiable {
    let d: Date
    let s: Int
    var id: Date { d }
}

// MARK: - Profile
// Matcher "profiles"-tabellen i Supabase

struct Profile: Codable, Identifiable {
    let id: UUID
    let displayName: String?
    let friendCode: String?
    let avatarUrl: String?
    let city: String?
    let country: String?
    let createdAt: Date?
    let isFoundingMember: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case friendCode  = "friend_code"
        case avatarUrl   = "avatar_url"
        case city
        case country
        case createdAt   = "created_at"
        case isFoundingMember = "is_founding_member"
    }
}

// MARK: - FriendProfile
// Returnert av get_friend_profile RPC — inkluderer stats

struct FriendProfile: Codable, Identifiable {
    let id: UUID
    let displayName: String?
    let avatarUrl: String?
    let coverUrl: String?
    let city: String?
    let friendCode: String?
    let createdAt: Date?
    let bio: String?
    let cigarCount: Int
    let humidorCount: Int
    let friendCount: Int
    let avgScore: Int?           // Gjennomsnittlig rating (nil = ingen logger ennå)
    let favoritesCount: Int      // Antall røkt igjen = true
    let brandsTried: Int         // Unike merker røkt
    let country: String?
    let isFoundingMember: Bool?
    let humidorsCount: Int?      // Antall humidor-beholdere (til nivåberegning)
    let rhCount: Int?            // Antall RH-målinger (til nivåberegning)

    enum CodingKeys: String, CodingKey {
        case id
        case displayName    = "display_name"
        case avatarUrl      = "avatar_url"
        case coverUrl       = "cover_url"
        case city
        case country
        case friendCode     = "friend_code"
        case createdAt      = "created_at"
        case bio
        case cigarCount     = "cigar_count"
        case humidorCount   = "humidor_count"
        case friendCount    = "friend_count"
        case avgScore       = "avg_score"
        case favoritesCount = "favorites_count"
        case brandsTried    = "brands_tried"
        case isFoundingMember = "is_founding_member"
        case humidorsCount  = "humidors_count"
        case rhCount        = "rh_count"
    }
}

// MARK: - ProfileFavorites
// Returnert av get_own_profile_favorites() RPC — aggregert smaksprofil.
// Alle felt er valgfrie: NULL når det ikke finnes nok loggdata ennå.

struct ProfileFavorites: Codable {
    let favoriteCigarId:    UUID?
    let favoriteCigar:      String?
    let favoriteCigarScore: Int?
    let favoriteBrand:      String?
    let favoriteVitola:     String?
    let favoriteCountry:    String?
    let favoriteWrapper:    String?
    let favoriteBinder:     String?
    let favoriteFiller:     String?
    let favoriteFlavor:     String?
    let favoriteStrength:   Double?

    enum CodingKeys: String, CodingKey {
        case favoriteCigarId    = "favorite_cigar_id"
        case favoriteCigar      = "favorite_cigar"
        case favoriteCigarScore = "favorite_cigar_score"
        case favoriteBrand      = "favorite_brand"
        case favoriteVitola     = "favorite_vitola"
        case favoriteCountry    = "favorite_country"
        case favoriteWrapper    = "favorite_wrapper"
        case favoriteBinder     = "favorite_binder"
        case favoriteFiller     = "favorite_filler"
        case favoriteFlavor     = "favorite_flavor"
        case favoriteStrength   = "favorite_strength"
    }
}

// MARK: - HumidorEntry
// Matcher "humidor"-tabellen i Supabase

struct HumidorEntry: Identifiable, Encodable {
    let id: UUID
    let userId: UUID
    let cigarId: UUID
    var humidorId: UUID?
    var quantity: Int
    let purchaseDate: Date?
    let addedToHumidorAt: Date?
    let purchasePrice: Double?
    let storageNotes: String?
    let store: String?          // Hvor sigaren ble kjøpt (butikk)
    let createdAt: Date?
    var photoURL: String?
    var cigar: Cigar?

    enum CodingKeys: String, CodingKey {
        case id
        case userId             = "user_id"
        case cigarId            = "cigar_id"
        case humidorId          = "humidor_id"
        case quantity
        case purchaseDate       = "purchase_date"
        case addedToHumidorAt   = "added_to_humidor_at"
        case purchasePrice      = "purchase_price"
        case storageNotes       = "storage_notes"
        case store
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
        humidorId       = try c.decodeIfPresent(UUID.self, forKey: .humidorId)
        quantity        = try c.decode(Int.self,     forKey: .quantity)
        addedToHumidorAt = try c.decodeIfPresent(Date.self,   forKey: .addedToHumidorAt)
        purchasePrice   = try c.decodeIfPresent(Double.self,  forKey: .purchasePrice)
        storageNotes    = try c.decodeIfPresent(String.self,  forKey: .storageNotes)
        store           = try c.decodeIfPresent(String.self,  forKey: .store)
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
    var humidorId: UUID?
    let quantity: Int
    let purchaseDate: Date?
    let addedToHumidorAt: Date?
    let purchasePrice: Double?
    let storageNotes: String?
    let store: String?

    enum CodingKeys: String, CodingKey {
        case userId             = "user_id"
        case cigarId            = "cigar_id"
        case humidorId          = "humidor_id"
        case quantity
        case purchaseDate       = "purchase_date"
        case addedToHumidorAt   = "added_to_humidor_at"
        case purchasePrice      = "purchase_price"
        case storageNotes       = "storage_notes"
        case store
    }
}

// MARK: - CutType

enum CutType: String, Codable, CaseIterable, Identifiable {
    case straight = "straight_cut"
    case vCut     = "v_cut"
    case punch    = "punch_cut"
    case other    = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .straight: return "Straight Cut"
        case .vCut:     return "V-Cut"
        case .punch:    return "Punch Cut"
        case .other:    return "Other"
        }
    }

    var icon: String {
        switch self {
        case .straight: return "scissors"
        case .vCut:     return "v.square"
        case .punch:    return "circle.dashed"
        case .other:    return "ellipsis.circle"
        }
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
    var photoUrl: String?          // URL til bilde tatt under røykingen
    var cutType: CutType?          // Klippetypen brukt på sigaren
    var store: String?             // Hvor sigaren ble kjøpt (butikk)
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
        case photoUrl           = "photo_url"
        case cutType            = "cut_type"
        case store
        case createdAt          = "created_at"
        case cigar              = "cigars"
    }

    // Hjelpefunksjon: label for 0-100 score
    var scoreLabel: String? {
        guard let r = rating else { return nil }
        switch r {
        case 95...100: return "Eksepsjonell"
        case 90...94:  return "Fremragende"
        case 85...89:  return "Meget bra"
        case 80...84:  return "Bra"
        case 70...79:  return "Grei"
        default:       return "Ikke for meg"
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
    let photoUrl: String?
    let cutType: String?    // raw value fra CutType enum
    let store: String?      // Hvor sigaren ble kjøpt (butikk)

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
        case photoUrl           = "photo_url"
        case cutType            = "cut_type"
        case store
    }
}
