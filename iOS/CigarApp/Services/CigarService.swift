import Foundation
import Supabase

// MARK: - CigarService
// Håndterer alle database-kall mot "cigars"-tabellen

@MainActor
class CigarService: ObservableObject {

    // MARK: - Meld feil på sigardata

    private struct ReportCigarParams: Encodable {
        let p_cigar_id: String
        let p_field: String
        let p_comment: String?
    }

    /// Sender inn en rettelse. Bruker-ID sendes IKKE fra klienten — `report_cigar`
    /// leser `auth.uid()` selv.
    func reportCigar(cigarId: UUID, field: String, comment: String) async throws {
        let trimmed = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        try await supabase
            .rpc("report_cigar", params: ReportCigarParams(
                p_cigar_id: cigarId.uuidString,
                p_field:    field,
                p_comment:  trimmed.isEmpty ? nil : trimmed
            ))
            .execute()
    }

    // MARK: - Legg til egen sigar

    private struct CreateOwnCigarParams: Encodable {
        let p_brand: String
        let p_series: String?
        let p_vitola: String?
        let p_country: String?
        let p_wrapper: String?
        let p_ring_gauge: Int?
        let p_length_inches: Double?
        let p_note: String?
        let p_suggest: Bool
    }

    /// Oppretter en privat sigar for den innloggede brukeren, og sender den
    /// eventuelt til review-køen. Raden er usynlig for alle andre til den er
    /// godkjent — ingen skriver rett inn i det delte oppslagsverket.
    func createOwnCigar(
        brand: String,
        series: String,
        vitola: String,
        country: String,
        wrapper: String,
        ringGauge: Int?,
        lengthInches: Double?,
        note: String,
        suggest: Bool
    ) async throws -> Cigar {
        func clean(_ s: String) -> String? {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }

        let newId: UUID = try await supabase
            .rpc("create_own_cigar", params: CreateOwnCigarParams(
                p_brand:         brand.trimmingCharacters(in: .whitespacesAndNewlines),
                p_series:        clean(series),
                p_vitola:        clean(vitola),
                p_country:       clean(country),
                p_wrapper:       clean(wrapper),
                p_ring_gauge:    ringGauge,
                p_length_inches: lengthInches,
                p_note:          clean(note),
                p_suggest:       suggest
            ))
            .execute()
            .value

        return try await fetchCigar(id: newId)
    }

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
        // Prefiks-matching (:*) på siste ord gjør at "Ashton Clas" treffer "Ashton Classic"
        // mens brukeren fortsatt skriver — tidligere ord krever eksakt token-match.
        var words = query.lowercased().split(separator: " ").map(String.init)
        if let last = words.last {
            words[words.count - 1] = "\(last):*"
        }
        let tsQuery = words.joined(separator: " & ")

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

    // MARK: - Dagens utvalgte (sigarer med rating)
    // Returnerer sigarer med avg_rating >= 1, stabilt sortert etter id,
    // slik at daglig deterministisk valg (dayOfYear % count) gir samme sigar hele dagen.
    // Returnerer et STORT, stabilt basseng for «Dagens utvalgte»: høyest ratede
    // først, deretter resten (uratede sist). Tidligere returnerte denne KUN de
    // ratede sigarene når det fantes minst én — og siden nesten ingen er ratet
    // ennå kollapset bassenget til én sigar, så «Dagens utvalgte» satt fast på
    // samme sigar dag etter dag. Nå er det alltid hundrevis å rotere blant.
    func fetchAboveAverageCigars() async throws -> [Cigar] {
        let results: [Cigar] = try await supabase
            .from("cigars")
            .select()
            .order("avg_rating", ascending: false, nullsFirst: false)
            .order("id")
            .limit(500)
            .execute()
            .value
        return results
    }

