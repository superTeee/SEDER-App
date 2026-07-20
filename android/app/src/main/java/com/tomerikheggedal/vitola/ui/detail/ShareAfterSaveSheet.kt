package com.tomerikheggedal.vitola.ui.detail

import android.content.Intent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.tomerikheggedal.vitola.data.ShareRepository
import kotlinx.coroutines.launch

// Del etter lagring. Vises etter at et journalinnlegg er lagret. To brytere,
// aldri påtvunget. «Del i appen» → Aktivitet. «Del eksternt» → native delings-ark.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShareAfterSaveSheet(entryId: String, onDismiss: () -> Unit) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    var community by remember { mutableStateOf(false) }
    var external by remember { mutableStateOf(false) }
    var saving by remember { mutableStateOf(false) }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface) {
        Column(
            Modifier.fillMaxWidth().padding(horizontal = 24.dp).padding(bottom = 28.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Text("Dele opplevelsen din?", style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold)
            Text("Journalen din er privat. Velg selv hva du deler.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant)

            Spacer(Modifier.height(6.dp))
            ToggleRow("Del i appen", "Vises i Aktivitet for andre", community) { community = it }
            HorizontalDivider(color = MaterialTheme.colorScheme.surfaceVariant)
            ToggleRow("Del eksternt", "Del lenken via delings-arket", external) { external = it }
            Spacer(Modifier.height(10.dp))

            Button(
                onClick = {
                    if (saving) return@Button
                    saving = true
                    scope.launch {
                        val res = runCatching { ShareRepository.setSharing(entryId, community, external) }.getOrNull()
                        val slug = res?.publicSlug
                        if (external && slug != null) {
                            val send = Intent(Intent.ACTION_SEND).apply {
                                type = "text/plain"
                                putExtra(Intent.EXTRA_TEXT, ShareRepository.publicUrl(slug))
                            }
                            runCatching { context.startActivity(Intent.createChooser(send, "Del")) }
                        }
                        onDismiss()
                    }
                },
                enabled = !saving && (community || external),
                modifier = Modifier.fillMaxWidth()
            ) {
                if (saving) CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp,
                    color = MaterialTheme.colorScheme.onPrimary)
                else Text("Del", fontWeight = FontWeight.SemiBold)
            }
            OutlinedButton(onClick = onDismiss, modifier = Modifier.fillMaxWidth()) {
                Text("Behold privat")
            }
            TextButton(onClick = onDismiss, modifier = Modifier.fillMaxWidth()) {
                Text("Avbryt")
            }
        }
    }
}

@Composable
private fun ToggleRow(title: String, subtitle: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(vertical = 6.dp)) {
        Column(Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.SemiBold)
            Text(subtitle, style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Switch(checked = checked, onCheckedChange = onChange)
    }
}
