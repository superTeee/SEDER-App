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

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let str = try decoder.singleValueContainer().decode(String.self)
            let fmts = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss"
            ]
            for fmt in fmts {
                let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX")
                f.dateFormat = fmt
                if let d = f.date(from: str) { return d }
            }
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Ugyldig dato: \(str)"
            )
        }

        return try decoder.decode([FeedPost].self, from: response.data)
    }

    // MARK: - Opprett post

    /// Oppretter et nytt innlegg (uten bilde).
    func createPost(userId: UUID, content: String?, tastingLogId: UUID? = nil, imageUrl: String? = nil) async throws -> FeedPost {
        let newPost = NewPost(userId: userId, tastingLogId: tastingLogId, content: content, imageUrl: imageUrl)
        let response = try await supabase
            .from("posts")
            .insert(newPost)
            .select()
            .single()
            .execute()

        // Hent hele innlegget med forfatterinfo via get_feed (nyeste post)
        let posts = try await fetchFeed(limit: 1, offset: 0)
        // Fallback: returner første post fra feed
        if let first = posts.first { return first }

        throw FeedError.postNotFound
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

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let str = try decoder.singleValueContainer().decode(String.self)
            let fmts = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss"
            ]
            for fmt in fmts {
                let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX")
                f.dateFormat = fmt
                if let d = f.date(from: str) { return d }
            }
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Ugyldig dato: \(str)"
            )
        }

        return try decoder.decode([FeedComment].self, from: response.data)
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
