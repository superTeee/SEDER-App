package com.tomerikheggedal.vitola.ui.journal

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DeleteOutline
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.tomerikheggedal.vitola.data.JournalRepository
import com.tomerikheggedal.vitola.data.TastingLog
import com.tomerikheggedal.vitola.ui.rememberCropPicker
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.math.roundToInt

private fun scoreLabel(score: Int): String = when (score) {
    in 95..100 -> "Eksepsjonell"; in 90..94 -> "Fremragende"; in 85..89 -> "Meget bra"
    in 80..84 -> "Bra"; in 70..79 -> "Grei"; else -> "Ikke for meg"
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditJournalSheet(log: TastingLog, onDismiss: () -> Unit, onChanged: () -> Unit) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    var hasScore by remember { mutableStateOf(log.rating != null) }
    var score by remember { mutableStateOf((log.rating ?: 85).toFloat()) }
    var smokeAgain by remember { mutableStateOf(log.smokeAgain) }
    var notes by remember { mutableStateOf(log.personalNotes ?: "") }
    var store by remember { mutableStateOf(log.store ?: "") }
    var draw by remember { mutableStateOf(log.drawRating ?: 0) }
    var burn by remember { mutableStateOf(log.burnRating ?: 0) }
    var flavor by remember { mutableStateOf(log.flavorRating ?: 0) }
    var cutType by remember { mutableStateOf(log.cutType) }
    var newPhotoJpeg by remember { mutableStateOf<ByteArray?>(null) }
    var photoPreview by remember { mutableStateOf<android.net.Uri?>(null) }
    var saving by remember { mutableStateOf(false) }
    var confirmDelete by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    val pickPhoto = rememberCropPicker(0, 0) { uri ->
        photoPreview = uri
        scope.launch { newPhotoJpeg = withContext(Dispatchers.IO) { journalUriToJpeg(context, uri) } }
    }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface) {
        Column(
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp).padding(bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            Text("Rediger journalinnlegg", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)

            log.cigar?.let { c ->
                Column {
                    Text(c.brand, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    val sub = listOfNotNull(c.series, c.vitola).joinToString(" · ")
                    if (sub.isNotBlank()) Text(sub, style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }

            // Poengsum
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Label("Poengsum")
                    Spacer(Modifier.weight(1f))
                    Switch(checked = hasScore, onCheckedChange = { hasScore = it })
                }
                if (hasScore) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("${score.roundToInt()}", style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
                        Spacer(Modifier.width(10.dp))
                        Text(scoreLabel(score.roundToInt()), style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    Slider(value = score, onValueChange = { score = it }, valueRange = 50f..100f)
                }
            }

            // Røk igjen?
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Label("Ville du røkt den igjen?")
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(selected = smokeAgain == true,
                        onClick = { smokeAgain = if (smokeAgain == true) null else true }, label = { Text("Ja") })
                    FilterChip(selected = smokeAgain == false,
                        onClick = { smokeAgain = if (smokeAgain == false) null else false }, label = { Text("Nei") })
                }
            }

            // Del-vurderinger (1–5, som iOS)
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Label("Del-vurderinger")
                DotRatingRow("Trekk", draw) { draw = it }
                DotRatingRow("Brenning", burn) { burn = it }
                DotRatingRow("Smak", flavor) { flavor = it }
            }

            // Snitt-type
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Label("Snitt")
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("straight_cut" to "Rett", "v_cut" to "V-snitt", "punch_cut" to "Punch").forEach { (code, lbl) ->
                        FilterChip(selected = cutType == code,
                            onClick = { cutType = if (cutType == code) null else code }, label = { Text(lbl) })
                    }
                }
            }

            // Bilde (bytt/legg til)
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Label("Bilde")
                val previewModel: Any? = photoPreview ?: log.photoUrl
                if (previewModel != null) {
                    AsyncImage(model = previewModel, contentDescription = null, contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxWidth().height(160.dp).clip(RoundedCornerShape(8.dp)))
                }
                OutlinedButton(onClick = pickPhoto, modifier = Modifier.fillMaxWidth()) {
                    Text(if (previewModel != null) "Bytt bilde" else "Legg til bilde")
                }
            }

            OutlinedTextField(value = notes, onValueChange = { notes = it },
                label = { Text("Notater") }, modifier = Modifier.fillMaxWidth(), minLines = 2)
            OutlinedTextField(value = store, onValueChange = { store = it },
                label = { Text("Kjøpt hos") }, singleLine = true, modifier = Modifier.fillMaxWidth())

            error?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyMedium) }

            Button(
                onClick = {
                    if (saving) return@Button
                    saving = true; error = null
                    scope.launch {
                        try {
                            val photoUrl = newPhotoJpeg?.let { JournalRepository.uploadLogPhoto(log.id, it) }
                            JournalRepository.updateLog(
                                logId = log.id,
                                rating = if (hasScore) score.roundToInt() else null,
                                smokeAgain = smokeAgain, notes = notes, store = store,
                                drawRating = draw.takeIf { it > 0 },
                                burnRating = burn.takeIf { it > 0 },
                                flavorRating = flavor.takeIf { it > 0 },
                                cutType = cutType, photoUrl = photoUrl,
                            )
                            onChanged()
                        } catch (e: Exception) { error = e.message ?: "Kunne ikke lagre"; saving = false }
                    }
                },
                enabled = !saving, modifier = Modifier.fillMaxWidth()
            ) {
                if (saving) CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp,
                    color = MaterialTheme.colorScheme.onPrimary)
                else Text("Lagre", fontWeight = FontWeight.SemiBold)
            }

            TextButton(onClick = { confirmDelete = true }, modifier = Modifier.fillMaxWidth()) {
                Icon(Icons.Filled.DeleteOutline, null, tint = MaterialTheme.colorScheme.error,
                    modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(6.dp))
                Text("Slett innlegg", color = MaterialTheme.colorScheme.error)
            }
        }
    }

    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            confirmButton = {
                TextButton(onClick = {
                    confirmDelete = false
                    scope.launch { runCatching { JournalRepository.deleteLog(log.id) }; onChanged() }
                }) { Text("Slett", color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = { TextButton(onClick = { confirmDelete = false }) { Text("Avbryt") } },
            title = { Text("Slett innlegg?") },
            text = { Text("Dette kan ikke angres.") }
        )
    }
}