    // MARK: - Dagens utvalgte (smakstilpasset)
    // Velger en sigar som ligner brukerens smak (utledet fra journalen), men
    // som brukeren IKKE allerede har logget. Smaksvektoren vektes av brukerens
    // egen score, så høyt ratede sigarer former smaken mest. Blant topp-treffene
    // velges én deterministisk per dag (stabil hele dagen, roterer over tid).
    // Returnerer nil hvis vi mangler nok data — da faller kalleren tilbake til
    // den gamle rating-baserte logikken (ny bruker med tom journal).
    func fetchTasteFeaturedCigar() async throws -> Cigar? {
        // 1. Hent brukerens logger med full sigar-data
        let userId = try await supabase.auth.session.user.id
        let logs: [TastingLog] = try await supabase
            .from("tasting_logs")
            .select("*, cigars(*)")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        // Trenger minst én logget sigar med data for å bygge en smaksprofil
        guard logs.contains(where: { $0.cigar != nil }) else { return nil }
        let loggedIds = Set(logs.map { $0.cigarId })

        // 2. Bygg smaks-vektor, vektet av brukerens egen score (0–100)
        var strengthSum = 0.0, strengthW = 0.0
        var bodySum     = 0.0, bodyW     = 0.0
        var sweetSum    = 0.0, sweetW    = 0.0
        var flavorSum   = 0.0, flavorW   = 0.0
        var countryCounts: [String: Double] = [:]
        var leafCounts:    [String: Double] = [:]
        var noteCounts:    [String: Double] = [:]

        for log in logs {
            guard let c = log.cigar else { continue }
            // Ulogget score → nøytral 60 så sigaren fortsatt teller litt
            let weight = Double(max(1, log.rating ?? 60))
            if let s  = c.strength        { strengthSum += s  * weight; strengthW += weight }
            if let b  = c.body            { bodySum     += b  * weight; bodyW     += weight }
            if let sw = c.sweetness       { sweetSum    += sw * weight; sweetW    += weight }
            if let f  = c.flavorIntensity { flavorSum   += f  * weight; flavorW   += weight }
            if let co = c.wrapperCountry  { countryCounts[co, default: 0] += weight }
            if let wl = c.wrapperLeaf     { leafCounts[wl, default: 0]    += weight }
            for note in c.flavorNotes ?? [] { noteCounts[note, default: 0] += weight }
        }

        let tStrength = strengthW > 0 ? strengthSum / strengthW : nil
        let tBody     = bodyW     > 0 ? bodySum     / bodyW     : nil
        let tSweet    = sweetW    > 0 ? sweetSum    / sweetW    : nil
        let tFlavor   = flavorW   > 0 ? flavorSum   / flavorW   : nil
        let topCountry = countryCounts.max { $0.value < $1.value }?.key
        let topLeaf    = leafCounts.max    { $0.value < $1.value }?.key
        let topNotes   = Set(noteCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key })

        // 3. Kandidater: rated sigarer, helst de brukeren IKKE har logget (oppdagelse).
        //    MEN: for en storbruker som har logget nesten alt kan dette kollapse til
        //    én enkelt sigar — da roterer ikke «Dagens utvalgte» (satt fast på samme
        //    sigar dag etter dag). Har vi for få ulog­gede kandidater, tar vi med hele
        //    utvalget (også loggede) slik at det alltid finnes nok å rotere blant.
        let above = try await fetchAboveAverageCigars()
        let unlogged = above.filter { !loggedIds.contains($0.id) }
        let candidates = unlogged.count >= 12 ? unlogged : above
        guard !candidates.isEmpty else { return nil }

        // 4. Scoring: numerisk nærhet på styrke/fylde/sødme/smaksintensitet,
        //    pluss bonus for samme wrapper-land, wrapper-blad og delte smaksnoter
        func score(_ c: Cigar) -> Double {
            var parts: [Double] = []
            if let t = tStrength, let v = c.strength        { parts.append(1 - abs(v - t) / 4.5) }
            if let t = tBody,     let v = c.body            { parts.append(1 - abs(v - t) / 5.0) }
            if let t = tSweet,    let v = c.sweetness       { parts.append(1 - abs(v - t) / 5.0) }
            if let t = tFlavor,   let v = c.flavorIntensity { parts.append(1 - abs(v - t) / 5.0) }
            var s = parts.isEmpty ? 0.5 : parts.reduce(0, +) / Double(parts.count)
            if let co = c.wrapperCountry, co == topCountry { s += 0.15 }
            if let wl = c.wrapperLeaf,    wl == topLeaf    { s += 0.10 }
            let shared = Set(c.flavorNotes ?? []).intersection(topNotes).count
            s += 0.05 * Double(min(shared, 3))
            return s
        }

