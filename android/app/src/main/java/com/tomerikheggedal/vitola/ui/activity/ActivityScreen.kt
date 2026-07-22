package com.tomerikheggedal.vitola.ui.activity

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import kotlin.math.roundToInt
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
    val starCount = ((item.cigarRating ?: 0) / 20.0).roundToInt().coerceIn(0, 5)
    Column(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp))
            .background(MaterialTheme.colorScheme.surface)
            .clickable(onClick = onClick)
    ) {
        // 1. hvem + verb
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                Modifier.size(24.dp).clip(CircleShape).background(MaterialTheme.colorScheme.primary),
                contentAlignment = Alignment.Center
            ) {
                Text(initials(item.authorName), fontSize = 11.sp, fontWeight = FontWeight.Medium, color = Color.White)
            }
            Spacer(Modifier.width(6.dp))
            Text(item.authorName, fontSize = 13.sp, fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface)
            Spacer(Modifier.width(6.dp))
            Text(item.verbText, fontSize = 13.sp, fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        HorizontalDivider(color = MaterialTheme.colorScheme.background)

        // 2. sigar + «Lagre i liste»
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(Modifier.weight(1f)) {
                Text(item.cigarBrand, fontSize = 16.sp, fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface)
                if (item.cigarMeta.isNotBlank()) {
                    Text(item.cigarMeta, fontSize = 12.sp, fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            Spacer(Modifier.width(8.dp))
            Row(
                Modifier.clickable(enabled = !isWishlisted, onClick = onWishlist),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(if (isWishlisted) "Lagret" else "Lagre i liste", fontSize = 12.sp,
                    fontWeight = FontWeight.Medium, color = MaterialTheme.colorScheme.onSurface)
                Spacer(Modifier.width(5.dp))
                Icon(
                    if (isWishlisted) Icons.Filled.Bookmark else Icons.Outlined.BookmarkBorder,
                    contentDescription = "Lagre i liste", modifier = Modifier.size(20.dp),
                    tint = MaterialTheme.colorScheme.onSurface
                )
            }
        }

        // 3. bilde — kant-til-kant
        if (!item.tastingPhotoUrl.isNullOrBlank()) {
            AsyncImage(
                model = item.tastingPhotoUrl, contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxWidth().height(240.dp)
            )
        }

        // 4. Min vurdering
        if (item.verb != "wishlist" && (item.cigarRating ?: 0) > 0) {
            Row(
                Modifier.fillMaxWidth().padding(start = 16.dp, end = 16.dp, top = 12.dp, bottom = 10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Min vurdering ($starCount/5)", fontSize = 14.sp, fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface)
                Spacer(Modifier.weight(1f))
                Row {
                    repeat(5) { i ->
                        Icon(
                            if (i < starCount) Icons.Filled.Star else Icons.Outlined.StarBorder,
                            contentDescription = null, modifier = Modifier.size(18.dp),
                            tint = if (i < starCount) MaterialTheme.colorScheme.primary
                                   else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.35f)
                        )
                    }
                }
            }
        }

        // 5. notat
        if (!item.personalNotes.isNullOrBlank()) {
            Text(
                item.personalNotes!!, fontSize = 13.sp, lineHeight = 17.sp,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.fillMaxWidth().padding(start = 14.dp, end = 14.dp, top = 2.dp, bottom = 16.dp)
            )
        }
    }
}

private fun initials(name: String): String {
    val s = name.trim().split(" ").filter { it.isNotBlank() }.take(2)
        .mapNotNull { it.firstOrNull()?.toString() }.joinToString("")
    return if (s.isBlank()) "?" else s.uppercase()
}
