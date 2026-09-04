package com.tomerikheggedal.vitola.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// Vanlige vitolaer med typisk størrelse (ringmål × lengde i tommer).
// Speiler iOS AddCigarSheet — trykk på en chip fyller format + forhåndsutfyller mål.
data class VitolaPreset(val name: String, val ring: Int, val length: Double)

val vitolaPresets = listOf(
    VitolaPreset("Robusto", 50, 5.0),
    VitolaPreset("Toro", 52, 6.0),
    VitolaPreset("Churchill", 48, 7.0),
    VitolaPreset("Corona", 42, 5.5),
    VitolaPreset("Petit Corona", 42, 4.5),
    VitolaPreset("Lonsdale", 42, 6.5),
    VitolaPreset("Double Corona", 49, 7.5),
    VitolaPreset("Torpedo", 52, 6.1),
    VitolaPreset("Belicoso", 52, 5.5),
    VitolaPreset("Rothschild", 50, 4.5),
    VitolaPreset("Gordo", 60, 6.0),
    VitolaPreset("Lancero", 38, 7.5),
    VitolaPreset("Panetela", 38, 6.0),
    VitolaPreset("Perfecto", 48, 5.0),
    VitolaPreset("Culebra", 38, 5.75),
)

fun vitolaLengthText(v: Double): String =
    if (v % 1.0 == 0.0) v.toInt().toString() else v.toString()

@Composable
fun VitolaChips(selected: String, onPick: (VitolaPreset) -> Unit) {
    LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        items(vitolaPresets) { p ->
            val isSel = selected.equals(p.name, ignoreCase = true)
            Text(
                p.name, fontSize = 13.sp, fontWeight = FontWeight.Medium,
                // Outline-chip (matcher iOS): Accent-kant + hvit tekst; fylt Accent når valgt.
                color = if (isSel) MaterialTheme.colorScheme.onPrimary
                        else MaterialTheme.colorScheme.onBackground,
                modifier = Modifier
                    .clip(CircleShape)
                    .then(
                        if (isSel) Modifier.background(MaterialTheme.colorScheme.primary)
                        else Modifier.border(1.2.dp, MaterialTheme.colorScheme.primary, CircleShape)
                    )
                    .clickable { onPick(p) }
                    .padding(horizontal = 12.dp, vertical = 6.dp)
            )
        }
    }
}
