package com.tomerikheggedal.vitola.ui.journal

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tomerikheggedal.vitola.data.StatsRepository
import com.tomerikheggedal.vitola.data.TopBrand
import com.tomerikheggedal.vitola.data.UserStats
import java.text.NumberFormat
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StatistikkSheet(onDismiss: () -> Unit) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var stats by remember { mutableStateOf<UserStats?>(null) }
    var loading by remember { mutableStateOf(true) }

    LaunchedEffect(Unit) {
        stats = StatsRepository.myStats()
        loading = false
    }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.background) {
        Column(
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState())
                .padding(start = 16.dp, end = 16.dp, bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(22.dp)
        ) {
            Text("Statistikk", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(start = 4.dp, top = 4.dp))

            val s = stats
            when {
                loading -> Box(Modifier.fillMaxWidth().height(220.dp), Alignment.Center) {
                    CircularProgressIndicator()
                }
                s == null || s.totalLogged == 0 -> EmptyStats()
                else -> StatsContent(s)
            }
        }
    }
}

@Composable
private fun EmptyStats() {
    Column(
        Modifier.fillMaxWidth().padding(vertical = 40.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Text("Ingen data ennå", style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold)
        Text("Loggfør noen sigarer, så dukker innsikten opp her.",
            style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun StatsContent(s: UserStats) {
    // Nøkkeltall — 2×2 rutenett
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatCard("Røkt totalt", "${s.totalLogged}", Modifier.weight(1f))
            StatCard("Merker prøvd", "${s.brandsTried}", Modifier.weight(1f))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatCard("Snittscore", s.avgScore?.toString() ?: "–", Modifier.weight(1f))
            StatCard("Humidor-verdi", "${kr(s.humidorValue)} kr", Modifier.weight(1f))
        }
    }

    if (s.scoreSeries.size >= 2) {
        StatSection("Score over tid") {
            ScoreChart(s.scoreSeries.map { it.s })
        }
    }

    s.strengthAvg?.let { st ->
        StatSection("Snitt-styrke") {
            Row(horizontalArrangement = Arrangement.spacedBy(9.dp)) {
                (1..5).forEach { i ->
                    Box(
                        Modifier.weight(1f).height(8.dp).clip(RoundedCornerShape(4.dp))
                            .background(
                                if (i <= st) MaterialTheme.colorScheme.primary
                                else MaterialTheme.colorScheme.surfaceVariant
                            )
                    )
                }
            }
            Spacer(Modifier.height(6.dp))
            Text(strengthText(st), style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }

    if (s.topBrands.isNotEmpty()) {
        StatSection("Mest røkte merker") {
            val maxN = s.topBrands.maxOf { it.n }.coerceAtLeast(1)
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                s.topBrands.forEach { b -> BrandBar(b, maxN) }
            }
        }
    }
}

@Composable
private fun StatCard(label: String, value: String, modifier: Modifier = Modifier) {
    Column(
        modifier.clip(RoundedCornerShape(12.dp))
            .background(MaterialTheme.colorScheme.surface).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Text(label.uppercase(), style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.SemiBold, letterSpacing = 0.5.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, fontSize = 22.sp, fontWeight = FontWeight.Bold, maxLines = 1)
    }
}

@Composable
private fun StatSection(title: String, content: @Composable ColumnScope.() -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text(title.uppercase(), style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.SemiBold, letterSpacing = 0.6.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
        Column(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp))
                .background(MaterialTheme.colorScheme.surface).padding(16.dp),
            content = content
        )
    }
}

@Composable
private fun BrandBar(b: TopBrand, maxN: Int) {
    val accent = MaterialTheme.colorScheme.primary
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Text(b.brand, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium,
            maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.width(110.dp))
        Box(Modifier.weight(1f).height(18.dp).clip(RoundedCornerShape(9.dp))
            .background(accent.copy(alpha = 0.12f))) {
            Box(Modifier.fillMaxWidth(b.n.toFloat() / maxN).fillMaxHeight()
                .clip(RoundedCornerShape(9.dp)).background(accent))
        }
        Text("${b.n}", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.End, modifier = Modifier.width(26.dp))
    }
}

// Enkel linjegraf: score 40–100 mappet til høyden.
@Composable
private fun ScoreChart(scores: List<Int>) {
    val accent = MaterialTheme.colorScheme.primary
    Canvas(Modifier.fillMaxWidth().height(190.dp)) {
        if (scores.size < 2) return@Canvas
        val lo = 40f; val hi = 100f
        val w = size.width; val h = size.height
        val stepX = w / (scores.size - 1)
        fun y(v: Int) = h - ((v.coerceIn(lo.toInt(), hi.toInt()) - lo) / (hi - lo)) * h
        val pts = scores.mapIndexed { i, v -> Offset(i * stepX, y(v)) }

        val path = Path().apply {
            moveTo(pts.first().x, pts.first().y)
            for (i in 1 until pts.size) {
                val p0 = pts[i - 1]; val p1 = pts[i]
                val midX = (p0.x + p1.x) / 2
                cubicTo(midX, p0.y, midX, p1.y, p1.x, p1.y)
            }
        }
        drawPath(path, accent, style = Stroke(width = 3f, cap = StrokeCap.Round))
        pts.forEach { drawCircle(accent, radius = 4f, center = it) }
    }
}

private fun kr(v: Double): String =
    NumberFormat.getIntegerInstance(Locale("nb", "NO")).format(v.toLong())

private fun strengthText(v: Double): String = when {
    v < 2 -> "Mild"; v < 3 -> "Medium"; v < 4 -> "Fyldig"; else -> "Sterk"
}
