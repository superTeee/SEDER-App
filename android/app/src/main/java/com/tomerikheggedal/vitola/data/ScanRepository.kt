package com.tomerikheggedal.vitola.data

import android.graphics.BitmapFactory
import android.util.Base64
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.github.jan.supabase.functions.functions
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.rpc
import io.github.jan.supabase.storage.storage
import io.ktor.client.call.body
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.coroutines.resume

// Skanning av sigarbånd. Speiler iOS ScanService:
//   Steg 1: on-device OCR (ML Kit) → Steg 2: DB-søk → Steg 3: GPT-4o (edge function)
//   + form-/wrapper-avklaring når samme bånd matcher flere varianter.
// (ML Kit mangler Vision sin vokabular-biasing og pålitelige konfidens, så
//  OCR-delen er en tilnærming — resten av flyten er lik iOS.)
object ScanRepository {

    private const val OCR_THRESHOLD = 0.5

    /** Full skann-flyt fra et bånd-bilde. */
    suspend fun scanBand(imageJpeg: ByteArray): ScanOutcome {
        val (rawText, confidence) = runCatching { ocr(imageJpeg) }.getOrDefault("" to 0.0)
        val isLowConfidence = confidence < OCR_THRESHOLD
        val searchText = cleanOcrTextForSearch(rawText)

        var hits: List<ScanHit>
        var auto: Cigar? = null

        if (searchText.isNotBlank()) {
            val cigars = runCatching { CigarRepository.search(searchText).map { it.cigar } }
                .getOrDefault(emptyList())
            if (cigars.isNotEmpty()) {
                hits = cigars.mapIndexed { i, c ->
                    ScanHit(c, "Tekst: $rawText", exact = false, confidence = confidenceScore(c, rawText, i))
                }
                auto = exactSeriesMatch(cigars, rawText)
                // Flere DB-treff uten eksakt variant + trygg OCR → spør AI. Ellers vis lista.
                if (auto == null && cigars.size > 1 && !isLowConfidence) {
                    val ai = runCatching { scanWithAI(imageJpeg, rawText) }.getOrNull()
                    if (ai != null && ai.first.isNotEmpty()) { hits = ai.first; auto = ai.second }
                }
            } else {
                val ai = runCatching { scanWithAI(imageJpeg, rawText) }.getOrNull()
                hits = ai?.first ?: emptyList(); auto = ai?.second
            }
        } else {
            val ai = runCatching { scanWithAI(imageJpeg, rawText) }.getOrNull()
            hits = ai?.first ?: emptyList(); auto = ai?.second
        }

        hits = hits.sortedByDescending { it.confidence }

        // Avklaring: samme merke, men skiller på form (body_type) eller wrapper.
        var needsShape = false
        var needsWrapper = false
        var candidates = emptyList<Cigar>()
        if (auto == null && hits.size > 1) {
            val cs = hits.map { it.cigar }
            if (cs.map { it.brand.lowercase() }.toSet().size == 1) {
                val bodyTypes = cs.mapNotNull { it.bodyType?.lowercase() }.toSet()
                if (bodyTypes.size > 1) {
                    needsShape = true; candidates = cs
                } else {
                    val series = cs.mapNotNull { it.series?.lowercase() }.toSet()
                    val wraps = cs.mapNotNull { it.wrapperLeaf?.lowercase() }.toSet()
                    if (series.size == 1 && wraps.size > 1) { needsWrapper = true; candidates = cs }
                }
            }
        }

        // Logg skann-hendelsen for dekning-datahjulet (treffrate + hvilke sigarer
        // folk skanner som vi ikke har). Best effort — velter aldri flyten.
        val top = hits.firstOrNull()
        logScanEvent(rawText, hits.isNotEmpty(), top?.cigar?.id, top?.confidence)

        return ScanOutcome(hits, auto, needsShape, needsWrapper, candidates, rawText)
    }

    /** Sender skann-resultatet til Supabase (log_scan_event) for dekning-analyse. */
    private suspend fun logScanEvent(ocrText: String, hit: Boolean, matchedCigarId: String?, confidence: Double?) {
        runCatching {
            Supa.client.postgrest.rpc("log_scan_event", buildJsonObject {
                put("p_ocr_text", ocrText.take(300))
                put("p_hit", hit)
                if (matchedCigarId != null) put("p_matched_cigar_id", matchedCigarId) else put("p_matched_cigar_id", JsonNull)
                if (confidence != null) put("p_confidence", confidence) else put("p_confidence", JsonNull)
            })
        }
    }

    /** Bakoverkompatibel enkel skann (kun AI) — brukes der full flyt ikke trengs. */
    suspend fun scan(imageJpeg: ByteArray): List<ScanHit> = scanBand(imageJpeg).hits

