import Foundation
import Supabase

// MARK: - CigarService
// Håndterer alle database-kall mot "cigars"-tabellen

@MainActor
class CigarService: ObservableObject {

    // MARK: - Søk etter sigarer (tekst-matching fra OCR)
    func searchCigars(query: String) async throws -> [Cigar] {
        let results: [Cigar] = try await supabase
            .from("cigars")
            .select()
            .textSearch("search_vector", query: query.lowercased().split(separator: " ").joined(separator: " | "))
            .order("avg_rating", ascending: false)
            .limit(10)
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

    // Legg til sigar i humidoren
    func addToHumidor(cigarId: UUID, userId: UUID, quantity: Int = 1) async throws {
        let entry = NewHumidorEntry(
            userId: userId,
            cigarId: cigarId,
            quantity: quantity,
            purchaseDate: nil,
            purchasePrice: nil,
            storageNotes: nil
        )

        try await supabase
            .from("humidor")
            .insert(entry)
            .execute()
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
