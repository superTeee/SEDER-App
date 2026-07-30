package com.tomerikheggedal.vitola.ui.journal

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import androidx.core.content.FileProvider
import com.tomerikheggedal.vitola.data.TastingLog
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.time.Instant
import java.time.OffsetDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

// Journal-eksport (PDF/CSV) — Android-motpart til iOS JournalExporter.
object JournalExport {

    private val NO = Locale("nb", "NO")
    private val DATE = DateTimeFormatter.ofPattern("yyyy-MM-dd", NO)

    private fun cutLabel(code: String?): String? = when (code) {
        "straight_cut" -> "Rett"
        "v_cut" -> "V-snitt"
        "punch_cut" -> "Punch"
        else -> code
    }

    private fun dateStr(iso: String): String {
        val inst = runCatching { OffsetDateTime.parse(iso).toInstant() }
            .recoverCatching { Instant.parse(iso) }.getOrNull() ?: return iso
        return inst.atZone(ZoneId.systemDefault()).format(DATE)
    }

    private fun today(): String = OffsetDateTime.now().format(DATE)

    private fun exportDir(context: Context): File =
        File(context.cacheDir, "exports").apply { mkdirs() }

    private fun share(context: Context, file: File, mime: String) {
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        val send = Intent(Intent.ACTION_SEND).apply {
            type = mime
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        context.startActivity(Intent.createChooser(send, "Del journal"))
    }

    // CSV — UTF-8 med BOM (så Excel viser æøå riktig). Fil-arbeid på IO-tråd, deling på hovedtråd.
    suspend fun exportCsv(context: Context, logs: List<TastingLog>) {
        val file = withContext(Dispatchers.IO) { buildCsv(context, logs) }
        withContext(Dispatchers.Main) { share(context, file, "text/csv") }
    }

    private fun buildCsv(context: Context, logs: List<TastingLog>): File {
        fun esc(s: String?): String = "\"" + (s ?: "").replace("\"", "\"\"") + "\""
        val header = "Dato,Merke,Serie,Vitola,Score,Røyk igjen,Trekk,Brenning,Smak,Kutt,Kjøpt hos,Notat"
        val rows = StringBuilder("﻿").append(header)
        logs.sortedByDescending { it.smokedAt }.forEach { l ->
            val c = l.cigar
            val cols = listOf(
                dateStr(l.smokedAt), c?.brand, c?.series, c?.vitola,
                l.rating?.toString(), l.smokeAgain?.let { if (it) "Ja" else "Nei" },
                l.drawRating?.toString(), l.burnRating?.toString(), l.flavorRating?.toString(),
                cutLabel(l.cutType), l.store, l.personalNotes
            ).joinToString(",") { esc(it) }
            rows.append("\n").append(cols)
        }
        val file = File(exportDir(context), "seder-journal.csv")
        file.writeText(rows.toString(), Charsets.UTF_8)
        return file
    }

    // PDF — enkel, lesbar liste (A4). Fil-arbeid på IO-tråd, deling på hovedtråd.
    suspend fun exportPdf(context: Context, logs: List<TastingLog>) {
        val file = withContext(Dispatchers.IO) { buildPdf(context, logs) }
        withContext(Dispatchers.Main) { share(context, file, "application/pdf") }
    }

    private fun buildPdf(context: Context, logs: List<TastingLog>): File {
        val pageW = 595; val pageH = 842; val margin = 40f
        val doc = PdfDocument()
        val sorted = logs.sortedByDescending { it.smokedAt }

        val title = Paint().apply { color = Color.BLACK; textSize = 20f; typeface = Typeface.DEFAULT_BOLD; isAntiAlias = true }
        val sub = Paint().apply { color = Color.GRAY; textSize = 11f; isAntiAlias = true }
        val name = Paint().apply { color = Color.BLACK; textSize = 13f; typeface = Typeface.DEFAULT_BOLD; isAntiAlias = true }
        val meta = Paint().apply { color = Color.DKGRAY; textSize = 11f; isAntiAlias = true }
        val note = Paint().apply { color = Color.BLACK; textSize = 11f; isAntiAlias = true }

        var pageNo = 1
        var page = doc.startPage(PdfDocument.PageInfo.Builder(pageW, pageH, pageNo).create())
        var canvas = page.canvas
        var y = margin

        fun header() {
            canvas.drawText("SEDER — Journal", margin, y + 16f, title); y += 28f
            canvas.drawText("${sorted.size} registreringer · eksportert ${today()}", margin, y + 11f, sub); y += 26f
        }
        header()

        fun newPage() {
            doc.finishPage(page)
            pageNo++
            page = doc.startPage(PdfDocument.PageInfo.Builder(pageW, pageH, pageNo).create())
            canvas = page.canvas
            y = margin
            header()
        }

        fun wrap(text: String, paint: Paint, maxW: Float): List<String> {
            val out = mutableListOf<String>()
            var line = StringBuilder()
            text.split(" ").forEach { word ->
                val test = if (line.isEmpty()) word else "$line $word"
                if (paint.measureText(test) > maxW && line.isNotEmpty()) {
                    out.add(line.toString()); line = StringBuilder(word)
                } else line = StringBuilder(test)
            }
            if (line.isNotEmpty()) out.add(line.toString())
            return out
        }

        for (l in sorted) {
            if (y > pageH - margin - 60) newPage()
            val c = l.cigar
            val label = listOfNotNull(c?.brand, c?.series, c?.vitola).joinToString(" ")
            canvas.drawText(label.ifEmpty { "Ukjent sigar" }, margin, y + 13f, name); y += 18f

            var line = dateStr(l.smokedAt)
            l.rating?.let { line += " · $it/100" }
            l.store?.takeIf { it.isNotEmpty() }?.let { line += " · $it" }
            canvas.drawText(line, margin, y + 11f, meta); y += 16f

            l.personalNotes?.takeIf { it.isNotBlank() }?.let { n ->
                wrap(n, note, pageW - margin * 2).forEach { ln ->
                    if (y > pageH - margin - 20) newPage()
                    canvas.drawText(ln, margin, y + 11f, note); y += 15f
                }
            }
            y += 12f
        }

        doc.finishPage(page)
        val file = File(exportDir(context), "seder-journal.pdf")
        file.outputStream().use { doc.writeTo(it) }
        doc.close()
        return file
    }
}
