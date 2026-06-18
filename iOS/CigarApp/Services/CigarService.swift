import Foundation
import Supabase

// MARK: - CigarService
// Håndterer alle database-kall mot "cigars"-tabellen

@MainActor
class CigarService: ObservableObject {

    // MARK: - Søk etter sigarer (tekst-matching fra OCR)
    func searchCigars(query: String) async throws -> [Cigar] {
        // Bruker search_cigars_ranked() i Supabase (se migrations/002_ranked_search.sql)
        // i stedet for å sortere på avg_rating — den sorterer på faktisk
        // tekst-relevans (ts_rank), så et godt OCR-treff ikke kan bli
        // overstyrt av en populær sigar som bare matcher løst på ett ord.
        let tsQuery = query.lowercased().split(separator: " ").joined(separator: " | ")

        let results: [Cigar] = try await supabase
            .rpc("search_cigars_ranked", params: ["search_query": tsQuery])
            .execute()
            .value

        return results
    }

    // MARK: - Hent sigarer basert på merke
    func fetchCigarsByBrand(_ brand: String) async throws -> [Cigar] {
        let results: [Cigar] = try await supabase
            .from("cigars")
            .select()
            .ilike("brand", pattern: "%\(brand)%")
            .order("series")
            .execute()
            .value

        return results
    }

    // MARK: - Hent én sigar basert på ID
    func fetchCigar(id: UUID) async throws -> Cigar {
        let result: Cigar = try await supabase
            .from("cigars")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        return result
    }

    // MARK: - Hent alle sigarer (for browsing)
    func fetchAllCigars(limit: Int = 50) async throws -> [Cigar] {
        let results: [Cigar] = try await supabase
            .from("cigars")
            .select()
            .order("brand")
            .limit(limit)
            .execute()
            .value

        return results
    }
}

// MARK: - HumidorService
// Håndterer brukerens personlige sigarsamling

@MainActor
class HumidorService: ObservableObject {

    // Hent alle sigarer i humidoren
    func fetchHumidor(userId: UUID) async throws -> [HumidorEntry] {
        let results: [HumidorEntry] = try await supabase
            .from("humidor")
            .select("*, cigars(*)")   // JOIN med cigars-tabellen
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return results
    }

    // Legg til sigar i humidoren — returnerer den nye raden (inkl. id)
    // slik at UI kan tilby "Fjern fra humidor" umiddelbart uten ny navigasjon.
    @discardableResult
    func addToHumidor(cigarId: UUID, userId: UUID, quantity: Int = 1) async throws -> HumidorEntry {
        let entry = NewHumidorEntry(
            userId: userId,
            cigarId: cigarId,
            quantity: quantity,
            purchaseDate: nil,
            purchasePrice: nil,
            storageNotes: nil
        )

        let inserted: HumidorEntry = try await supabase
            .from("humidor")
            .insert(entry)
            .select("*, cigars(*)")
            .single()
            .execute()
            .value

        return inserted
    }

    // Oppdater antall
    func updateQuantity(entryId: UUID, quantity: Int) async throws {
        try await supabase
            .from("humidor")
            .update(["quantity": quantity])
            .eq("id", value: entryId.uuidString)
            .execute()
    }

    // Fjern fra humidor
    func removeFromHumidor(entryId: UUID) async throws {
        try await supabase
            .from("humidor")
            .delete()
            .eq("id", value: entryId.uuidString)
            .execute()
    }

    // Oppdater stjerne-vurderinger (konstruksjon, trekk, aske, smak)
    func updateScores(
        entryId: UUID,
        construction: Int?,
        draw: Int?,
        burn: Int?,
        flavor: Int?
    ) async throws {
        let update = HumidorScoreUpdate(
            scoreConstruction: construction,
            scoreDraw: draw,
            scoreBurn: burn,
            scoreFlavor: flavor
        )

        try await supabase
            .from("humidor")
            .update(update)
            .eq("id", value: entryId.uuidString)
            .execute()
    }

    // Last opp bilde til Supabase Storage og lagre URL på humidor-oppføringen
    func uploadPhoto(entryId: UUID, userId: UUID, imageData: Data) async throws -> String {
        // VIKTIG: auth.uid()::text i Postgres er små bokstaver, mens Swift sin
        // UUID.uuidString er store bokstaver. RLS-policyen på "humidor-photos"
        // sjekker at første mappenivå i path == auth.uid()::text, så path MÅ
        // være lowercase her, ellers blir opplastingen avvist (RLS-feil).
        let path = "\(userId.uuidString.lowercased())/\(entryId.uuidString.lowercased()).jpg"

        try await supabase.storage
            .from("humidor-photos")
            .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg", upsert: true))

        let publicURL = try supabase.storage
            .from("humidor-photos")
            .getPublicURL(path: path)

        // Cache-buster: path er deterministisk per entryId, så uten denne
        // serverer AsyncImage/URLCache det gamle bildet etter "Bytt bilde"
        // siden URL-strengen ellers er identisk.
        var finalURLString = publicURL.absoluteString
        if var components = URLComponents(url: publicURL, resolvingAgainstBaseURL: false) {
            components.queryItems = [URLQueryItem(name: "v", value: "\(Int(Date().timeIntervalSince1970))")]
            if let url = components.url {
                finalURLString = url.absoluteString
            }
        }

        try await updatePhotoURL(entryId: entryId, url: finalURLString)
        return finalURLString
    }

    // Oppdater bilde-URL på en humidor-oppføring
    func updatePhotoURL(entryId: UUID, url: String) async throws {
        try await supabase
            .from("humidor")
            .update(["photo_url": url])
            .eq("id", value: entryId.uuidString)
            .execute()
    }
}

// MARK: - TastingService
// Håndterer røykenotater og smaksvurderinger

@MainActor
class TastingService: ObservableObject {

    // Hent alle smaksnotater for en bruker
    func fetchLogs(userId: UUID) async throws -> [TastingLog] {
        let results: [TastingLog] = try await supabase
            .from("tasting_logs")
            .select("*, cigars(*)")
            .eq("user_id", value: userId.uuidString)
            .order("smoked_at", ascending: false)
            .execute()
            .value

        return results
    }

    // Lagre ny smaksvurdering
    func saveLog(_ log: NewTastingLog) async throws {
        try await supabase
            .from("tasting_logs")
            .insert(log)
            .execute()
    }
}
