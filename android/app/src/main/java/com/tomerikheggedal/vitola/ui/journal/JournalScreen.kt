package com.tomerikheggedal.vitola.ui.journal

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.BarChart
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material.icons.outlined.PictureAsPdf
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.tomerikheggedal.vitola.data.JournalRepository
import com.tomerikheggedal.vitola.data.ProManager
import com.tomerikheggedal.vitola.data.Supa
import com.tomerikheggedal.vitola.data.TastingLog
import com.tomerikheggedal.vitola.ui.components.ScoreBadge
import com.tomerikheggedal.vitola.ui.components.SectionLabel
import io.github.jan.supabase.gotrue.SessionStatus
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.gotrue.providers.Google
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.OffsetDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

private val NO = Locale("nb", "NO")
private val MONTH_FMT = DateTimeFormatter.ofPattern("LLLL yyyy", NO)
private val DATE_FMT = DateTimeFormatter.ofPattern("d. MMM", NO)

private fun parseInstant(s: String): Instant? =
    runCatching { OffsetDateTime.parse(s).toInstant() }
        .recoverCatching { Instant.parse(s) }
        .getOrNull()

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun JournalScreen(onProfile: () -> Unit = {}, onCigar: (String) -> Unit, onPaywall: () -> Unit = {}) {
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val status by Supa.client.auth.sessionStatus.collectAsState()
    val isAuthed = status is SessionStatus.Authenticated
    val isPro by ProManager.isPro.collectAsState()

    var logs by remember { mutableStateOf<List<TastingLog>>(emptyList()) }
    var loading by remember { mutableStateOf(false) }
    var editLog by remember { mutableStateOf<TastingLog?>(null) }
    var reloadKey by remember { mutableStateOf(0) }
    var menuOpen by remember { mutableStateOf(false) }
    var showStats by remember { mutableStateOf(false) }

    suspend fun reload() { logs = runCatching { JournalRepository.myLogs() }.getOrDefault(emptyList()) }

    LaunchedEffect(isAuthed, reloadKey) {
        if (isAuthed) { loading = true; reload(); loading = false } else logs = emptyList()
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Journal", fontWeight = FontWeight.Bold) },
                navigationIcon = { com.tomerikheggedal.vitola.ui.components.TopBarProfileAvatar(onProfile) },
                actions = {
                    if (isAuthed) {
                        Box {
                            IconButton(onClick = { menuOpen = true }) {
                                Icon(Icons.Outlined.MoreVert, contentDescription = "Mer")
                            }
                            DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                                DropdownMenuItem(
                                    text = { Text("Statistikk") },
                                    leadingIcon = { Icon(Icons.Outlined.BarChart, null) },
                                    onClick = { menuOpen = false; if (isPro) showStats = true else onPaywall() }
                                )
                                DropdownMenuItem(
                                    text = { Text("Eksporter som PDF") },
                                    leadingIcon = { Icon(Icons.Outlined.PictureAsPdf, null) },
                                    enabled = logs.isNotEmpty(),
                                    onClick = { menuOpen = false; if (isPro) scope.launch { runCatching { JournalExport.exportPdf(context, logs) } } else onPaywall() }
                                )
                                DropdownMenuItem(
                                    text = { Text("Eksporter som CSV") },
                                    leadingIcon = { Icon(Icons.Outlined.Description, null) },
                                    enabled = logs.isNotEmpty(),
                                    onClick = { menuOpen = false; if (isPro) scope.launch { runCatching { JournalExport.exportCsv(context, logs) } } else onPaywall() }
                                )
                            }
                        }
                    }
                },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        }
    ) { padding ->
        Box(Modifier.padding(padding).fillMaxSize()) {
            when {
                !isAuthed -> LoginPrompt { scope.launch { Supa.client.auth.signInWith(Google) } }
                loading -> CircularProgressIndicator(Modifier.align(Alignment.Center))
                logs.isEmpty() -> Text(
                    "Ingen journalinnlegg ennå.",
                    textAlign = TextAlign.Center,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.align(Alignment.Center).padding(32.dp)
                )
                else -> {
                    // Grupper per måned (loggene er allerede sortert nyest først).
                    val byMonth = logs.groupBy { log ->
                        parseInstant(log.smokedAt)?.atZone(ZoneId.systemDefault())?.format(MONTH_FMT)
                            ?.replaceFirstChar { it.uppercase() } ?: "Ukjent"
                    }
                    LazyColumn(
                        Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(bottom = 24.dp)
                    ) {
                        byMonth.forEach { (month, monthLogs) ->
                            item(key = "m_$month") { SectionLabel(month) }
                            itemsIndexed(monthLogs, key = { _, it -> it.id }) { index, log ->
                                JournalTimelineEntry(
                                    log = log,
                                    isFirst = index == 0,
                                    isLast = index == monthLogs.lastIndex,
                                    onClick = { editLog = log }
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    editLog?.let { log ->
        EditJournalSheet(
            log = log,
            onDismiss = { editLog = null },
            onChanged = { editLog = null; reloadKey++ }
        )
    }

    if (showStats) StatistikkSheet(onDismiss = { showStats = false })
}

// Én journaloppføring med vertikal tidslinje til venstre (som iOS): linje over/under
// og et accent-punkt, med linja skjult over første og under siste innlegg i måneden.
@Composable
private fun JournalTimelineEntry(
    log: TastingLog,
    isFirst: Boolean,
    isLast: Boolean,
    onClick: () -> Unit,
) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp).height(IntrinsicSize.Min),
        verticalAlignment = Alignment.Top
    ) {
        Column(
            Modifier.width(24.dp).fillMaxHeight(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                Modifier.width(1.5.dp).weight(1f)
                    .background(if (isFirst) Color.Transparent else MaterialTheme.colorScheme.outlineVariant)
            )
            Box(Modifier.size(10.dp).clip(CircleShape).background(MaterialTheme.colorScheme.primary))
            Box(
                Modifier.width(1.5.dp).weight(1f)
                    .background(if (isLast) Color.Transparent else MaterialTheme.colorScheme.outlineVariant)
            )
        }
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f)) {
            JournalCard(log, onClick)
            if (!isLast) Spacer(Modifier.height(18.dp))
        }
    }
}

@Composable
private fun JournalCard(log: TastingLog, onClick: () -> Unit) {
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(6.dp))
            .background(MaterialTheme.colorScheme.surface)
            .clickable(onClick = onClick)
    ) {
        log.photoUrl?.let { url ->
            AsyncImage(
                model = url, contentDescription = null, contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxWidth().height(180.dp)
            )
        }
        Row(Modifier.fillMaxWidth().padding(14.dp), verticalAlignment = Alignment.Top) {
            Column(Modifier.weight(1f)) {
                val c = log.cigar
                Text(c?.brand ?: "Ukjent sigar", style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Medium, letterSpacing = 0.sp)
                val sub = listOfNotNull(c?.series, c?.vitola).joinToString(" · ")
                if (sub.isNotBlank()) Text(sub, style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                log.personalNotes?.takeIf { it.isNotBlank() }?.let {
                    Spacer(Modifier.height(4.dp))
                    Text(it, style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface, maxLines = 2)
                }
                val date = parseInstant(log.smokedAt)?.atZone(ZoneId.systemDefault())?.format(DATE_FMT)
                if (date != null) {
                    Spacer(Modifier.height(6.dp))
                    Text(date, style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            log.rating?.let { rating ->
                Spacer(Modifier.width(10.dp))
                ScoreBadge("$rating" + (log.scoreLabel?.let { " · $it" } ?: ""), fontSize = 12.sp)
            }
        }
    }
}

@Composable
private fun LoginPrompt(onLogin: () -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("Logg inn for å se journalen din.", textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(Modifier.height(16.dp))
        Button(onClick = onLogin) { Text("Logg inn med Google") }
    }
}
