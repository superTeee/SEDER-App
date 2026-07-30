package com.tomerikheggedal.vitola.ui.activity

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import android.content.Intent
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.StarBorder
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
import kotlin.math.roundToInt
import com.tomerikheggedal.vitola.data.ActivityItem
import com.tomerikheggedal.vitola.data.ActivityRepository
import com.tomerikheggedal.vitola.data.FriendRepository
import com.tomerikheggedal.vitola.data.JournalRepository
import com.tomerikheggedal.vitola.data.ShareRepository
import com.tomerikheggedal.vitola.data.Supa
import com.tomerikheggedal.vitola.data.WishlistRepository
import io.github.jan.supabase.gotrue.SessionStatus
import io.github.jan.supabase.gotrue.auth
import kotlinx.coroutines.launch

// Aktivitet — scrollbar strøm av delte journal-hendelser. Ikke innlegg, ingen
// kommentarer. Hele kortet → sigarens detaljside. «＋ ønskeliste» legger rett til.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ActivityScreen(onProfile: () -> Unit = {}, onCigar: (String) -> Unit, onUser: (String) -> Unit = {}) {
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

    val context = LocalContext.current
    val myId = remember { Supa.client.auth.currentUserOrNull()?.id }
    val snackbar = remember { SnackbarHostState() }
    var pendingDelete by remember { mutableStateOf<ActivityItem?>(null) }
    var showCompose by remember { mutableStateOf(false) }
    var composeLogCigar by remember { mutableStateOf<com.tomerikheggedal.vitola.data.Cigar?>(null) }
    var composeShareId by remember { mutableStateOf<String?>(null) }

    suspend fun reload() {
        items = runCatching { ActivityRepository.activity(40) }.getOrDefault(items)
    }

    fun addFriend(item: ActivityItem) {
        scope.launch {
            val ok = runCatching { FriendRepository.request(item.userId) }.isSuccess
            snackbar.showSnackbar(
                if (ok) "Venneforespørsel sendt til ${item.authorName}" else "Kunne ikke sende forespørsel"
            )
        }
    }
    fun shareItem(item: ActivityItem) {
        scope.launch {
            val slug = item.publicSlug ?: runCatching {
                ShareRepository.setSharing(item.entryId, community = true, external = true).publicSlug
            }.getOrNull()
            if (slug == null) { snackbar.showSnackbar("Kunne ikke dele akkurat nå"); return@launch }
            val url = ShareRepository.publicUrl(slug)
            val name = listOfNotNull(item.cigarBrand, item.cigarSeries, item.cigarVitola).joinToString(" · ")
            val text = name + (item.cigarRating?.let { " · $it/100" } ?: "") + " på SEDER\n$url"
            val send = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"; putExtra(Intent.EXTRA_TEXT, text)
            }
            context.startActivity(Intent.createChooser(send, "Del"))
        }
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        snackbarHost = { SnackbarHost(snackbar) },
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Aktivitet", fontWeight = FontWeight.Bold) },
                navigationIcon = { com.tomerikheggedal.vitola.ui.components.TopBarProfileAvatar(onProfile) },
                actions = {
                    if (isAuthed) {
                        IconButton(onClick = { showCompose = true }) {
                            Icon(Icons.Filled.Add, contentDescription = "Nytt innlegg",
                                tint = MaterialTheme.colorScheme.onBackground)
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
                !isAuthed -> Centered("Logg inn for å se aktivitet.")
                loading -> CircularProgressIndicator(Modifier.align(Alignment.Center))
                items.isEmpty() -> Centered("Ingen aktivitet ennå.\nDel et journalinnlegg, eller finn nye sigarer i Utforsk.")
                else -> LazyColumn(
                    Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    items(items, key = { it.entryId }) { item ->
                        ActivityCard(
                            item = item,
                            isWishlisted = wishlisted.contains(item.cigarId),
                            isMine = myId != null && item.userId == myId,
                            onClick = { onCigar(item.cigarId) },
                            onUser = { onUser(item.userId) },
                            onAddFriend = { addFriend(item) },
                            onShare = { shareItem(item) },
                            onDelete = { pendingDelete = item },
                            onLike = {
                                val wasLiked = item.likedByMe
                                items = items.map {
                                    if (it.entryId == item.entryId)
                                        it.copy(likedByMe = !wasLiked,
                                                likeCount = it.likeCount + if (wasLiked) -1 else 1)
                                    else it
                                }
                                scope.launch {
                                    runCatching { ActivityRepository.toggleLike(item.entryId) }
                                        .onFailure {
                                            items = items.map {
                                                if (it.entryId == item.entryId)
                                                    it.copy(likedByMe = wasLiked,
                                                            likeCount = it.likeCount + if (wasLiked) 1 else -1)
                                                else it
                                            }
                                        }
                                }
                            },
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

    pendingDelete?.let { target ->
        AlertDialog(
            onDismissRequest = { pendingDelete = null },
            title = { Text("Slette innlegget?") },
            text = { Text("Innlegget fjernes fra aktiviteten og journalen din.") },
            confirmButton = {
                TextButton(onClick = {
                    pendingDelete = null
                    scope.launch {
                        runCatching { JournalRepository.deleteLog(target.entryId) }
                        items = items.filterNot { it.entryId == target.entryId }
                    }
                }) { Text("Slett") }
            },
            dismissButton = { TextButton(onClick = { pendingDelete = null }) { Text("Avbryt") } }
        )
    }

    // «+» nytt innlegg: søk opp en sigar → samme logg-ark (0–100 + notat) → del-tilbud.
    if (showCompose) {
        ComposePostSheet(
            onDismiss = { showCompose = false },
            onPick = { cigar -> showCompose = false; composeLogCigar = cigar }
        )
    }
    composeLogCigar?.let { c ->
        com.tomerikheggedal.vitola.ui.detail.SmokingLogSheet(
            cigar = c,
            humidorEntryId = null,
            onDismiss = { composeLogCigar = null },
            onLogged = { logId ->
                composeLogCigar = null
                scope.launch { reload() }
                if (logId.isNotBlank()) composeShareId = logId
            }
        )
    }
    composeShareId?.let { eid ->
        com.tomerikheggedal.vitola.ui.detail.ShareAfterSaveSheet(
            entryId = eid, onDismiss = { composeShareId = null }
        )
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
    isMine: Boolean,
    onClick: () -> Unit,
    onUser: () -> Unit,
    onAddFriend: () -> Unit,
    onShare: () -> Unit,
    onDelete: () -> Unit,
    onLike: () -> Unit,
    onWishlist: () -> Unit,
) {
    var menuOpen by remember { mutableStateOf(false) }
    val starCount = ((item.cigarRating ?: 0) / 20.0).roundToInt().coerceIn(0, 5)
    Column(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp))
            .background(MaterialTheme.colorScheme.surface)
            .clickable(onClick = onClick)
    ) {
        // 1. hvem + verb — avatar+navn trykkbart inn til posterens profil
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                Modifier.clip(RoundedCornerShape(6.dp)).clickable(onClick = onUser),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    Modifier.size(28.dp).clip(CircleShape).background(MaterialTheme.colorScheme.primary),
                    contentAlignment = Alignment.Center
                ) {
                    Text(initials(item.authorName), fontSize = 13.sp, fontWeight = FontWeight.Medium, color = Color.White)
                }
                Spacer(Modifier.width(8.dp))
                Text(item.authorName, fontSize = 14.sp, fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface)
            }
            Spacer(Modifier.width(6.dp))
            Text(item.verbText, fontSize = 13.sp, fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(Modifier.weight(1f))
            Box {
                IconButton(onClick = { menuOpen = true }, modifier = Modifier.size(32.dp)) {
                    Icon(Icons.Filled.MoreVert, contentDescription = "Mer",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                    if (!isMine) {
                        DropdownMenuItem(text = { Text("Legg til som venn") },
                            onClick = { menuOpen = false; onAddFriend() })
                    }
                    DropdownMenuItem(text = { Text("Del") },
                        onClick = { menuOpen = false; onShare() })
                    if (isMine) {
                        DropdownMenuItem(text = { Text("Slett") },
                            onClick = { menuOpen = false; onDelete() })
                    }
                }
            }
        }
        HorizontalDivider(color = MaterialTheme.colorScheme.background)

        // 2. sigar + «Lagre i liste»
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(Modifier.weight(1f)) {
                Text(item.cigarBrand, fontSize = 17.sp, fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface)
                if (item.cigarMeta.isNotBlank()) {
                    Text(item.cigarMeta, fontSize = 13.sp, fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            Spacer(Modifier.width(8.dp))
            // Like — hjerte + antall like tett inntil ikonet
            Row(
                Modifier.clickable(onClick = onLike),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    if (item.likedByMe) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder,
                    contentDescription = "Lik", modifier = Modifier.size(26.dp),
                    tint = if (item.likedByMe) Color(0xFFFF3B30) else MaterialTheme.colorScheme.onSurface
                )
                if (item.likeCount > 0) {
                    Spacer(Modifier.width(5.dp))
                    Text("${item.likeCount}", fontSize = 14.sp, fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            Spacer(Modifier.width(14.dp))
            // Bokmerke — ikon uten label, 2px større
            Icon(
                if (isWishlisted) Icons.Filled.Bookmark else Icons.Outlined.BookmarkBorder,
                contentDescription = "Lagre i liste",
                modifier = Modifier.size(26.dp).clickable(enabled = !isWishlisted, onClick = onWishlist),
                tint = MaterialTheme.colorScheme.onSurface
            )
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
                Text("Min vurdering ($starCount/5)", fontSize = 15.sp, fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface)
                Spacer(Modifier.weight(1f))
                Row {
                    repeat(5) { i ->
                        Icon(
                            if (i < starCount) Icons.Filled.Star else Icons.Outlined.StarBorder,
                            contentDescription = null, modifier = Modifier.size(19.dp),
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
                item.personalNotes!!, fontSize = 14.sp, lineHeight = 18.sp,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.fillMaxWidth().padding(start = 14.dp, end = 14.dp, top = 2.dp, bottom = 16.dp)
            )
        }
    }
}

// «+» fra Aktivitet: søk opp en sigar å skrive om → velg → logg-ark (i ActivityScreen).
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ComposePostSheet(onDismiss: () -> Unit, onPick: (com.tomerikheggedal.vitola.data.Cigar) -> Unit) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()
    var query by remember { mutableStateOf("") }
    var results by remember { mutableStateOf<List<com.tomerikheggedal.vitola.data.Cigar>>(emptyList()) }
    var searching by remember { mutableStateOf(false) }
    var hasSearched by remember { mutableStateOf(false) }

    fun runSearch() {
        val q = query.trim()
        if (q.isBlank()) { results = emptyList(); hasSearched = false; return }
        scope.launch {
            searching = true; hasSearched = true
            results = runCatching {
                com.tomerikheggedal.vitola.data.CigarRepository.search(q).map { it.cigar }.distinctBy { it.id }
            }.getOrDefault(emptyList())
            searching = false
        }
    }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface) {
        Column(
            Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(bottom = 24.dp)
                .heightIn(max = 520.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Text("Nytt innlegg", fontSize = 20.sp, fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface)
            Text("Søk opp en sigar du vil skrive om.", fontSize = 14.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
            OutlinedTextField(
                value = query,
                onValueChange = { query = it; if (it.isBlank()) { results = emptyList(); hasSearched = false } },
                placeholder = { Text("F.eks. Liga Privada, Padrón…") },
                leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
                trailingIcon = { if (searching) CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp) },
                singleLine = true,
                keyboardActions = androidx.compose.foundation.text.KeyboardActions(onSearch = { runSearch() }),
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(
                    imeAction = androidx.compose.ui.text.input.ImeAction.Search),
                modifier = Modifier.fillMaxWidth()
            )
            if (hasSearched && results.isEmpty() && !searching) {
                Text("Ingen sigarer matchet «$query».", fontSize = 13.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            LazyColumn(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                items(results, key = { it.id }) { cigar ->
                    Column(
                        Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp))
                            .clickable { onPick(cigar) }.padding(vertical = 10.dp)
                    ) {
                        Text(cigar.brand, fontSize = 15.sp, fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurface)
                        val meta = listOfNotNull(cigar.series, cigar.vitola).joinToString(" · ")
                        if (meta.isNotBlank()) {
                            Text(meta, fontSize = 12.sp, fontWeight = FontWeight.Medium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
            }
        }
    }
}

private fun initials(name: String): String {
    val s = name.trim().split(" ").filter { it.isNotBlank() }.take(2)
        .mapNotNull { it.firstOrNull()?.toString() }.joinToString("")
    return if (s.isBlank()) "?" else s.uppercase()
}
