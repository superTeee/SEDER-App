package com.tomerikheggedal.vitola.data

import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// Ønskeliste — samme "wishlist"-tabell som iOS WishlistService.
object WishlistRepository {

    private fun uid(): String? = Supa.client.auth.currentUserOrNull()?.id

    /** Alle ønskeliste-sigarer for innlogget bruker (nyeste først). */
    suspend fun list(): List<Cigar> {
        val id = uid() ?: return emptyList()
        return Supa.client.from("wishlist")
            .select(Columns.raw("cigar_id, created_at, cigars(*)")) {
                filter { eq("user_id", id) }
                order("created_at", Order.DESCENDING)
            }
            .decodeList<WishlistRow>()
            .map { it.cigars }
    }

    /** Er sigaren allerede i ønskelisten? */
    suspend fun isInWishlist(cigarId: String): Boolean {
        val id = uid() ?: return false
        return Supa.client.from("wishlist")
            .select(Columns.list("id")) {
                filter { eq("user_id", id); eq("cigar_id", cigarId) }
                limit(1)
            }
            .decodeList<IdRow>()
            .isNotEmpty()
    }

    suspend fun add(cigarId: String) {
        val id = uid() ?: error("Ikke innlogget")
        Supa.client.from("wishlist").insert(NewItem(user_id = id, cigar_id = cigarId))
    }

    suspend fun remove(cigarId: String) {
        val id = uid() ?: return
        Supa.client.from("wishlist").delete {
            filter { eq("user_id", id); eq("cigar_id", cigarId) }
        }
    }

    /** Bytt tilstand; returnerer ny tilstand (true = nå i ønskelisten). */
    suspend fun toggle(cigarId: String): Boolean =
        if (isInWishlist(cigarId)) { remove(cigarId); false }
        else { add(cigarId); true }
}

@Serializable
private data class WishlistRow(
    @SerialName("cigar_id") val cigarId: String,
    @SerialName("created_at") val createdAt: String? = null,
    val cigars: Cigar,
)

@Serializable
private data class NewItem(val user_id: String, val cigar_id: String)

@Serializable
private data class IdRow(val id: String)
