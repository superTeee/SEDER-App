package com.tomerikheggedal.vitola.data

import android.util.Base64
import io.github.jan.supabase.functions.functions
import io.ktor.client.call.body
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// Kvittering → humidor. Speiler iOS ReceiptService: sender kvittering-bildet til
// parse-receipt edge function, som leser varelinjene med GPT-vision og matcher
// hver mot databasen via match_cigar. Returnerer treff + ikke-funnet.
object ReceiptRepository {

    /** Les en kvittering og få tilbake matchede + ukjente varelinjer. */
    suspend fun parseReceipt(imageJpeg: ByteArray): ReceiptParseResult {
        val b64 = Base64.encodeToString(imageJpeg, Base64.NO_WRAP)
        return Supa.client.functions
            .invoke("parse-receipt", ReceiptReq(image = b64))
            .body()
    }
}

@Serializable
private data class ReceiptReq(val image: String)

/** En varelinje som ble matchet mot en sigar i databasen. */
@Serializable
data class ReceiptMatchedLine(
    @SerialName("cigar_id") val cigarId: String,
    val brand: String,
    val series: String? = null,
    val vitola: String? = null,
    @SerialName("receipt_name") val receiptName: String,
    val quantity: Int = 1,
    @SerialName("unit_price") val unitPrice: Double? = null,
    val score: Double = 0.0,
)

/** En varelinje appen ikke fant i databasen — brukeren håndterer manuelt. */
@Serializable
data class ReceiptUnmatchedLine(
    val name: String,
    val quantity: Int = 1,
    @SerialName("unit_price") val unitPrice: Double? = null,
)

/** Hele svaret fra parse-receipt. */
@Serializable
data class ReceiptParseResult(
    val store: String? = null,
    val matched: List<ReceiptMatchedLine> = emptyList(),
    val unmatched: List<ReceiptUnmatchedLine> = emptyList(),
)
