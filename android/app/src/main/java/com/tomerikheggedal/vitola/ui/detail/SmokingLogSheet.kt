package com.tomerikheggedal.vitola.ui.detail

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.tomerikheggedal.vitola.data.Cigar
import com.tomerikheggedal.vitola.data.JournalRepository
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

private fun scoreLabel(score: Int): String = when (score) {
    in 95..100 -> "Eksepsjonell"
    in 90..94 -> "Fremragende"
    in 85..89 -> "Meget bra"
    in 80..84 -> "Bra"
    in 70..79 -> "Grei"
    else -> "Ikke for meg"
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SmokingLogSheet(
    cigar: Cigar,
    humidorEntryId: String?,
    onDismiss: () -> Unit,
    onLogged: (String) -> Unit,   // ny log-id (til del-etter-lagring)
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()

    var hasScore by remember { mutableStateOf(true) }
    var score by remember { mutableStateOf(85f) }
    var smokeAgain by remember { mutableStateOf<Boolean?>(null) }
    var notes by remember { mutableStateOf("") }
    var store by remember { mutableStateOf("") }
    var storeSuggestions by remember { mutableStateOf(com.tomerikheggedal.vitola.ui.KnownStores.norway) }
    var showSub by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        val mine = runCatching { com.tomerikheggedal.vitola.data.HumidorRepository.storeSuggestions() }.getOrDefault(emptyList())
        storeSuggestions = com.tomerikheggedal.vitola.ui.KnownStores.merged(mine)
    }
    var drawRating by remember { mutableStateOf(0) }   // 0 = ikke satt, 1–5
    var burnRating by remember { mutableStateOf(0) }
    var flavorRating by remember { mutableStateOf(0) }
    var cutType by remember { mutableStateOf<String?>(null) }
    var saving by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface) {
        Column(
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp).padding(bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            Text("Marker som røkt", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)

            // Sigar
            Column {
                Text(cigar.brand, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                val sub = listOfNotNull(cigar.series, cigar.vitola).joinToString(" · ")
                if (sub.isNotBlank()) Text(sub, style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
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
                        onClick = { smokeAgain = if (smokeAgain == true) null else true },
                        label = { Text("Ja") })
                    FilterChip(selected = smokeAgain == false,
                        onClick = { smokeAgain = if (smokeAgain == false) null else false },
                        label = { Text("Nei") })
                }
            }

            // Detaljer (valgfritt): del-vurderinger — som iOS.
            Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Row(
                    Modifier.fillMaxWidth().clickable { showSub = !showSub },
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Detaljer (valgfritt)", style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.weight(1f))
                    Icon(
                        if (showSub) Icons.Filled.KeyboardArrowUp else Icons.Filled.KeyboardArrowDown,
                        contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                if (showSub) {
                    DotRatingRow("Trekk", drawRating) { drawRating = it }
                    DotRatingRow("Brenning", burnRating) { burnRating = it }
                    DotRatingRow("Smak", flavorRating) { flavorRating = it }
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Label("Kutt")
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            listOf("straight_cut" to "Rett", "v_cut" to "V-snitt", "punch_cut" to "Punch")
                                .forEach { (code, lbl) ->
                                    FilterChip(
                                        selected = cutType == code,
                                        onClick = { cutType = if (cutType == code) null else code },
                                        label = { Text(lbl) }
                                    )
                                }
                        }
                    }
                }
            }

            OutlinedTextField(
                value = notes, onValueChange = { notes = it },
                label = { Text("Notater (valgfritt)") },
                modifier = Modifier.fillMaxWidth(), minLines = 2
            )

            OutlinedTextField(
                value = store, onValueChange = { store = it },
                label = { Text("Kjøpt hos (valgfritt)") },
                singleLine = true, modifier = Modifier.fillMaxWidth()
            )
            com.tomerikheggedal.vitola.ui.StoreChips(storeSuggestions, store) { store = it }

            error?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyMedium) }

            Button(
                onClick = {
                    if (saving) return@Button
                    saving = true; error = null
                    scope.launch {
                        try {
                            val logId = JournalRepository.addLog(
                                cigarId = cigar.id,
                                rating = if (hasScore) score.roundToInt() else null,
                                smokeAgain = smokeAgain,
                                notes = notes,
                                store = store,
                                humidorEntryId = humidorEntryId,
                                drawRating = drawRating.takeIf { it > 0 },
                                burnRating = burnRating.takeIf { it > 0 },
                                flavorRating = flavorRating.takeIf { it > 0 },
                                cutType = cutType,
                            )
                            onLogged(logId)
                        } catch (e: Exception) {
                            error = e.message ?: "Kunne ikke lagre"
                            saving = false
                        }
                    }
                },
                enabled = !saving,
                modifier = Modifier.fillMaxWidth()
            ) {
                if (saving) CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp,
                    color = MaterialTheme.colorScheme.onPrimary)
                else Text("Marker som røkt", fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

@Composable
private fun Label(text: String) {
    Text(text.uppercase(), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.onSurfaceVariant)
}

// Prikkerad 1–5 (trykk på samme prikk igjen = nullstill), som iOS' dotRatingRow.
@Composable
private fun DotRatingRow(label: String, value: Int, onChange: (Int) -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(label, style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurface, modifier = Modifier.weight(1f))
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            for (i in 1..5) {
                val filled = i <= value
                Box(
                    Modifier.size(20.dp).clip(CircleShape)
                        .background(
                            if (filled) MaterialTheme.colorScheme.primary
                            else MaterialTheme.colorScheme.surfaceVariant
                        )
                        .clickable { onChange(if (value == i) 0 else i) }
                )
            }
        }
    }
}
