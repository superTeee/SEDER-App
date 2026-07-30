package com.tomerikheggedal.vitola.ui.profile

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.filled.Badge
import androidx.compose.material.icons.filled.ChatBubbleOutline
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Place
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tomerikheggedal.vitola.AppPrefs
import com.tomerikheggedal.vitola.data.Profile
import com.tomerikheggedal.vitola.data.ProfileRepository
import com.tomerikheggedal.vitola.data.ProManager
import com.tomerikheggedal.vitola.data.Supa
import com.tomerikheggedal.vitola.ui.PinSetupSheet
import com.tomerikheggedal.vitola.ui.components.SectionLabel
import com.tomerikheggedal.vitola.ui.theme.ThemeState
import io.github.jan.supabase.gotrue.auth
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(onBack: () -> Unit, onPaywall: () -> Unit = {}) {
    val isPro by ProManager.isPro.collectAsState()
    var forceFree by remember { mutableStateOf(ProManager.debugForceFree) }
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val email = Supa.client.auth.currentUserOrNull()?.email
    val version = remember {
        runCatching { context.packageManager.getPackageInfo(context.packageName, 0).versionName }
            .getOrNull() ?: "1.0"
    }
    var profile by remember { mutableStateOf<Profile?>(null) }
    var showEditName by remember { mutableStateOf(false) }
    var showEditLocation by remember { mutableStateOf(false) }
    var pinSet by remember { mutableStateOf(AppPrefs.isPinSet(context)) }
    var showPinSetup by remember { mutableStateOf(false) }
    var showPinRemove by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { profile = runCatching { ProfileRepository.myProfile() }.getOrNull() }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = { Text("Innstillinger", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Tilbake") }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        }
    ) { padding ->
        Column(
            Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState())
                .padding(bottom = 32.dp)
        ) {
            // SEDER Pro / medlemskap
            if (email != null) {
                SectionLabel("Medlemskap")
                SettingsCard {
                    if (isPro) {
                        Row(
                            Modifier.fillMaxWidth().padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(Icons.Filled.Badge, null, tint = MaterialTheme.colorScheme.primary)
                            Spacer(Modifier.width(12.dp))
                            Column {
                                Text("SEDER Pro", fontWeight = FontWeight.Medium)
                                Text("Aktiv", style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                    } else {
                        ActionRow(
                            icon = { Icon(Icons.Filled.Badge, null, tint = MaterialTheme.colorScheme.primary) },
                            text = "Oppgrader til Pro",
                            onClick = onPaywall
                        )
                    }
                    if (com.tomerikheggedal.vitola.BuildConfig.DEBUG) {
                        HorizontalDivider(Modifier.padding(start = 52.dp), color = MaterialTheme.colorScheme.surfaceVariant)
                        Row(
                            Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text("DEBUG: simuler gratisbruker", Modifier.weight(1f),
                                style = MaterialTheme.typography.bodyMedium)
                            Switch(checked = forceFree, onCheckedChange = {
                                forceFree = it; ProManager.debugForceFree = it
                            })
                        }
                    }
                }
            }

            // Konto
            if (email != null) {
                SectionLabel("Konto")
                SettingsCard {
                    Column(Modifier.padding(16.dp)) {
                        Text("Innlogget som", style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Text(email, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium)
                    }
                }
            }

            // Profil — endre navn / sted
            if (email != null) {
                SectionLabel("Profil")
                SettingsCard {
                    ActionRow(
                        icon = { Icon(Icons.Filled.Badge, null, tint = MaterialTheme.colorScheme.primary) },
                        text = "Endre navn",
                        onClick = { showEditName = true }
                    )
                    HorizontalDivider(Modifier.padding(start = 52.dp), color = MaterialTheme.colorScheme.surfaceVariant)
                    ActionRow(
                        icon = { Icon(Icons.Filled.Place, null, tint = MaterialTheme.colorScheme.primary) },
                        text = "Endre by og land",
                        onClick = { showEditLocation = true }
                    )
                }
            }

            // Utseende — tema
            SectionLabel("Utseende")
            SettingsCard {
                Column(Modifier.padding(16.dp)) {
                    Text("Tema", style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium)
                    Spacer(Modifier.height(10.dp))
                    val options = listOf("system" to "System", "light" to "Lys", "dark" to "Mørk")
                    SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                        options.forEachIndexed { i, (value, label) ->
                            SegmentedButton(
                                selected = ThemeState.mode == value,
                                onClick = { ThemeState.set(context, value) },
                                shape = SegmentedButtonDefaults.itemShape(i, options.size)
                            ) { Text(label) }
                        }
                    }
                }
            }

            // Sikkerhet — PIN-kodelås (kun innlogget)
            if (email != null) {
                SectionLabel("Sikkerhet")
                SettingsCard {
                    ActionRow(
                        icon = { Icon(Icons.Filled.Lock, null, tint = MaterialTheme.colorScheme.primary) },
                        text = if (pinSet) "Fjern kodelås" else "Sett kodelås",
                        onClick = { if (pinSet) showPinRemove = true else showPinSetup = true }
                    )
                }
            }

            // Tilbakemelding
            SectionLabel("Tilbakemelding")
            SettingsCard {
                ActionRow(
                    icon = { Icon(Icons.Filled.ChatBubbleOutline, null, tint = MaterialTheme.colorScheme.primary) },
                    text = "Gi tilbakemelding på appen",
                    onClick = {
                        val intent = Intent(Intent.ACTION_SENDTO).apply {
                            data = Uri.parse("mailto:theggedal@gmail.com")
                            putExtra(Intent.EXTRA_SUBJECT, "SEDER-tilbakemelding")
                        }
                        runCatching {
                            context.startActivity(Intent.createChooser(intent, "Send tilbakemelding"))
                        }
                    }
                )
            }

            // Om
            SectionLabel("Om")
            SettingsCard {
                Row(Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text("Versjon", Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge)
                    Text(version, style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }

            // Logg ut
            if (email != null) {
                Spacer(Modifier.height(8.dp))
                SettingsCard {
                    ActionRow(
                        icon = { Icon(Icons.AutoMirrored.Filled.Logout, null, tint = MaterialTheme.colorScheme.error) },
                        text = "Logg ut",
                        textColor = MaterialTheme.colorScheme.error,
                        onClick = { scope.launch { Supa.client.auth.signOut() }; onBack() }
                    )
                }
            }
        }
    }

    if (showEditName) {
        TextEditDialog(
            title = "Endre navn", label = "Visningsnavn",
            initial = profile?.displayName ?: "",
            onDismiss = { showEditName = false },
            onSave = { name ->
                showEditName = false
                scope.launch {
                    runCatching { ProfileRepository.updateName(name) }
                    profile = runCatching { ProfileRepository.myProfile() }.getOrNull()
                    ProfileRefresh.bump()
                }
            }
        )
    }
    if (showEditLocation) {
        LocationEditDialog(
            initialCity = profile?.city ?: "", initialCountry = profile?.country ?: "",
            onDismiss = { showEditLocation = false },
            onSave = { city, country ->
                showEditLocation = false
                scope.launch {
                    runCatching { ProfileRepository.updateLocation(city, country) }
                    profile = runCatching { ProfileRepository.myProfile() }.getOrNull()
                    ProfileRefresh.bump()
                }
            }
        )
    }
    if (showPinSetup) {
        PinSetupSheet(
            onDismiss = { showPinSetup = false },
            onSet = { showPinSetup = false; pinSet = true }
        )
    }
    if (showPinRemove) {
        AlertDialog(
            onDismissRequest = { showPinRemove = false },
            title = { Text("Fjern kodelås?") },
            text = { Text("Appen åpnes da uten kode.") },
            confirmButton = {
                TextButton(onClick = {
                    AppPrefs.clearPin(context); pinSet = false; showPinRemove = false
                }) { Text("Fjern", color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = { TextButton(onClick = { showPinRemove = false }) { Text("Avbryt") } }
        )
    }
}

@Composable
private fun TextEditDialog(
    title: String, label: String, initial: String,
    onDismiss: () -> Unit, onSave: (String) -> Unit,
) {
    var text by remember { mutableStateOf(initial) }
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = { TextButton(onClick = { onSave(text) }, enabled = text.isNotBlank()) { Text("Lagre") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Avbryt") } },
        title = { Text(title, fontWeight = FontWeight.Bold) },
        text = {
            OutlinedTextField(value = text, onValueChange = { text = it },
                label = { Text(label) }, singleLine = true, modifier = Modifier.fillMaxWidth())
        }
    )
}

@Composable
private fun LocationEditDialog(
    initialCity: String, initialCountry: String,
    onDismiss: () -> Unit, onSave: (String, String) -> Unit,
) {
    var city by remember { mutableStateOf(initialCity) }
    var country by remember { mutableStateOf(initialCountry) }
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = { TextButton(onClick = { onSave(city, country) }) { Text("Lagre") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Avbryt") } },
        title = { Text("By og land", fontWeight = FontWeight.Bold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(value = city, onValueChange = { city = it },
                    label = { Text("By") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = country, onValueChange = { country = it },
                    label = { Text("Land") }, singleLine = true, modifier = Modifier.fillMaxWidth())
            }
        }
    )
}

// Kort med hvit (surface) bakgrunn og 16dp sidemarg, uten skygge — som resten av appen.
@Composable
private fun SettingsCard(content: @Composable ColumnScope.() -> Unit) {
    Column(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp)
            .clip(RoundedCornerShape(6.dp)).background(MaterialTheme.colorScheme.surface),
        content = content
    )
}

@Composable
private fun ActionRow(
    icon: @Composable () -> Unit,
    text: String,
    textColor: Color = MaterialTheme.colorScheme.onSurface,
    onClick: () -> Unit,
) {
    Row(
        Modifier.fillMaxWidth().clickable(onClick = onClick).padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        icon()
        Text(text, style = MaterialTheme.typography.bodyLarge, color = textColor, letterSpacing = 0.sp)
    }
}
