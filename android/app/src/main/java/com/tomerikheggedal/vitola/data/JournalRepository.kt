package com.tomerikheggedal.vitola.data

import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class TastingLog(
    val id: String,
    @SerialName("smoked_at") val smokedAt: String,
    val rating: Int? = null,
    @SerialName("personal_notes") val personalNotes: String? = null,
    @SerialName("photo_url") val photoUrl: String? = null,
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
            .select(columns = Columns.raw("id, smoked_at, rating, personal_notes, photo_url, cigars(*)")) {
                filter { eq("user_id", uid) }
                order("smoked_at", Order.DESCENDING)
            }
            .decodeList()
    }
}
