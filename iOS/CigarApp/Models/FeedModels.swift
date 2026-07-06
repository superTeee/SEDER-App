import Foundation

// MARK: - FeedPost
// Matcher returverdiene fra get_feed() RPC-en.
// Inneholder forfatternavn, like/kommentar-count og valgfri sigar-kobling.

struct FeedPost: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let authorName: String
    let authorAvatarUrl: String?
    let content: String?
    let imageUrl: String?
    let createdAt: Date

    // Sosiale tellere
    var likeCount: Int
    var commentCount: Int
    var likedByMe: Bool

    // Sigar-data fra koblet tasting_log (valgfritt)
    let tastingLogId: UUID?
    let cigarBrand: String?
    let cigarSeries: String?
    let cigarVitola: String?
    let cigarRating: Int?
    let cigarScoreLabel: String?
    let tastingPhotoUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId             = "user_id"
        case authorName         = "author_name"
        case authorAvatarUrl    = "author_avatar_url"
        case content
        case imageUrl           = "image_url"
        case createdAt          = "created_at"
        case likeCount          = "like_count"
        case commentCount       = "comment_count"
        case likedByMe          = "liked_by_me"
        case tastingLogId       = "tasting_log_id"
        case cigarBrand         = "cigar_brand"
        case cigarSeries        = "cigar_series"
        case cigarVitola        = "cigar_vitola"
        case cigarRating        = "cigar_rating"
        case cigarScoreLabel    = "cigar_score_label"
        case tastingPhotoUrl    = "tasting_photo_url"
    }

    // Formatert tidspunkt (f.eks. "2 timer siden")
    var relativeTime: String {
        let diff = Date().timeIntervalSince(createdAt)
        switch diff {
        case ..<60:         return "Nå"
        case ..<3600:       return "\(Int(diff / 60)) min"
        case ..<86400:      return "\(Int(diff / 3600)) t"
        case ..<604800:     return "\(Int(diff / 86400)) d"
        default:
            let f = DateFormatter()
            f.dateFormat = "d. MMM"
            f.locale = Locale(identifier: "nb_NO")
            return f.string(from: createdAt)
        }
    }

    // Sigar-visningsnavn
    var cigarDisplayName: String? {
        guard let brand = cigarBrand else { return nil }
        return [brand, cigarSeries, cigarVitola].compactMap { $0 }.joined(separator: " ")
    }

    // Scorefarger
    var scoreColor: ScoreColor {
        guard let r = cigarRating else { return .neutral }
        switch r {
        case 90...: return .gold
        case 80...: return .brown
        case 70...: return .gray
        default:    return .neutral
        }
    }

    enum ScoreColor {
        case gold, brown, gray, neutral
    }
}

// MARK: - NewPost
// Payload for å opprette et nytt innlegg (INSERT i posts-tabellen).

struct NewPost: Encodable {
    let userId: UUID
    let tastingLogId: UUID?
    let content: String?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case userId         = "user_id"
        case tastingLogId   = "tasting_log_id"
        case content
        case imageUrl       = "image_url"
    }
}

// MARK: - FeedComment
// Matcher returverdiene fra get_post_comments() RPC-en.

struct FeedComment: Codable, Identifiable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    let authorName: String
    let authorAvatarUrl: String?
    let content: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case postId         = "post_id"
        case userId         = "user_id"
        case authorName     = "author_name"
        case authorAvatarUrl = "author_avatar_url"
        case content
        case createdAt  = "created_at"
    }

    var relativeTime: String {
        let diff = Date().timeIntervalSince(createdAt)
        switch diff {
        case ..<60:     return "Nå"
        case ..<3600:   return "\(Int(diff / 60)) min"
        case ..<86400:  return "\(Int(diff / 3600)) t"
        default:        return "\(Int(diff / 86400)) d"
        }
    }
}

// MARK: - NewComment

struct NewComment: Encodable {
    let postId: UUID
    let userId: UUID
    let content: String

    enum CodingKeys: String, CodingKey {
        case postId     = "post_id"
        case userId     = "user_id"
        case content
    }
}
