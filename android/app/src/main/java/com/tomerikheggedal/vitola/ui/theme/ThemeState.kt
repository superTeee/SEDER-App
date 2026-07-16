package com.tomerikheggedal.vitola.ui.theme

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

// Brukervalgt tema. "system" følger enheten, ellers tvunget lys/mørk.
// Reaktiv Compose-state så endring i Innstillinger slår gjennom umiddelbart.
object ThemeState {
    private const val PREFS = "vitola_prefs"
    private const val KEY = "theme_mode"

    var mode by mutableStateOf("system")
        private set

    fun load(ctx: Context) {
        mode = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, "system") ?: "system"
    }

    fun set(ctx: Context, newMode: String) {
        mode = newMode
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, newMode).apply()
    }

    fun isDark(systemDark: Boolean): Boolean = when (mode) {
        "dark" -> true
        "light" -> false
        else -> systemDark
    }
}
