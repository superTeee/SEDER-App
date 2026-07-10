import Foundation

// MARK: - SupabaseDecoder
//
// Postgres skriver tidsstempler i tre former, avhengig av hvor de kommer fra:
//
//     2026-07-10T08:14:32.123456+00:00   ← timestamptz med mikrosekunder
//     2026-07-10T08:14:32+00:00          ← timestamptz uten
//     2026-07-10T08:14:32                ← timestamp uten sone
//
// En vanlig JSONDecoder klarer bare den den er stilt inn på. Derfor prøver vi
// alle tre, i tur og orden, og feiler med en lesbar melding hvis ingen passer.
//
// Denne dekoderen bodde i FeedService. Da AdminService trengte det samme, ble
// det ett sted i stedet for to.

enum SupabaseDecoder {

    static let shared: JSONDecoder = {
        let decoder = JSONDecoder()

        let formatters: [DateFormatter] = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss"
        ].map { format in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            return formatter
        }

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            for formatter in formatters {
                if let date = formatter.date(from: raw) { return date }
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Ugyldig dato: \(raw)"
            )
        }

        return decoder
    }()
}