    // MARK: - Datahjul for bildegjenkjenning
    // Når brukeren løser en skanning (velger riktig sigar), lagrer vi bånd-bildet
    // i bildebiblioteket og bånd-teksten som lært alias (aktiveres når nok
    // brukere bekrefter samme kobling). Alt er «best effort» — skal aldri velte
    // skanne-flyten.
    private suspend fun uploadBandSample(imageJpeg: ByteArray): String? {
        val userId = Supa.client.auth.currentUserOrNull()?.id ?: return null
        val path = "${userId.lowercase()}/${java.util.UUID.randomUUID().toString().lowercase()}.jpg"
        return runCatching {
            Supa.client.storage.from("band-samples").upload(path, imageJpeg, upsert = true)
            path
        }.getOrNull()
    }

    /** Registrer at brukeren løste en skanning: kobling bånd→sigar + bilde. */
    suspend fun resolveScan(ocrText: String, cigarId: String, imageJpeg: ByteArray?) {
        // Kjør hvis vi har enten tekst ELLER et bånd-bilde. Grafiske bånd uten tekst
        // gir ingen alias, men bildet lagres til fremtidig visuell matching.
        if (ocrText.isBlank() && imageJpeg == null) return
        runCatching {
            val path = imageJpeg?.let { uploadBandSample(it) }
            Supa.client.postgrest.rpc("record_scan_resolution", buildJsonObject {
                put("p_ocr_text", ocrText)
                put("p_cigar_id", cigarId)
                if (path != null) put("p_image_path", path) else put("p_image_path", JsonNull)
            })
        }
    }

    /** Avklar form med et bilde av hele sigaren. Returnerer entydig treff, ellers null. */
    suspend fun resolveShape(candidates: List<Cigar>, imageJpeg: ByteArray): Cigar? {
        val b64 = Base64.encodeToString(imageJpeg, Base64.NO_WRAP)
        val guess: ShapeGuess = runCatching {
            Supa.client.functions.invoke("scan-cigar", ModeReq(image = b64, mode = "shape")).body<ShapeGuess>()
        }.getOrNull() ?: return null
        return candidates.filter { it.bodyType?.lowercase() == guess.bodyType.lowercase() }.singleOrNull()
    }

    /** Avklar wrapper med et bilde av hele sigaren. Returnerer entydig treff, ellers null. */
    suspend fun resolveWrapper(candidates: List<Cigar>, imageJpeg: ByteArray): Cigar? {
        val b64 = Base64.encodeToString(imageJpeg, Base64.NO_WRAP)
        val guess: WrapperGuess = runCatching {
            Supa.client.functions.invoke("scan-cigar", ModeReq(image = b64, mode = "wrapper")).body<WrapperGuess>()
        }.getOrNull() ?: return null
        val w = guess.wrapper ?: return null
        return candidates.filter { it.wrapperLeaf?.lowercase() == w.lowercase() }.singleOrNull()
    }

    // MARK: - AI-fallback via edge function

    private suspend fun scanWithAI(imageJpeg: ByteArray, ocrText: String): Pair<List<ScanHit>, Cigar?> {
        val b64 = Base64.encodeToString(imageJpeg, Base64.NO_WRAP)
        val response = Supa.client.functions.invoke("scan-cigar", ScanReq(image = b64, ocr_text = ocrText))
        val matches: List<AICigarMatch> = response.body()
        val hits = mutableListOf<ScanHit>()
        val exact = mutableListOf<Cigar>()
        for (m in matches) {
            val c = runCatching { CigarRepository.byId(m.cigarId) }.getOrNull() ?: continue
            hits.add(ScanHit(c, m.reason, m.exactMatch, m.confidence))
            if (m.exactMatch) exact.add(c)
        }
        return hits to (if (exact.size == 1) exact.first() else null)
    }

    // MARK: - On-device OCR (ML Kit)

    private suspend fun ocr(imageJpeg: ByteArray): Pair<String, Double> {
        val bitmap = BitmapFactory.decodeByteArray(imageJpeg, 0, imageJpeg.size) ?: return "" to 0.0
        val input = InputImage.fromBitmap(bitmap, 0)
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        val result: Text? = suspendCancellableCoroutine { cont ->
            recognizer.process(input)
                .addOnSuccessListener { cont.resume(it) }
                .addOnFailureListener { cont.resume(null) }
        }
        val text = result?.text?.replace("\n", " ")?.trim() ?: ""
        // Min-konfidens blant substansielle elementer (der ML Kit oppgir det).
        val confs = result?.textBlocks
            ?.flatMap { it.lines }?.flatMap { it.elements }
            ?.filter { it.text.trim().length > 2 }
            ?.mapNotNull { it.confidence?.toDouble()?.takeIf { c -> !c.isNaN() } }
            ?: emptyList()
        return text to (confs.minOrNull() ?: 0.0)
    }

