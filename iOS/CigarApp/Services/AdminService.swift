import Foundation
import Supabase

// MARK: - AdminService
//
// Alt her går gjennom SECURITY DEFINER-funksjoner som selv sjekker `is_admin()`.
// Appen kan ikke jukse seg til admin ved å kalle riktig endepunkt — sperren står
// i databasen, ikke i denne filen. `admins` er en egen tabell, ikke et flagg på
// `profiles`, nettopp så ingen kan gjøre seg selv til admin ved å oppdatere sin
// egen profil.
//
// Merk: `admin_approve_submission` gjør en privat sigar offentlig, men setter
// IKKE `verified_at`. En godkjent brukerinnsendt sigar er synlig, ikke verifisert.
// Skal den bli verifisert, må målene settes med `admin_fix_cigar`, og da må det
// oppgis hvor tallene kommer fra.

@MainActor
final class AdminService: ObservableObject {

    @Published private(set) var isAdmin = false
    @Published private(set) var reports: [AdminReport] = []
    @Published private(set) var submissions: [AdminSubmission] = []
    @Published private(set) var gaps: [CigarGap] = []
    /// Ekte totaltall (respekterer søk), uavhengig av 300-grensen på lista.
    @Published private(set) var gapsTotal = 0
    @Published private(set) var scanHitrate: ScanHitrate?
    @Published private(set) var scanGaps: [ScanGap] = []
    @Published private(set) var isLoading = false

    var antallIKo: Int { reports.count + submissions.count }

    // MARK: - Er brukeren admin?

    func refreshAdminStatus() async {
        isAdmin = (await attempt("is_admin") {
            let svar: Bool = try await supabase.rpc("is_admin").execute().value
            return svar
        }) ?? false
    }

    // MARK: - Køen

    func loadQueue() async {
        guard isAdmin else { return }
        isLoading = true
        defer { isLoading = false }

        let r: [AdminReport]? = await attempt("admin_pending_reports") {
            let svar = try await supabase.rpc("admin_pending_reports").execute()
            return try SupabaseDecoder.shared.decode([AdminReport].self, from: svar.data)
        }
        let s: [AdminSubmission]? = await attempt("admin_pending_submissions") {
            let svar = try await supabase.rpc("admin_pending_submissions").execute()
            return try SupabaseDecoder.shared.decode([AdminSubmission].self, from: svar.data)
        }

        reports     = r ?? []
        submissions = s ?? []
    }

    // MARK: - Datahull
    //
    // Offentlige rader som mangler noe appen viser. Verst først. Egen last, så
    // køen ikke må vente på 300 rader hver gang admin åpner skjermen.

    struct GapSearchParam: Encodable { let p_search: String? }

    /// Laster hull-lista (topp 300, verst først) og det ekte totaltallet ved
    /// siden av. Et valgfritt søk filtrerer begge på merke/serie/vitola.
    func loadGaps(search: String = "") async {
        guard isAdmin else { return }
        isLoading = true
        defer { isLoading = false }

        let trimmet = search.trimmingCharacters(in: .whitespacesAndNewlines)
        let param = GapSearchParam(p_search: trimmet.isEmpty ? nil : trimmet)

        let g: [CigarGap]? = await attempt("admin_data_gaps") {
            let svar = try await supabase.rpc("admin_data_gaps", params: param).execute()
            return try SupabaseDecoder.shared.decode([CigarGap].self, from: svar.data)
        }
        let total: Int? = await attempt("admin_data_gaps_count") {
            let svar = try await supabase.rpc("admin_data_gaps_count", params: param).execute()
            return try SupabaseDecoder.shared.decode(Int.self, from: svar.data)
        }

        gaps = g ?? []
        gapsTotal = total ?? gaps.count
    }

    // MARK: - Skann-dekning
    //
    // Steg 1 i dekning-datahjulet: treffrate + hvilke sigarer folk skanner som
    // vi ikke traff (mest skannet først). Kilde: scan_events-tabellen.

    struct DaysParam: Encodable { let p_days: Int }
    struct GapsParam: Encodable { let p_days: Int; let p_limit: Int }

    func loadScanCoverage(days: Int = 30) async {
        guard isAdmin else { return }
        isLoading = true
        defer { isLoading = false }

        let h: [ScanHitrate]? = await attempt("admin_scan_hitrate") {
            let svar = try await supabase.rpc("admin_scan_hitrate", params: DaysParam(p_days: days)).execute()
            return try SupabaseDecoder.shared.decode([ScanHitrate].self, from: svar.data)
        }
        let gaps: [ScanGap]? = await attempt("admin_scan_gaps") {
            let svar = try await supabase.rpc("admin_scan_gaps", params: GapsParam(p_days: days, p_limit: 50)).execute()
            return try SupabaseDecoder.shared.decode([ScanGap].self, from: svar.data)
        }

        scanHitrate = h?.first
        scanGaps = gaps ?? []
    }

