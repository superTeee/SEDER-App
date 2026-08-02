package com.tomerikheggedal.vitola.ui.explore

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.tomerikheggedal.vitola.data.CigarRepository
import kotlinx.coroutines.launch

// Legg til en sigar manuelt når hverken søk eller AI finner den.
// Raden er privat for brukeren; «Foreslå …» sender den til review-køen.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddCigarSheet(
    initialBrand: String = "",
    initialNote: String = "",
    onDismiss: () -> Unit,
    onCreated: (String) -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()

    var brand by remember { mutableStateOf(initialBrand) }
    var series by remember { mutableStateOf("") }
    var vitola by remember { mutableStateOf("") }
    var country by remember { mutableStateOf("") }
    var wrapper by remember { mutableStateOf("") }
    var ring by remember { mutableStateOf("") }
    var length by remember { mutableStateOf("") }
    var note by remember { mutableStateOf(initialNote) }
    var suggest by remember { mutableStateOf(initialNote.isNotBlank()) }
    var saving by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface) {
        Column(
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp).padding(bottom = 28.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text("Legg til sigar", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)

            OutlinedTextField(brand, { brand = it }, label = { Text("Merke *") },
                singleLine = true, modifier = Modifier.fillMaxWidth())
            OutlinedTextField(series, { series = it }, label = { Text("Serie") },
                singleLine = true, modifier = Modifier.fillMaxWidth())
            OutlinedTextField(vitola, { vitola = it }, label = { Text("Format / vitola") },
                singleLine = true, modifier = Modifier.fillMaxWidth())
            // Chips med vanlige vitolaer → fyller format + typisk størrelse.
            com.tomerikheggedal.vitola.ui.components.VitolaChips(selected = vitola) { p ->
                vitola = p.name
                if (ring.isBlank()) ring = p.ring.toString()
                if (length.isBlank()) length = com.tomerikheggedal.vitola.ui.components.vitolaLengthText(p.length)
            }
            OutlinedTextField(country, { country = it }, label = { Text("Opprinnelsesland") },
                singleLine = true, modifier = Modifier.fillMaxWidth())
            OutlinedTextField(wrapper, { wrapper = it }, label = { Text("Dekkblad") },
                singleLine = true, modifier = Modifier.fillMaxWidth())

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(ring, { ring = it.filter(Char::isDigit) },
                    label = { Text("Ring gauge") }, singleLine = true, modifier = Modifier.weight(1f),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number))
                OutlinedTextField(length, { length = it.filter { c -> c.isDigit() || c == '.' || c == ',' } },
                    label = { Text("Lengde (tommer)") }, singleLine = true, modifier = Modifier.weight(1f),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number))
            }

            OutlinedTextField(note, { note = it }, label = { Text("Notat (valgfritt)") },
                minLines = 2, modifier = Modifier.fillMaxWidth())

            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text("Foreslå til den delte databasen", style = MaterialTheme.typography.bodyLarge)
                    Text("Sendes til gjennomgang før den blir synlig for andre.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Switch(checked = suggest, onCheckedChange = { suggest = it })
            }

            error?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyMedium) }

            Button(
                onClick = {
                    if (brand.isBlank()) { error = "Merke må fylles ut."; return@Button }
                    saving = true; error = null
                    scope.launch {
                        val res = runCatching {
                            CigarRepository.createOwnCigar(
                                brand = brand, series = series, vitola = vitola, country = country,
                                wrapper = wrapper,
                                ringGauge = ring.toIntOrNull(),
                                lengthInches = length.replace(',', '.').toDoubleOrNull(),
                                note = note, suggest = suggest,
                            )
                        }
                        saving = false
                        res.getOrNull()?.let { onCreated(it) }
                            ?: run { error = "Kunne ikke lagre — prøv igjen." }
                    }
                },
                enabled = !saving && brand.isNotBlank(),
                modifier = Modifier.fillMaxWidth()
            ) {
                if (saving) CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp,
                    color = MaterialTheme.colorScheme.onPrimary)
                else Text("Lagre sigar")
            }
        }
    }
}
