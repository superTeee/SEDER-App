package com.tomerikheggedal.vitola.data

import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import io.github.jan.supabase.postgrest.rpc
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

// Favoritt-sigarer — samme "favorites"-tabell + get_favorites-RPC som iOS FavoriteService.
object FavoriteRepository {

    private fun uid(): String? = Supa.client.auth.currentUserOrNull()?.id

    /** Alle favoritt-sigarer for innlogget bruker (nyeste først) — brukes i Humidor-fanen. */
    suspend fun list(): List<Cigar> {
        val id = uid() ?: return emptyList()
        return Supa.client.from("favorites")
            .select(Columns.raw("cigar_id, created_at, cigars(*)")) {
                filter { eq("user_id", id) }
                order("created_at", Order.DESCENDING)
            }
            .decodeList<FavoriteRow>()
            .map { it.cigars }
    }

    /** Favorittliste for egen eller venns profil (navn + vitola) via RPC med vennskaps-sjekk. */
    suspend fun favoriteList(userId: String): List<FavoriteListItem> =
        Supa.client.postgrest
            .rpc("get_favorites", buildJsonObject { put("p_user_id", userId) })
            .decodeList()

    suspend fun isFavorite(cigarId: String): Boolean {
        val id = uid() ?: return false
        return Supa.client.from("favorites")
            .select(Columns.list("id")) {
                filter { eq("user_id", id); eq("cigar_id", cigarId) }
                limit(1)
            }
            .decodeList<FavIdRow>()
            .isNotEmpty()
    }

    suspend fun add(cigarId: String) {
        val id = uid() ?: error("Ikke innlogget")
        Supa.client.from("favorites").insert(FavNewItem(user_id = id, cigar_id = cigarId))
    }

    suspend fun remove(cigarId: String) {
        val id = uid() ?: return
        Supa.client.from("favorites").delete {
            filter { eq("user_id", id); eq("cigar_id", cigarId) }
        }
    }

    /** Bytt tilstand; returnerer ny tilstand (true = nå favoritt). */
    suspend fun toggle(cigarId: String): Boolean =
        if (isFavorite(cigarId)) { remove(cigarId); false }
        else { add(cigarId); true }
}

// Én favoritt slik den vises på profilen (navn + vitola nå; rating/butikk kan legges på senere).
@Serializable
data class FavoriteListItem(
    @SerialName("cigar_id") val cigarId: String,
    val brand: String,
    val series: String? = null,
    val vitola: String? = null,
)

@Serializable
private data class FavoriteRow(
    @SerialName("cigar_id") val cigarId: String,
    @SerialName("created_at") val createdAt: String? = null,
    val cigars: Cigar,
)

@Serializable
private data class FavNewItem(val user_id: String, val cigar_id: String)

@Serializable
private data class FavIdRow(val id: String)
