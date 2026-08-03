package com.tomerikheggedal.vitola.ui.components

import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.core.animateFloat
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

// Stilren skanne-loader (speiler iOS ScanningOverlay): gull-hjørner rammer inn en
// sigar i kontur med et rundt sigarbelte, en gull-stråle glir opp og ned, og
// teksten veksler mykt mellom de tre stegene.
@Composable
fun ScanLoader() {
    val steps = listOf("Skanner sigarbeltet", "Skanner dekkblad", "Søker i basen")
    var idx by remember { mutableStateOf(0) }
    LaunchedEffect(Unit) {
        while (true) { delay(4600); idx = (idx + 1) % steps.size }
    }

    val accent = MaterialTheme.colorScheme.primary
    val outline = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)

    val infinite = rememberInfiniteTransition(label = "scanBeam")
    val beam by infinite.animateFloat(
        initialValue = 0f, targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1400, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse,
        ), label = "beamY"
    )

    Box(
        Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.55f)),
        contentAlignment = Alignment.Center
    ) {
        Column(
            Modifier
                .background(MaterialTheme.colorScheme.surface, RoundedCornerShape(20.dp))
                .padding(horizontal = 44.dp, vertical = 42.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // ── Skanne-vindu (uten bakgrunn) ──
            Box(Modifier.size(width = 158.dp, height = 72.dp)) {
                // Hjørne-braketter
                Canvas(Modifier.fillMaxSize()) {
                    val len = 12.dp.toPx(); val inset = 6.dp.toPx(); val sw = 1.5.dp.toPx()
                    val x0 = inset; val x1 = size.width - inset; val y0 = 0f; val y1 = size.height
                    val c = accent.copy(alpha = 0.7f)
                    fun l(a: Offset, b: Offset) = drawLine(c, a, b, sw, cap = StrokeCap.Round)
                    l(Offset(x0, y0 + len), Offset(x0, y0)); l(Offset(x0, y0), Offset(x0 + len, y0))
                    l(Offset(x1 - len, y0), Offset(x1, y0)); l(Offset(x1, y0), Offset(x1, y0 + len))
                    l(Offset(x0, y1 - len), Offset(x0, y1)); l(Offset(x0, y1), Offset(x0 + len, y1))
                    l(Offset(x1 - len, y1), Offset(x1, y1)); l(Offset(x1, y1), Offset(x1, y1 - len))
                }

                // Sigar i kontur med rundt sigarbelte
                Box(
                    Modifier.align(Alignment.Center).rotate(-9f)
                        .size(width = 93.dp, height = 17.dp)
                        .border(1.5.dp, outline, RoundedCornerShape(9.dp)),
                    contentAlignment = Alignment.CenterEnd
                ) {
                    Box(
                        Modifier.padding(end = 7.dp).size(14.dp)
                            .background(accent.copy(alpha = 0.15f), CircleShape)
                            .border(1.5.dp, accent, CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Box(Modifier.size(3.dp).background(accent, CircleShape))
                    }
                }

                // Skanner-stråle: opp og ned
                Box(
                    Modifier.fillMaxWidth().padding(horizontal = 6.dp)
                        .offset(y = (8f + 54f * beam).dp)
                        .height(2.dp)
                        .background(
                            Brush.horizontalGradient(
                                listOf(Color.Transparent, accent, accent, Color.Transparent)
                            ),
                            RoundedCornerShape(1.dp)
                        )
                )
            }

            Spacer(Modifier.height(40.dp))

            Crossfade(targetState = steps[idx], animationSpec = tween(700), label = "scanStep") { s ->
                Text(
                    s,
                    color = MaterialTheme.colorScheme.onSurface,
                    style = MaterialTheme.typography.bodyMedium.copy(fontSize = 17.sp)
                )
            }
        }
    }
}
