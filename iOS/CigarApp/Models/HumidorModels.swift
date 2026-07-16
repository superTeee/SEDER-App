import Foundation

// MARK: - HumidorType
// Typene humidor brukeren kan velge i opprett-sheeten.

enum HumidorType: String, CaseIterable, Codable, Identifiable {
    case desktop   = "Desktop"
    case travel    = "Travel"
    case cabinet   = "Cabinet"
    case electric  = "Electric"
    case tupperdor = "Tupperdor"
    case coolidor  = "Coolidor"
    case walkin    = "Walk-in"

    var id: String { rawValue }
    var displayName: String { rawValue }

    /// Kort forklaring — så en nybegynner forstår forskjellen på typene.
    var explanation: String {
        switch self {
        case .desktop:   return "Klassisk humidor for hjemmebruk og mindre samlinger."
        case .travel:    return "Robust humidor for reise og kortvarig transport."
        case .cabinet:   return "Større humidor for mange sigarer og mer organisert lagring."
        case .electric:  return "Elektrisk humidor med bedre kontroll på temperatur og/eller fuktighet."
        case .tupperdor: return "Lufttett plastboks med enkel og effektiv fuktkontroll."
        case .coolidor:  return "Kjøleboks brukt som rimelig og stabil lagringsløsning."
        case .walkin:    return "Et helt rom eller avlukke med kontrollert klima."
        }
    }

    /// SF Symbol som representerer typen.
    var icon: String {
        switch self {
        case .desktop:   return "archivebox"
        case .travel:    return "suitcase"
        case .cabinet:   return "cabinet"
        case .electric:  return "bolt"
        case .tupperdor: return "shippingbox"
        case .coolidor:  return "snowflake"
        case .walkin:    return "door.left.hand.open"
        }
    }
}

// MARK: - Humidor
// Matcher "humidors"-tabellen i Supabase (container for sigarer).

struct Humidor: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var name: String
    var type: String?
    var location: String?
    var capacity: Int?
    var imageURL: String?
    let createdAt: Date?

    /// Fylles separat (ikke fra tabellen) — antall sigarer i denne humidoren.
    var cigarCount: Int = 0

    enum CodingKeys: String, CodingKey {
        case id
        case userId    = "user_id"
        case name
        case type
        case location
        case capacity
        case imageURL  = "image_url"
        case createdAt = "created_at"
    }

    var typeEnum: HumidorType? { type.flatMap { HumidorType(rawValue: $0) } }
}

// MARK: - NewHumidor (insert-payload)

struct NewHumidor: Encodable {
    let userId: UUID
    let name: String
    let type: String?
    let location: String?
    let capacity: Int?

    enum CodingKeys: String, CodingKey {
        case userId   = "user_id"
        case name
        case type
        case location
        case capacity
    }
}
