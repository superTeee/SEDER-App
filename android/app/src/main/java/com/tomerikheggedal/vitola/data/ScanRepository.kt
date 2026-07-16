package com.tomerikheggedal.vitola.data

import io.github.jan.supabase.functions.functions
import io.ktor.client.call.body
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// AI-skanning av sigarbånd via Supabase Edge Function "scan-cigar".
// OpenAI-nøkkelen ligger server-side i funksjonen — aldri i appen.
object ScanRepository {

    suspend fun scan(imageJpeg: ByteArray): List<ScanHit> {
        val b64 = android.util.Base64.encodeToString(imageJpeg, android.util.Base64.NO_WRAP)
        val response = Supa.client.functions.invoke("scan-cigar", ScanReq(image = b64, ocr_text = ""))
        val matches: List<AICigarMatch> = response.body()
        // Berik hvert AI-treff med fullt sigar-objekt.
        return matches.mapNotNull { m ->
            runCatching { CigarRepository.byId(m.cigarId) }.getOrNull()
                ?.let { ScanHit(cigar = it, reason = m.reason, exact = m.exactMatch) }
        }
    }
}

data class ScanHit(val cigar: Cigar, val reason: String, val exact: Boolean)

@Serializable
private data class ScanReq(val image: String, val ocr_text: String = "")

@Serializable
private data class AICigarMatch(
    @SerialName("cigar_id") val cigarId: String,
    val confidence: Double = 0.0,
    val reason: String = "",
    @SerialName("exact_match") val exactMatch: Boolean = false,
)
