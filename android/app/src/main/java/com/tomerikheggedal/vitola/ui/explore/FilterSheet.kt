package com.tomerikheggedal.vitola.ui.explore

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.tomerikheggedal.vitola.data.CigarFilter
import com.tomerikheggedal.vitola.data.CigarRepository
import com.tomerikheggedal.vitola.data.FlavorIcon
import kotlinx.coroutines.delay

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun FilterSheet(
    initial: CigarFilter,
    onDismiss: () -> Unit,
    onApply: (CigarFilter) -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var draft by remember { mutableStateOf(initial) }
    var count by remember { mutableStateOf<Int?>(null) }
    var showVitolaGuide by remember { mutableStateOf(false) }

    // Live antall treff — debounced når filteret endres.
    LaunchedEffect(draft) {
        count = null
        delay(250)
        count = runCatching { CigarRepository.countFiltered(draft) }.getOrNull()
    }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState) {
        Column(Modifier.fillMaxWidth()) {
            // Tittel
            Row(
                Modifier.fillMaxWidth().padding(start = 20.dp, end = 12.dp, bottom = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Avansert søk", style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                IconButton(onClick = onDismiss) { Icon(Icons.Filled.Close, "Lukk") }
            }

            HorizontalDivider()

            Column(
                Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState())
            ) {
                Spacer(Modifier.height(16.dp))

                ChipSection(
                    title = "Vitola",
                    options = CigarFilter.VITOLA,
                    selected = draft.vitola,
                    subtitles = CigarFilter.VITOLA_SIZES,
                    onInfo = { showVitolaGuide = true },
                    onToggle = { draft = draft.copy(vitola = draft.vitola.toggle(it)) }
                )
                ChipSection("Tverrsnitt", CigarFilter.CROSS_SECTION, draft.crossSection,
                    onToggle = { draft = draft.copy(crossSection = draft.crossSection.toggle(it)) })
                ChipSection("Opphav", CigarFilter.ORIGIN, draft.origin,
                    onToggle = { draft = draft.copy(origin = draft.origin.toggle(it)) })
                ChipSection("Wrapper", CigarFilter.WRAPPER, draft.wrapper,
                    onToggle = { draft = draft.copy(wrapper = draft.wrapper.toggle(it)) })
                ChipSection("Binder", CigarFilter.BINDER, draft.binder,
                    onToggle = { draft = draft.copy(binder = draft.binder.toggle(it)) })
                ChipSection("Filler", CigarFilter.FILLER, draft.filler,
                    onToggle = { draft = draft.copy(filler = draft.filler.toggle(it)) })

                // Profil-slidere
                RangeRow("Styrke", draft.strength) { draft = draft.copy(strength = it) }
                RangeRow("Kropp", draft.body) { draft = draft.copy(body = it) }
                RangeRow("Sødme", draft.sweetness) { draft = draft.copy(sweetness = it) }
                RangeRow("Smaksintensitet", draft.flavorIntensity) { draft = draft.copy(flavorIntensity = it) }

                ChipSection("Smaksnoter", FlavorIcon.familyLabels, draft.flavorFamilies,
                    onToggle = { draft = draft.copy(flavorFamilies = draft.flavorFamilies.toggle(it)) })

                Spacer(Modifier.height(16.dp))
            }

            HorizontalDivider()

            // Bunn-CTA: Tilbakestill + Vis N resultater
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                TextButton(onClick = { draft = CigarFilter() }) { Text("Tilbakestill") }
                Button(
                    onClick = { onApply(draft) },
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        when (count) {
                            null -> "Vis resultater"
                            else -> "Vis $count ${if (count == 1) "resultat" else "resultater"}"
                        },
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
            Spacer(Modifier.height(12.dp))
        }
    }

    if (showVitolaGuide) VitolaGuideDialog { showVitolaGuide = false }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun ChipSection(
    title: String,
    options: List<String>,
    selected: List<String>,
    onToggle: (String) -> Unit,
    subtitles: Map<String, String> = emptyMap(),
    onInfo: (() -> Unit)? = null,
) {
    Column(Modifier.fillMaxWidth().padding(top = 6.dp, bottom = 10.dp)) {
        Row(
            Modifier.padding(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(title.uppercase(), style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurfaceVariant)
            if (onInfo != null) {
                IconButton(onClick = onInfo, modifier = Modifier.size(20.dp)) {
                    Icon(Icons.Outlined.Info, "Info", tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(16.dp))
                }
            }
        }
        FlowRow(
            Modifier.padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            options.forEach { opt ->
                val sub = subtitles[opt]
                FilterChip(
                    selected = opt in selected,
                    onClick = { onToggle(opt) },
                    label = {
                        if (sub != null) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text(opt)
                                Text(sub, style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        } else Text(opt)
                    }
                )
            }
        }
    }
}

@Composable
private fun RangeRow(
    label: String,
    range: ClosedFloatingPointRange<Float>,
    onChange: (ClosedFloatingPointRange<Float>) -> Unit,
) {
    Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 6.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(label.uppercase(), style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.weight(1f))
            val full = range == CigarFilter.FULL
            Text(
                if (full) "Alle" else "${range.start.toInt()} – ${range.endInclusive.toInt()}",
                style = MaterialTheme.typography.labelMedium,
                color = if (full) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.primary
            )
        }
        RangeSlider(
            value = range,
            onValueChange = { onChange(it.start..it.endInclusive) },
            valueRange = 1f..5f,
            steps = 3
        )
    }
}

@Composable
private fun VitolaGuideDialog(onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = { TextButton(onClick = onDismiss) { Text("Lukk") } },
        title = { Text("Vitola-formater", fontWeight = FontWeight.Bold) },
        text = {
            Column {
                Text("Ringmål × lengde for vanlige formater:",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(Modifier.height(8.dp))
                CigarFilter.VITOLA.forEach { v ->
                    Row(Modifier.fillMaxWidth().padding(vertical = 3.dp)) {
                        Text(v, Modifier.weight(1f), style = MaterialTheme.typography.bodyMedium)
                        Text(CigarFilter.VITOLA_SIZES[v] ?: "–",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.primary)
                    }
                }
            }
        }
    )
}

private fun List<String>.toggle(item: String): List<String> =
    if (item in this) this - item else this + item
