package com.tomerikheggedal.vitola.data

import android.content.Context

// Nylige søk lagret lokalt (SharedPreferences) — samme oppførsel som iOS:
// nyeste først, dedup (case-insensitivt), maks 10.
object SearchHistory {
    private const val PREFS = "vitola_prefs"
    private const val KEY = "recent_searches"
    private const val SEP = "§"
    private const val MAX = 10

    private fun Context.prefs() = getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun load(ctx: Context): List<String> =
        (ctx.prefs().getString(KEY, "") ?: "").split(SEP).filter { it.isNotBlank() }

    fun add(ctx: Context, term: String): List<String> {
        val t = term.trim()
        if (t.isBlank()) return load(ctx)
        val list = load(ctx).toMutableList()
        list.removeAll { it.equals(t, ignoreCase = true) }
        list.add(0, t)
        val capped = list.take(MAX)
        ctx.prefs().edit().putString(KEY, capped.joinToString(SEP)).apply()
        return capped
    }

    fun remove(ctx: Context, term: String): List<String> {
        val list = load(ctx).filter { it != term }
        ctx.prefs().edit().putString(KEY, list.joinToString(SEP)).apply()
        return list
    }
}
