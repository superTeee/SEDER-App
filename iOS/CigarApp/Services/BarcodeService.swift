import Foundation

// MARK: - RPC-responsmodell

struct BarcodeRPCRow: Codable {
    let barcodeId:      UUID
    let cigarId:        UUID
    let confirmedCount: Int
    let brand:          String
    let series:         String?
    let vitola:         String?
    let wrapperCountry: String?
    let strength:       Int?
    let avgRating:      Double?
    let flavorNotes:    [String]?

    enum CodingKeys: String, CodingKey {
        case barcodeId      = "barcode_id"
        case cigarId        = "cigar_id"
        case confirmedCount = "confirmed_count"
        case brand, series, vitola
        case wrapperCountry = "wrapper_country"
        case strength
        case avgRating      = "avg_rating"
        case flavorNotes    = "flavor_notes"
    }
}

// MARK: - UPCitemdb-responser (100 gratis kall/dag)

private struct UPCItemDBResponse: Codable {
    let total: Int
    let items: [UPCItemResult]
}

private struct UPCItemResult: Codable {
    let title: String
    let brand: String?
}

// MARK: - Resultattype

enum BarcodeLookupResult {
    /// Strekkode funnet direkte i vår DB — navigér til sigar uten bekreftelse
    case foundInDB(cigar: Cigar, confirmedCount: Int)
    /// Strekkode ikke i DB, men vi fant mulig sigar via UPCitemdb-tittel
    case foundViaSearch(cigar: Cigar, barcode: String, apiTitle: String)
    /// Ingen match noe sted — vis manuelt søk
    case notFound(barcode: String, apiTitle: String?)
}

// MARK: - BarcodeService

@MainActor
class BarcodeService: ObservableObject {

    @Published var isLoading   = false
    @Published var errorMessage: String?

    // MARK: - Oppslag

    /// Prøver DB → UPCitemdb → DB-søk på tittel, i den rekkefølgen.
    func lookupBarcode(_ barcode: String) async -> BarcodeLookupResult {
        isLoading = true
        defer { isLoading = false }

        // 1. Supabase DB (raskest, mest pålitelig)
        if let (cigar, count) = await lookupInSupabase(barcode) {
            return .foundInDB(cigar: cigar, confirmedCount: count)
        }

        // 2. UPCitemdb ekstern API
        let apiTitle = await lookupViaUPCItemDB(barcode)

        // 3. Søk i DB med tittel fra API
        if let title = apiTitle, !title.isEmpty {
            if let cigar = await searchCigarByTitle(title) {
                return .foundViaSearch(cigar: cigar, barcode: barcode, apiTitle: title)
            }
        }

        return .notFound(barcode: barcode, apiTitle: apiTitle)
    }

    // MARK: - Lagre strekkode-kobling

    /// Kaller save_barcode RPC — oppretter ny rad eller øker confirmed_count.
    func saveBarcode(_ barcode: String, cigarID: UUID, source: String = "user") async throws {
        // save_barcode returnerer UUID-en til raden
        let _: UUID = try await supabase
            .rpc("save_barcode", params: [
                "p_barcode":  barcode,
                "p_cigar_id": cigarID.uuidString.lowercased(),
                "p_source":   source
            ])
            .execute()
            .value
    }

    // MARK: - Private

    private func lookupInSupabase(_ barcode: String) async -> (Cigar, Int)? {
        do {
            let rows: [BarcodeRPCRow] = try await supabase
                .rpc("lookup_barcode", params: ["p_barcode": barcode])
                .execute()
                .value

            guard let row = rows.first else { return nil }

            let cigar: Cigar = try await supabase
                .from("cigars")
                .select()
                .eq("id", value: row.cigarId.uuidString.lowercased())
                .single()
                .execute()
                .value

            return (cigar, row.confirmedCount)
        } catch {
            return nil
        }
    }

    private func lookupViaUPCItemDB(_ barcode: String) async -> String? {
        guard let url = URL(string: "https://api.upcitemdb.com/prod/trial/lookup?upc=\(barcode)") else {
            return nil
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            // UPCitemdb returnerer 429 når gratis-grensen er nådd
            if let http = response as? HTTPURLResponse, http.statusCode != 200 { return nil }
            let parsed = try JSONDecoder().decode(UPCItemDBResponse.self, from: data)
            return parsed.items.first?.title
        } catch {
            return nil
        }
    }

    private func searchCigarByTitle(_ title: String) async -> Cigar? {
        do {
            let words = title.lowercased()
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { $0.count > 2 && !Self.stopWords.contains($0) }

            guard !words.isEmpty else { return nil }

            var tsWords = words
            tsWords[tsWords.count - 1] += ":*"
            let tsQuery = tsWords.joined(separator: " & ")

            let results: [Cigar] = try await supabase
                .rpc("search_cigars_ranked", params: [
                    "search_query": tsQuery,
                    "raw_text":     title
                ])
                .execute()
                .value

            return results.first
        } catch {
            return nil
        }
    }

    private static let stopWords: Set<String> = [
        "cigar", "cigars", "natural", "box", "pack", "bundle",
        "count", "the", "and", "with", "for", "single"
    ]
}
