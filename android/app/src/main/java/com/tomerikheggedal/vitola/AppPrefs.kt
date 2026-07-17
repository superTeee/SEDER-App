package com.tomerikheggedal.vitola

import android.content.Context
import java.security.MessageDigest

// Lokale flagg/PIN (iOS bruker UserDefaults + Keychain). PIN-en låser kun opp en
// allerede aktiv Supabase-sesjon lokalt — den erstatter ikke passord/server-innlogging.
object AppPrefs {
    private const val FILE = "vitola_prefs"
    private const val KEY_AGE = "hasVerifiedAge"
    private const val KEY_PRIVACY = "hasAcceptedPrivacy"
    private const val KEY_PIN = "pinHash"

    private fun p(ctx: Context) = ctx.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    fun hasVerifiedAge(ctx: Context) = p(ctx).getBoolean(KEY_AGE, false)
    fun setAgeVerified(ctx: Context) = p(ctx).edit().putBoolean(KEY_AGE, true).apply()

    fun hasAcceptedPrivacy(ctx: Context) = p(ctx).getBoolean(KEY_PRIVACY, false)
    fun setPrivacyAccepted(ctx: Context) = p(ctx).edit().putBoolean(KEY_PRIVACY, true).apply()

    fun isPinSet(ctx: Context) = p(ctx).getString(KEY_PIN, null) != null
    fun setPin(ctx: Context, pin: String) = p(ctx).edit().putString(KEY_PIN, sha256(pin)).apply()
    fun clearPin(ctx: Context) = p(ctx).edit().remove(KEY_PIN).apply()
    fun verifyPin(ctx: Context, pin: String): Boolean =
        p(ctx).getString(KEY_PIN, null)?.let { it == sha256(pin) } ?: false

    private fun sha256(s: String): String =
        MessageDigest.getInstance("SHA-256").digest(s.toByteArray()).joinToString("") { "%02x".format(it) }
}
