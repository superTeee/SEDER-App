package com.tomerikheggedal.vitola.ui.humidor

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.tomerikheggedal.vitola.data.Cigar
import com.tomerikheggedal.vitola.data.HumidorRepository
import com.tomerikheggedal.vitola.data.HumidorRow
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddToHumidorSheet(
    cigar: Cigar,
    onDismiss: () -> Unit,
    onAdded: (String) -> Unit,   // humidornavn tilbake for bekreftelse
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()

    var humidors by remember { mutableStateOf<List<HumidorRow>>(emptyList()) }
    var selected by remember { mutableStateOf<HumidorRow?>(null) }
    var quantity by remember { mutableStateOf(1) }
    var priceText by remember { mutableStateOf("") }
    var store by remember { mutableStateOf("") }
    var saving by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var showCreate by remember { mutableStateOf(false) }
    var reloadKey by remember { mutableStateOf(0) }
    var storeSuggestions by remember { mutableStateOf(com.tomerikheggedal.vitola.ui.KnownStores.norway) }

    LaunchedEffect(reloadKey) {
        humidors = runCatching { HumidorRepository.myHumidors().map { it.row } }.getOrDefault(emptyList())
        if (selected == null || humidors.none { it.id == selected?.id }) selected = humidors.firstOrNull()
    }
    LaunchedEffect(Unit) {
        val mine = runCatching { HumidorRepository.storeSuggestions() }.getOrDefault(emptyList())
        storeSuggestions = com.tomerikheggedal.vitola.ui.KnownStores.merged(mine)
    }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState, containerColor = MaterialTheme.colorScheme.surface) {
        Column(
            Modifier.fillMaxWidth().padding(horizontal = 24.dp).padding(bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            Text("Legg i humidor", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)

            // Sigar
            Column {
                Text(cigar.brand, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                val sub = listOfNotNull(cigar.series, cigar.vitola).joinToString(" · ")
                if (sub.isNotBlank()) Text(sub, style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }

            // Humidor-velger
            FieldLabel("Humidor")
            if (humidors.isEmpty()) {
                Text("Du har ingen humidor ennå.", style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            } else {
                HumidorPicker(humidors, selected) { selected = it }
            }
            TextButton(onClick = { showCreate = true }, contentPadding = PaddingValues(0.dp)) {
                Icon(Icons.Filled.Add, null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(6.dp))
                Text("Opprett ny humidor")
            }

            // Antall — høyt oppe (som ønsket)
            FieldLabel("Antall")
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                OutlinedIconButton(onClick = { if (quantity > 1) quantity-- }, enabled = quantity > 1) {
                    Icon(Icons.Filled.Remove, "Færre")
                }
                Text("$quantity stk", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                OutlinedIconButton(onClick = { if (quantity < 100) quantity++ }, enabled = quantity < 100) {
                    Icon(Icons.Filled.Add, "Flere")
                }
            }

            // Pris per sigar (valgfritt) — brukes til total verdi i humidoren
            FieldLabel("Pris per sigar")
            OutlinedTextField(
                value = priceText,
                onValueChange = { priceText = it },
                placeholder = { Text("0") },
                trailingIcon = { Text("kr", color = MaterialTheme.colorScheme.onSurfaceVariant) },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                modifier = Modifier.fillMaxWidth()
            )

            // Kjøpt hos
            FieldLabel("Kjøpt hos")
            OutlinedTextField(
                value = store,
                onValueChange = { store = it },
                placeholder = { Text("Butikk (valgfritt)") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Text),
                modifier = Modifier.fillMaxWidth()
            )
            com.tomerikheggedal.vitola.ui.StoreChips(storeSuggestions, store) { store = it }

            error?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyMedium) }

            Button(
                onClick = {
                    val h = selected ?: run { error = "Velg en humidor"; return@Button }
                    if (saving) return@Button
                    saving = true; error = null
                    scope.launch {
                        try {
                            val price = priceText.trim().replace(',', '.').toDoubleOrNull()
                            HumidorRepository.addCigar(cigar.id, h.id, quantity, store, price)
                            onAdded(h.name)
                        } catch (e: Exception) {
                            error = e.message ?: "Kunne ikke legge til"
                            saving = false
                        }
                    }
                },
                enabled = !saving && selected != null,
                modifier = Modifier.fillMaxWidth()
            ) {
                if (saving) CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp,
                    color = MaterialTheme.colorScheme.onPrimary)
                else Text("Legg til", fontWeight = FontWeight.SemiBold)
            }
        }
    }

    if (showCreate) {
        AddHumidorSheet(
            onDismiss = { showCreate = false },
            onCreated = { showCreate = false; reloadKey++ }
        )
    }
}

@Composable
private fun FieldLabel(text: String) {
    Text(text.uppercase(), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.onSurfaceVariant)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun HumidorPicker(humidors: List<HumidorRow>, selected: HumidorRow?, onSelect: (HumidorRow) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    ExposedDropdownMenuBox(expanded = expanded, onExpandedChange = { expanded = it }) {
        OutlinedTextField(
            value = selected?.name ?: "",
            onValueChange = {},
            readOnly = true,
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier.fillMaxWidth().menuAnchor()
        )
        ExposedDropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            humidors.forEach { h ->
                DropdownMenuItem(text = { Text(h.name) }, onClick = { onSelect(h); expanded = false })
            }
        }
    }
}