    // MARK: - OCR-tekst-rensing (port fra iOS)

    private val PHRASES_TO_STRIP = listOf(
        "REPUBLICA DOMINICANA", "REPÚBLICA DOMINICANA",
        "HECHO A MANO", "HECHO EN COSTA RICA", "HECHO EN NICARAGUA",
        "HECHO EN HONDURAS", "HECHO EN CUBA", "HECHO EN DOMINICANA", "HECHO EN",
        "MADE BY HAND", "HAND MADE", "HANDMADE", "HANDROLLED", "HAND ROLLED",
        "MADE IN USA", "MADE IN COSTA RICA", "MADE IN NICARAGUA", "MADE IN HONDURAS",
        "HABANA · CUBA", "HABANA-CUBA", "HABANA CUBA", "HABANA", "CUBA",
        "COSTA RICA", "COSTA-RICA",
        "NICARAGUA", "HONDURAS", "PANAMA", "ECUADOR",
        "DOMINICAN REPUBLIC", "DOMINICANA",
        "JALAPA", "ESTELÍ", "ESTELI", "JALAPA NICARAGUA",
        "SANTIAGO", "SANTIAGO DE LOS CABALLEROS",
        "DANLI", "DANLÍ", "TAMBORIL", "NAVARETTE", "VILLA GONZALEZ",
        "PREMIUM", "HANDCRAFTED", "HAND CRAFTED",
        "SINCE", "FOUNDED", "Desde", "DESDE",
    )

    private fun cleanOcrTextForSearch(raw: String): String {
        var cleaned = raw
        for (phrase in PHRASES_TO_STRIP) {
            cleaned = cleaned.replace(phrase, " ", ignoreCase = true)
        }
        // Fjern rene tall-/mål-tokens (ringmål, lengde) — de blokkerer AND-søket.
        return cleaned.split(Regex("\\s+"))
            .filter { it.isNotBlank() }
            .filter { token -> token.trim { it.isDigit() || it in ".,½¼¾×x\"'" }.isNotEmpty() }
            .joinToString(" ")
            .trim()
    }

    // MARK: - Heuristikker (port fra iOS)

    private fun confidenceScore(cigar: Cigar, ocrText: String, rank: Int): Double {
        val text = ocrText.lowercase()
        var score = 1.0 - rank * 0.15
        if (text.contains(cigar.brand.lowercase())) score += 0.2
        cigar.series?.let { if (text.contains(it.lowercase())) score += 0.15 }
        cigar.wrapperLeaf?.let { if (text.contains(it.lowercase())) score += 0.1 }
        return score.coerceIn(0.0, 1.0)
    }

    private fun exactSeriesMatch(cigars: List<Cigar>, ocrText: String): Cigar? {
        val text = ocrText.lowercase()
        val seriesCandidates = cigars.filter { c ->
            val s = c.series ?: return@filter false
            s.length > 2 && text.contains(s.lowercase())
        }
        if (seriesCandidates.size <= 1) return seriesCandidates.firstOrNull()
        val wrapperCandidates = seriesCandidates.filter { c ->
            val w = c.wrapperLeaf ?: return@filter false
            w.length > 2 && text.contains(w.lowercase())
        }
        return wrapperCandidates.singleOrNull()
    }
}

// Resultatet av en full skann.
data class ScanOutcome(
    val hits: List<ScanHit>,
    val autoSelected: Cigar?,
    val needsShape: Boolean,
    val needsWrapper: Boolean,
    val candidates: List<Cigar>,
    val ocrText: String,
)

data class ScanHit(val cigar: Cigar, val reason: String, val exact: Boolean, val confidence: Double = 0.0)

@Serializable
private data class ScanReq(val image: String, val ocr_text: String = "")

@Serializable
private data class ModeReq(val image: String, val mode: String)

@Serializable
private data class AICigarMatch(
    @SerialName("cigar_id") val cigarId: String,
    val confidence: Double = 0.0,
    val reason: String = "",
    @SerialName("exact_match") val exactMatch: Boolean = false,
)

@Serializable
private data class ShapeGuess(
    @SerialName("body_type") val bodyType: String = "",
    val confidence: Double = 0.0,
    val reason: String = "",
)

@Serializable
private data class WrapperGuess(
    val wrapper: String? = null,
    val confidence: Double = 0.0,
    val reason: String = "",
)
