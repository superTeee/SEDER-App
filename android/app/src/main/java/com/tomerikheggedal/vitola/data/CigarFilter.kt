package com.tomerikheggedal.vitola.data

// Avansert søk — samme kategorier som iOS. Tomme lister / fulle 1–5-områder
// betyr «ingen begrensning».
data class CigarFilter(
    val vitola: List<String> = emptyList(),
    val crossSection: List<String> = emptyList(),
    val origin: List<String> = emptyList(),
    val wrapper: List<String> = emptyList(),
    val binder: List<String> = emptyList(),
    val filler: List<String> = emptyList(),
    val flavorFamilies: List<String> = emptyList(),   // norske familie-etiketter
    val strength: ClosedFloatingPointRange<Float> = FULL,
    val body: ClosedFloatingPointRange<Float> = FULL,
    val sweetness: ClosedFloatingPointRange<Float> = FULL,
    val flavorIntensity: ClosedFloatingPointRange<Float> = FULL,
) {
    val isActive: Boolean
        get() = vitola.isNotEmpty() || crossSection.isNotEmpty() || origin.isNotEmpty() ||
            wrapper.isNotEmpty() || binder.isNotEmpty() || filler.isNotEmpty() ||
            flavorFamilies.isNotEmpty() ||
            strength != FULL || body != FULL || sweetness != FULL || flavorIntensity != FULL

    companion object {
        val FULL: ClosedFloatingPointRange<Float> = 1f..5f

        // Faste valglister — identiske med iOS.
        val VITOLA = listOf(
            "Toro", "Robusto", "Gordo", "Corona Gorda", "Churchill", "Corona",
            "Lancero", "Torpedo", "Belicoso", "Figurado", "Panatela", "Petit Corona"
        )
        val VITOLA_SIZES = mapOf(
            "Toro" to "50 × 6\"", "Robusto" to "50 × 5\"", "Gordo" to "60 × 6\"",
            "Corona Gorda" to "46 × 5.6\"", "Churchill" to "48 × 7\"", "Corona" to "42 × 5.5\"",
            "Lancero" to "38 × 7.5\"", "Torpedo" to "52 × 6.1\"", "Belicoso" to "52 × 5.5\"",
            "Panatela" to "38 × 6\"", "Petit Corona" to "42 × 4.5\""
        )
        val CROSS_SECTION = listOf("Box Pressed", "Oval", "Hexagonal")
        val ORIGIN = listOf(
            "Nicaragua", "Dominican Republic", "Honduras", "Cuba", "Mexico",
            "Ecuador", "Peru", "Costa Rica", "Panama", "USA"
        )
        val WRAPPER = listOf(
            "Connecticut Shade", "Ecuador Connecticut", "San Andrés", "Cameroon",
            "Sumatra", "Broadleaf", "Habano", "Colorado Claro", "Maduro", "Corojo"
        )
        val BINDER = listOf(
            "Nicaraguan", "Dominican", "Honduran", "Mexican San Andrés",
            "Ecuadorian", "Connecticut", "Sumatran", "Cameroon"
        )
        val FILLER = listOf(
            "Nicaraguan", "Dominican Republic", "Honduras", "Cuba", "Mexico",
            "Ecuador", "Peru", "Pennsylvania"
        )
    }
}
