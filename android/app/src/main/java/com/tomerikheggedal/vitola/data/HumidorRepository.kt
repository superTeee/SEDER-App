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
import java.time.Instant

@Serializable
data class HumidorRow(
    val id: String,
    val name: String,
    val type: String? = null,
    val location: String? = null,
    val capacity: Int? = null,
    @SerialName("image_url") val imageUrl: String? = null,
    @SerialName("target_rh") val targetRh: Int? = null,
    @SerialName("rh_min") val rhMin: Int? = null,
    @SerialName("rh_max") val rhMax: Int? = null,
) {
    /** «69 %» eller «67–71 %» — mål-RH for visning, eller null. */
    val rhTargetLabel: String?
        get() = when {
            rhMin != null && rhMax != null -> "$rhMin–$rhMax %"
            targetRh != null -> "$targetRh %"
            else -> null
        }
}

// Én registrert RH-måling. Matcher humidor_rh_readings-tabellen.
@Serializable
data class RhReading(
    val id: String,
    @SerialName("humidor_id") val humidorId: String,
    val rh: Double,
    val temperature: Double? = null,
    val note: String? = null,
    @SerialName("measured_at") val measuredAt: String,
)

// Rolig status basert på siste MÅLTE RH mot mål/område (samme logikk som iOS).
enum class RhStatus(val label: String) {
    NONE("Ingen målinger"),
    TOO_DRY("For tørr"),
    SLIGHTLY_LOW("Litt under målet"),
    STABLE("Stabil"),
    SLIGHTLY_HIGH("Litt over målet"),
    TOO_WET("For fuktig"),
}

fun rhStatus(rh: Double?, targetRh: Int?, rhMin: Int?, rhMax: Int?): RhStatus {
    if (rh == null) return RhStatus.NONE
    if (rhMin != null && rhMax != null) {
        return when {
            rh < rhMin - 3 -> RhStatus.TOO_DRY
            rh < rhMin -> RhStatus.SLIGHTLY_LOW
            rh <= rhMax -> RhStatus.STABLE
            rh <= rhMax + 3 -> RhStatus.SLIGHTLY_HIGH
            else -> RhStatus.TOO_WET
        }
    }
    if (targetRh != null) {
        val d = rh - targetRh
        return when {
            d < -4 -> RhStatus.TOO_DRY
            d < -1 -> RhStatus.SLIGHTLY_LOW
            d <= 1 -> RhStatus.STABLE
            d <= 4 -> RhStatus.SLIGHTLY_HIGH
            else -> RhStatus.TOO_WET
        }
    }
    return RhStatus.STABLE
}

/** Humidor + antall sigarer (antall regnes separat, ikke fra tabellen). */
data class HumidorUi(val row: HumidorRow, val count: Int)