        // 5. Deterministisk daglig valg blant topp-treffene
        let ranked = candidates
            .map { (cigar: $0, s: score($0)) }
            .sorted {
                $0.s != $1.s ? $0.s > $1.s
                             : ($0.cigar.avgRating ?? 0) > ($1.cigar.avgRating ?? 0)
            }
        let topK = min(20, ranked.count)
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % topK
        return ranked[index].cigar
    }

    // MARK: - Merkeliste med antall (for Explore-siden)
    //
    // Vi henter uansett én rad per sigar for å finne de unike merkene, så
    // antall sigarer og antall serier koster ingenting ekstra å telle opp.
    func fetchBrandSummaries() async throws -> [BrandSummary] {
        struct BrandRow: Decodable {
            let brand: String
            let series: String?
        }

        // PostgREST returnerer maks 1000 rader per kall. Med >1000 sigarer ble
        // merkelista kuttet (stoppet ~«H»). Paginer med .range() til alt er hentet.
        var order: [String] = []
        var cigarCounts: [String: Int] = [:]
        var seriesByBrand: [String: Set<String>] = [:]
        let pageSize = 1000
        var from = 0

        while true {
            let rows: [BrandRow] = try await supabase
                .from("cigars")
                .select("brand,series")
                .order("brand")
                .range(from: from, to: from + pageSize - 1)
                .execute()
                .value

            for row in rows {
                if cigarCounts[row.brand] == nil { order.append(row.brand) }
                cigarCounts[row.brand, default: 0] += 1
                if let series = row.series, !series.isEmpty {
                    seriesByBrand[row.brand, default: []].insert(series)
                }
            }

            if rows.count < pageSize { break } // siste side
            from += pageSize
        }

        return order.map { brand in
            BrandSummary(brand: brand,
                         cigarCount:  cigarCounts[brand] ?? 0,
                         seriesCount: seriesByBrand[brand]?.count ?? 0)
        }
    }

    // MARK: - Distinkte smaksnoter (for avansert-søk-filter)
    // Henter alle flavor_notes-arrays og returnerer et sett med de faktiske
    // rå-notatene som finnes på sigarer i databasen.
    func fetchDistinctFlavorNotes() async throws -> [String] {
        struct NoteRow: Decodable { let flavorNotes: [String]?
            enum CodingKeys: String, CodingKey { case flavorNotes = "flavor_notes" }
        }

        var seen = Set<String>()
        var notes: [String] = []
        let pageSize = 1000
        var from = 0

        while true {
            let rows: [NoteRow] = try await supabase
                .from("cigars")
                .select("flavor_notes")
                .range(from: from, to: from + pageSize - 1)
                .execute()
                .value

            for row in rows {
                for note in row.flavorNotes ?? [] {
                    let trimmed = note.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty, seen.insert(trimmed.lowercased()).inserted {
                        notes.append(trimmed)
                    }
                }
            }

            if rows.count < pageSize { break }
            from += pageSize
        }

        return notes
    }

    // MARK: - Avansert filtrert søk
    // Merk: filter-kall (.ilike/.eq) MÅ komme FØR .order()
    // fordi .order() returnerer PostgrestTransformBuilder som ikke har filter-metoder.
    // Norsk UI-label → faktiske DB-verdier (lowercase) i flavor_notes
    private static let norToEngNotes: [String: [String]] = [
        "Kremete":   ["cream", "creamy"],
        "Nøtter":    ["toasted nuts", "nuts", "nutty"],
        "Kaffe":     ["coffee", "espresso"],
        "Søt":       ["mild sweetness", "subtle sweetness", "sweetness", "sweet"],
        "Pepper":    ["black pepper", "pepper", "light pepper", "white pepper"],
        "Tre":       ["cedar", "woody", "wood"],
        "Jord":      ["earth", "earthy"],
        "Lær":       ["leather"],
        "Krydder":   ["spice", "mild spice", "light spice", "spicy"],
        "Blomst":    ["floral", "flower", "hay"],
        "Sitrus":    ["citrus"],
        "Sjokolade": ["dark chocolate", "cocoa", "chocolate", "dark cocoa"]
    ]

    /// Legger på alle aktive filtre. Delt av `fetchCigarsFiltered` og
    /// `countCigarsFiltered`, slik at listen og tellingen aldri kan komme i utakt.
    private func applyFilters(
        to query: PostgrestFilterBuilder,
        wrapperCountry: [String],
        binder: [String],
        filler: [String],
        commonFormat: [String],
        countryOrigin: [String],
        strengthRange: ClosedRange<Double>?,
        bodyRange: ClosedRange<Double>?,
        sweetnessRange: ClosedRange<Double>?,
        flavorIntensityRange: ClosedRange<Double>?,
        smokingNotes: [String],
        flavorNoteGroups: [[String]],
        crossSection: [String]
    ) -> PostgrestFilterBuilder {
        var builder = query

        if !wrapperCountry.isEmpty {
            let f = wrapperCountry.map { "wrapper_leaf.ilike.%\($0)%" }.joined(separator: ",")
            builder = builder.or(f)
        }
        if !binder.isEmpty {
            let f = binder.map { "binder.ilike.%\($0)%" }.joined(separator: ",")
            builder = builder.or(f)
        }
        if !filler.isEmpty {
            builder = builder.overlaps("filler", value: filler)
        }
        if !commonFormat.isEmpty {
            let f = commonFormat.map { "common_format.ilike.%\($0)%" }.joined(separator: ",")
            builder = builder.or(f)
        }
        if !countryOrigin.isEmpty {
            let f = countryOrigin.map { "country_origin.ilike.%\($0)%" }.joined(separator: ",")
            builder = builder.or(f)
        }
        if let r = strengthRange {
            builder = builder.gte("strength", value: r.lowerBound).lte("strength", value: r.upperBound)
        }
        if let r = bodyRange {
            builder = builder.gte("body", value: r.lowerBound).lte("body", value: r.upperBound)
        }
        if let r = sweetnessRange {
            builder = builder.gte("sweetness", value: r.lowerBound).lte("sweetness", value: r.upperBound)
        }
        if let r = flavorIntensityRange {
            builder = builder.gte("flavor_intensity", value: r.lowerBound).lte("flavor_intensity", value: r.upperBound)
        }
        if !flavorNoteGroups.isEmpty {
            // Dynamiske grupper (utledet fra faktiske DB-notater). Én overlaps
            // per gruppe → AND mellom valgte smaksnoter, OR innad i hver gruppe.
            for group in flavorNoteGroups where !group.isEmpty {
                builder = builder.overlaps("flavor_notes", value: group)
            }
        } else if !smokingNotes.isEmpty {
            // Fallback: statisk norsk→engelsk-mapping.
            for note in smokingNotes {
                let engValues = Self.norToEngNotes[note] ?? [note]
                builder = builder.overlaps("flavor_notes", value: engValues)
            }
        }
        if !crossSection.isEmpty {
            let f = crossSection.map { "cross_section.eq.\($0)" }.joined(separator: ",")
            builder = builder.or(f)
        }

        return builder
    }

    /// Sigarer som matcher filtrene. Merk taket på 1000 — PostgREST returnerer
    /// uansett ikke mer per kall.
    func fetchCigarsFiltered(
        wrapperCountry: [String] = [],
        binder: [String] = [],
        filler: [String] = [],
        commonFormat: [String] = [],
        countryOrigin: [String] = [],
        strengthRange: ClosedRange<Double>? = nil,
        bodyRange: ClosedRange<Double>? = nil,
        sweetnessRange: ClosedRange<Double>? = nil,
        flavorIntensityRange: ClosedRange<Double>? = nil,
        smokingNotes: [String] = [],
        flavorNoteGroups: [[String]] = [],
        crossSection: [String] = []
    ) async throws -> [Cigar] {
        let builder = applyFilters(
            to: supabase.from("cigars").select(),
            wrapperCountry: wrapperCountry, binder: binder, filler: filler,
            commonFormat: commonFormat, countryOrigin: countryOrigin,
            strengthRange: strengthRange, bodyRange: bodyRange,
            sweetnessRange: sweetnessRange, flavorIntensityRange: flavorIntensityRange,
            smokingNotes: smokingNotes, flavorNoteGroups: flavorNoteGroups,
            crossSection: crossSection)

        let results: [Cigar] = try await builder
            .order("brand")
            .order("series")
            .limit(1000)
            .execute()
            .value

        return results
    }

    /// Hvor mange sigarer filtrene faktisk treffer.
    ///
    /// Tidligere ble dette regnet ut som `fetchCigarsFiltered().count` — men den
    /// spørringen hadde `.limit(200)`, så knappen sa «Vis 200 resultater» både
    /// ved 1650 og 397 treff. Her spør vi databasen om antallet direkte
    /// (`head: true, count: .exact`), uten å laste en eneste rad.
    func countCigarsFiltered(
        wrapperCountry: [String] = [],
        binder: [String] = [],
        filler: [String] = [],
        commonFormat: [String] = [],
        countryOrigin: [String] = [],
        strengthRange: ClosedRange<Double>? = nil,
        bodyRange: ClosedRange<Double>? = nil,
        sweetnessRange: ClosedRange<Double>? = nil,
        flavorIntensityRange: ClosedRange<Double>? = nil,
        smokingNotes: [String] = [],
        flavorNoteGroups: [[String]] = [],
        crossSection: [String] = []
    ) async throws -> Int {
        let builder = applyFilters(
            to: supabase.from("cigars").select("id", head: true, count: .exact),
            wrapperCountry: wrapperCountry, binder: binder, filler: filler,
            commonFormat: commonFormat, countryOrigin: countryOrigin,
            strengthRange: strengthRange, bodyRange: bodyRange,
            sweetnessRange: sweetnessRange, flavorIntensityRange: flavorIntensityRange,
            smokingNotes: smokingNotes, flavorNoteGroups: flavorNoteGroups,
            crossSection: crossSection)

        return try await builder.execute().count ?? 0
    }

    // MARK: - Hent sigarer basert på vitola/format
    func fetchCigarsByVitola(_ format: String) async throws -> [Cigar] {
        let results: [Cigar] = try await supabase
            .from("cigars")
            .select()
            .ilike("common_format", pattern: "%\(format)%")
            .order("brand")
            .order("series")
            .limit(300)
            .execute()
            .value
        return results
    }

    // MARK: - Topp-vurderte sigarer (Brukernes topp N)
    // Henter sigarer med høyest avg_rating — oppdateres automatisk
    // etterhvert som brukere scorer sigarer via tasting_logs.
    func fetchTopRatedCigars(limit: Int = 5) async throws -> [Cigar] {
        // Snitt regnes fra reelle brukerratinger (tasting_logs), ikke seed-verdien
        // cigars.avg_rating. Krever minst 1 reell stemme — hev terskelen når
        // brukermassen vokser. Se migrasjon 107.
        struct Params: Encodable {
            let p_limit: Int
            let p_min_votes: Int
        }
        let results: [Cigar] = try await supabase
            .rpc("top_rated_cigars", params: Params(p_limit: limit, p_min_votes: 1))
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

        // PostgREST returnerer maks 1000 rader per kall. Uten paginering mistet
        // vokabularet alle merker etter ~rad 1000, og skanning av dem ble dårligere.
        var words = Set<String>()
        var from = 0
        let pageSize = 1000

        while true {
            let rows: [BrandSeriesRow] = try await supabase
                .from("cigars")
                .select("brand, series")
                .order("id")
                .range(from: from, to: from + pageSize - 1)
                .execute()
                .value

            for row in rows {
                words.formUnion(row.brand.split(separator: " ").map(String.init))
                if let series = row.series {
                    words.formUnion(series.split(separator: " ").map(String.init))
                }
            }

            if rows.count < pageSize { break } // siste side
            from += pageSize
        }

        return Array(words)
    }
}

