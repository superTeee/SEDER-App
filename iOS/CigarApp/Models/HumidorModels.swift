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

    // Mål-RH (relativ luftfuktighet) og valgfritt akseptabelt område.
    var targetRh: Int?
    var rhMin: Int?
    var rhMax: Int?

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
        case targetRh  = "target_rh"
        case rhMin     = "rh_min"
        case rhMax     = "rh_max"
    }

    var typeEnum: HumidorType? { type.flatMap { HumidorType(rawValue: $0) } }

    /// «69 %» eller «67–71 %» — mål-RH for visning, eller nil hvis ikke satt.
    var rhTargetLabel: String? {
        if let lo = rhMin, let hi = rhMax { return "\(lo)–\(hi) %" }
        if let t = targetRh { return "\(t) %" }
        return nil
    }

    /// Rolig status basert på siste MÅLTE RH mot mål/område. Aldri dramatisk.
    func rhStatus(for rh: Double?) -> RHStatus {
        guard let rh else { return .none }
        if let lo = rhMin, let hi = rhMax {
            switch rh {
            case ..<(Double(lo) - 3): return .tooDry
            case ..<Double(lo):       return .slightlyLow
            case ...Double(hi):       return .stable
            case ...(Double(hi) + 3): return .slightlyHigh
            default:                  return .tooWet
            }
        } else if let t = targetRh {
            switch rh - Double(t) {
            case ..<(-4): return .tooDry
            case ..<(-1): return .slightlyLow
            case ...1:    return .stable
            case ...4:    return .slightlyHigh
            default:      return .tooWet
            }
        }
        return .stable   // måling finnes, men ingen mål å sammenligne mot
    }
}

// MARK: - RHStatus
// Rolig, forståelig status — vises som etikett, ikke som alarm.

enum RHStatus {
    case none, tooDry, slightlyLow, stable, slightlyHigh, tooWet

    var label: String {
        switch self {
        case .none:         return "Ingen målinger"
        case .tooDry:       return "For tørr"
        case .slightlyLow:  return "Litt under målet"
        case .stable:       return "Stabil"
        case .slightlyHigh: return "Litt over målet"
        case .tooWet:       return "For fuktig"
        }
    }
}

// MARK: - HumidorRHReading (én registrert måling)
// Matcher "humidor_rh_readings"-tabellen. Bygget for senere grafer/påminnelser.

struct HumidorRHReading: Identifiable, Codable {
    let id: UUID
    let humidorId: UUID
    let rh: Double
    let temperature: Double?
    let note: String?
    let measuredAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case humidorId  = "humidor_id"
        case rh
        case temperature
        case note
        case measuredAt = "measured_at"
    }

    /// «Ikke målt nylig» når siste måling er eldre enn 7 dager.
    var isStale: Bool { measuredAt < Calendar.current.date(byAdding: .day, value: -7, to: Date())! }
}

// MARK: - NewRHReading (insert-payload) — user_id settes av DB via auth.uid()

struct NewRHReading: Encodable {
    let humidorId: UUID
    let rh: Double
    let temperature: Double?
    let note: String?
    let measuredAt: Date

    enum CodingKeys: String, CodingKey {
        case humidorId  = "humidor_id"
        case rh
        case temperature
        case note
        case measuredAt = "measured_at"
    }
}

// MARK: - NewHumidor (insert-payload)

struct NewHumidor: Encodable {
    let userId: UUID
    let name: String
    let type: String?
    let location: String?
    let capacity: Int?
    var targetRh: Int? = nil
    var rhMin: Int? = nil
    var rhMax: Int? = nil

    enum CodingKeys: String, CodingKey {
        case userId   = "user_id"
        case name
        case type
        case location
        case capacity
        case targetRh = "target_rh"
        case rhMin    = "rh_min"
        case rhMax    = "rh_max"
    }
}
