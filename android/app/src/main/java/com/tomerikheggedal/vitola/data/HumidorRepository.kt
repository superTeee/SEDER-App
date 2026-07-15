package com.tomerikheggedal.vitola.data

import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import kotlinx.serialization.Serializable
import java.time.Instant

@Serializable
data class HumidorRow(val id: String, val name: String)

// Humidor-kall for den innloggede brukeren. RLS i basen sørger for at man bare
// ser/endrer sine egne rader — samme tabeller som iOS ("humidors" + "humidor").
object HumidorRepository {

    /** Brukerens humidorer (RLS filtrerer til eieren). */
    suspend fun myHumidors(): List<HumidorRow> =
        Supa.client.from("humidors")
            .select(columns = Columns.list("id", "name"))
            .decodeList()

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
private data class NewEntry(
    val user_id: String,
    val cigar_id: String,
    val humidor_id: String,
    val quantity: Int,
    val added_to_humidor_at: String
)
