package com.tomerikheggedal.vitola.ui.explore

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
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

