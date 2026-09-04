package com.tomerikheggedal.vitola.ui.explore

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
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
    var showWrapperGuide by remember { mutableStateOf(false) }

    // Live antall treff — debounced når filteret endres.
    LaunchedEffect(draft) {
        count = null
        delay(250)
        count = runCatching { CigarRepository.countFiltered(draft) }.getOrNull()
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface,
    ) {
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
                    title = "Form / Vitola",
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
                    onInfo = { showWrapperGuide = true },
                    onToggle = { draft = draft.copy(wrapper = draft.wrapper.toggle(it)) })
                ChipSection("Binder", CigarFilter.BINDER, draft.binder,
                    onToggle = { draft = draft.copy(binder = draft.binder.toggle(it)) })
                ChipSection("Filler", CigarFilter.FILLER, draft.filler,
                    onToggle = { draft = draft.copy(filler = draft.filler.toggle(it)) })

                // Profil-slidere under én PROFIL-seksjon (som iOS).
                SectionHeader("Profil")
                RangeRow("Styrke", draft.strength) { draft = draft.copy(strength = it) }
                SliderDivider()
                RangeRow("Kropp", draft.body) { draft = draft.copy(body = it) }
                SliderDivider()
                RangeRow("Sødme", draft.sweetness) { draft = draft.copy(sweetness = it) }
                SliderDivider()
                RangeRow("Smaksintensitet", draft.flavorIntensity) { draft = draft.copy(flavorIntensity = it) }
                Spacer(Modifier.height(6.dp))

                ChipSection("Smaksnoter", FlavorIcon.familyLabels, draft.flavorFamilies,
                    onToggle = { draft = draft.copy(flavorFamilies = draft.flavorFamilies.toggle(it)) })

                Spacer(Modifier.height(16.dp))
            }

            HorizontalDivider()

            // Bunn-CTA: vertikal stack (som iOS) — Vis treff øverst, Nullstill under.
            Column(
                Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = { onApply(draft) },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        when (count) {
                            null -> "Vis resultater"
                            else -> "Vis $count ${if (count == 1) "resultat" else "resultater"}"
                        },
                        fontWeight = FontWeight.SemiBold
                    )
                }
                TextButton(onClick = { draft = CigarFilter() }, modifier = Modifier.fillMaxWidth()) {
                    Text("Tilbakestill")
                }
            }
            Spacer(Modifier.height(12.dp))
        }
    }

    if (showVitolaGuide) VitolaGuideDialog { showVitolaGuide = false }
    if (showWrapperGuide) WrapperGuideDialog { showWrapperGuide = false }
}

// Varm tan bak valgt chip — samme som iOS (#E0D2BA). Fast, uansett tema.

