package com.tomerikheggedal.vitola.data

import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Order

// Alle databasekall for sigarer. Samme tabell/RPC-er som iOS bruker.
object CigarRepository {

    /** Merker (unike) med antall — for Utforsk-lista. */
    suspend fun brands(): List<BrandSummary> {
        val rows = Supa.client.from("cigars")
            .select(columns = io.github.jan.supabase.postgrest.query.Columns.list("brand", "series")) {
                filter { eq("is_public", true) }
            }
            .decodeList<BrandRow>()

        return rows.groupBy { it.brand }
            .map { (brand, list) ->
                BrandSummary(
                    brand = brand,
                    cigarCount = list.size,
                    seriesCount = list.mapNotNull { it.series }.toSet().size
                )
            }
            .sortedBy { it.brand.lowercase() }
    }

    /** Fritekstsøk på merke/serie/vitola. */
    suspend fun search(query: String): List<Cigar> {
        if (query.isBlank()) return emptyList()
        val q = "%$query%"
        return Supa.client.from("cigars")
            .select {
                filter {
                    eq("is_public", true)
                    or {
                        ilike("brand", q)
                        ilike("series", q)
                        ilike("vitola", q)
                    }
                }
                order("brand", Order.ASCENDING)
                limit(50)
            }
            .decodeList()
    }

    /** Alle sigarer for ett merke. */
    suspend fun byBrand(brand: String): List<Cigar> {
        return Supa.client.from("cigars")
            .select {
                filter {
                    eq("is_public", true)
                    eq("brand", brand)
                }
                order("series", Order.ASCENDING)
            }
            .decodeList()
    }

    /** Én sigar. */
    suspend fun byId(id: String): Cigar? {
        return Supa.client.from("cigars")
            .select { filter { eq("id", id) } }
            .decodeList<Cigar>()
            .firstOrNull()
    }
}

@kotlinx.serialization.Serializable
private data class BrandRow(
    val brand: String,
    val series: String? = null,
)

data class BrandSummary(
    val brand: String,
    val cigarCount: Int,
    val seriesCount: Int,
) {
    val subtitle: String
        get() {
            val parts = mutableListOf<String>()
            if (seriesCount > 1) parts.add("$seriesCount serier")
            parts.add("$cigarCount ${if (cigarCount == 1) "sigar" else "sigarer"}")
            return parts.joinToString(" · ")
        }
}