    /// Fyller tomme felt på én sigar. Sender bare feltene admin faktisk fylte
    /// ut — resten utelates fra JSON og lar basen stå. Returnerer true ved suksess.
    @discardableResult
    func fillCigar(_ id: UUID, patch: CigarFillPatch) async -> Bool {
        let ok = await attempt("admin_fill_cigar") {
            try await supabase
                .rpc("admin_fill_cigar", params: patch.params(cigarId: id))
                .execute()
        }
        // Fjern raden fra lista først når basen sa ja.
        if ok != nil { gaps.removeAll { $0.id == id } }
        return ok != nil
    }

    // MARK: - Handlinger

    private struct ReportAction: Encodable {
        let p_report_id: String
        let p_status: String
    }
    private struct SubmissionAction: Encodable {
        let p_submission_id: String
    }

    func resolveReport(_ id: UUID, status: ReportStatus) async {
        let ok = await attempt("admin_resolve_report") {
            try await supabase
                .rpc("admin_resolve_report",
                     params: ReportAction(p_report_id: id.uuidString, p_status: status.rawValue))
                .execute()
        }
        // Fjern først når basen faktisk sa ja. Ellers ville raden forsvinne fra
        // skjermen mens den fortsatt lå i køen.
        if ok != nil { reports.removeAll { $0.id == id } }
    }

    func approveSubmission(_ id: UUID) async {
        let ok = await attempt("admin_approve_submission") {
            try await supabase
                .rpc("admin_approve_submission", params: SubmissionAction(p_submission_id: id.uuidString))
                .execute()
        }
        if ok != nil { submissions.removeAll { $0.id == id } }
    }

    func rejectSubmission(_ id: UUID) async {
        let ok = await attempt("admin_reject_submission") {
            try await supabase
                .rpc("admin_reject_submission", params: SubmissionAction(p_submission_id: id.uuidString))
                .execute()
        }
        if ok != nil { submissions.removeAll { $0.id == id } }
    }
}

// MARK: - Modeller

enum ReportStatus: String {
    case resolved   // rettet, eller allerede riktig
    case rejected   // innmeldingen holdt ikke
}

struct AdminReport: Codable, Identifiable, Hashable {
    let id: UUID
    let cigarId: UUID
    let cigarNavn: String
    let field: String
    let comment: String?
    let melder: String
    let createdAt: Date
    let ringGauge: Int?
    let lengthInches: Double?
    let sourceUrl: String?
    let verified: Bool

    /// Feltnavnene kommer rå fra basen, på engelsk. Appen er på norsk.
    var feltNavn: String {
        switch field {
        case "origin":      return "Opprinnelse"
        case "dimensions":  return "Mål"
        case "tobacco":     return "Tobakk"
        case "description": return "Beskrivelse"
        case "flavor":      return "Smaksnoter"
        default:            return "Annet"
        }
    }

    var maalTekst: String {
        guard let ringGauge, let lengthInches else { return "Mangler mål" }
        return "\(ringGauge) × \(String(format: "%.1f", lengthInches))\""
    }

    enum CodingKeys: String, CodingKey {
        case id
        case cigarId      = "cigar_id"
        case cigarNavn    = "cigar_navn"
        case field, comment, melder, verified
        case createdAt    = "created_at"
        case ringGauge    = "ring_gauge"
        case lengthInches = "length_inches"
        case sourceUrl    = "source_url"
    }
}

struct AdminSubmission: Codable, Identifiable, Hashable {
    let id: UUID
    let cigarId: UUID
    let cigarNavn: String
    let note: String?
    let foreslattAv: String
    let createdAt: Date
    let ringGauge: Int?
    let lengthInches: Double?
    let countryOrigin: String?

    var maalTekst: String {
        guard let ringGauge, let lengthInches else { return "Uten mål" }
        return "\(ringGauge) × \(String(format: "%.1f", lengthInches))\""
    }

    enum CodingKeys: String, CodingKey {
        case id
        case cigarId       = "cigar_id"
        case cigarNavn     = "cigar_navn"
        case note
        case foreslattAv   = "foreslatt_av"
        case createdAt     = "created_at"
        case ringGauge     = "ring_gauge"
        case lengthInches  = "length_inches"
        case countryOrigin = "country_origin"
    }
}

