package com.tomerikheggedal.vitola.data

import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.rpc
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// Aggregert statistikk for innlogget bruker (get_user_stats RPC — samme som iOS).
@Serializable
data class UserStats(
    @SerialName("total_logged") val totalLogged: Int = 0,
    @SerialName("brands_tried") val brandsTried: Int = 0,
    @SerialName("avg_score") val avgScore: Int? = null,
    @SerialName("strength_avg") val strengthAvg: Double? = null,
    @SerialName("humidor_value") val humidorValue: Double = 0.0,
    @SerialName("top_brands") val topBrands: List<TopBrand> = emptyList(),
    @SerialName("score_series") val scoreSeries: List<ScorePoint> = emptyList(),
)

@Serializable
data class TopBrand(val brand: String, val n: Int)

// d = smoked_at (ISO-tidsstempel), s = score (0–100)
@Serializable
data class ScorePoint(val d: String, val s: Int)

object StatsRepository {
    suspend fun myStats(): UserStats? {
        Supa.client.auth.currentUserOrNull() ?: return null
        return runCatching {
            Supa.client.postgrest.rpc("get_user_stats").decodeAs<UserStats>()
        }.getOrNull()
    }
}
