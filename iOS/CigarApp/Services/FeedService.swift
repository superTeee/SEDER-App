import Foundation
import UIKit

// MARK: - FeedService
// Håndterer alle API-kall mot feed-funksjonaliteten:
// hent feed, opprett post, toggle like, hent/legg til kommentarer, last opp bilde.

class FeedService {

    // MARK: - Private param structs (unngår mixed-type dictionary-problemer)
    private struct GetFeedParams: Encodable {
        let p_limit: Int
        let p_offset: Int
    }

    /// Postgres sender tidsstempler i tre varianter. Dekoderen som takler alle
    /// bor i `SupabaseDecoder` — den ble delt da AdminService trengte den samme.
    private static var decoder: JSONDecoder { SupabaseDecoder.shared }

    // MARK: - Feed

    /// Henter feed (egne + venners poster), nyest først.
    ///
    /// Bruker-ID sendes IKKE fra klienten. `get_feed` leser `auth.uid()` selv —
    /// ellers kunne hvem som helst be om hvem som helst sin feed.
    func fetchFeed(limit: Int = 50, offset: Int = 0) async throws -> [FeedPost] {
        let response = try await supabase
            .rpc("get_feed", params: GetFeedParams(
                p_limit:   limit,
                p_offset:  offset
            ))
            .execute()

        return try Self.decoder.decode([FeedPost].self, from: response.data)
    }

    // MARK: - Opprett post

    /// Oppretter et nytt innlegg og returnerer det ferdig beriket (forfatter, sigar).
    func createPost(userId: UUID, content: String?, tastingLogId: UUID? = nil, imageUrl: String? = nil) async throws -> FeedPost {
        struct InsertedPost: Decodable { let id: UUID }

        let newPost = NewPost(userId: userId, tastingLogId: tastingLogId, content: content, imageUrl: imageUrl)
        let inserted: InsertedPost = try await supabase
            .from("posts")
            .insert(newPost)
            .select("id")
            .single()
            .execute()
            .value

        // Hent det berikede innlegget via get_feed. Vi slår opp på ID i stedet for
        // å anta at nyeste post er vår — to innlegg kan lande i samme sekund.
        let recent = try await fetchFeed(limit: 10, offset: 0)
        guard let post = recent.first(where: { $0.id == inserted.id }) else {
            throw FeedError.postNotFound
        }
        return post
    }

    /// Laster opp bilde til Supabase Storage og returnerer offentlig URL.
    func uploadPostImage(userId: UUID, postId: UUID, imageData: Data) async throws -> String {
        // MERK: Bruk lowercase UUID — PostgreSQL auth.uid()::text er lowercase,
        // og storage RLS bruker TEXT-sammenligning (case-sensitiv).
        let path = "\(userId.uuidString.lowercased())/\(postId.uuidString.lowercased()).jpg"

        // Komprimer til maks 1200px bredde
        let compressed = compressImage(imageData, maxWidth: 1200)

        _ = try await supabase.storage
            .from("post-images")
            .upload(path, data: compressed, options: .init(contentType: "image/jpeg", upsert: true))

        let publicUrl = try supabase.storage
            .from("post-images")
            .getPublicURL(path: path)

        return publicUrl.absoluteString
    }

    // MARK: - Likes

    /// Toggler en like. Returnerer ny `likedByMe`-status.
    ///
    /// Bruker-ID sendes IKKE fra klienten — `toggle_post_like` leser `auth.uid()`
    /// selv, ellers kunne man like og avlike på vegne av andre.
    func toggleLike(postId: UUID) async throws -> Bool {
        let response = try await supabase
            .rpc("toggle_post_like", params: [
                "p_post_id": postId.uuidString
            ])
            .execute()

        // toggle_post_like returnerer en boolean
        if let bool = try? JSONDecoder().decode(Bool.self, from: response.data) {
            return bool
        }
        throw FeedError.toggleFailed
    }

    // MARK: - Kommentarer

    /// Henter kommentarer til et innlegg, eldst først.
    func fetchComments(postId: UUID) async throws -> [FeedComment] {
        let response = try await supabase
            .rpc("get_post_comments", params: ["p_post_id": postId.uuidString])
            .execute()

        return try Self.decoder.decode([FeedComment].self, from: response.data)
    }

    /// Legger til en kommentar på et innlegg.
    func addComment(postId: UUID, userId: UUID, content: String) async throws {
        let newComment = NewComment(postId: postId, userId: userId, content: content)
        try await supabase
            .from("post_comments")
            .insert(newComment)
            .execute()
    }

    /// Sletter et innlegg (kun eier kan slette, styrt av RLS).
    func deletePost(postId: UUID) async throws {
        try await supabase
            .from("posts")
            .delete()
            .eq("id", value: postId.uuidString)
            .execute()
    }

    // MARK: - Moderering (rapporter / blokker)

    /// Rapporterer et innlegg med en oppgitt grunn.
    func reportPost(postId: UUID, reason: String) async throws {
        try await supabase
            .rpc("report_post", params: [
                "p_post_id": postId.uuidString,
                "p_reason":  reason
            ])
            .execute()
    }

