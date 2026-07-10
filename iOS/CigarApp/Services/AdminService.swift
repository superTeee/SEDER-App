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
