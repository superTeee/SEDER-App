package com.tomerikheggedal.vitola.ui.detail

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
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
