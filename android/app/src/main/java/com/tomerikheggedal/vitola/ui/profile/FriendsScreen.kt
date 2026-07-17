package com.tomerikheggedal.vitola.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.tomerikheggedal.vitola.data.FriendEntry
import com.tomerikheggedal.vitola.data.FriendRepository
import com.tomerikheggedal.vitola.data.UserSearchResult
import com.tomerikheggedal.vitola.ui.components.SectionLabel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FriendsScreen(onBack: () -> Unit, onUser: (String) -> Unit) {
    val scope = rememberCoroutineScope()
    var entries by remember { mutableStateOf<List<FriendEntry>>(emptyList()) }
    var myCode by remember { mutableStateOf<String?>(null) }
    var query by remember { mutableStateOf("") }
    var results by remember { mutableStateOf<List<UserSearchResult>>(emptyList()) }
    var tab by remember { mutableStateOf(0) }
    var reloadKey by remember { mutableStateOf(0) }

    suspend fun reload() { entries = FriendRepository.friendsAndRequests() }

    LaunchedEffect(reloadKey) { reload(); myCode = FriendRepository.myFriendCode() }
    LaunchedEffect(query) {
        if (query.isBlank()) { results = emptyList(); return@LaunchedEffect }
        delay(300)
        results = FriendRepository.searchUsers(query)
    }

    val friends = entries.filter { it.status == "accepted" }
    val incoming = entries.filter { it.status == "pending" && it.direction == "incoming" }
    val outgoing = entries.filter { it.status == "pending" && it.direction == "outgoing" }
    val pendingCount = incoming.size + outgoing.size

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = { Text("Venner", fontWeight = FontWeight.Bold) },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Tilbake") } },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.background)
            )
        }
    ) { padding ->
        LazyColumn(Modifier.padding(padding).fillMaxSize(), contentPadding = PaddingValues(bottom = 24.dp)) {
            // Søk
            item {
                OutlinedTextField(
                    value = query, onValueChange = { query = it },
                    placeholder = { Text("Søk etter brukere") },
                    leadingIcon = { Icon(Icons.Filled.Search, null) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)
                )
            }
            if (query.isNotBlank()) {
                items(results, key = { "s_${it.id}" }) { r ->
                    SearchRow(r, alreadyFriend = entries.any { it.otherUserId == r.id }) {
                        scope.launch { runCatching { FriendRepository.request(r.id) }; reload() }
                    }
                    HorizontalDivider(color = MaterialTheme.colorScheme.surfaceVariant)
                }
                if (results.isEmpty()) item {
                    Text("Ingen brukere funnet", color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(20.dp))
                }
            } else {
                // Din kode
                item { SectionLabel("Din kode") }
                item {
                    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp).clip(RoundedCornerShape(6.dp))
                        .background(MaterialTheme.colorScheme.surface).padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f)) {
                            Text("Del denne med en venn", style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Text(myCode ?: "—", style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
                        }
                    }
                }

                // Tabs
                item {
                    TabRow(selectedTabIndex = tab, containerColor = MaterialTheme.colorScheme.background,
                        modifier = Modifier.padding(top = 12.dp)) {
                        Tab(selected = tab == 0, onClick = { tab = 0 }, text = { Text("Venner (${friends.size})") })
                        Tab(selected = tab == 1, onClick = { tab = 1 },
                            text = { Text("Forespørsler" + if (pendingCount > 0) " ($pendingCount)" else "") })
                    }
                }

                if (tab == 0) {
                    if (friends.isEmpty()) item {
                        Text("Ingen venner ennå. Søk etter en venn i søkefeltet.",
                            color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(20.dp))
                    }
                    items(friends, key = { it.friendshipId }) { f ->
                        FriendRow(f) { onUser(f.otherUserId) }
                        HorizontalDivider(color = MaterialTheme.colorScheme.surfaceVariant)
                    }
                } else {
                    if (incoming.isEmpty() && outgoing.isEmpty()) item {
                        Text("Ingen forespørsler for øyeblikket.",
                            color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(20.dp))
                    }
                    if (incoming.isNotEmpty()) item { SectionLabel("Innkommende") }
                    items(incoming, key = { "in_${it.friendshipId}" }) { e ->
                        RequestRow(e, incoming = true,
                            onAccept = { scope.launch { runCatching { FriendRepository.respond(e.friendshipId, true) }; reload() } },
                            onDecline = { scope.launch { runCatching { FriendRepository.respond(e.friendshipId, false) }; reload() } },
                            onOpen = { onUser(e.otherUserId) })
                        HorizontalDivider(color = MaterialTheme.colorScheme.surfaceVariant)
                    }
                    if (outgoing.isNotEmpty()) item { SectionLabel("Sendt, venter på svar") }
                    items(outgoing, key = { "out_${it.friendshipId}" }) { e ->
                        RequestRow(e, incoming = false, onAccept = {}, onDecline = {}, onOpen = { onUser(e.otherUserId) })
                        HorizontalDivider(color = MaterialTheme.colorScheme.surfaceVariant)
                    }
                }
            }
        }
    }
}

@Composable
private fun Avatar(url: String?) {
    if (url != null) AsyncImage(model = url, contentDescription = null, contentScale = ContentScale.Crop,
        modifier = Modifier.size(40.dp).clip(CircleShape))
    else Box(Modifier.size(40.dp).clip(CircleShape).background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)),
        contentAlignment = Alignment.Center) {
        Icon(Icons.Filled.Person, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(22.dp))
    }
}

@Composable
private fun SearchRow(r: UserSearchResult, alreadyFriend: Boolean, onAdd: () -> Unit) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically) {
        Avatar(r.avatarUrl)
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(r.displayName ?: "Vitola-bruker", fontWeight = FontWeight.Medium, style = MaterialTheme.typography.bodyLarge)
            r.friendCode?.let { Text(it, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant) }
        }
        if (alreadyFriend) Text("Lagt til", style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
        else TextButton(onClick = onAdd) { Text("Legg til") }
    }
}

@Composable
private fun FriendRow(f: FriendEntry, onOpen: () -> Unit) {
    Row(Modifier.fillMaxWidth().clickable(onClick = onOpen).padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically) {
        Avatar(f.otherAvatarUrl)
        Spacer(Modifier.width(12.dp))
        Text(f.otherDisplayName ?: "Vitola-bruker", fontWeight = FontWeight.Medium,
            style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
    }
}

@Composable
private fun RequestRow(e: FriendEntry, incoming: Boolean, onAccept: () -> Unit, onDecline: () -> Unit, onOpen: () -> Unit) {
    Row(Modifier.fillMaxWidth().clickable(onClick = onOpen).padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically) {
        Avatar(e.otherAvatarUrl)
        Spacer(Modifier.width(12.dp))
        Text(e.otherDisplayName ?: "Vitola-bruker", fontWeight = FontWeight.Medium,
            style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
        if (incoming) {
            TextButton(onClick = onAccept) { Text("Godkjenn") }
            TextButton(onClick = onDecline) { Text("Avslå", color = MaterialTheme.colorScheme.error) }
        } else {
            Text("Venter", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
