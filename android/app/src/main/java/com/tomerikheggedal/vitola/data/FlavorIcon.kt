package com.tomerikheggedal.vitola.data

import androidx.annotation.DrawableRes
import com.tomerikheggedal.vitola.R

// Smaksnote → ikon-familie (samme kart som iOS). Case-insensitivt.
// Ikonene ligger som vector drawables (res/drawable/flavor_*.xml) og tintes
// til Accent i UI-et.
object FlavorIcon {

    private val map: Map<String, String> = mapOf(
        "almond" to "nuts",
        "almonds" to "nuts",
        "anise" to "cinnamon",
        "black pepper" to "pepper",
        "butter" to "cream",
        "caramel" to "honey",
        "cardamom" to "cinnamon",
        "cedar" to "cedar",
        "chocolate" to "cocoa",
        "cinnamon" to "cinnamon",
        "citrus" to "citrus",
        "cocoa" to "cocoa",
        "coffee" to "coffee",
        "cream" to "cream",
        "dark chocolate" to "cocoa",
        "dark cocoa" to "cocoa",
        "dark earth" to "earth",
        "dark fruit" to "fruit",
        "dark roasted coffee" to "coffee",
        "dark spice" to "spice",
        "dark tobacco" to "tobacco",
        "dried fruit" to "fruit",
        "earth" to "earth",
        "espresso" to "coffee",
        "floral" to "floral",
        "fruit" to "fruit",
        "gentle earth" to "earth",
        "gentle floral" to "floral",
        "gentle pepper" to "pepper",
        "gentle spice" to "spice",
        "grass" to "hay",
        "hay" to "hay",
        "honey" to "honey",
        "kremete" to "cream",
        "leather" to "leather",
        "light earth" to "earth",
        "light floral" to "floral",
        "light pepper" to "pepper",
        "light spice" to "spice",
        "light wood" to "wood",
        "maple" to "honey",
        "mild coffee" to "coffee",
        "mild cream" to "cream",
        "mild earth" to "earth",
        "mild krydder" to "spice",
        "mild pepper" to "pepper",
        "mild spice" to "spice",
        "mineral" to "minerals",
        "minerals" to "minerals",
        "mint" to "mint",
        "minty" to "mint",
        "molasses" to "honey",
        "mynte" to "mint",
        "natural sweetness" to "honey",
        "nougat" to "nuts",
        "nut" to "nuts",
        "nuts" to "nuts",
        "nøtter" to "nuts",
        "oak" to "wood",
        "paprika" to "pepper",
        "pepper" to "pepper",
        "peppermint" to "mint",
        "roasted almonds" to "nuts",
        "roasted aromas" to "coffee",
        "roasted cashews" to "nuts",
        "roasted coffee" to "coffee",
        "roasted espresso" to "coffee",
        "roasted nuts" to "nuts",
        "sedertre" to "cedar",
        "smoky wood" to "wood",
        "soft spice" to "spice",
        "spearmint" to "mint",
        "spice" to "spice",
        "sweet cream" to "cream",
        "sweet earth" to "earth",
        "sweet spice" to "spice",
        "sweet spices" to "spice",
        "toast" to "toast",
        "toasted bread" to "toast",
        "toasted cream" to "cream",
        "toasted nuts" to "nuts",
        "toasted wood" to "wood",
        "tobacco" to "tobacco",
        "vanilla" to "vanilla",
        "whiskey" to "whisky",
        "white pepper" to "pepper",
        "wood" to "wood",
    )

    // Ikon-familie → norsk etikett (appen er på norsk).
    private val label: Map<String, String> = mapOf(
        "cedar" to "Sedertre", "cocoa" to "Kakao", "leather" to "Lær", "tobacco" to "Tobakk",
        "cinnamon" to "Kanel", "minerals" to "Mineral", "whisky" to "Whisky", "citrus" to "Sitrus",
        "wood" to "Tre", "pepper" to "Pepper", "nuts" to "Nøtter", "vanilla" to "Vanilje",
        "earth" to "Jord", "fruit" to "Frukt", "floral" to "Blomst", "hay" to "Høy",
        "coffee" to "Kaffe", "honey" to "Honning", "toast" to "Toast", "cream" to "Kremete",
        "spice" to "Krydder", "mint" to "Mynte",
    )

    // Ikon-familie → drawable-ressurs.
    @DrawableRes
    private fun drawable(icon: String): Int? = when (icon) {
        "cedar" -> R.drawable.flavor_cedar
        "cinnamon" -> R.drawable.flavor_cinnamon
        "citrus" -> R.drawable.flavor_citrus
        "cocoa" -> R.drawable.flavor_cocoa
        "coffee" -> R.drawable.flavor_coffee
        "cream" -> R.drawable.flavor_cream
        "earth" -> R.drawable.flavor_earth
        "floral" -> R.drawable.flavor_floral
        "fruit" -> R.drawable.flavor_fruit
        "hay" -> R.drawable.flavor_hay
        "honey" -> R.drawable.flavor_honey
        "leather" -> R.drawable.flavor_leather
        "minerals" -> R.drawable.flavor_minerals
        "mint" -> R.drawable.flavor_mint
        "nuts" -> R.drawable.flavor_nuts
        "pepper" -> R.drawable.flavor_pepper
        "spice" -> R.drawable.flavor_spice
        "toast" -> R.drawable.flavor_toast
        "tobacco" -> R.drawable.flavor_tobacco
        "vanilla" -> R.drawable.flavor_vanilla
        "whisky" -> R.drawable.flavor_whisky
        "wood" -> R.drawable.flavor_wood
        else -> null
    }

    /** Ikon (drawable-id) + norsk etikett for en smaksnote, eller null om ukjent. */
    fun forNote(note: String): FlavorMatch? {
        val icon = map[note.lowercase().trim()] ?: return null
        val res = drawable(icon) ?: return null
        return FlavorMatch(res, label[icon] ?: note.replaceFirstChar { it.uppercase() })
    }

    /** Norske smaksnote-familier (for filter-chips), alfabetisk. */
    val familyLabels: List<String> = label.values.distinct().sorted()

    /** Alle rå DB-notater som hører til en norsk familie-etikett (for filter-overlaps). */
    fun rawNotesFor(familyLabel: String): List<String> {
        val family = label.entries.firstOrNull { it.value == familyLabel }?.key ?: return emptyList()
        return map.filterValues { it == family }.keys.toList()
    }
}

data class FlavorMatch(@DrawableRes val drawable: Int, val label: String)
