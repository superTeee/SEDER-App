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

    /// Koblet HumSense-sensor (nil = manuell humidor). Er den satt, henter appen
    /// live RH/temp fra `humidor-sensor`-edge-funksjonen.
    var sensorId: String?

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
        case sensorId  = "sensor_id"
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

// MARK: - SensorReading
// Én avlesning fra HumSense-sensoren: relativ fuktighet (%), evt. temperatur (°C)
// og tidspunkt. (Ligger her, ikke i egen fil, så den er garantert med i target.)
struct SensorReading: Equatable {
    let rh: Double
    let temperature: Double?
    let pressure: Double?     // lufttrykk i hPa, hvis sensoren rapporterer det
    let time: Date?
}

// MARK: - HumidorSensorService
// Henter live-data via edge-funksjonen `humidor-sensor` (proxy som holder
// HumSense-nøkkelen server-side). Går via URLSession med anon-nøkkelen som JWT,
// så vi kan sende GET med query uansett Supabase-SDK-versjon. Robust tolkning av
// feltnavn (rh/humidity, temp/temperature, timestamp/time …).
final class HumidorSensorService {

    private let base = SupabaseConfig.projectURL.appendingPathComponent("functions/v1/humidor-sensor")

    /// Siste måling. Siste verdi ER jo bare det nyeste punktet i historikken, så
    /// vi bruker ALLTID nyeste historikk-punkt — aldri det separate «latest»-
    /// endepunktet, som viser seg å henge igjen på en frossen gammel verdi.
    /// Prøver kort historikk først (billigst), så en full dag hvis sensoren har
    /// vært stille en stund. Det gamle latest-endepunktet er kun aller siste
    /// utvei, og bare hvis det ikke finnes historikk i det hele tatt.
    func latest(sensorId: String) async -> SensorReading? {
        if let newest = await history(sensorId: sensorId, hours: 1).last { return newest }
        if let newest = await history(sensorId: sensorId, hours: 24).last { return newest }
        guard let obj = await fetchJSON(sensorId: sensorId, mode: "latest", hours: nil) else { return nil }
        return reading(from: unwrapObject(obj))
    }

    /// Historikk (standard 24 t), sortert eldst → nyest.
    func history(sensorId: String, hours: Int = 24) async -> [SensorReading] {
        guard let obj = await fetchJSON(sensorId: sensorId, mode: "history", hours: hours) else { return [] }
        return unwrapArray(obj)
            .compactMap { reading(from: $0) }
            .sorted { ($0.time ?? .distantPast) < ($1.time ?? .distantPast) }
    }

    // MARK: Nettverk
    private func fetchJSON(sensorId: String, mode: String, hours: Int?) async -> Any? {
        var comps = URLComponents(url: base, resolvingAgainstBaseURL: false)
        var items = [URLQueryItem(name: "sensor_ID", value: sensorId),
                     URLQueryItem(name: "mode", value: mode)]
        if let hours { items.append(URLQueryItem(name: "hours", value: String(hours))) }
        comps?.queryItems = items
        guard let url = comps?.url else { return nil }

        var req = URLRequest(url: url)
        req.timeoutInterval = 12
        req.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) ?? true else { return nil }
            return try? JSONSerialization.jsonObject(with: data)
        } catch {
            print("⚠️ humidor-sensor feilet: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: Robust tolkning
    private func unwrapObject(_ obj: Any) -> [String: Any] {
        if let arr = obj as? [[String: Any]], let last = arr.last { return last }
        guard let dict = obj as? [String: Any] else { return [:] }
        for key in ["data", "measurement", "latest", "reading", "result", "current"] {
            if let inner = dict[key] as? [String: Any] { return inner }
            if let arr = dict[key] as? [[String: Any]], let last = arr.last { return last }
        }
        return dict
    }

    private func unwrapArray(_ obj: Any) -> [[String: Any]] {
        if let arr = obj as? [[String: Any]] { return arr }
        if let dict = obj as? [String: Any] {
            for key in ["data", "measurements", "history", "readings", "results", "items", "values"] {
                if let arr = dict[key] as? [[String: Any]] { return arr }
            }
        }
        return []
    }

    private func number(_ dict: [String: Any], _ keys: Set<String>) -> Double? {
        for (k, v) in dict where keys.contains(k.lowercased()) {
            if let d = v as? Double { return d }
            if let i = v as? Int { return Double(i) }
            if let s = v as? String, let d = Double(s.replacingOccurrences(of: ",", with: ".")) { return d }
        }
        return nil
    }

    private func reading(from dict: [String: Any]) -> SensorReading? {
        guard let rh = number(dict, ["rh", "humidity", "humidity_percent", "humiditypercent", "relative_humidity", "relativehumidity", "hum", "rel_humidity", "moisture"]) else { return nil }
        let temp = number(dict, ["temp", "temperature", "temperature_c", "temp_c", "tempc", "celsius", "t"])
        let pressure = number(dict, ["pressure_hpa", "pressurehpa", "pressure", "hpa", "baro", "barometric_pressure", "baro_pressure"])
        return SensorReading(rh: rh, temperature: temp, pressure: pressure, time: parseTime(dict))
    }

    private func parseTime(_ dict: [String: Any]) -> Date? {
        let keys: Set<String> = ["timestamp_ms", "timestampms", "timestamp", "time", "ts", "created_at", "createdat", "measured_at", "measuredat", "date", "datetime", "recorded_at", "recordedat"]
        for (k, v) in dict where keys.contains(k.lowercased()) {
            if let s = v as? String {
                let f1 = ISO8601DateFormatter()
                if let d = f1.date(from: s) { return d }
                let f2 = ISO8601DateFormatter(); f2.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let d = f2.date(from: s) { return d }
            }
            if let n = (v as? Double) ?? (v as? Int).map(Double.init) {
                return Date(timeIntervalSince1970: n > 1_000_000_000_000 ? n / 1000 : n)
            }
        }
        return nil
    }
}
