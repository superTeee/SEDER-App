package com.tomerikheggedal.vitola.data

import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import io.github.jan.supabase.postgrest.rpc

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

    /** Fritekstsøk på merke/serie/form + smaksnoter. Hvert treff sier hva som matchet. */
    suspend fun search(query: String): List<SearchHit> {
        if (query.isBlank()) return emptyList()
        val q = "%$query%"

        // 1) Tekst-treff på merke/serie/form.
        val textHits = Supa.client.from("cigars")
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
            .decodeList<Cigar>()

        // 2) Smaksnote-treff: norsk søkeord → familie(r) → rå DB-notater (engelsk).
        val families = FlavorIcon.familyLabels.filter { it.contains(query, ignoreCase = true) }
        val flavorHits: List<Cigar>
        val flavorLabel: String?
        if (families.isNotEmpty()) {
            val rawNotes = families.flatMap { FlavorIcon.rawNotesFor(it) }.distinct()
            flavorLabel = families.joinToString(", ")
            flavorHits = Supa.client.from("cigars")
                .select {
                    filter {
                        eq("is_public", true)
                        overlaps("flavor_notes", rawNotes)
                    }
                    order("brand", Order.ASCENDING)
                    limit(50)
                }
                .decodeList()
        } else {
            flavorHits = emptyList(); flavorLabel = null
        }

        // 3) Slå sammen: tekst-treff først, deretter smaks-treff som ikke alt er med.
        val textIds = textHits.map { it.id }.toSet()
        val hits = mutableListOf<SearchHit>()
        textHits.forEach { hits.add(SearchHit(it, null)) }
        flavorHits.forEach { if (it.id !in textIds) hits.add(SearchHit(it, flavorLabel)) }
        return hits
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

    /** Brukernes topp 3 — snitt fra reelle stemmer (RPC top_rated_cigars, migrasjon 107). */
    suspend fun topRated(limit: Int = 3): List<Cigar> {
        return Supa.client.postgrest
            .rpc("top_rated_cigars", TopParams(p_limit = limit, p_min_votes = 1))
            .decodeList()
    }

    /** Dagens utvalgte — deterministisk valg per dag fra topp-ratede sigarer (som iOS-fallback).
     *  `gte("avg_rating", 0)` utelukker sigarer uten rating (null-sammenligning er false). */
    suspend fun featured(): Cigar? {
        val pool = Supa.client.from("cigars")
            .select {
                filter {
                    eq("is_public", true)
                    gte("avg_rating", 0)
                }
                order("avg_rating", Order.DESCENDING)
                order("id", Order.ASCENDING)
                limit(500)
            }
            .decodeList<Cigar>()
        if (pool.isEmpty()) return null
        val day = java.time.LocalDate.now().dayOfYear
        return pool[(day - 1).mod(pool.size)]
    }

    // Avansert søk — samme filter-logikk som iOS (applyFilters).
    // Hver kategori er en OR-gruppe; kategoriene AND-es sammen.
    // Bygges inline i begge funksjonene under (samme DSL som search()).

    /** Sigarer som matcher filteret (maks 1000, som iOS). */
    suspend fun filtered(f: CigarFilter): List<Cigar> {
        return Supa.client.from("cigars")
            .select {
                filter {
                    eq("is_public", true)
                    if (f.vitola.isNotEmpty()) or { f.vitola.forEach { ilike("common_format", "%$it%") } }
                    if (f.origin.isNotEmpty()) or { f.origin.forEach { ilike("country_origin", "%$it%") } }
                    if (f.wrapper.isNotEmpty()) or { f.wrapper.forEach { ilike("wrapper_leaf", "%$it%") } }
                    if (f.binder.isNotEmpty()) or { f.binder.forEach { ilike("binder", "%$it%") } }
                    if (f.filler.isNotEmpty()) overlaps("filler", f.filler)
                    if (f.crossSection.isNotEmpty()) or { f.crossSection.forEach { eq("cross_section", it) } }
                    if (f.strength != CigarFilter.FULL) { gte("strength", f.strength.start); lte("strength", f.strength.endInclusive) }
                    if (f.body != CigarFilter.FULL) { gte("body", f.body.start); lte("body", f.body.endInclusive) }
                    if (f.sweetness != CigarFilter.FULL) { gte("sweetness", f.sweetness.start); lte("sweetness", f.sweetness.endInclusive) }
                    if (f.flavorIntensity != CigarFilter.FULL) { gte("flavor_intensity", f.flavorIntensity.start); lte("flavor_intensity", f.flavorIntensity.endInclusive) }
                    f.flavorFamilies.forEach { fam ->
                        val notes = FlavorIcon.rawNotesFor(fam)
                        if (notes.isNotEmpty()) overlaps("flavor_notes", notes)
                    }
                }
                order("brand", Order.ASCENDING)
                order("series", Order.ASCENDING)
                limit(1000)
            }
            .decodeList()
    }

    /** Antall treff for filteret. Henter kun id-kolonnen for å holde det lett. */
    suspend fun countFiltered(f: CigarFilter): Int {
        return Supa.client.from("cigars")
            .select(Columns.list("id")) {
                filter {
                    eq("is_public", true)
                    if (f.vitola.isNotEmpty()) or { f.vitola.forEach { ilike("common_format", "%$it%") } }
                    if (f.origin.isNotEmpty()) or { f.origin.forEach { ilike("country_origin", "%$it%") } }
                    if (f.wrapper.isNotEmpty()) or { f.wrapper.forEach { ilike("wrapper_leaf", "%$it%") } }
                    if (f.binder.isNotEmpty()) or { f.binder.forEach { ilike("binder", "%$it%") } }
                    if (f.filler.isNotEmpty()) overlaps("filler", f.filler)
                    if (f.crossSection.isNotEmpty()) or { f.crossSection.forEach { eq("cross_section", it) } }
                    if (f.strength != CigarFilter.FULL) { gte("strength", f.strength.start); lte("strength", f.strength.endInclusive) }
                    if (f.body != CigarFilter.FULL) { gte("body", f.body.start); lte("body", f.body.endInclusive) }
                    if (f.sweetness != CigarFilter.FULL) { gte("sweetness", f.sweetness.start); lte("sweetness", f.sweetness.endInclusive) }
                    if (f.flavorIntensity != CigarFilter.FULL) { gte("flavor_intensity", f.flavorIntensity.start); lte("flavor_intensity", f.flavorIntensity.endInclusive) }
                    f.flavorFamilies.forEach { fam ->
                        val notes = FlavorIcon.rawNotesFor(fam)
                        if (notes.isNotEmpty()) overlaps("flavor_notes", notes)
                    }
                }
                limit(1000)
            }
            .decodeList<IdRow>()
            .size
    }
}

// Ett søketreff + hva det matchet på (smaksnote-etikett, eller null for tekst-treff).
data class SearchHit(val cigar: Cigar, val matchedFlavor: String?)

@kotlinx.serialization.Serializable
private data class TopParams(val p_limit: Int, val p_min_votes: Int)

@kotlinx.serialization.Serializable
private data class IdRow(val id: String)

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
