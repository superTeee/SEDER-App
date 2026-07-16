package com.tomerikheggedal.vitola.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Settings
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
    var stats by remember { mutableStateOf(ProfileStats(0, 0, 0)) }
    var loading by remember { mutableStateOf(false) }

    LaunchedEffect(isAuthed) {
        if (isAuthed) {
            loading = true
            profile = runCatching { ProfileRepository.myProfile() }.getOrNull()
            stats = runCatching { ProfileRepository.myStats() }.getOrDefault(ProfileStats(0, 0, 0))
            loading = false
        } else {
            profile = null; stats = ProfileStats(0, 0, 0)
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
                    ProfileRepository.authEmail()?.let {
                        Spacer(Modifier.height(2.dp))
                        Text(it, style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    profile?.friendCode?.let {
                        Spacer(Modifier.height(8.dp))
                        Text("Vennekode: $it", style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.primary, letterSpacing = 0.sp)
                    }

                    Spacer(Modifier.height(24.dp))
                    StatsCard(stats)
                }
            }
        }
    }
}

@Composable
private fun Avatar(url: String?) {
    val size = 92.dp
    if (url != null) {
        AsyncImage(
            model = url, contentDescription = null, contentScale = ContentScale.Crop,
            modifier = Modifier.size(size).clip(CircleShape)
        )
    } else {
        Box(
            Modifier.size(size).clip(CircleShape)
                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(Icons.Filled.Person, null, tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(44.dp))
        }
    }
}

@Composable
private fun StatsCard(stats: ProfileStats) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(6.dp))
            .background(MaterialTheme.colorScheme.surface).padding(vertical = 18.dp),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        Stat(stats.cigars, "Loggført")
        Stat(stats.humidorEntries, "I humidor")
        Stat(stats.friends, "Venner")
    }
}

@Composable
private fun Stat(value: Int, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text("$value", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary)
        Spacer(Modifier.height(2.dp))
        Text(label, style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
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
