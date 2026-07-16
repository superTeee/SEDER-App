package com.tomerikheggedal.vitola.data

import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
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

/** Én rad i en humidor: sigaren + antall. */
@Serializable
data class HumidorContentRow(
    val quantity: Int? = null,
    @SerialName("added_to_humidor_at") val addedAt: String? = null,
    @SerialName("cigars") val cigar: Cigar? = null,
)

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

    /** Én humidor (metadata). */
    suspend fun humidorById(id: String): HumidorRow? {
        return Supa.client.from("humidors")
            .select(columns = Columns.list("id", "name", "type", "location", "capacity", "image_url")) {
                filter { eq("id", id) }
            }
            .decodeList<HumidorRow>()
            .firstOrNull()
    }

    /** Sigarene i én humidor (med antall > 0). */
    suspend fun humidorContents(humidorId: String): List<HumidorContentRow> {
        val userId = Supa.client.auth.currentUserOrNull()?.id ?: error("Ikke innlogget")
        return Supa.client.from("humidor")
            .select(columns = Columns.raw("quantity, added_to_humidor_at, cigars(*)")) {
                filter {
                    eq("humidor_id", humidorId)
                    eq("user_id", userId)
                }
                order("added_to_humidor_at", Order.DESCENDING)
            }
            .decodeList<HumidorContentRow>()
            .filter { (it.quantity ?: 1) > 0 && it.cigar != null }
    }

    val types = listOf("Desktop", "Travel", "Cabinet", "Electric", "Tupperdor", "Coolidor", "Walk-in")

    /** Opprett en ny humidor for den innloggede brukeren. */
    suspend fun createHumidor(name: String, type: String?, location: String?, capacity: Int?) {
        val userId = Supa.client.auth.currentUserOrNull()?.id ?: error("Ikke innlogget")
        Supa.client.from("humidors").insert(
            NewHumidor(
                user_id = userId,
                name = name,
                type = type,
                location = location?.ifBlank { null },
                capacity = capacity
            )
        )
    }

    /** Legg en sigar i en humidor med antall og valgfri butikk. */
    suspend fun addCigar(cigarId: String, humidorId: String, quantity: Int = 1, store: String? = null) {
        val userId = Supa.client.auth.currentUserOrNull()?.id ?: error("Ikke innlogget")
        Supa.client.from("humidor").insert(
            NewEntry(
                user_id = userId,
                cigar_id = cigarId,
                humidor_id = humidorId,
                quantity = quantity,
                added_to_humidor_at = Instant.now().toString(),
                store = store?.ifBlank { null }
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
private data class NewHumidor(
    val user_id: String,
    val name: String,
    val type: String? = null,
    val location: String? = null,
    val capacity: Int? = null,
)

@Serializable
private data class NewEntry(
    val user_id: String,
    val cigar_id: String,
    val humidor_id: String,
    val quantity: Int,
    val added_to_humidor_at: String,
    val store: String? = null,
)