// MARK: - Datahull

/// Ett hull-felt. rawValue matcher strengene basen legger i `missing`.
enum GapField: String, CaseIterable, Identifiable, Hashable {
    case dimensions
    case origin
    case wrapper
    case strength
    case flavor
    case description

    var id: String { rawValue }

    /// Norsk etikett (appen er på norsk).
    var label: String {
        switch self {
        case .dimensions:  return "Mål"
        case .origin:      return "Opprinnelse"
        case .wrapper:     return "Dekkblad"
        case .strength:    return "Styrke"
        case .flavor:      return "Smaksnoter"
        case .description: return "Beskrivelse"
        }
    }

    var systemImage: String {
        switch self {
        case .dimensions:  return "ruler"
        case .origin:      return "mappin.and.ellipse"
        case .wrapper:     return "leaf"
        case .strength:    return "gauge.medium"
        case .flavor:      return "nose"
        case .description: return "text.alignleft"
        }
    }
}

/// En offentlig sigar med minst ett tomt felt. Kommer fra admin_data_gaps().
// MARK: - Skann-dekning-modeller

struct ScanHitrate: Codable, Hashable {
    let total: Int
    let hits: Int
    let rate: Double?      // prosent, null hvis ingen skann ennå

    var misses: Int { total - hits }
    var rateText: String { rate.map { "\(Int($0.rounded()))%" } ?? "–" }
}

struct ScanGap: Codable, Identifiable, Hashable {
    let normText: String
    let sampleOcr: String
    let misses: Int

    var id: String { normText }
    var visningsnavn: String { sampleOcr.isEmpty ? normText : sampleOcr }

    enum CodingKeys: String, CodingKey {
        case normText  = "norm_text"
        case sampleOcr = "sample_ocr"
        case misses
    }
}

struct CigarGap: Codable, Identifiable, Hashable {
    let id: UUID
    let cigarNavn: String?
    let brand: String
    let ringGauge: Int?
    let lengthInches: Double?
    let countryOrigin: String?
    let wrapperLeaf: String?
    let strength: Double?
    let hasFlavor: Bool
    let hasDescription: Bool
    let missing: [String]
    let gapCount: Int
    let sourceTier: String?
    let verified: Bool

    /// Feltene som mangler, som typede verdier. Ukjente strenger hoppes over.
    var manglendeFelt: [GapField] {
        missing.compactMap { GapField(rawValue: $0) }
    }

    var visningsnavn: String {
        cigarNavn?.isEmpty == false ? cigarNavn! : brand
    }

    enum CodingKeys: String, CodingKey {
        case id
        case cigarNavn      = "cigar_navn"
        case brand
        case ringGauge      = "ring_gauge"
        case lengthInches   = "length_inches"
        case countryOrigin  = "country_origin"
        case wrapperLeaf    = "wrapper_leaf"
        case strength
        case hasFlavor      = "has_flavor"
        case hasDescription = "has_description"
        case missing
        case gapCount       = "gap_count"
        case sourceTier     = "source_tier"
        case verified
    }
}

/// Det admin fyller inn. Bare felt satt til non-nil sendes til basen — resten
/// utelates fra JSON (encodeIfPresent) og lar raden stå. `sourceUrl` er påkrevd.
struct CigarFillPatch {
    var sourceUrl: String
    var ringGauge: Int?
    var lengthInches: Double?
    var countryOrigin: String?
    var wrapperLeaf: String?
    var strength: Double?
    var flavorNotes: [String]?
    var description: String?

    func params(cigarId: UUID) -> FillParams {
        FillParams(
            p_cigar_id: cigarId.uuidString,
            p_source_url: sourceUrl,
            p_ring_gauge: ringGauge,
            p_length_inches: lengthInches,
            p_country_origin: countryOrigin,
            p_wrapper_leaf: wrapperLeaf,
            p_strength: strength,
            p_flavor_notes: flavorNotes,
            p_description: description
        )
    }

    struct FillParams: Encodable {
        let p_cigar_id: String
        let p_source_url: String
        let p_ring_gauge: Int?
        let p_length_inches: Double?
        let p_country_origin: String?
        let p_wrapper_leaf: String?
        let p_strength: Double?
        let p_flavor_notes: [String]?
        let p_description: String?
        // Standard-synthesert encode bruker encodeIfPresent for optionals:
        // nil-felt havner ikke i JSON, og basen bruker default (null).
    }
}