// Liten seksjonsoverskrift (13sp semibold, sekundær, uppercase) — som iOS.
@Composable
private fun SectionHeader(title: String, onInfo: (() -> Unit)? = null) {
    Row(
        Modifier.padding(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Text(title.uppercase(), fontSize = 13.sp, fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurfaceVariant, letterSpacing = 0.sp)
        if (onInfo != null) {
            IconButton(onClick = onInfo, modifier = Modifier.size(20.dp)) {
                Icon(Icons.Outlined.Info, "Info", tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(16.dp))
            }
        }
    }
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
    // Alle chips er alltid åpne (som iOS) — ingen «Se alle»-kollaps.
    val shown = options

    Column(Modifier.fillMaxWidth().padding(bottom = 4.dp)) {
        SectionHeader(title, onInfo)
        FlowRow(
            Modifier.padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            shown.forEach { opt ->
                FilterPill(
                    text = opt,
                    subtitle = subtitles[opt],
                    selected = opt in selected,
                    onClick = { onToggle(opt) }
                )
            }
        }
    }
}

// Kapsel-chip som iOS: valgt = tan fyll uten kant; uvalgt = accent-kant, klar bg.
@Composable
private fun FilterPill(text: String, subtitle: String?, selected: Boolean, onClick: () -> Unit) {
    val base = Modifier.clip(CircleShape)
    val styled = if (selected) base.background(MaterialTheme.colorScheme.primary)
                 else base.border(1.2.dp, MaterialTheme.colorScheme.primary, CircleShape)
    Row(
        styled.clickable(onClick = onClick).padding(horizontal = 14.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(text, fontSize = 15.sp, fontWeight = FontWeight.Medium, letterSpacing = 0.sp,
            color = if (selected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurface)
        if (subtitle != null) {
            Spacer(Modifier.width(6.dp))
            Text(subtitle, fontSize = 12.sp, letterSpacing = 0.sp,
                color = if (selected) MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.6f)
                        else MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun SliderDivider() {
    HorizontalDivider(Modifier.padding(horizontal = 16.dp),
        color = MaterialTheme.colorScheme.surfaceVariant)
}

@Composable
private fun RangeRow(
    label: String,
    range: ClosedFloatingPointRange<Float>,
    onChange: (ClosedFloatingPointRange<Float>) -> Unit,
) {
    Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(label.uppercase(), fontSize = 13.sp, fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant, letterSpacing = 0.sp,
                modifier = Modifier.weight(1f))
            val full = range == CigarFilter.FULL
            Text(
                if (full) "Alle" else String.format("%.1f – %.1f", range.start, range.endInclusive),
                fontSize = 13.sp,
                fontWeight = if (full) FontWeight.Normal else FontWeight.SemiBold,
                color = if (full) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.primary
            )
        }
        RangeSlider(
            value = range,
            onValueChange = { onChange(it.start..it.endInclusive) },
            valueRange = 1f..5f,
            steps = 7,   // 1,0 – 5,0 i 0,5-steg (som iOS)
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

// Dekkblad-guide: opphav, typiske smaksnoter og et kort kjennetegn per wrapper.
// Fargeprøven til venstre er en pekepinn på hvor lyst/mørkt bladet er. Speiler iOS.
private data class WrapInfo(
    val name: String, val origin: String, val notes: String, val info: String, val color: Color
)

private val WRAPPER_GUIDE = listOf(
    WrapInfo("Connecticut Shade", "USA (Connecticut) / Ecuador",
        "Mild, kremet, nøtter, gress, hvit pepper",
        "Skyggedyrket under duk for et tynt, lyst og silkeaktig blad. Det mildeste alternativet — trygt for nybegynnere.",
        Color(0xFFD8B98A)),
    WrapInfo("Ecuador Connecticut", "Ecuador (Connecticut-frø)",
        "Mild–medium, kremet, nøtter, lett sødme",
        "Connecticut-frø dyrket under Ecuadors naturlige skydekke. Litt fyldigere enn ekte Connecticut Shade, men fortsatt mildt.",
        Color(0xFFC8A56A)),
    WrapInfo("Colorado Claro", "Fargenyanse (variabelt opphav)",
        "Balansert, nøtter, sedertre, mild sødme",
        "Egentlig en fargebeskrivelse (lys rødbrun), ikke et sted. Kjennetegner et middels modent, godt balansert dekkblad.",
        Color(0xFFB07A46)),
    WrapInfo("Cameroon", "Kamerun / Vest-Afrika",
        "Krydder, sort pepper, kakao, tørket frukt",
        "Sjeldent og lunefullt å dyrke. Kjent for en distinkt krydret sødme og et fint, kornete utseende.",
        Color(0xFF8A4E26)),
    WrapInfo("Habano", "Nicaragua / Ecuador (cubansk frø)",
        "Pepper, krydder, sedertre, fyldig, kraftig",
        "Cubansk-frø-dekkblad dyrket utenfor Cuba. Kraftfullt og krydret — ryggraden i mange fyldige sigarer.",
        Color(0xFF7A3E1F)),
    WrapInfo("Corojo", "Honduras / Nicaragua (cubansk sort)",
        "Pepper, krydder, lær, kraftig, tørr finish",
        "Klassisk cubansk sort, i dag mest dyrket i Honduras og Nicaragua. Krydret og robust.",
        Color(0xFF733A1C)),
    WrapInfo("Sumatra", "Ecuador / Indonesia (Sumatra)",
        "Medium, jord, krydder, lær, lett sødme",
        "Mørkt, litt krydret blad. Ecuador-dyrket Sumatra er mildere; indonesisk er kraftigere.",
        Color(0xFF5E3A1E)),
    WrapInfo("San Andrés", "Mexico (San Andrés-dalen)",
        "Mørk sjokolade, kaffe, jord, pepper, sødme",
        "Meksikansk maduro-blad, ofte solmodnet og ekstra fermentert. Rikt og mørkt.",
        Color(0xFF3E2617)),
    WrapInfo("Broadleaf", "USA (Connecticut Broadleaf)",
        "Mørk sjokolade, kaffe, karamell, pepprig finish",
        "Robust, tykt blad som fermenteres til en mørk maduro med naturlig sødme. En klassiker i maduro-sigarer.",
        Color(0xFF2E1B10)),
    WrapInfo("Maduro", "Metode (ofte Broadleaf / San Andrés)",
        "Sjokolade, kaffe, karamell, espresso, sødme",
        "«Maduro» betyr moden. Lengre fermentering med varme og trykk gir et mørkt, søtt og fyldig blad — en metode, ikke et opphav.",
        Color(0xFF241511)),
)

@Composable
private fun WrapperGuideDialog(onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = { TextButton(onClick = onDismiss) { Text("Lukk") } },
        title = { Text("Dekkblad-guide", fontWeight = FontWeight.Bold) },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState())) {
                Text("Dekkbladet står for mye av smaken — fra lyst og mildt til mørkt og kraftig. Fargen er en pekepinn, ikke en fasit.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(Modifier.height(10.dp))
                WRAPPER_GUIDE.forEach { w ->
                    Row(Modifier.fillMaxWidth().padding(vertical = 8.dp)) {
                        Box(Modifier.size(30.dp).clip(CircleShape).background(w.color))
                        Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            Text(w.name, style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.SemiBold)
                            Text(w.origin, style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Spacer(Modifier.height(3.dp))
                            Text(w.notes, style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Medium)
                            Spacer(Modifier.height(2.dp))
                            Text(w.info, style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
            }
        }
    )
}

private fun List<String>.toggle(item: String): List<String> =
    if (item in this) this - item else this + item
