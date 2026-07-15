package com.tomerikheggedal.vitola.data

import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.gotrue.Auth
import io.github.jan.supabase.postgrest.Postgrest

// Samme Vitola-prosjekt som iOS (ref: wpcricosogcmzebkplwp).
// Anon-nøkkelen er trygg i kildekode — RLS beskytter dataene i basen.
object Supa {
    val client = createSupabaseClient(
        supabaseUrl = "https://wpcricosogcmzebkplwp.supabase.co",
        supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndwY3JpY29zb2djbXplYmtwbHdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE1NjE0OTQsImV4cCI6MjA5NzEzNzQ5NH0.wdTDMuY1EzZFkoFdLP-HKx-Jx_cfT1OlPjMpet9gL44"
    ) {
        install(Postgrest)
        install(Auth) {
            // Nettleser-basert OAuth redirecter tilbake hit etter innlogging.
            // Samme verdier legges inn som Redirect URL i Supabase Auth-innstillingene:
            //   com.tomerikheggedal.vitola://login-callback
            scheme = "com.tomerikheggedal.vitola"
            host = "login-callback"
        }
    }
}
