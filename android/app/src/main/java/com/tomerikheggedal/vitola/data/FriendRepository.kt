package com.tomerikheggedal.vitola.data

import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.rpc
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

// Begrenset offentlig profil (get_friend_profile RPC — samme som iOS).
@Serializable
data class FriendProfile(
    val id: String,
    @SerialName("display_name") val displayName: String? = null,
    @SerialName("avatar_url") val avatarUrl: String? = null,
    val bio: String? = null,
    val city: String? = null,
    val country: String? = null,
    @SerialName("cigar_count") val cigarCount: Int = 0,
    @SerialName("humidor_count") val humidorCount: Int = 0,
    @SerialName("friend_count") val friendCount: Int = 0,
    @SerialName("brands_tried") val brandsTried: Int = 0,
    @SerialName("is_founding_member") val isFoundingMember: Boolean = false,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("humidors_count") val humidorsCount: Int = 0,
    @SerialName("rh_count") val rhCount: Int = 0,
)

// En venn/forespørsel (get_friends_and_requests RPC).
@Serializable
data class FriendEntry(
    @SerialName("friendship_id") val friendshipId: String,
    @SerialName("other_user_id") val otherUserId: String,
    @SerialName("other_display_name") val otherDisplayName: String? = null,
    @SerialName("other_avatar_url") val otherAvatarUrl: String? = null,
    val status: String,               // pending / accepted / declined
    val direction: String,            // outgoing / incoming
)

// Brukersøk-treff (search_users RPC).
@Serializable
data class UserSearchResult(
    val id: String,
    @SerialName("display_name") val displayName: String? = null,
    @SerialName("friend_code") val friendCode: String? = null,
    @SerialName("avatar_url") val avatarUrl: String? = null,
)

enum class FriendState { NONE, PENDING_OUT, PENDING_IN, FRIENDS, SELF }

object FriendRepository {

    suspend fun profile(userId: String): FriendProfile? = runCatching {
        Supa.client.postgrest.rpc("get_friend_profile", buildJsonObject { put("p_user_id", userId) })
            .decodeAs<FriendProfile>()
    }.getOrNull()

    suspend fun friendsAndRequests(): List<FriendEntry> = runCatching {
        Supa.client.postgrest.rpc("get_friends_and_requests").decodeList<FriendEntry>()
    }.getOrDefault(emptyList())

    /** Relasjon til en bruker + eventuell friendship-id (for å svare). */
    suspend fun stateWith(userId: String): Pair<FriendState, String?> {
        if (userId == Supa.client.auth.currentUserOrNull()?.id) return FriendState.SELF to null
        val entry = friendsAndRequests().firstOrNull { it.otherUserId == userId }
            ?: return FriendState.NONE to null
        val state = when {
            entry.status == "accepted" -> FriendState.FRIENDS
            entry.status == "pending" && entry.direction == "incoming" -> FriendState.PENDING_IN
            entry.status == "pending" -> FriendState.PENDING_OUT
            else -> FriendState.NONE
        }
        return state to entry.friendshipId
    }

    suspend fun request(userId: String) {
        Supa.client.postgrest.rpc("request_friendship", buildJsonObject { put("p_user_id", userId) })
    }

    /** Søk etter brukere på navn. */
    suspend fun searchUsers(query: String): List<UserSearchResult> {
        if (query.isBlank()) return emptyList()
        return runCatching {
            Supa.client.postgrest.rpc("search_users", buildJsonObject { put("p_query", query) })
                .decodeList<UserSearchResult>()
        }.getOrDefault(emptyList())
    }

    /** Send venneforespørsel via vennekode. */
    suspend fun sendByCode(code: String) {
        Supa.client.postgrest.rpc("send_friend_request", buildJsonObject { put("p_code", code.trim().uppercase()) })
    }

    /** Egen vennekode (fra profiles). */
    suspend fun myFriendCode(): String? {
        val uid = Supa.client.auth.currentUserOrNull()?.id ?: return null
        return runCatching {
            Supa.client.from("profiles")
                .select(io.github.jan.supabase.postgrest.query.Columns.list("friend_code")) { filter { eq("id", uid) } }
                .decodeList<CodeRow>().firstOrNull()?.friendCode
        }.getOrNull()
    }

    suspend fun respond(friendshipId: String, accept: Boolean) {
        Supa.client.from("friendships").update(
            buildJsonObject { put("status", if (accept) "accepted" else "declined") }
        ) { filter { eq("id", friendshipId) } }
    }
}

@Serializable
private data class CodeRow(@SerialName("friend_code") val friendCode: String? = null)
