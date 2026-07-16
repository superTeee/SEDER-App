package com.tomerikheggedal.vitola.data

import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
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
    val bio: String? = null,
    val city: String? = null,
    val country: String? = null,
)

data class ProfileStats(
    val cigars: Int,        // Røkt (tasting_logs)
    val humidorEntries: Int, // I humidor
    val brandsTried: Int,    // Merker prøvd
    val friends: Int,        // Venner
)

// Egen profil + stats for innlogget bruker (samme tabeller som iOS).
object ProfileRepository {

    suspend fun myProfile(): Profile? {
        val uid = Supa.client.auth.currentUserOrNull()?.id ?: return null
        return Supa.client.from("profiles")
            .select(columns = Columns.list("id", "display_name", "friend_code", "avatar_url", "bio", "city", "country")) {
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
