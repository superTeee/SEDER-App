package com.tomerikheggedal.vitola.ui.journal

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.tomerikheggedal.vitola.data.JournalRepository
import com.tomerikheggedal.vitola.data.Supa
import com.tomerikheggedal.vitola.data.TastingLog
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
fun JournalScreen(onCigar: (String) -> Unit) {
    val scope = rememberCoroutineScope()
    val status by Supa.client.auth.sessionStatus.collectAsState()
    val isAuthed = status is SessionStatus.Authenticated

    var logs by remember { mutableStateOf<List<TastingLog>>(emptyList()) }
    var loading by remember { mutableStateOf(false) }
    var editLog by remember { mutableStateOf<TastingLog?>(null) }
    var reloadKey by remember { mutableStateOf(0) }

    suspend fun reload() { logs = runCatching { JournalRepository.myLogs() }.getOrDefault(emptyList()) }

    LaunchedEffect(isAuthed, reloadKey) {
        if (isAuthed) { loading = true; reload(); loading = false } else logs = emptyList()
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Journal", fontWeight = FontWeight.Bold) },
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
                        contentPadding = PaddingValues(bottom = 24.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        byMonth.forEach { (month, monthLogs) ->
                            item(key = "m_$month") { SectionLabel(month) }
                            items(monthLogs, key = { it.id }) { log ->
                                JournalCard(log) { editLog = log }
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
}

@Composable
private fun JournalCard(log: TastingLog, onClick: () -> Unit) {
    Column(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
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
                Text(
                    "$rating" + (log.scoreLabel?.let { " · $it" } ?: ""),
                    style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.primary,
                    modifier = Modifier
                        .clip(RoundedCornerShape(6.dp))
                        .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f))
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                )
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
