import Foundation
import Supabase

// MARK: - CigarService
// Håndterer alle database-kall mot "cigars"-tabellen

@MainActor
class CigarService: ObservableObject {

    // MARK: - Søk etter sigarer (tekst-matching fra OCR)
    func searchCigars(query: String) async throws -> [Cigar] {
        // Bruker search_cigars_ranked() i Supabase (se migrations/002_ranked_search.sql,
        // utvidet i 004_brand_hierarchy.sql) i stedet for å sortere på avg_rating —
        // den sorterer på faktisk tekst-relevans (ts_rank), så et godt OCR-treff
        // ikke kan bli overstyrt av en populær sigar som bare matcher løst på ett ord.
        //
        // "raw_text" sendes uendret (ikke tokenisert) slik at funksjonen også kan
        // matche kjente alias (f.eks. "MF The Judge", "FDLA", "Blue Label") mot
        // cigar_aliases-tabellen — disse er ofte forkortelser som ikke inneholder
        // alle ordene i det offisielle serienavnet, og ville ellers ikke gitt treff.
        // AND-basert søk: alle ord må finnes i samme rad, ikke bare ett.
        // Dette hindrer at et deskriptivt ord på båndet (f.eks. "Cameroon")
        // matcher et annet merkes serienavn (LFD Cameroon Cabinet) bare fordi
        // det ene ordet finnes der. Merkenavnet (f.eks. "Aurora") er ikke
        // i LFD-radene og eliminerer dem helt.
        // Hvis AND-søket gir null treff, faller appen gjennom til AI-fallback.
        let tsQuery = query.lowercased().split(separator: " ").joined(separator: " & ")

        let results: [Cigar] = try await supabase
            .rpc("search_cigars_ranked", params: [
                "search_query": tsQuery,
                "raw_text": query
            ])
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

    // MARK: - Hent ordliste for OCR-bias (Vision customWords)
    // Sigarbånd bruker ofte sterkt stilisert kursiv/skrift-font for
    // merke- og serienavn (f.eks. "Blue" på My Father-bånd). Apple Vision
    // er trent på trykt tekst og kan da rett og slett la ordet falle bort
    // fra resultatet i stedet for å gjette feil — det gir ikke nødvendigvis
    // lav konfidens vi kan fange opp, ordet er bare borte fra teksten.
    //
    // Løsningen er VNRecognizeTextRequest.customWords: en liste Vision
    // bruker til å "biase" gjetningene sine mot. Vi henter derfor ut alle
    // unike ord fra brand/series i databasen (vårt eget, kjente vokabular
    // av sigarmerker og serienavn) og bruker det som hint i ScanService.
    func fetchOcrVocabulary() async throws -> [String] {
        struct BrandSeriesRow: Decodable {
            let brand: String
            let series: String?
        }

        let rows: [BrandSeriesRow] = try await supabase
            .from("cigars")
            .select("brand, series")
            .execute()
            .value

        var words = Set<String>()
        for row in rows {
            for part in row.brand.split(separator: " ") {
                words.insert(String(part))
            }
            if let series = row.series {
                for part in series.split(separator: " ") {
                    words.insert(String(part))
                }
            }
        }

        return Array(words)
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

    // Legg til sigar i humidoren med kjøpsdato, humidordato og antall.
    // Returnerer den nye raden (inkl. id) slik at UI kan vise humidor-view umiddelbart.
    @discardableResult
    func addToHumidor(
        cigarId: UUID,
        userId: UUID,
        quantity: Int = 1,
        purchasedAt: Date? = nil,
        addedToHumidorAt: Date? = nil
    ) async throws -> HumidorEntry {
        let entry = NewHumidorEntry(
            userId: userId,
            cigarId: cigarId,
            quantity: quantity,
            purchaseDate: purchasedAt,
            addedToHumidorAt: addedToHumidorAt,
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

    // Logg en røykesession: lagrer til tasting_logs OG dekrementerer antall i humidoren.
    // Antall kan ikke gå under 0.
    func logSmokingSession(
        humidorEntry: HumidorEntry,
        userId: UUID,
        smokedAt: Date,
        rating: Int?,
        smokeAgain: Bool?,
        drawRating: Int?,
        burnRating: Int?,
        flavorRating: Int?,
        notes: String?
    ) async throws {
        guard let cigar = humidorEntry.cigar else { return }

        // 1. Lagre til tasting_logs
        let log = NewTastingLog(
            userId: userId,
            cigarId: cigar.id,
            humidorEntryId: humidorEntry.id,
            smokedAt: smokedAt,
            rating: rating,
            smokeAgain: smokeAgain,
            drawRating: drawRating,
            burnRating: burnRating,
            flavorRating: flavorRating,
            personalNotes: notes?.isEmpty == false ? notes : nil
        )
        try await supabase
            .from("tasting_logs")
            .insert(log)
            .execute()

        // 2. Dekrementer antall (minst 0)
        let newQuantity = max(0, humidorEntry.quantity - 1)
        try await supabase
            .from("humidor")
            .update(["quantity": newQuantity])
            .eq("id", value: humidorEntry.id.uuidString)
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
// Henter journal-data (røykelogg) for JournalView

@MainActor
class TastingService: ObservableObject {

    // Hent alle røykeoppføringer for en bruker, nyest først
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
}
