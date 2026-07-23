package com.tomerikheggedal.vitola.data

import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.rpc
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

// Aktivitet = strukturert strøm av delte journal-hendelser (get_activity).
// Deling styres av set_entry_sharing. Speiler iOS ActivityService/ShareService.

@Serializable
data class ActivityItem(
    @SerialName("entry_id") val entryId: String,
    @SerialName("user_id") val userId: String,
    @SerialName("author_name") val authorName: String,
    @SerialName("author_avatar_url") val authorAvatarUrl: String? = null,
    val verb: String = "logged",
    @SerialName("personal_notes") val personalNotes: String? = null,
    @SerialName("tasting_photo_url") val tastingPhotoUrl: String? = null,
    @SerialName("cigar_id") val cigarId: String,
    @SerialName("cigar_brand") val cigarBrand: String,
    @SerialName("cigar_series") val cigarSeries: String? = null,
    @SerialName("cigar_vitola") val cigarVitola: String? = null,
    @SerialName("cigar_rating") val cigarRating: Int? = null,
    @SerialName("shared_at") val sharedAt: String? = null,
    @SerialName("public_slug") val publicSlug: String? = null,
) {
    val cigarMeta: String get() = listOfNotNull(cigarSeries, cigarVitola).joinToString(" · ")
    val verbText: String get() = if (verb == "wishlist") "vil prøve" else "delte en sigar"
}

@Serializable
data class EntrySharing(
    @SerialName("entry_id") val entryId: String? = null,
    @SerialName("shared_to_community") val sharedToCommunity: Boolean = false,
    @SerialName("shared_externally") val sharedExternally: Boolean = false,
    @SerialName("public_slug") val publicSlug: String? = null,
    @SerialName("shared_at") val sharedAt: String? = null,
)

object ActivityRepository {

    /** Aktivitets-strømmen — delte journal-hendelser, nyeste først. */
    suspend fun activity(limit: Int = 30, before: String? = null): List<ActivityItem> =
        Supa.client.postgrest.rpc("get_activity", buildJsonObject {
            put("p_limit", limit)
            if (before != null) put("p_before", before)
        }).decodeList()
}

object ShareRepository {

    /** Setter/endrer deling på en journal-oppføring. Eier-sjekk skjer i RPC-en. */
    suspend fun setSharing(entryId: String, community: Boolean, external: Boolean): EntrySharing =
        Supa.client.postgrest.rpc("set_entry_sharing", buildJsonObject {
            put("p_entry_id", entryId)
            put("p_community", community)
            put("p_external", external)
        }).decodeList<EntrySharing>().first()

    /** Offentlig URL til en delt oppføring — pen side hostet på Vercel
     *  (rendrer som ekte HTML m/Open Graph-kort). */
    fun publicUrl(slug: String): String =
        "https://seder-app-pearl.vercel.app/j/$slug"
}
