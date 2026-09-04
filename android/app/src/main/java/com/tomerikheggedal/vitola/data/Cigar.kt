package com.tomerikheggedal.vitola.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// Matcher "cigars"-tabellen i Supabase (delmengde for MVP: Utforsk + detalj).
@Serializable
data class Cigar(
    val id: String,
    val brand: String,
    val series: String? = null,
    val vitola: String? = null,
    @SerialName("common_format") val commonFormat: String? = null,
    @SerialName("body_type") val bodyType: String? = null,
    @SerialName("country_origin") val countryOrigin: String? = null,
    @SerialName("wrapper_country") val wrapperCountry: String? = null,
    @SerialName("wrapper_leaf") val wrapperLeaf: String? = null,
    val binder: String? = null,
    val filler: List<String>? = null,
    val strength: Double? = null,
    val body: Double? = null,
    val sweetness: Double? = null,
    @SerialName("flavor_intensity") val flavorIntensity: Double? = null,
    @SerialName("flavor_notes") val flavorNotes: List<String>? = null,
    val description: String? = null,
    @SerialName("ring_gauge") val ringGauge: Int? = null,
    @SerialName("length_inches") val lengthInches: Double? = null,
    @SerialName("avg_rating") val avgRating: Double? = null,
    @SerialName("source_tier") val sourceTier: String? = null,
    @SerialName("verified_at") val verifiedAt: String? = null,
) {
    val fullName: String
        get() = listOfNotNull(brand, series, vitola).joinToString(" ")

    /** Merke + serie som ett rent navn, uten gjentatte ord ved siden av
     *  hverandre («Arturo Fuente» + «Fuente Fuente OpusX» → «Arturo Fuente
     *  OpusX»). Speiler iOS Cigar.displayName. */
    val displayName: String
        get() {
            val words = (brand.split(" ") + (series?.split(" ") ?: emptyList()))
                .filter { it.isNotBlank() }
            if (words.isEmpty()) return "Ukjent sigar"
            val out = mutableListOf<String>()
            for (w in words) {
                if (out.lastOrNull()?.lowercase() != w.lowercase()) out.add(w)
            }
            return out.joinToString(" ")
        }

    /** «50 × 4.9"» — null når ett av tallene mangler (halvt mål = ingen mål). */
    val dimensionsLabel: String?
        get() {
            val r = ringGauge ?: return null
            val l = lengthInches ?: return null
            val lStr = if (l % 1.0 == 0.0) l.toInt().toString() else String.format("%.1f", l)
            return "$r × $lStr\""
        }

    val isVerified: Boolean get() = verifiedAt != null

    /** Tillitsmerke-tekst (som iOS). Navngir aldri en forhandler — forhandler-kilde
     *  vises som nøytralt «Verifisert». null = ingen merke (ubekreftet). */
    val verificationLabel: String?
        get() = when (sourceTier) {
            "manufacturer" -> if (isVerified) "Verifisert mot produsent" else null
            "community"    -> if (isVerified) "Bekreftet av brukere" else null
            "retailer"     -> "Verifisert"
            else           -> null
        }
}
