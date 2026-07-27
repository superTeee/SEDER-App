package com.tomerikheggedal.vitola.data

import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import io.github.jan.supabase.storage.storage
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

@Serializable
data class TastingLog(
    val id: String,
    @SerialName("smoked_at") val smokedAt: String,
    val rating: Int? = null,
    @SerialName("smoke_again") val smokeAgain: Boolean? = null,
    @SerialName("personal_notes") val personalNotes: String? = null,
    val store: String? = null,
    @SerialName("photo_url") val photoUrl: String? = null,
    @SerialName("draw_rating") val drawRating: Int? = null,
    @SerialName("burn_rating") val burnRating: Int? = null,
    @SerialName("flavor_rating") val flavorRating: Int? = null,
    @SerialName("cut_type") val cutType: String? = null,
    @SerialName("cigars") val cigar: Cigar? = null,
) {
    // 0–100 personlig score → norsk etikett (samme skala som iOS).
    val scoreLabel: String?
        get() = rating?.let {
            when (it) {
                in 95..100 -> "Eksepsjonell"
                in 90..94 -> "Fremragende"
                in 85..89 -> "Meget bra"
                in 80..84 -> "Bra"
                in 70..79 -> "Grei"
                else -> "Ikke for meg"
            }
        }
}

// Journal = brukerens egne tasting_logs. RLS gir kun egne rader.
object JournalRepository {
    suspend fun myLogs(): List<TastingLog> {
        val uid = Supa.client.auth.currentUserOrNull()?.id ?: return emptyList()
        return Supa.client.from("tasting_logs")
            .select(columns = Columns.raw("id, smoked_at, rating, smoke_again, personal_notes, store, photo_url, draw_rating, burn_rating, flavor_rating, cut_type, cigars(*)")) {
                filter { eq("user_id", uid) }
                order("smoked_at", Order.DESCENDING)
            }
            .decodeList()
    }

    /** Siste røkte sigar (for profilen). */
    suspend fun lastLog(): TastingLog? {
        val uid = Supa.client.auth.currentUserOrNull()?.id ?: return null
        return Supa.client.from("tasting_logs")
            .select(columns = Columns.raw("id, smoked_at, rating, smoke_again, personal_notes, store, photo_url, draw_rating, burn_rating, flavor_rating, cut_type, cigars(*)")) {
                filter { eq("user_id", uid) }
                order("smoked_at", Order.DESCENDING)
                limit(1)
            }
            .decodeList<TastingLog>()
            .firstOrNull()
    }

    /** Oppdater et journalinnlegg. Del-vurderinger 1–5 (null = ikke satt). */
    suspend fun updateLog(
        logId: String, rating: Int?, smokeAgain: Boolean?, notes: String?, store: String?,
        drawRating: Int? = null, burnRating: Int? = null, flavorRating: Int? = null,
        cutType: String? = null, photoUrl: String? = null,
    ) {
        Supa.client.from("tasting_logs").update(
            buildJsonObject {
                put("rating", rating)
                put("smoke_again", smokeAgain)
                put("personal_notes", notes?.ifBlank { null })
                put("store", store?.ifBlank { null })
                put("draw_rating", drawRating)
                put("burn_rating", burnRating)
                put("flavor_rating", flavorRating)
                put("cut_type", cutType)
                if (photoUrl != null) put("photo_url", photoUrl)
            }
        ) { filter { eq("id", logId) } }
    }

    /** Last opp/bytt loggbilde (bucket log-photos, lowercase path). Returnerer URL. */
    suspend fun uploadLogPhoto(logId: String, jpeg: ByteArray): String {
        val uid = Supa.client.auth.currentUserOrNull()?.id ?: error("Ikke innlogget")
        val path = "${uid.lowercase()}/${logId.lowercase()}.jpg"
        Supa.client.storage.from("log-photos").upload(path, jpeg, upsert = true)
        return Supa.client.storage.from("log-photos").publicUrl(path) + "?v=${System.currentTimeMillis() / 1000}"
    }

    /** Slett et journalinnlegg. */
    suspend fun deleteLog(logId: String) {
        Supa.client.from("tasting_logs").delete { filter { eq("id", logId) } }
    }

    /** Logg en røkt sigar. rating = 0–100 (null = ingen poengsum). Returnerer ny log-id. */
    suspend fun addLog(
        cigarId: String,
        rating: Int?,
        smokeAgain: Boolean?,
        notes: String?,
        store: String?,
        humidorEntryId: String? = null,
        drawRating: Int? = null,
        burnRating: Int? = null,
        flavorRating: Int? = null,
    ): String {
        val uid = Supa.client.auth.currentUserOrNull()?.id ?: error("Ikke innlogget")
        val inserted = Supa.client.from("tasting_logs").insert(
            NewLog(
                user_id = uid,
                cigar_id = cigarId,
                humidor_entry_id = humidorEntryId,
                smoked_at = java.time.Instant.now().toString(),
                rating = rating,
                smoke_again = smokeAgain,
                personal_notes = notes?.ifBlank { null },
                store = store?.ifBlank { null },
                draw_rating = drawRating,
                burn_rating = burnRating,
                flavor_rating = flavorRating,
            )
        ) {
            select(Columns.list("id"))
        }.decodeList<LogIdRow>().firstOrNull()
        // Røyker man en sigar fra en humidor, teller vi ned antallet (minst 0) — som iOS.
        if (humidorEntryId != null) {
            runCatching { HumidorRepository.decrementEntry(humidorEntryId) }
        }
        return inserted?.id ?: ""
    }
}

@Serializable
private data class LogIdRow(val id: String)

@Serializable
private data class NewLog(
    val user_id: String,
    val cigar_id: String,
    val humidor_entry_id: String? = null,
    val smoked_at: String,
    val rating: Int? = null,
    val smoke_again: Boolean? = null,
    val personal_notes: String? = null,
    val store: String? = null,
    val draw_rating: Int? = null,
    val burn_rating: Int? = null,
    val flavor_rating: Int? = null,
)
