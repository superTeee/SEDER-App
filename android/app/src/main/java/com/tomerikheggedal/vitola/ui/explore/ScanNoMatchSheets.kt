package com.tomerikheggedal.vitola.ui.explore

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.WorkspacePremium
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.tomerikheggedal.vitola.data.CigarRepository
import com.tomerikheggedal.vitola.data.HumidorRepository
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

// Vennlig «ingen treff»-ark: forklarer hvorfor + gir vei videre (prøv på nytt /
// legg inn manuelt). Speiler iOS NoMatchView.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NoMatchSheet(
    onDismiss: () -> Unit,
    onRetry: () -> Unit,
    onManualAdd: () -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val accent = MaterialTheme.colorScheme.primary

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface) {
        Column(
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState())
                .padding(horizontal = 22.dp).padding(bottom = 28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            // Stiplet «spøkelses-sigar»
            Box(
                Modifier.padding(top = 6.dp).size(84.dp)
                    .background(accent.copy(alpha = 0.12f), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Canvas(Modifier.size(84.dp)) {
                    rotate(-20f, pivot = center) {
                        val stroke = Stroke(
                            width = 2.4.dp.toPx(),
                            pathEffect = PathEffect.dashPathEffect(floatArrayOf(14f, 10f))
                        )
                        val w = size.width * 0.60f
                        val h = size.height * 0.20f
                        val left = center.x - w / 2f
                        val top = center.y - h / 2f
                        drawRoundRect(
                            color = accent,
                            topLeft = Offset(left, top),
                            size = Size(w, h),
                            cornerRadius = CornerRadius(h / 2f, h / 2f),
                            style = stroke
                        )
                        // bånd nær høyre ende
                        drawRect(
                            color = accent,
                            topLeft = Offset(left + w * 0.70f, top),
                            size = Size(w * 0.14f, h),
                            style = stroke
                        )
                    }
                }
            }

            Text("Vi fant ikke denne sigaren",
                style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Text("Ingen match i databasen – ennå.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant)

            // Årsaker
            Column(
                Modifier.fillMaxWidth().padding(top = 14.dp)
                    .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                        RoundedCornerShape(14.dp))
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text("Det kan skyldes:", style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.SemiBold)
                listOf(
                    "Gjenskinn eller refleks i sigarbeltet",
                    "Lite eller ingen tekst på båndet",
                    "Utydelig, bøyd eller vinklet tekst",
                    "For svakt lys",
                ).forEach {
                    Text("•  $it", style = MaterialTheme.typography.bodyMedium)
                }
            }

            Button(onClick = onManualAdd, modifier = Modifier.fillMaxWidth().padding(top = 18.dp)) {
                Text("Legg den inn manuelt")
            }
            OutlinedButton(onClick = onRetry, modifier = Modifier.fillMaxWidth()) {
                Text("Prøv på nytt med nytt bilde")
            }
        }
    }
}

// Manuell innlegging: kort motiverende tekst + merke-autocomplete → create_own_cigar
// + legg i humidor. Speiler iOS ManualAddSheet.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ManualAddCigarSheet(
    ocrText: String,
    onDismiss: () -> Unit,
    onAdded: () -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()
    val accent = MaterialTheme.colorScheme.primary

    var brand by remember { mutableStateOf("") }
    var series by remember { mutableStateOf("") }
    var vitola by remember { mutableStateOf("") }
    var brandChosen by remember { mutableStateOf(false) }
    var suggestions by remember { mutableStateOf<List<String>>(emptyList()) }
    var saving by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    // Autocomplete mot eksisterende merker (debounce).
    LaunchedEffect(brand, brandChosen) {
        if (brandChosen || brand.isBlank()) { suggestions = emptyList(); return@LaunchedEffect }
        delay(250)
        suggestions = runCatching { CigarRepository.searchBrands(brand) }.getOrDefault(emptyList())
    }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface) {
        Column(
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState())
                .padding(horizontal = 22.dp).padding(bottom = 28.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text("Legg den inn – og hjelp fellesskapet",
                style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
            Text("Den havner rett i humidoren din. Vi verifiserer den og legger den i basen, så neste som skanner får treff – takket være deg.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 5.dp))

            // Bidragsyter-badge
            Row(
                Modifier.fillMaxWidth().padding(top = 12.dp)
                    .background(accent.copy(alpha = 0.10f), RoundedCornerShape(9.dp))
                    .padding(horizontal = 11.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(7.dp)
            ) {
                Icon(Icons.Filled.WorkspacePremium, contentDescription = null, tint = accent,
                    modifier = Modifier.size(18.dp))
                Text("Teller mot Bidragsyter-merket på profilen din",
                    style = MaterialTheme.typography.bodySmall, color = accent)
            }

            OutlinedTextField(
                value = brand,
                onValueChange = { brand = it; brandChosen = false },
                label = { Text("Merke *") }, singleLine = true,
                modifier = Modifier.fillMaxWidth().padding(top = 16.dp)
            )
            if (!brandChosen && suggestions.isNotEmpty()) {
                Column(
                    Modifier.fillMaxWidth()
                        .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                            RoundedCornerShape(10.dp))
                ) {
                    suggestions.forEach { b ->
                        Row(
                            Modifier.fillMaxWidth()
                                .clickable { brand = b; brandChosen = true; suggestions = emptyList() }
                                .padding(horizontal = 12.dp, vertical = 11.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(b, style = MaterialTheme.typography.bodyLarge)
                            Text("i basen", style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.primary)
                        }
                    }
                }
            }

            OutlinedTextField(series, { series = it }, label = { Text("Serie / navn") },
                singleLine = true, modifier = Modifier.fillMaxWidth().padding(top = 14.dp))
            OutlinedTextField(vitola, { vitola = it }, label = { Text("Vitola / format") },
                singleLine = true, modifier = Modifier.fillMaxWidth().padding(top = 14.dp))

            error?.let {
                Text(it, color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodyMedium, modifier = Modifier.padding(top = 10.dp))
            }

            Button(
                onClick = {
                    if (brand.isBlank()) { error = "Merke må fylles ut."; return@Button }
                    saving = true; error = null
                    scope.launch {
                        val res = runCatching {
                            val note = if (ocrText.isBlank()) "" else "Fra skann: ${ocrText.take(200)}"
                            val id = CigarRepository.createOwnCigar(
                                brand = brand, series = series, vitola = vitola,
                                country = "", wrapper = "", ringGauge = null, lengthInches = null,
                                note = note, suggest = true,
                            )
                            val humidors = runCatching { HumidorRepository.myHumidors() }.getOrDefault(emptyList())
                            humidors.firstOrNull()?.let { h ->
                                runCatching { HumidorRepository.addCigar(cigarId = id, humidorId = h.row.id) }
                            }
                            id
                        }
                        saving = false
                        if (res.isSuccess) onAdded()
                        else error = "Kunne ikke legge til – prøv igjen."
                    }
                },
                enabled = !saving && brand.isNotBlank(),
                modifier = Modifier.fillMaxWidth().padding(top = 24.dp)
            ) {
                if (saving) CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp,
                    color = MaterialTheme.colorScheme.onPrimary)
                else Text("Legg til i humidoren")
            }
        }
    }
}
