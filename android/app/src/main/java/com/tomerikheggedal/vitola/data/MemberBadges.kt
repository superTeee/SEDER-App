package com.tomerikheggedal.vitola.data

// Ansiennitet (Primary) + opptjente merker (Secondary). Samme regler som iOS:
// et nivå krever BÅDE medlemstid OG handlinger.

data class MemberStats(
    val months: Int,
    val journal: Int,        // tasting_logs (røkt/loggført)
    val humidorCigars: Int,  // sigarer i humidorene
    val humidors: Int,       // antall humidor-beholdere
    val rh: Int,             // RH-målinger
    val brands: Int,         // unike merker
)

fun monthsSince(iso: String?): Int {
    if (iso.isNullOrBlank()) return 0
    val start = runCatching { java.time.OffsetDateTime.parse(iso).toLocalDate() }.getOrNull() ?: return 0
    return java.time.Period.between(start, java.time.LocalDate.now())
        .toTotalMonths().toInt().coerceAtLeast(0)
}

fun FriendProfile.memberStats(): MemberStats = MemberStats(
    months = monthsSince(createdAt),
    journal = cigarCount,
    humidorCigars = humidorCount,
    humidors = humidorsCount,
    rh = rhCount,
    brands = brandsTried,
)

enum class MemberLevel(val title: String, val criteria: String) {
    SIGARENTUSIAST("Sigarentusiast", "Fra dag 1"),
    KJENNER("Kjenner", "1 md · 5+ journalinnlegg"),
    SAMLER("Samler", "3 md · 2 humidorer · 10 sigarer · RH-måling"),
    KURATOR("Kurator", "6 md · 3 humidorer · 30 sigarer · 15 journalinnlegg"),
    SIGARAFICIONADO("Sigaraficionado", "12 md · 100+ røkt · 20+ merker");

    fun achieved(s: MemberStats): Boolean = when (this) {
        SIGARENTUSIAST -> true
        KJENNER -> s.months >= 1 && s.journal >= 5
        SAMLER -> s.months >= 3 && s.humidors >= 2 && s.humidorCigars >= 10 && s.rh >= 1
        KURATOR -> s.months >= 6 && s.humidors >= 3 && s.humidorCigars >= 30 && s.journal >= 15
        SIGARAFICIONADO -> s.months >= 12 && s.journal >= 100 && s.brands >= 20
    }

    companion object {
        /** Høyeste sammenhengende oppnådde nivå (stopper ved første hull). */
        fun current(s: MemberStats): MemberLevel {
            var lvl = SIGARENTUSIAST
            for (l in values()) { if (l.achieved(s)) lvl = l else break }
            return lvl
        }
    }
}

data class SecondaryBadge(
    val title: String,
    val subtitle: String,
    val iconKey: String,     // mappes til ikon i UI
    val earned: Boolean,
)

fun secondaryBadges(profile: FriendProfile, stats: MemberStats): List<SecondaryBadge> = listOf(
    SecondaryBadge("Tidlig tester", "Blant de første", "seal", profile.isFoundingMember),
    SecondaryBadge("Anmelder", "50+ vurderinger", "pencil", stats.journal >= 50),
    SecondaryBadge("Bidragsyter", "Godkjente rettelser", "thumb", false),
    SecondaryBadge("Pioner", "Legg til nye sigarer", "add", false),
    SecondaryBadge("Ambassadør", "Verv 3 venner", "people", false),
)
