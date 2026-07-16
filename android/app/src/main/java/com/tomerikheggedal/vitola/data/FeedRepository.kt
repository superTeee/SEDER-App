package com.tomerikheggedal.vitola.data

import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.rpc
import io.github.jan.supabase.storage.storage
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

// Matcher get_feed()-RPC-en (samme som iOS FeedPost).
@Serializable
data class FeedPost(
    val id: String,
    @SerialName("user_id") val userId: String,
    @SerialName("author_name") val authorName: String,
    @SerialName("author_avatar_url") val authorAvatarUrl: String? = null,
    val content: String? = null,
    @SerialName("image_url") val imageUrl: String? = null,
    @SerialName("created_at") val createdAt: String,
    @SerialName("like_count") val likeCount: Int = 0,
    @SerialName("comment_count") val commentCount: Int = 0,
    @SerialName("liked_by_me") val likedByMe: Boolean = false,
    @SerialName("tasting_log_id") val tastingLogId: String? = null,
    @SerialName("cigar_brand") val cigarBrand: String? = null,
    @SerialName("cigar_series") val cigarSeries: String? = null,
    @SerialName("cigar_vitola") val cigarVitola: String? = null,
    @SerialName("cigar_rating") val cigarRating: Int? = null,
    @SerialName("cigar_score_label") val cigarScoreLabel: String? = null,
    @SerialName("tasting_photo_url") val tastingPhotoUrl: String? = null,
) {
    val cigarDisplayName: String?
        get() = cigarBrand?.let { listOfNotNull(cigarBrand, cigarSeries, cigarVitola).joinToString(" ") }
}

@Serializable
data class FeedComment(
    val id: String,
    @SerialName("post_id") val postId: String,
    @SerialName("user_id") val userId: String,
    @SerialName("author_name") val authorName: String,
    @SerialName("author_avatar_url") val authorAvatarUrl: String? = null,
    val content: String,
    @SerialName("created_at") val createdAt: String,
)

object FeedRepository {

    suspend fun feed(limit: Int = 50, offset: Int = 0): List<FeedPost> =
        Supa.client.postgrest.rpc("get_feed", GetFeedParams(limit, offset)).decodeList()

    /** Liker / avliker et innlegg. Returnerer ny liked-status. */
    suspend fun toggleLike(postId: String): Boolean =
        Supa.client.postgrest.rpc("toggle_post_like", PostIdParam(postId)).decodeAs()

    suspend fun comments(postId: String): List<FeedComment> =
        Supa.client.postgrest.rpc("get_post_comments", PostIdParam(postId)).decodeList()

    suspend fun addComment(postId: String, content: String) {
        val uid = Supa.client.auth.currentUserOrNull()?.id ?: error("Ikke innlogget")
        Supa.client.from("post_comments").insert(
            NewComment(user_id = uid, post_id = postId, content = content.trim())
        )
    }

    /** Opprett et innlegg med tekst og valgfritt bilde (allerede komprimert til JPEG). */
    suspend fun createPost(content: String, imageJpeg: ByteArray? = null) {
        val uid = Supa.client.auth.currentUserOrNull()?.id ?: error("Ikke innlogget")

        // 1) Sett inn innlegget, hent id-en tilbake.
        val inserted = Supa.client.from("posts")
            .insert(NewPost(user_id = uid, content = content.trim().ifBlank { null })) {
                select(Columns.list("id"))
            }
            .decodeList<InsertedId>()
            .firstOrNull() ?: return

        // 2) Last opp bilde til post-images (lowercase path for RLS) og skriv image_url.
        if (imageJpeg != null) {
            val path = "${uid.lowercase()}/${inserted.id.lowercase()}.jpg"
            Supa.client.storage.from("post-images").upload(path, imageJpeg) { upsert = true }
            val url = Supa.client.storage.from("post-images").publicUrl(path)
            Supa.client.from("posts").update(
                buildJsonObject { put("image_url", url) }
            ) { filter { eq("id", inserted.id) } }
        }
    }
}

@Serializable
private data class GetFeedParams(val p_limit: Int, val p_offset: Int)

@Serializable
private data class PostIdParam(val p_post_id: String)

@Serializable
private data class NewComment(val user_id: String, val post_id: String, val content: String)

@Serializable
private data class NewPost(val user_id: String, val content: String? = null)

@Serializable
private data class InsertedId(val id: String)
