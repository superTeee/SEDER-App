package com.tomerikheggedal.vitola.ui.humidor

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.tomerikheggedal.vitola.data.HumidorRepository
import com.tomerikheggedal.vitola.data.HumidorRow
import com.tomerikheggedal.vitola.data.ReceiptParseResult
import com.tomerikheggedal.vitola.data.ReceiptUnmatchedLine
import com.tomerikheggedal.vitola.ui.explore.AddCigarSheet
import kotlinx.coroutines.launch

// «250» for hele tall, «249,5» ellers — norsk visning av enhetspris.
private fun formatReceiptPrice(value: Double): String =
    if (value % 1.0 == 0.0) value.toInt().toString()
    else String.format("%.1f", value).replace('.', ',')

// Én redigerbar rad (matchet ELLER manuelt løst). State-backet så UI oppdateres.
private class EditableReceiptLine(
    val cigarId: String,
    val title: String,
    val receiptName: String,
    quantity: Int,
    priceText: String,
    humidorId: String?,
) {
    var quantity by mutableStateOf(quantity)
    var priceText by mutableStateOf(priceText)
    var humidorId by mutableStateOf(humidorId)
    var included by mutableStateOf(true)
    // Satt når raden ble smart-rutet til sist-brukte humidor (viser «sist her»-hint).
    var smartAssigned by mutableStateOf(false)
}

// Bekreft-skjerm: varelinjene fra kvitteringen, ferdig matchet. Én standard-humidor
// øverst gjelder alle rader; hver rad kan overstyres. Ukjente varer nederst.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReceiptConfirmSheet(
    result: ReceiptParseResult,
    humidors: List<HumidorRow>,
    onDismiss: () -> Unit,
    onFinished: () -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()

    val lines = remember {
        mutableStateListOf<EditableReceiptLine>().apply {
            addAll(result.matched.map { m ->
                EditableReceiptLine(
                    cigarId = m.cigarId,
                    title = listOfNotNull(m.brand, m.series, m.vitola).joinToString(" · "),
                    receiptName = m.receiptName,
                    quantity = m.quantity.coerceAtLeast(1),
                    priceText = m.unitPrice?.let { formatReceiptPrice(it) } ?: "",
                    humidorId = humidors.firstOrNull()?.id,
                )
            })
        }
    }
    val unmatched = remember { mutableStateListOf<ReceiptUnmatchedLine>().apply { addAll(result.unmatched) } }
    var defaultHumidorId by remember { mutableStateOf(humidors.firstOrNull()?.id) }
    var store by remember { mutableStateOf(result.store ?: "") }
    var saving by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var manualResolving by remember { mutableStateOf<ReceiptUnmatchedLine?>(null) }
    var groupByHumidor by remember { mutableStateOf(false) }

    // Smart forhåndsvalg: rut hver sigar til humidoren den lå i sist.
    LaunchedEffect(Unit) {
        val ids = lines.map { it.cigarId }
        val last = runCatching { HumidorRepository.lastHumidorByCigar(ids) }.getOrDefault(emptyMap())
        lines.forEach { l -> last[l.cigarId]?.let { hid -> l.humidorId = hid; l.smartAssigned = true } }
    }

    val total = lines.filter { it.included }.sumOf { it.quantity }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface) {
        Column(
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp).padding(bottom = 28.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Text("Fra kvittering", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)

            if (humidors.isEmpty()) {
                Column(horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.fillMaxWidth().padding(vertical = 24.dp)) {
                    Icon(Icons.Filled.Inventory2, null, modifier = Modifier.size(48.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.height(10.dp))
                    Text("Opprett en humidor først", fontWeight = FontWeight.SemiBold)
                    Text("Du trenger minst én humidor å legge sigarene i.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                return@Column
            }

            // Standard-humidor for alle
            FieldLabelR("Legg alle i")
            HumidorDropdown(humidors, defaultHumidorId) { id ->
                defaultHumidorId = id
                lines.forEach { it.humidorId = id; it.smartAssigned = false }
            }
            Text("Velger du humidor her, flyttes alle sigarene dit. Overstyr hver enkelt under.",
                style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)

            // Grupper etter humidor (read-only oppsummering med totalsum).
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text("Grupper etter humidor", Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge)
                Switch(checked = groupByHumidor, onCheckedChange = { groupByHumidor = it })
            }
            if (groupByHumidor) {
                Column(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp))
                        .background(MaterialTheme.colorScheme.background).padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    lines.filter { it.included }.groupBy { it.humidorId }.forEach { (hid, ls) ->
                        val name = humidors.firstOrNull { it.id == hid }?.name ?: "Ingen humidor"
                        val qty = ls.sumOf { it.quantity }
                        val sum = ls.sumOf {
                            (it.priceText.trim().replace(',', '.').toDoubleOrNull() ?: 0.0) * it.quantity
                        }
                        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                            Text("$name · $qty stk", Modifier.weight(1f),
                                style = MaterialTheme.typography.bodyMedium)
                            Text("${formatReceiptPrice(sum)} kr", fontWeight = FontWeight.SemiBold,
                                style = MaterialTheme.typography.bodyMedium)
                        }
                    }
                }
            }

            FieldLabelR("Kjøpt hos")
            OutlinedTextField(
                value = store, onValueChange = { store = it },
                placeholder = { Text("Butikk (valgfritt)") }, singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )

            HorizontalDivider(color = MaterialTheme.colorScheme.surfaceVariant)
            Text("Funnet i basen (${lines.size})", style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurfaceVariant)

            lines.forEach { line -> LineRow(line, humidors) }

            if (unmatched.isNotEmpty()) {
                HorizontalDivider(color = MaterialTheme.colorScheme.surfaceVariant)
                Text("Fant ikke i basen (${unmatched.size})", style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurfaceVariant)
                unmatched.forEach { item ->
                    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f)) {
                            Text(item.name, style = MaterialTheme.typography.bodyMedium)
                            Text("${item.quantity} stk" + (item.unitPrice?.let { " · ${formatReceiptPrice(it)} kr" } ?: ""),
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        TextButton(onClick = { manualResolving = item }) { Text("Legg til manuelt") }
                    }
                }
            }

            error?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyMedium) }

            Button(
                onClick = {
                    if (saving || total == 0) return@Button
                    saving = true; error = null
                    scope.launch {
                        try {
                            val s = store.trim().ifBlank { null }
                            lines.filter { it.included }.forEach { l ->
                                val hid = l.humidorId ?: defaultHumidorId ?: return@forEach
                                val price = l.priceText.trim().replace(',', '.').toDoubleOrNull()
                                HumidorRepository.addCigar(l.cigarId, hid, l.quantity, s, price)
                            }
                            onFinished(); onDismiss()
                        } catch (e: Exception) {
                            error = "Kunne ikke legge til alt. Prøv igjen."; saving = false
                        }
                    }
                },
                enabled = !saving && total > 0,
                modifier = Modifier.fillMaxWidth()
            ) {
                if (saving) CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp,
                    color = MaterialTheme.colorScheme.onPrimary)
                else Text(if (total > 0) "Legg til $total sigarer" else "Ingen valgt", fontWeight = FontWeight.SemiBold)
            }
        }
    }

    manualResolving?.let { pending ->
        AddCigarSheet(initialBrand = pending.name, onDismiss = { manualResolving = null }) { newId ->
            manualResolving = null
            unmatched.remove(pending)
            lines.add(EditableReceiptLine(
                cigarId = newId,
                title = pending.name,
                receiptName = pending.name,
                quantity = pending.quantity.coerceAtLeast(1),
                priceText = pending.unitPrice?.let { formatReceiptPrice(it) } ?: "",
                humidorId = defaultHumidorId,
            ))
        }
    }
}