// MARK: - HumidorService
// Håndterer brukerens personlige sigarsamling

@MainActor
class HumidorService: ObservableObject {

    // Brukerens egne tidligere butikker — til «Kjøpt hos»-forslag.
    // Slår sammen distinkte butikknavn fra humidor og røykelogger, så «Tax-free
    // Gardermoen» dukker opp igjen neste gang uten at brukeren må skrive det på ny.
    func fetchStoreSuggestions(userId: UUID) async -> [String] {
        struct Row: Decodable { let store: String? }
        async let humidorRows: [Row] = (try? await supabase
            .from("humidor").select("store")
            .eq("user_id", value: userId.uuidString)
            .execute().value) ?? []
        async let logRows: [Row] = (try? await supabase
            .from("tasting_logs").select("store")
            .eq("user_id", value: userId.uuidString)
            .execute().value) ?? []
        let all = (await humidorRows + logRows)
            .compactMap { $0.store?.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return Array(Set(all)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

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
        humidorId: UUID? = nil,
        quantity: Int = 1,
        purchasedAt: Date? = nil,
        addedToHumidorAt: Date? = nil,
        store: String? = nil,
        purchasePrice: Double? = nil
    ) async throws -> HumidorEntry {
        let entry = NewHumidorEntry(
            userId: userId,
            cigarId: cigarId,
            humidorId: humidorId,
            quantity: quantity,
            purchaseDate: purchasedAt,
            addedToHumidorAt: addedToHumidorAt,
            purchasePrice: purchasePrice,
            storageNotes: nil,
            store: store?.isEmpty == false ? store : nil
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
    // Returnerer IDen til den nye log-raden (brukes til foto-opplasting).
    // Antall kan ikke gå under 0.
    @discardableResult
    func logSmokingSession(
        humidorEntry: HumidorEntry,
        userId: UUID,
        smokedAt: Date,
        rating: Int?,
        smokeAgain: Bool?,
        drawRating: Int?,
        burnRating: Int?,
        flavorRating: Int?,
        notes: String?,
        cutType: CutType? = nil,
        store: String? = nil
    ) async throws -> UUID {
        guard let cigar = humidorEntry.cigar else { throw URLError(.badServerResponse) }

        // 1. Lagre til tasting_logs og hent tilbake IDen
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
            personalNotes: notes?.isEmpty == false ? notes : nil,
            photoUrl: nil,
            cutType: cutType?.rawValue,
            store: store?.isEmpty == false ? store : nil
        )
        struct InsertedLog: Decodable { let id: UUID }
        let inserted: InsertedLog = try await supabase
            .from("tasting_logs")
            .insert(log)
            .select("id")
            .single()
            .execute()
            .value

        // 2. Dekrementer antall (minst 0)
        let newQuantity = max(0, humidorEntry.quantity - 1)
        try await supabase
            .from("humidor")
            .update(["quantity": newQuantity])
            .eq("id", value: humidorEntry.id.uuidString)
            .execute()

        return inserted.id
    }

    // Logg en røyk UTEN humidor: lagrer kun til tasting_logs (ingen humidor-kobling,
    // ingen antall-dekrementering). Brukes fra Utforsk/scan når man ikke eier sigaren.
    @discardableResult
    func logTastingForCigar(
        cigarId: UUID,
        userId: UUID,
        smokedAt: Date,
        rating: Int?,
        smokeAgain: Bool?,
        drawRating: Int?,
        burnRating: Int?,
        flavorRating: Int?,
        notes: String?,
        cutType: CutType? = nil,
        store: String? = nil
    ) async throws -> UUID {
        let log = NewTastingLog(
            userId: userId,
            cigarId: cigarId,
            humidorEntryId: nil,
            smokedAt: smokedAt,
            rating: rating,
            smokeAgain: smokeAgain,
            drawRating: drawRating,
            burnRating: burnRating,
            flavorRating: flavorRating,
            personalNotes: notes?.isEmpty == false ? notes : nil,
            photoUrl: nil,
            cutType: cutType?.rawValue,
            store: store?.isEmpty == false ? store : nil
        )
        struct InsertedLog: Decodable { let id: UUID }
        let inserted: InsertedLog = try await supabase
            .from("tasting_logs")
            .insert(log)
            .select("id")
            .single()
            .execute()
            .value
        return inserted.id
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
            .upload(path, data: downscaledJPEG(imageData, maxDim: 1400), options: FileOptions(contentType: "image/jpeg", upsert: true))

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

    // MARK: - Humidorer (containere)

    /// Hent alle humidorer for brukeren, eldst først.
    func fetchHumidors(userId: UUID) async throws -> [Humidor] {
        let humidors: [Humidor] = try await supabase
            .from("humidors")
            .select("*")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
        return humidors
    }

    /// Opprett en ny humidor.
    @discardableResult
    func createHumidor(userId: UUID, name: String, type: String?, location: String?, capacity: Int?,
                       targetRh: Int? = nil, rhMin: Int? = nil, rhMax: Int? = nil) async throws -> Humidor {
        let new = NewHumidor(userId: userId, name: name, type: type, location: location, capacity: capacity,
                             targetRh: targetRh, rhMin: rhMin, rhMax: rhMax)
        let inserted: Humidor = try await supabase
            .from("humidors")
            .insert(new)
            .select("*")
            .single()
            .execute()
            .value
        return inserted
    }

    /// Oppdater en humidor.
    func updateHumidor(id: UUID, name: String, type: String?, location: String?, capacity: Int?,
                       targetRh: Int? = nil, rhMin: Int? = nil, rhMax: Int? = nil) async throws {
        struct Patch: Encodable {
            let name: String
            let type: String?
            let location: String?
            let capacity: Int?
            let targetRh: Int?
            let rhMin: Int?
            let rhMax: Int?
            enum CodingKeys: String, CodingKey {
                case name, type, location, capacity
                case targetRh = "target_rh", rhMin = "rh_min", rhMax = "rh_max"
            }
        }
        try await supabase
            .from("humidors")
            .update(Patch(name: name, type: type, location: location, capacity: capacity,
                          targetRh: targetRh, rhMin: rhMin, rhMax: rhMax))
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - RH-målinger (relativ luftfuktighet)

    /// Alle RH-målinger for en humidor, nyeste først.
    func fetchRHReadings(humidorId: UUID) async throws -> [HumidorRHReading] {
        try await supabase
            .from("humidor_rh_readings")
            .select("id, humidor_id, rh, temperature, note, measured_at")
            .eq("humidor_id", value: humidorId.uuidString)
            .order("measured_at", ascending: false)
            .execute()
            .value
    }

    /// Siste RH-måling per humidor (til trafikklys-status i humidor-lista).
    /// RLS gir kun brukerens egne rader, så vi kan hente alle og redusere i klienten.
    func fetchLatestRHReadings() async throws -> [UUID: HumidorRHReading] {
        let all: [HumidorRHReading] = try await supabase
            .from("humidor_rh_readings")
            .select("id, humidor_id, rh, temperature, note, measured_at")
            .order("measured_at", ascending: false)
            .execute()
            .value
        var map: [UUID: HumidorRHReading] = [:]
        for r in all where map[r.humidorId] == nil { map[r.humidorId] = r }
        return map
    }

    /// Registrer en ny RH-måling. user_id settes av databasen via auth.uid().
    func addRHReading(humidorId: UUID, rh: Double, temperature: Double?, note: String?, measuredAt: Date) async throws {
        let new = NewRHReading(
            humidorId: humidorId, rh: rh, temperature: temperature,
            note: note?.isEmpty == false ? note : nil, measuredAt: measuredAt
        )
        try await supabase.from("humidor_rh_readings").insert(new).execute()
    }

    /// Slett en humidor. Sigarer i den beholdes (humidor_id settes til null via ON DELETE SET NULL).
    func deleteHumidor(id: UUID) async throws {
        try await supabase
            .from("humidors")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Flytt en sigar-oppføring til en annen humidor.
    func moveEntry(entryId: UUID, toHumidorId: UUID) async throws {
        try await supabase
            .from("humidor")
            .update(["humidor_id": toHumidorId.uuidString])
            .eq("id", value: entryId.uuidString)
            .execute()
    }

    /// Last opp forsidebilde for en humidor (bucket: humidor-covers).
    @discardableResult
    func uploadHumidorCover(humidorId: UUID, userId: UUID, imageData: Data) async throws -> String {
        let path = "\(userId.uuidString.lowercased())/\(humidorId.uuidString.lowercased()).jpg"
        try await supabase.storage
            .from("humidor-covers")
            .upload(path, data: downscaledJPEG(imageData, maxDim: 1400), options: FileOptions(contentType: "image/jpeg", upsert: true))
        let publicURL = try supabase.storage
            .from("humidor-covers")
            .getPublicURL(path: path)
        var finalURLString = publicURL.absoluteString
        if var components = URLComponents(url: publicURL, resolvingAgainstBaseURL: false) {
            components.queryItems = [URLQueryItem(name: "v", value: "\(Int(Date().timeIntervalSince1970))")]
            if let url = components.url { finalURLString = url.absoluteString }
        }
        try await supabase
            .from("humidors")
            .update(["image_url": finalURLString])
            .eq("id", value: humidorId.uuidString)
            .execute()
        return finalURLString
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

    // Last opp bilde til log-photos bucket og oppdater photo_url på loggen
    func uploadLogPhoto(logId: UUID, userId: UUID, imageData: Data) async throws -> String {
        let path = "\(userId.uuidString.lowercased())/\(logId.uuidString.lowercased()).jpg"

        try await supabase.storage
            .from("log-photos")
            .upload(path, data: downscaledJPEG(imageData, maxDim: 1200, quality: 0.7), options: FileOptions(contentType: "image/jpeg", upsert: true))

        let publicURL = try supabase.storage
            .from("log-photos")
            .getPublicURL(path: path)

        var finalURLString = publicURL.absoluteString
        if var components = URLComponents(url: publicURL, resolvingAgainstBaseURL: false) {
            components.queryItems = [URLQueryItem(name: "v", value: "\(Int(Date().timeIntervalSince1970))")]
            if let url = components.url { finalURLString = url.absoluteString }
        }

        // Ikke gjør .update() her — save() i EditLogSheet sender URL-en
        // videre til updateLog() via RPC, som håndterer photo_url-oppdateringen.
        return finalURLString
    }

    // MARK: - Datahjul for bildegjenkjenning
    // Når brukeren løser en skanning (velger riktig sigar), lagrer vi bånd-bildet
    // og bånd-teksten koblet til sigaren. Bildet mater bildebiblioteket, og
    // teksten blir en lært alias når nok brukere har bekreftet samme kobling.
    // Alt er «best effort» — skal aldri velte selve skanne-flyten.
    func uploadBandSample(userId: UUID, imageData: Data) async throws -> String {
        let path = "\(userId.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"
        try await supabase.storage
            .from("band-samples")
            .upload(path, data: downscaledJPEG(imageData, maxDim: 1200, quality: 0.7), options: FileOptions(contentType: "image/jpeg", upsert: true))
        return path
    }

    func recordScanResolution(ocrText: String, cigarId: UUID, imagePath: String?) async {
        struct Params: Encodable {
            let p_ocr_text: String
            let p_cigar_id: String
            let p_image_path: String?
        }
        do {
            try await supabase
                .rpc("record_scan_resolution", params: Params(
                    p_ocr_text: ocrText,
                    p_cigar_id: cigarId.uuidString,
                    p_image_path: imagePath
                ))
                .execute()
        } catch {
            print("record_scan_resolution feilet (ignorert): \(error)")
        }
    }

    /// Én samlet «løs skanning»-handling: last opp bånd-bildet (om vi har det)
    /// og registrer koblingen. Kalles når brukeren velger riktig sigar.
    func resolveScan(ocrText: String, cigarId: UUID, userId: UUID?, bandImage: Data?) async {
        guard !ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var path: String? = nil
        if let bandImage, let userId {
            path = try? await uploadBandSample(userId: userId, imageData: bandImage)
        }
        await recordScanResolution(ocrText: ocrText, cigarId: cigarId, imagePath: path)
    }

    // URL til delbart log-kort (Edge Function)
    func shareURL(for logId: UUID) -> String {
        "https://wpcricosogcmzebkplwp.supabase.co/functions/v1/log-card?id=\(logId.uuidString)"
    }

    // Slett en røykelogg
    func deleteLog(id: UUID) async throws {
        try await supabase
            .from("tasting_logs")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // Oppdater en eksisterende røykelogg via RPC-funksjon.
    // Bruker SECURITY DEFINER-funksjonen update_own_tasting_log som gjør
    // UPDATE med eksplisitt user_id = auth.uid() sjekk i WHERE-klausulen.
    // Dette er mer robust enn PostgREST .update() + RLS WITH CHECK.
    func updateLog(
        id: UUID,
        smokedAt: Date,
        rating: Int?,
        smokeAgain: Bool?,
        drawRating: Int?,
        burnRating: Int?,
        flavorRating: Int?,
        personalNotes: String?,
        photoUrl: String?
    ) async throws {
        struct Params: Encodable {
            let p_id: String
            let p_smoked_at: Date
            let p_rating: Int?
            let p_smoke_again: Bool?
            let p_draw_rating: Int?
            let p_burn_rating: Int?
            let p_flavor_rating: Int?
            let p_personal_notes: String?
            let p_photo_url: String?

            func encode(to encoder: Encoder) throws {
                var c = encoder.container(keyedBy: CodingKeys.self)
                try c.encode(p_id,             forKey: .p_id)
                try c.encode(p_smoked_at,      forKey: .p_smoked_at)
                try c.encode(p_rating,         forKey: .p_rating)
                try c.encode(p_smoke_again,    forKey: .p_smoke_again)
                try c.encode(p_draw_rating,    forKey: .p_draw_rating)
                try c.encode(p_burn_rating,    forKey: .p_burn_rating)
                try c.encode(p_flavor_rating,  forKey: .p_flavor_rating)
                try c.encode(p_personal_notes, forKey: .p_personal_notes)
                try c.encode(p_photo_url,      forKey: .p_photo_url)
            }

            enum CodingKeys: String, CodingKey {
                case p_id, p_smoked_at, p_rating, p_smoke_again,
                     p_draw_rating, p_burn_rating, p_flavor_rating,
                     p_personal_notes, p_photo_url
            }
        }

        let params = Params(
            p_id:             id.uuidString.lowercased(),
            p_smoked_at:      smokedAt,
            p_rating:         rating,
            p_smoke_again:    smokeAgain,
            p_draw_rating:    drawRating,
            p_burn_rating:    burnRating,
            p_flavor_rating:  flavorRating,
            p_personal_notes: personalNotes,
            p_photo_url:      photoUrl
        )

        try await supabase
            .rpc("update_own_tasting_log", params: params)
            .execute()
    }
}