    /// Blokkerer en bruker — skjuler innhold begge veier og fjerner evt. vennskap.
    func blockUser(userId: UUID) async throws {
        try await supabase
            .rpc("block_user", params: ["p_blocked_id": userId.uuidString])
            .execute()
    }

    /// Opphever blokkering av en bruker.
    func unblockUser(userId: UUID) async throws {
        try await supabase
            .rpc("unblock_user", params: ["p_blocked_id": userId.uuidString])
            .execute()
    }

    // MARK: - Helpers

    private func compressImage(_ data: Data, maxWidth: CGFloat) -> Data {
        guard let uiImage = UIImage(data: data) else { return data }
        let scale = min(1.0, maxWidth / uiImage.size.width)
        let newSize = CGSize(width: uiImage.size.width * scale, height: uiImage.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in uiImage.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: 0.82) ?? data
    }
}

// MARK: - Aktivitet & deling (Feed → Aktivitet)
// Aktivitet avledes fra journalen (tasting_logs) via get_activity, ikke fra posts.
// Deling styres av set_entry_sharing. Ny kode bor her (eksisterende prosjektfil).

/// Én hendelse i Aktivitet-strømmen (delt journal-oppføring).
struct ActivityItem: Decodable, Identifiable {
    let entryId: UUID
    let userId: UUID
    let authorName: String
    let authorAvatarUrl: String?
    let verb: String
    let personalNotes: String?
    let tastingPhotoUrl: String?
    let cigarId: UUID
    let cigarBrand: String
    let cigarSeries: String?
    let cigarVitola: String?
    let cigarRating: Int?
    let sharedAt: Date?
    let publicSlug: String?

    var id: UUID { entryId }

    /// «Torpedo · Maduro» — undertittel til sigar-kortet.
    var cigarMetaLine: String {
        [cigarSeries, cigarVitola].compactMap { $0 }.joined(separator: " · ")
    }

    enum CodingKeys: String, CodingKey {
        case entryId = "entry_id"
        case userId = "user_id"
        case authorName = "author_name"
        case authorAvatarUrl = "author_avatar_url"
        case verb
        case personalNotes = "personal_notes"
        case tastingPhotoUrl = "tasting_photo_url"
        case cigarId = "cigar_id"
        case cigarBrand = "cigar_brand"
        case cigarSeries = "cigar_series"
        case cigarVitola = "cigar_vitola"
        case cigarRating = "cigar_rating"
        case sharedAt = "shared_at"
        case publicSlug = "public_slug"
    }
}

/// Delings-status returnert fra set_entry_sharing.
struct EntrySharing: Decodable {
    let entryId: UUID
    let sharedToCommunity: Bool
    let sharedExternally: Bool
    let publicSlug: String?
    let sharedAt: Date?

    enum CodingKeys: String, CodingKey {
        case entryId = "entry_id"
        case sharedToCommunity = "shared_to_community"
        case sharedExternally = "shared_externally"
        case publicSlug = "public_slug"
        case sharedAt = "shared_at"
    }
}

// MARK: - ActivityService
class ActivityService: ObservableObject {

    private struct Params: Encodable {
        let p_limit: Int
        let p_before: Date?
    }
    private static var decoder: JSONDecoder { SupabaseDecoder.shared }

    /// Aktivitets-strømmen — delte journal-hendelser, nyeste først.
    /// Bruker-ID sendes ikke; get_activity leser auth.uid() selv.
    func fetchActivity(limit: Int = 30, before: Date? = nil) async throws -> [ActivityItem] {
        let response = try await supabase
            .rpc("get_activity", params: Params(p_limit: limit, p_before: before))
            .execute()
        return try Self.decoder.decode([ActivityItem].self, from: response.data)
    }
}

// MARK: - ShareService
class ShareService: ObservableObject {

    private struct Params: Encodable {
        let p_entry_id: String
        let p_community: Bool
        let p_external: Bool
    }
    private static var decoder: JSONDecoder { SupabaseDecoder.shared }

    /// Setter/endrer deling på en journal-oppføring. Eier-sjekk skjer i RPC-en.
    @discardableResult
    func setSharing(entryId: UUID, community: Bool, external: Bool) async throws -> EntrySharing {
        let response = try await supabase
            .rpc("set_entry_sharing", params: Params(
                p_entry_id: entryId.uuidString,
                p_community: community,
                p_external: external
            ))
            .single()
            .execute()
        return try Self.decoder.decode(EntrySharing.self, from: response.data)
    }

    /// Offentlig URL til en delt oppføring.
    /// TODO: bytt til pen universal link `vitola.app/j/<slug>` når DNS/AASA er satt opp.
    /// Inntil da peker vi rett på edge-funksjonen som rendrer den offentlige siden.
    func publicURL(slug: String) -> URL? {
        URL(string: "https://wpcricosogcmzebkplwp.supabase.co/functions/v1/public-journal?slug=\(slug)")
    }
}

// MARK: - FeedError

enum FeedError: LocalizedError {
    case postNotFound
    case toggleFailed

    var errorDescription: String? {
        switch self {
        case .postNotFound: return "Kunne ikke finne innlegget."
        case .toggleFailed: return "Kunne ikke oppdatere liken."
        }
    }
}
