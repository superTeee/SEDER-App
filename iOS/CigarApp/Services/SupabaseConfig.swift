import Foundation
import Supabase

// MARK: - Supabase klient (singleton)
// Disse verdiene finner du i Supabase Dashboard → Settings → API

enum SupabaseConfig {
    // Vitola-prosjektet (ref: wpcricosogcmzebkplwp)
    static let projectURL = URL(string: "https://wpcricosogcmzebkplwp.supabase.co")!
    static let anonKey    = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndwY3JpY29zb2djbXplYmtwbHdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE1NjE0OTQsImV4cCI6MjA5NzEzNzQ5NH0.wdTDMuY1EzZFkoFdLP-HKx-Jx_cfT1OlPjMpet9gL44"
}

// Global klient-instans — brukes overalt i appen
let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.projectURL,
    supabaseKey: SupabaseConfig.anonKey
)
