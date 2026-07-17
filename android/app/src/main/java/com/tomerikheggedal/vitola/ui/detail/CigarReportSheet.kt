package com.tomerikheggedal.vitola.ui.detail

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.tomerikheggedal.vitola.data.Cigar
import com.tomerikheggedal.vitola.data.CigarRepository
import kotlinx.coroutines.launch

// Feltene brukeren kan melde feil på — samme koder som iOS CigarReportField.
private val REPORT_FIELDS = listOf(
    "origin" to "Feil opprinnelsesland",
    "dimensions" to "Feil mål eller format",
    "tobacco" to "Feil dekkblad, omblad eller innmat",
    "description" to "Feil i beskrivelsen",
    "flavor" to "Feil smaksnoter",
    "other" to "Noe annet",
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CigarReportSheet(cigar: Cigar, onDismiss: () -> Unit, onSent: () -> Unit) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()

    var field by remember { mutableStateOf("origin") }
    var comment by remember { mutableStateOf("") }
    var sending by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface) {
        Column(
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp).padding(bottom = 28.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Text("Meld feil", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)

            Column {
                Text(cigar.brand, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                cigar.series?.let {
                    Text(it, style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }

            Text("Hva stemmer ikke?", style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant)

            Column {
                REPORT_FIELDS.forEach { (code, label) ->
                    Row(
                        Modifier.fillMaxWidth()
                            .selectable(selected = field == code, onClick = { field = code })
                            .padding(vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(label, Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge)
                        if (field == code) {
                            Icon(Icons.Filled.Check, null, tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(20.dp))
                        }
                    }
                }
            }

            OutlinedTextField(
                value = comment, onValueChange = { comment = it },
                placeholder = { Text("Skriv hva som er riktig, og gjerne hvor du vet det fra") },
                supportingText = { Text("En kildelenke gjør at rettelsen går raskere gjennom.") },
                modifier = Modifier.fillMaxWidth(), minLines = 3
            )

            error?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyMedium) }

            Button(
                onClick = {
                    sending = true; error = null
                    scope.launch {
                        val res = runCatching { CigarRepository.reportCigar(cigar.id, field, comment) }
                        sending = false
                        if (res.isSuccess) onSent()
                        else error = "Kunne ikke sende inn — prøv igjen."
                    }
                },
                enabled = !sending,
                modifier = Modifier.fillMaxWidth()
            ) {
                if (sending) CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp,
                    color = MaterialTheme.colorScheme.onPrimary)
                else Text("Send inn")
            }
        }
    }
}
