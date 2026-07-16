package com.tomerikheggedal.vitola.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.Public
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.tomerikheggedal.vitola.data.FriendProfile
import com.tomerikheggedal.vitola.data.FriendRepository
import com.tomerikheggedal.vitola.data.FriendState
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UserProfileScreen(userId: String, onBack: () -> Unit) {
    val scope = rememberCoroutineScope()
    var profile by remember { mutableStateOf<FriendProfile?>(null) }
    var state by remember { mutableStateOf(FriendState.NONE) }
    var friendshipId by remember { mutableStateOf<String?>(null) }
    var loading by remember { mutableStateOf(true) }
    var working by remember { mutableStateOf(false) }

    suspend fun reloadState() {
        val (s, fid) = FriendRepository.stateWith(userId)
        state = s; friendshipId = fid
    }

    LaunchedEffect(userId) {
        loading = true
        profile = FriendRepository.profile(userId)
        reloadState()
        loading = false
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = { Text(profile?.displayName ?: "Profil", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Tilbake") }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.background)
            )
        }
    ) { padding ->
        when {
            loading -> Box(Modifier.padding(padding).fillMaxSize(), Alignment.Center) { CircularProgressIndicator() }
            profile == null -> Box(Modifier.padding(padding).fillMaxSize(), Alignment.Center) { Text("Fant ikke profilen") }
            else -> {
                val p = profile!!
                Column(Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally) {
                    Avatar(p.avatarUrl)
                    Spacer(Modifier.height(14.dp))
                    Text(p.displayName ?: "Vitola-bruker", style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold)
                    val place = listOfNotNull(p.city, p.country).joinToString(", ")
                    if (place.isNotBlank()) {
                        Spacer(Modifier.height(2.dp))
                        Text(place, style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    p.bio?.takeIf { it.isNotBlank() }?.let {
                        Spacer(Modifier.height(10.dp))
                        Text(it, style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center)
                    }

                    Spacer(Modifier.height(20.dp))
                    // Venne-handling
                    FriendAction(
                        state = state, working = working,
                        onRequest = {
                            working = true
                            scope.launch { runCatching { FriendRepository.request(userId) }; reloadState(); working = false }
                        },
                        onRespond = { accept ->
                            val fid = friendshipId ?: return@FriendAction
                            working = true
                            scope.launch { runCatching { FriendRepository.respond(fid, accept) }; reloadState(); working = false }
                        }
                    )

                    Spacer(Modifier.height(22.dp))
                    StatsCard(p)
                    Spacer(Modifier.height(32.dp))
                }
            }
        }
    }
}

@Composable
private fun FriendAction(state: FriendState, working: Boolean, onRequest: () -> Unit, onRespond: (Boolean) -> Unit) {
    when (state) {
        FriendState.NONE -> Button(onClick = onRequest, enabled = !working, modifier = Modifier.fillMaxWidth()) {
            if (working) CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp, color = MaterialTheme.colorScheme.onPrimary)
            else { Icon(Icons.Filled.PersonAdd, null, modifier = Modifier.size(18.dp)); Spacer(Modifier.width(8.dp)); Text("Legg til venn") }
        }
        FriendState.PENDING_OUT -> OutlinedButton(onClick = {}, enabled = false, modifier = Modifier.fillMaxWidth()) {
            Text("Forespørsel sendt")
        }
        FriendState.PENDING_IN -> Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Button(onClick = { onRespond(true) }, enabled = !working, modifier = Modifier.weight(1f)) { Text("Godta") }
            OutlinedButton(onClick = { onRespond(false) }, enabled = !working, modifier = Modifier.weight(1f)) { Text("Avslå") }
        }
        FriendState.FRIENDS -> OutlinedButton(onClick = {}, enabled = false, modifier = Modifier.fillMaxWidth()) {
            Icon(Icons.Filled.Check, null, modifier = Modifier.size(18.dp)); Spacer(Modifier.width(8.dp)); Text("Venner")
        }
        FriendState.SELF -> {}
    }
}

@Composable
private fun Avatar(url: String?) {
    val size = 92.dp
    if (url != null) {
        AsyncImage(model = url, contentDescription = null, contentScale = ContentScale.Crop,
            modifier = Modifier.size(size).clip(CircleShape))
    } else {
        Box(Modifier.size(size).clip(CircleShape).background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)),
            contentAlignment = Alignment.Center) {
            Icon(Icons.Filled.Person, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(44.dp))
        }
    }
}

@Composable
private fun StatsCard(p: FriendProfile) {
    Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp)).background(MaterialTheme.colorScheme.surface)
        .padding(vertical = 16.dp), verticalAlignment = Alignment.CenterVertically) {
        Cell(Icons.Filled.Inventory2, p.humidorCount, "I humidor", Modifier.weight(1f))
        Divider()
        Cell(Icons.Filled.LocalFireDepartment, p.cigarCount, "Røkt", Modifier.weight(1f))
        Divider()
        Cell(Icons.Filled.Public, p.brandsTried, "Merker prøvd", Modifier.weight(1f))
        Divider()
        Cell(Icons.Filled.Group, p.friendCount, "Venner", Modifier.weight(1f))
    }
}

@Composable
private fun Divider() { Box(Modifier.width(1.dp).height(40.dp).background(MaterialTheme.colorScheme.surfaceVariant)) }

@Composable
private fun Cell(icon: ImageVector, value: Int, label: String, modifier: Modifier = Modifier) {
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Icon(icon, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(20.dp))
        Text("$value", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        Text(label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center)
    }
}
