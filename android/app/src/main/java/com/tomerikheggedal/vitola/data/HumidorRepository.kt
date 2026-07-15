package com.tomerikheggedal.vitola.data

import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.time.Instant

@Serializable
data class HumidorRow(
    val id: String,
    val name: String,
    val type: String? = null,
    val location: String? = null,
    val capacity: Int? = null,
    @SerialName("image_url") val imageUrl: String? = null,
)

/** Humidor + antall sigarer (antall regnes separat, ikke fra tabellen). */
data class HumidorUi(val row: HumidorRow, val count: Int)

// Humidor-kall for den innloggede brukeren. RLS i basen sørger for at man bare
// ser/endrer sine egne rader — samme tabeller som iOS ("humidors" + "humidor").
object HumidorRepository {

    /** Brukerens humidorer med antall sigarer. */
    suspend fun myHumidors(): List<HumidorUi> {
        val humidors = Supa.client.from("humidors")
            .select(columns = Columns.list("id", "name", "type", "location", "capacity", "image_url"))
            .decodeList<HumidorRow>()

        val entries = Supa.client.from("humidor")
            .select(columns = Columns.list("humidor_id", "quantity"))
            .decodeList<EntryCount>()

        val counts = entries
            .filter { it.humidor_id != null }
            .groupBy { it.humidor_id!! }
            .mapValues { (_, list) -> list.sumOf { it.quantity ?: 1 } }

        return humidors.map { HumidorUi(it, counts[it.id] ?: 0) }
    }

    /** Legg én sigar i en humidor (antall 1). */
    suspend fun addCigar(cigarId: String, humidorId: String) {
        val userId = Supa.client.auth.currentUserOrNull()?.id ?: error("Ikke innlogget")
        Supa.client.from("humidor").insert(
            NewEntry(
                user_id = userId,
                cigar_id = cigarId,
                humidor_id = humidorId,
                quantity = 1,
                added_to_humidor_at = Instant.now().toString()
            )
        )
    }
}

@Serializable
private data class EntryCount(
    val humidor_id: String? = null,
    val quantity: Int? = null,
)

@Serializable
private data class NewEntry(
    val user_id: String,
    val cigar_id: String,
    val humidor_id: String,
    val quantity: Int,
    val added_to_humidor_at: String
)
