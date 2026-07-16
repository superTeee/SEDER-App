package com.tomerikheggedal.vitola.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.filled.Settings
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
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.tomerikheggedal.vitola.data.Profile
import com.tomerikheggedal.vitola.data.ProfileRepository
import com.tomerikheggedal.vitola.data.ProfileStats
import com.tomerikheggedal.vitola.data.Supa
import io.github.jan.supabase.gotrue.SessionStatus
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.gotrue.providers.Google
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(onSettings: () -> Unit = {}) {
    val scope = rememberCoroutineScope()
    val status by Supa.client.auth.sessionStatus.collectAsState()
    val isAuthed = status is SessionStatus.Authenticated

    var profile by remember { mutableStateOf<Profile?>(null) }
    var stats by remember { mutableStateOf(ProfileStats(0, 0, 0, 0)) }
    var loading by remember { mutableStateOf(false) }
    var reloadKey by remember { mutableStateOf(0) }
    var showBioEditor by remember { mutableStateOf(false) }

    LaunchedEffect(isAuthed, reloadKey, ProfileRefresh.version) {
        if (isAuthed) {
            loading = true
            profile = runCatching { ProfileRepository.myProfile() }.getOrNull()
            stats = runCatching { ProfileRepository.myStats() }.getOrDefault(ProfileStats(0, 0, 0, 0))
            loading = false
        } else {
            profile = null; stats = ProfileStats(0, 0, 0, 0)
        }
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Profil", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                ),
                actions = {
                    IconButton(onClick = onSettings) {
                        Icon(Icons.Filled.Settings, contentDescription = "Innstillinger")
                    }
                }
            )
        }
    ) { padding ->
        Box(Modifier.padding(padding).fillMaxSize()) {
            when {
                !isAuthed -> LoginPrompt { scope.launch { Supa.client.auth.signInWith(Google) } }
                loading -> CircularProgressIndicator(Modifier.align(Alignment.Center))
                else -> Column(
                    Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    // Hero: avatar + navn + sted + bio
                    Avatar(profile?.avatarUrl ?: ProfileRepository.authAvatar())
                    Spacer(Modifier.height(14.dp))
                    Text(
                        profile?.displayName ?: ProfileRepository.authName() ?: "Vitola-bruker",
                        style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold
                    )
                    val place = listOfNotNull(profile?.city, profile?.country).joinToString(", ")
                    if (place.isNotBlank()) {
                        Spacer(Modifier.height(2.dp))
                        Text(place, style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }

                    Spacer(Modifier.height(10.dp))
                    val bio = profile?.bio
                    Text(
                        if (bio.isNullOrBlank()) "Legg til bio…" else bio,
                        style = MaterialTheme.typography.bodyMedium,
                        textAlign = TextAlign.Center,
                        color = if (bio.isNullOrBlank()) MaterialTheme.colorScheme.primary
                                else MaterialTheme.colorScheme.onSurface,
                        modifier = Modifier.clip(RoundedCornerShape(6.dp)).clickable { showBioEditor = true }
                            .padding(horizontal = 8.dp, vertical = 4.dp)
                    )

                    Spacer(Modifier.height(22.dp))
                    StatsCard(stats)
                }
            }
        }
    }

    if (showBioEditor) {
        BioEditorDialog(
            current = profile?.bio ?: "",
            onDismiss = { showBioEditor = false },
            onSave = { newBio ->
                showBioEditor = false
                scope.launch { runCatching { ProfileRepository.saveBio(newBio) }; reloadKey++ }
            }
        )
    }
}

@Composable
private fun Avatar(url: String?) {
    val size = 96.dp
    if (url != null) {
        AsyncImage(model = url, contentDescription = null, contentScale = ContentScale.Crop,
            modifier = Modifier.size(size).clip(CircleShape))
    } else {
        Box(
            Modifier.size(size).clip(CircleShape)
                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(Icons.Filled.Person, null, tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(46.dp))
        }
    }
}

// 4-cellers stats-kort med ikoner og skillelinjer — som iOS.
@Composable
private fun StatsCard(stats: ProfileStats) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp))
            .background(MaterialTheme.colorScheme.surface).padding(vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        StatCell(Icons.Filled.Inventory2, stats.humidorEntries, "I humidor", Modifier.weight(1f))
        StatDivider()
        StatCell(Icons.Filled.LocalFireDepartment, stats.cigars, "Røkt", Modifier.weight(1f))
        StatDivider()
        StatCell(Icons.Filled.Public, stats.brandsTried, "Merker prøvd", Modifier.weight(1f))
        StatDivider()
        StatCell(Icons.Filled.Group, stats.friends, "Venner", Modifier.weight(1f))
    }
}

@Composable
private fun StatDivider() {
    Box(Modifier.width(1.dp).height(40.dp).background(MaterialTheme.colorScheme.surfaceVariant))
}

@Composable
private fun StatCell(icon: ImageVector, value: Int, label: String, modifier: Modifier = Modifier) {
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Icon(icon, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(20.dp))
        Text("$value", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        Text(label, style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
    }
}

@Composable
private fun BioEditorDialog(current: String, onDismiss: () -> Unit, onSave: (String) -> Unit) {
    var text by remember { mutableStateOf(current) }
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = { TextButton(onClick = { onSave(text) }) { Text("Lagre") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Avbryt") } },
        title = { Text("Bio", fontWeight = FontWeight.Bold) },
        text = {
            OutlinedTextField(
                value = text, onValueChange = { text = it },
                placeholder = { Text("Skriv litt om deg selv…") },
                modifier = Modifier.fillMaxWidth(), minLines = 3
            )
        }
    )
}

@Composable
private fun LoginPrompt(onLogin: () -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("Logg inn for å se profilen din.", textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(Modifier.height(16.dp))
        Button(onClick = onLogin) { Text("Logg inn med Google") }
    }
}