/** Én rad i en humidor: sigaren + antall. */
@Serializable
data class HumidorContentRow(
    val id: String? = null,   // oppførings-id (for flytt/fjern)
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
            .select(columns = Columns.list("id", "name", "type", "location", "capacity", "image_url", "target_rh", "rh_min", "rh_max"))
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
            .select(columns = Columns.list("id", "name", "type", "location", "capacity", "image_url", "target_rh", "rh_min", "rh_max")) {
                filter { eq("id", id) }
            }
            .decodeList<HumidorRow>()
            .firstOrNull()
    }

    /** Sigarene i én humidor (med antall > 0). */
    suspend fun humidorContents(humidorId: String): List<HumidorContentRow> {
        val userId = Supa.client.auth.currentUserOrNull()?.id ?: error("Ikke innlogget")
        return Supa.client.from("humidor")
            .select(columns = Columns.raw("id, quantity, added_to_humidor_at, cigars(*)")) {
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

    // Kort forklaring per type — så en nybegynner forstår forskjellen.
    val typeExplanations = mapOf(
        "Desktop" to "Klassisk humidor for hjemmebruk og mindre samlinger.",
        "Travel" to "Robust humidor for reise og kortvarig transport.",
        "Cabinet" to "Større humidor for mange sigarer og mer organisert lagring.",
        "Electric" to "Elektrisk humidor med bedre kontroll på temperatur og/eller fuktighet.",
        "Tupperdor" to "Lufttett plastboks med enkel og effektiv fuktkontroll.",
        "Coolidor" to "Kjøleboks brukt som rimelig og stabil lagringsløsning.",
        "Walk-in" to "Et helt rom eller avlukke med kontrollert klima.",
    )

    /** Opprett en ny humidor for den innloggede brukeren. */
    suspend fun createHumidor(
        name: String, type: String?, location: String?, capacity: Int?,
        targetRh: Int? = null, rhMin: Int? = null, rhMax: Int? = null,
    ) {
        val userId = Supa.client.auth.currentUserOrNull()?.id ?: error("Ikke innlogget")
        Supa.client.from("humidors").insert(
            NewHumidor(
                user_id = userId,
                name = name,
                type = type,
                location = location?.ifBlank { null },
                capacity = capacity,
                target_rh = targetRh,
                rh_min = rhMin,
                rh_max = rhMax,
            )
        )
    }

    /** Alle RH-målinger for en humidor, nyeste først. */
    suspend fun readings(humidorId: String): List<RhReading> {
        return Supa.client.from("humidor_rh_readings")
            .select(columns = Columns.list("id", "humidor_id", "rh", "temperature", "note", "measured_at")) {
                filter { eq("humidor_id", humidorId) }
                order("measured_at", Order.DESCENDING)
            }
            .decodeList()
    }

    /** Registrer en ny RH-måling. user_id settes av DB via auth.uid(). */
    suspend fun addReading(humidorId: String, rh: Double, temperature: Double?, note: String?, measuredAt: String) {
        Supa.client.from("humidor_rh_readings").insert(
            NewRhReading(
                humidor_id = humidorId,
                rh = rh,
                temperature = temperature,
                note = note?.ifBlank { null },
                measured_at = measuredAt,
            )
        )
    }

    /** Humidor-oppføringens id hvis sigaren allerede ligger i en av brukerens humidorer. */
    suspend fun entryIdForCigar(cigarId: String): String? {
        val userId = Supa.client.auth.currentUserOrNull()?.id ?: return null
        return Supa.client.from("humidor")
            .select(columns = Columns.list("id")) {
                filter { eq("user_id", userId); eq("cigar_id", cigarId) }
                limit(1)
            }
            .decodeList<EntryIdRow>()
            .firstOrNull()?.id
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

    // MARK: Rediger/slett humidor + flytt/fjern oppføring — samme tabeller som iOS.

    /** Oppdater en humidor. */
    suspend fun updateHumidor(
        id: String, name: String, type: String?, location: String?, capacity: Int?,
        targetRh: Int? = null, rhMin: Int? = null, rhMax: Int? = null,
    ) {
        Supa.client.from("humidors").update(
            HumidorPatch(
                name = name, type = type, location = location?.ifBlank { null }, capacity = capacity,
                target_rh = targetRh, rh_min = rhMin, rh_max = rhMax,
            )
        ) { filter { eq("id", id) } }
    }

    /** Slett en humidor. Sigarene beholdes (humidor_id → null via ON DELETE SET NULL). */
    suspend fun deleteHumidor(id: String) {
        Supa.client.from("humidors").delete { filter { eq("id", id) } }
    }

    /** Flytt en sigar-oppføring til en annen humidor. */
    suspend fun moveEntry(entryId: String, toHumidorId: String) {
        Supa.client.from("humidor").update(
            buildJsonObject { put("humidor_id", toHumidorId) }
        ) { filter { eq("id", entryId) } }
    }

    /** Fjern en sigar-oppføring helt fra humidoren. */
    suspend fun removeEntry(entryId: String) {
        Supa.client.from("humidor").delete { filter { eq("id", entryId) } }
    }

    /** Sett nytt antall på en oppføring. */
    suspend fun updateQuantity(entryId: String, quantity: Int) {
        Supa.client.from("humidor").update(
            buildJsonObject { put("quantity", quantity) }
        ) { filter { eq("id", entryId) } }
    }

    /** Dekrementer antall med 1 (minst 0) — brukes når man markerer en sigar som røkt. */
    suspend fun decrementEntry(entryId: String) {
        val current = Supa.client.from("humidor")
            .select(columns = Columns.list("quantity")) { filter { eq("id", entryId) } }
            .decodeList<QuantityRow>()
            .firstOrNull()?.quantity ?: return
        updateQuantity(entryId, (current - 1).coerceAtLeast(0))
    }

    /** Last opp forsidebilde (bucket: humidor-covers, lowercase path for RLS) og skriv image_url. */
    suspend fun uploadCover(humidorId: String, imageJpeg: ByteArray) {
        val userId = Supa.client.auth.currentUserOrNull()?.id ?: error("Ikke innlogget")
        val path = "${userId.lowercase()}/${humidorId.lowercase()}.jpg"
        Supa.client.storage.from("humidor-covers").upload(path, imageJpeg, upsert = true)
        // Cache-buster så det nye bildet vises (path er deterministisk).
        val url = Supa.client.storage.from("humidor-covers").publicUrl(path) +
            "?v=${System.currentTimeMillis() / 1000}"
        Supa.client.from("humidors").update(
            buildJsonObject { put("image_url", url) }
        ) { filter { eq("id", humidorId) } }
    }
}

@Serializable
private data class EntryIdRow(val id: String)

@Serializable
private data class QuantityRow(val quantity: Int? = null)

@Serializable
private data class HumidorPatch(
    val name: String,
    val type: String? = null,
    val location: String? = null,
    val capacity: Int? = null,
    val target_rh: Int? = null,
    val rh_min: Int? = null,
    val rh_max: Int? = null,
)

@Serializable
private data class NewRhReading(
    val humidor_id: String,
    val rh: Double,
    val temperature: Double? = null,
    val note: String? = null,
    val measured_at: String,
)

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
    val target_rh: Int? = null,
    val rh_min: Int? = null,
    val rh_max: Int? = null,
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
