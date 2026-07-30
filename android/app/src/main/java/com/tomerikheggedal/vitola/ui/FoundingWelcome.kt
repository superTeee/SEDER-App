package com.tomerikheggedal.vitola.ui

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.outlined.EmojiEvents
import androidx.compose.material.icons.outlined.Verified
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.tomerikheggedal.vitola.data.ProConfig

// Founding-medlem-feiring — speiler iOS' FoundingWelcomeView. Vises kun én gang,
// rett etter innlogging/onboarding, når claim_founding_number returnerer et nummer.
// Nummer <= cap → founding-medlem (kode + livstids-tilbud). Ellers → nøytral velkomst.
@Composable
fun FoundingWelcomeDialog(number: Int, onClose: () -> Unit) {
    val context = LocalContext.current
    val accent = MaterialTheme.colorScheme.primary
    val isFounding = number <= ProConfig.foundingCap
    var copied by remember { mutableStateOf(false) }

    fun copyCode() {
        val cm = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        cm.setPrimaryClip(ClipData.newPlainText("SEDER-kode", ProConfig.foundingCode))
        copied = true
    }
    fun openRedeem() {
        runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/redeem"))) }
    }

    Dialog(
        onDismissRequest = onClose,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Surface(color = MaterialTheme.colorScheme.background, modifier = Modifier.fillMaxSize()) {
            Column(
                Modifier.fillMaxSize().padding(horizontal = 8.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Box(
                    Modifier.size(96.dp).clip(CircleShape)
                        .border(1.5.dp, accent, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        if (isFounding) Icons.Outlined.EmojiEvents else Icons.Outlined.Verified,
                        null, tint = accent, modifier = Modifier.size(40.dp)
                    )
                }
                Spacer(Modifier.height(20.dp))

                if (isFounding) {
                    Text("Gratulerer", fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = accent)
                    Spacer(Modifier.height(6.dp))
                    Row(verticalAlignment = Alignment.Bottom) {
                        Text("$number", fontSize = 44.sp, fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onBackground)
                        Text(" / ${ProConfig.foundingCap}", fontSize = 26.sp, fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    Spacer(Modifier.height(6.dp))
                    Text(
                        "Du er blant de ${ProConfig.foundingCap} første medlemmene i SEDER",
                        fontSize = 15.sp, color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 40.dp)
                    )
                    Spacer(Modifier.height(20.dp))

                    // Kode-kort — trykk for å kopiere.
                    Column(
                        Modifier.padding(horizontal = 28.dp).fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(MaterialTheme.colorScheme.surface)
                            .clickable { copyCode() }
                            .padding(16.dp)
                    ) {
                        Text("DIN FOUNDING-KODE", fontSize = 11.sp, fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Spacer(Modifier.height(4.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(ProConfig.foundingCode, fontSize = 20.sp, fontWeight = FontWeight.SemiBold,
                                fontFamily = FontFamily.Monospace, color = MaterialTheme.colorScheme.onBackground)
                            Spacer(Modifier.weight(1f))
                            Icon(if (copied) Icons.Filled.Check else Icons.Filled.ContentCopy, null, tint = accent)
                        }
                        Spacer(Modifier.height(6.dp))
                        Text("100 kr av første år · 349 kr", fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    Spacer(Modifier.height(10.dp))

                    Button(
                        onClick = { copyCode(); openRedeem() },
                        colors = ButtonDefaults.buttonColors(containerColor = accent),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.padding(horizontal = 28.dp).fillMaxWidth().height(50.dp)
                    ) { Text("Bruk koden nå", fontSize = 16.sp, fontWeight = FontWeight.SemiBold) }

                    Spacer(Modifier.height(2.dp))
                    TextButton(onClick = onClose) {
                        Text("Kanskje senere", fontSize = 14.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                } else {
                    Text("Velkommen til SEDER", fontSize = 24.sp, fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onBackground)
                    Spacer(Modifier.height(6.dp))
                    Text("Din digitale humidor og sigarjournal", fontSize = 15.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 40.dp))
                    Spacer(Modifier.height(20.dp))
                    Button(
                        onClick = onClose,
                        colors = ButtonDefaults.buttonColors(containerColor = accent),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.padding(horizontal = 28.dp).fillMaxWidth().height(50.dp)
                    ) { Text("Kom i gang", fontSize = 16.sp, fontWeight = FontWeight.SemiBold) }
                }
            }
        }
    }
}
