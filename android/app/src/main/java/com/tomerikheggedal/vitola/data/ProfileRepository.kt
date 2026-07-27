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

@Serializable
data class Profile(
    val id: String,
    @SerialName("display_name") val displayName: String? = null,
    @SerialName("friend_code") val friendCode: String? = null,
    @SerialName("avatar_url") val avatarUrl: String? = null,
    @SerialName("cover_url") val coverUrl: String? = null,
    val bio: String? = null,
    val city: String? = null,
    val country: String? = null,
    @SerialName("is_founding_member") val isFoundingMember: Boolean = false,
)

data class ProfileStats(
    val cigars: Int,        // Røkt (tasting_logs)
    val humidorEntries: Int, // I humidor
    val brandsTried: Int,    // Merker prøvd
    val friends: Int,        // Venner
)

// Smaksprofil — fra get_own_profile_favorites RPC (samme som iOS).
@Serializable
data class ProfileFavorites(
    @SerialName("favorite_cigar") val favoriteCigar: String? = null,
    @SerialName("favorite_cigar_score") val favoriteCigarScore: Int? = null,
    @SerialName("favorite_brand") val favoriteBrand: String? = null,
    @SerialName("favorite_vitola") val favoriteVitola: String? = null,
    @SerialName("favorite_country") val favoriteCountry: String? = null,
    @SerialName("favorite_wrapper") val favoriteWrapper: String? = null,
    @SerialName("favorite_binder") val favoriteBinder: String? = null,
    @SerialName("favorite_filler") val favoriteFiller: String? = null,
    @SerialName("favorite_flavor") val favoriteFlavor: String? = null,
    @SerialName("favorite_strength") val favoriteStrength: Double? = null,
)

// Egen profil + stats for innlogget bruker (samme tabeller som iOS).
object ProfileRepository {

    suspend fun myProfile(): Profile? {
        val uid = Supa.client.auth.currentUserOrNull()?.id ?: return null
        return Supa.client.from("profiles")
            .select(columns = Columns.list("id", "display_name", "friend_code", "avatar_url", "cover_url", "bio", "city", "country", "is_founding_member")) {
                filter { eq("id", uid) }
            }
            .decodeList<Profile>()
            .firstOrNull()
    }

    suspend fun myStats(): ProfileStats {
        val uid = Supa.client.auth.currentUserOrNull()?.id ?: return ProfileStats(0, 0, 0, 0)

        // Røkt + hvilke merker (for «Merker prøvd») i ett kall.
        val logs = Supa.client.from("tasting_logs")
            .select(columns = Columns.raw("id, cigars(brand)")) { filter { eq("user_id", uid) } }
            .decodeList<LogBrandRow>()
        val cigars = logs.size
        val brandsTried = logs.mapNotNull { it.cigar?.brand }.distinct().size

        val humidorEntries = Supa.client.from("humidor")
            .select(columns = Columns.list("id")) { filter { eq("user_id", uid) } }
            .decodeList<IdOnly>().size

        val friends = Supa.client.from("friendships")
            .select(columns = Columns.list("id")) {
                filter {
                    eq("status", "accepted")
                    or { eq("requester_id", uid); eq("recipient_id", uid) }
                }
            }
            .decodeList<IdOnly>().size

        return ProfileStats(cigars = cigars, humidorEntries = humidorEntries, brandsTried = brandsTried, friends = friends)
    }

    /** Oppdater visningsnavn. */
    suspend fun updateName(name: String) {
        val uid = Supa.client.auth.currentUserOrNull()?.id ?: return
        Supa.client.from("profiles").update(
            buildJsonObject { put("display_name", name.trim()) }
        ) { filter { eq("id", uid) } }
    }

    /** Oppdater by og land. */
    suspend fun updateLocation(city: String, country: String) {
        val uid = Supa.client.auth.currentUserOrNull()?.id ?: return
        Supa.client.from("profiles").update(
            buildJsonObject {
                put("city", city.trim().ifBlank { null })
                put("country", country.trim().ifBlank { null })
            }
        ) { filter { eq("id", uid) } }
    }

    /** Lagre bio. */
    suspend fun saveBio(bio: String) {
        val uid = Supa.client.auth.currentUserOrNull()?.id ?: return
        Supa.client.from("profiles").update(
            buildJsonObject { put("bio", bio.trim().ifBlank { null }) }
        ) { filter { eq("id", uid) } }
    }

    /** Smaksprofil (favoritter) — beregnet fra journalen i basen. */
    suspend fun myFavorites(): ProfileFavorites? {
        Supa.client.auth.currentUserOrNull() ?: return null
        return runCatching {
            Supa.client.postgrest.rpc("get_own_profile_favorites").decodeList<ProfileFavorites>().firstOrNull()
        }.getOrNull()
    }

    /** Last opp avatar (allerede komprimert JPEG), skriv avatar_url. Returnerer ny URL. */
    suspend fun uploadAvatar(jpeg: ByteArray): String? {
        val uid = Supa.client.auth.currentUserOrNull()?.id ?: return null
        val path = "${uid.lowercase()}/avatar.jpg"   // lowercase for RLS
        Supa.client.storage.from("avatars").upload(path, jpeg, upsert = true)
        val url = Supa.client.storage.from("avatars").publicUrl(path) + "?v=${System.currentTimeMillis() / 1000}"
        Supa.client.from("profiles").update(
            buildJsonObject { put("avatar_url", url) }
        ) { filter { eq("id", uid) } }
        return url
    }

    /** Last opp toppbilde (cover), skriv cover_url. Bruker avatars-bøtta (som iOS). */
    suspend fun uploadCover(jpeg: ByteArray): String? {
        val uid = Supa.client.auth.currentUserOrNull()?.id ?: return null
        val path = "${uid.lowercase()}/cover.jpg"   // lowercase for RLS
        Supa.client.storage.from("avatars").upload(path, jpeg, upsert = true)
        val url = Supa.client.storage.from("avatars").publicUrl(path) + "?v=${System.currentTimeMillis() / 1000}"
        Supa.client.from("profiles").update(
            buildJsonObject { put("cover_url", url) }
        ) { filter { eq("id", uid) } }
        return url
    }

    /** Navn/e-post/avatar fra innloggingen (Google-metadata) som fallback. */
    fun authName(): String? = Supa.client.auth.currentUserOrNull()?.userMetadata
        ?.get("full_name")?.toString()?.trim('"')?.ifBlank { null }

    fun authEmail(): String? = Supa.client.auth.currentUserOrNull()?.email

    fun authAvatar(): String? = Supa.client.auth.currentUserOrNull()?.userMetadata
        ?.get("avatar_url")?.toString()?.trim('"')?.ifBlank { null }
}

@Serializable
private data class IdOnly(val id: String)

@Serializable
private data class LogBrandRow(
    val id: String,
    @SerialName("cigars") val cigar: BrandOnly? = null,
)

@Serializable
private data class BrandOnly(val brand: String? = null)