@Composable
private fun Label(text: String) {
    Text(text.uppercase(), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.onSurfaceVariant)
}

// 1–5 prikker (0 = ikke satt). Trykk samme verdi igjen for å nullstille.
@Composable
private fun DotRatingRow(label: String, value: Int, onSet: (Int) -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(label, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.width(90.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            (1..5).forEach { i ->
                Box(
                    Modifier.size(22.dp).clip(CircleShape)
                        .background(if (i <= value) MaterialTheme.colorScheme.primary
                                    else MaterialTheme.colorScheme.surfaceVariant)
                        .clickable { onSet(if (value == i) 0 else i) }
                )
            }
        }
    }
}

// Galleri-Uri → nedskalert JPEG (maks 1200px) — mindre fil = raskere/mer pålitelig lasting (som iOS).
private fun journalUriToJpeg(context: android.content.Context, uri: android.net.Uri, maxDim: Int = 1200): ByteArray? {
    val bitmap = context.contentResolver.openInputStream(uri)?.use {
        android.graphics.BitmapFactory.decodeStream(it)
    } ?: return null
    val longest = maxOf(bitmap.width, bitmap.height)
    val scaled = if (longest > maxDim) {
        val r = maxDim.toFloat() / longest
        android.graphics.Bitmap.createScaledBitmap(bitmap,
            (bitmap.width * r).toInt().coerceAtLeast(1), (bitmap.height * r).toInt().coerceAtLeast(1), true)
    } else bitmap
    val out = java.io.ByteArrayOutputStream()
    scaled.compress(android.graphics.Bitmap.CompressFormat.JPEG, 70, out)
    return out.toByteArray()
}