@Composable
private fun FieldLabelR(text: String) {
    Text(text.uppercase(), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.onSurfaceVariant)
}

// Én matchet rad: avkrysning, tittel, antall-stepper, pris, humidor-overstyring.
@Composable
private fun LineRow(line: EditableReceiptLine, humidors: List<HumidorRow>) {
    Column(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp))
            .background(MaterialTheme.colorScheme.background).padding(10.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Checkbox(checked = line.included, onCheckedChange = { line.included = it })
            Column(Modifier.weight(1f)) {
                Text(line.title.ifBlank { line.receiptName },
                    style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                if (line.title != line.receiptName) {
                    Text("På kvittering: ${line.receiptName}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }

        Row(verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            OutlinedIconButton(onClick = { if (line.quantity > 1) line.quantity-- },
                enabled = line.included && line.quantity > 1, modifier = Modifier.size(34.dp)) {
                Icon(Icons.Filled.Remove, "Færre", modifier = Modifier.size(18.dp))
            }
            Text("${line.quantity} stk", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
            OutlinedIconButton(onClick = { if (line.quantity < 100) line.quantity++ },
                enabled = line.included && line.quantity < 100, modifier = Modifier.size(34.dp)) {
                Icon(Icons.Filled.Add, "Flere", modifier = Modifier.size(18.dp))
            }
            Spacer(Modifier.weight(1f))
            OutlinedTextField(
                value = line.priceText, onValueChange = { line.priceText = it },
                placeholder = { Text("0") }, singleLine = true, enabled = line.included,
                trailingIcon = { Text("kr", color = MaterialTheme.colorScheme.onSurfaceVariant) },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                modifier = Modifier.width(120.dp)
            )
        }

        Row(verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            HumidorDropdown(humidors, line.humidorId, enabled = line.included) {
                line.humidorId = it; line.smartAssigned = false
            }
            if (line.smartAssigned) {
                Text("sist her", style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.primary)
            }
        }
    }
}

// Nedtrekk for humidor-valg (standard og per rad).
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun HumidorDropdown(
    humidors: List<HumidorRow>,
    selectedId: String?,
    enabled: Boolean = true,
    onSelect: (String) -> Unit,
) {
    var expanded by remember { mutableStateOf(false) }
    val name = humidors.firstOrNull { it.id == selectedId }?.name ?: "Velg humidor"
    Box {
        AssistChip(
            onClick = { if (enabled) expanded = true },
            enabled = enabled,
            label = { Text(name) },
            leadingIcon = { Icon(Icons.Filled.Inventory2, null, modifier = Modifier.size(16.dp)) },
            trailingIcon = { Icon(Icons.Filled.ArrowDropDown, null) }
        )
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            humidors.forEach { h ->
                DropdownMenuItem(text = { Text(h.name) }, onClick = { onSelect(h.id); expanded = false })
            }
        }
    }
}
