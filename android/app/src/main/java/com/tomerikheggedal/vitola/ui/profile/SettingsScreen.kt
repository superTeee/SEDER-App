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
import androidx.compose.material.icons.filled.ChatBubbleOutline
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
import com.tomerikheggedal.vitola.data.Supa
import com.tomerikheggedal.vitola.ui.components.SectionLabel
import com.tomerikheggedal.vitola.ui.theme.ThemeState
import io.github.jan.supabase.gotrue.auth
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(onBack: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val email = Supa.client.auth.currentUserOrNull()?.email
    val version = remember {
        runCatching { context.packageManager.getPackageInfo(context.packageName, 0).versionName }
            .getOrNull() ?: "1.0"
    }

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

            // Tilbakemelding
            SectionLabel("Tilbakemelding")
            SettingsCard {
                ActionRow(
                    icon = { Icon(Icons.Filled.ChatBubbleOutline, null, tint = MaterialTheme.colorScheme.primary) },
                    text = "Gi tilbakemelding på appen",
                    onClick = {
                        val intent = Intent(Intent.ACTION_SENDTO).apply {
                            data = Uri.parse("mailto:theggedal@gmail.com")
                            putExtra(Intent.EXTRA_SUBJECT, "Vitola-tilbakemelding")
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
