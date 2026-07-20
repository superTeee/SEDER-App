package com.tomerikheggedal.vitola.ui.activity

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.tomerikheggedal.vitola.data.ActivityItem
import com.tomerikheggedal.vitola.data.ActivityRepository
import com.tomerikheggedal.vitola.data.Supa
import com.tomerikheggedal.vitola.data.WishlistRepository
import io.github.jan.supabase.gotrue.SessionStatus
import io.github.jan.supabase.gotrue.auth
import kotlinx.coroutines.launch

// Aktivitet — scrollbar strøm av delte journal-hendelser. Ikke innlegg, ingen
// kommentarer. Hele kortet → sigarens detaljside. «＋ ønskeliste» legger rett til.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ActivityScreen(onCigar: (String) -> Unit) {
    val status by Supa.client.auth.sessionStatus.collectAsState()
    val isAuthed = status is SessionStatus.Authenticated
    val scope = rememberCoroutineScope()

    var items by remember { mutableStateOf<List<ActivityItem>>(emptyList()) }
    var loading by remember { mutableStateOf(true) }
    var wishlisted by remember { mutableStateOf<Set<String>>(emptySet()) }

    LaunchedEffect(isAuthed) {
        if (isAuthed) {
            loading = true
            items = runCatching { ActivityRepository.activity(40) }.getOrDefault(emptyList())
            loading = false
        } else { items = emptyList(); loading = false }
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Aktivitet", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        }
    ) { padding ->
        Box(Modifier.padding(padding).fillMaxSize()) {
            when {
                !isAuthed -> Centered("Logg inn for å se aktivitet.")
                loading -> CircularProgressIndicator(Modifier.align(Alignment.Center))
                items.isEmpty() -> Centered("Ingen aktivitet ennå.\nDel et journalinnlegg, eller finn nye sigarer i Utforsk.")
                else -> LazyColumn(
                    Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(14.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(items, key = { it.entryId }) { item ->
                        ActivityCard(
                            item = item,
                            isWishlisted = wishlisted.contains(item.cigarId),
                            onClick = { onCigar(item.cigarId) },
                            onWishlist = {
                                if (!wishlisted.contains(item.cigarId)) {
                                    wishlisted = wishlisted + item.cigarId
                                    scope.launch {
                                        runCatching { WishlistRepository.add(item.cigarId) }
                                            .onFailure { wishlisted = wishlisted - item.cigarId }
                                    }
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun BoxScope.Centered(text: String) {
    Text(
        text, textAlign = TextAlign.Center,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.align(Alignment.Center).padding(32.dp)
    )
}

@Composable
private fun ActivityCard(
    item: ActivityItem,
    isWishlisted: Boolean,
    onClick: () -> Unit,
    onWishlist: () -> Unit,
) {
    Column(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp))
            .background(MaterialTheme.colorScheme.surface)
            .clickable(onClick = onClick)
            .padding(12.dp)
    ) {
        // hvem + verb
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier.size(34.dp).clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.15f)),
                contentAlignment = Alignment.Center
            ) {
                Text(initials(item.authorName), style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
            }
            Spacer(Modifier.width(10.dp))
            Text(
                buildString { append(item.authorName); append(" "); append(item.verbText) },
                style = MaterialTheme.typography.bodyMedium
            )
        }

        // rating — prominent (kun logg-hendelser med score)
        if (item.verb != "wishlist" && (item.cigarRating ?: 0) > 0) {
            Spacer(Modifier.height(8.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(stars(item.cigarRating!!), color = MaterialTheme.colorScheme.primary,
                    fontSize = 18.sp, letterSpacing = 2.sp)
                Spacer(Modifier.width(8.dp))
                Text("${item.cigarRating}/100", style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }

        // bilde
        if (!item.tastingPhotoUrl.isNullOrBlank()) {
            Spacer(Modifier.height(9.dp))
            AsyncImage(
                model = item.tastingPhotoUrl, contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxWidth().height(190.dp).clip(RoundedCornerShape(9.dp))
            )
        }

        // notat
        if (!item.personalNotes.isNullOrBlank()) {
            Spacer(Modifier.height(9.dp))
            Text("«${item.personalNotes}»", style = MaterialTheme.typography.bodyMedium,
                fontStyle = FontStyle.Italic)
        }

        // sigar-kort + ønskeliste
        Spacer(Modifier.height(9.dp))
        Row(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(9.dp))
                .background(MaterialTheme.colorScheme.background).padding(10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(Modifier.weight(1f)) {
                Text(item.cigarBrand, style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold)
                if (item.cigarMeta.isNotBlank()) {
                    Text(item.cigarMeta, style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            AssistChip(
                onClick = onWishlist,
                enabled = !isWishlisted,
                label = { Text(if (isWishlisted) "På lista" else "ønskeliste") },
                leadingIcon = {
                    Icon(if (isWishlisted) Icons.Filled.Check else Icons.Filled.Add,
                        null, modifier = Modifier.size(16.dp))
                }
            )
        }
    }
}

private fun initials(name: String): String {
    val s = name.trim().split(" ").filter { it.isNotBlank() }.take(2)
        .mapNotNull { it.firstOrNull()?.toString() }.joinToString("")
    return if (s.isBlank()) "?" else s.uppercase()
}

private fun stars(rating: Int): String {
    val v = rating / 20.0
    return (0 until 5).joinToString("") { i ->
        if (v - i >= 1) "★" else if (v - i >= 0.5) "½" else "☆"
    }
}
