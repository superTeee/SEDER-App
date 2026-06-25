import Foundation

// MARK: - FriendEntry
// Matcher resultatet fra get_friends_and_requests() i Supabase —
// én rad per vennskap/forespørsel, sett fra den innloggede brukerens side.

struct FriendEntry: Codable, Identifiable {
    let friendshipId: UUID
    let otherUserId: UUID
    let otherDisplayName: String?
    let status: String        // "pending" | "accepted" | "declined"
    let direction: String     // "incoming" | "outgoing"
    let createdAt: Date?

    var id: UUID { friendshipId }

    enum CodingKeys: String, CodingKey {
        case friendshipId      = "friendship_id"
        case otherUserId       = "other_user_id"
        case otherDisplayName  = "other_display_name"
        case status
        case direction
        case createdAt         = "created_at"
    }

    var isPending: Bool { status == "pending" }
    var isAccepted: Bool { status == "accepted" }
    var isIncoming: Bool { direction == "incoming" }
    var isOutgoing: Bool { direction == "outgoing" }

    var displayName: String {
        otherDisplayName ?? "Sigar-entusiast"
    }
}

// MARK: - Parametre til RPC-kall

struct FriendCodeParam: Encodable {
    let pCode: String

    enum CodingKeys: String, CodingKey {
        case pCode = "p_code"
    }
}
