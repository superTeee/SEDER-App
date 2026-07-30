package com.tomerikheggedal.vitola.ui

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.revenuecat.purchases.Package
import com.tomerikheggedal.vitola.data.ProConfig
import com.tomerikheggedal.vitola.data.ProManager
import kotlinx.coroutines.launch

// MARK: - Paywall (speiler iOS PaywallView)
//
// Årlig/månedlig pakker fra RevenueCat («default»-offering), sammenligningstabell,
// auto-fornyelse-tekst, kampanjekode (åpner Play-innløsning) og gjenopprett kjøp.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PaywallScreen(onBack: () -> Unit) {
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val activity = context as? Activity

    var annual by remember { mutableStateOf<Package?>(null) }
    var monthly by remember { mutableStateOf<Package?>(null) }
    var yearlySelected by remember { mutableStateOf(true) }
    var loading by remember { mutableStateOf(true) }
    var working by remember { mutableStateOf(false) }
    var message by remember { mutableStateOf<String?>(null) }

    val isPro by ProManager.isPro.collectAsState()

    LaunchedEffect(Unit) {
        val offering = ProManager.currentOffering()
        annual = offering?.annual
        monthly = offering?.monthly
        loading = false
    }

    // Lukk automatisk hvis Pro blir aktivt (kjøp/restore lyktes).
    LaunchedEffect(isPro) { if (isPro) onBack() }

    val accent = MaterialTheme.colorScheme.primary

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            CenterAlignedTopAppBar(
                title = { },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Outlined.Close, contentDescription = "Lukk")
                    }
                },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        }
    ) { padding ->
        Column(
            Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp)
        ) {
            // Tittel
            Text(
                "SEDER Pro",
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold,
                color = accent,
                modifier = Modifier.fillMaxWidth(),
                textAlign = TextAlign.Center
            )
            Spacer(Modifier.height(6.dp))
            Text(
                "Få mest ut av samlingen din",
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onBackground,
                modifier = Modifier.fillMaxWidth(),
                textAlign = TextAlign.Center
            )
            Spacer(Modifier.height(4.dp))
            Text(
                "Ubegrenset humidor, eksport og innsikt.",
                fontSize = 14.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.fillMaxWidth(),
                textAlign = TextAlign.Center
            )

            Spacer(Modifier.height(20.dp))

            // Sammenligningstabell
            ComparisonTable()

            Spacer(Modifier.height(8.dp))
            Text(
                "Skanning, journal og vurderinger er alltid gratis.",
                fontSize = 12.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.fillMaxWidth(),
                textAlign = TextAlign.Center
            )

            Spacer(Modifier.height(20.dp))

            // Pris-kort (årlig / månedlig)
            if (loading) {
                CircularProgressIndicator(Modifier.align(Alignment.CenterHorizontally))
            } else if (annual == null && monthly == null) {
                Text(
                    "Kunne ikke laste abonnement. Prøv igjen senere.",
                    fontSize = 13.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Center
                )
            } else {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    annual?.let { pkg ->
                        PriceCard(
                            title = "Årlig",
                            price = pkg.product.price.formatted,
                            sub = "spar mest",
                            selected = yearlySelected,
                            accent = accent,
                            modifier = Modifier.weight(1f)
                        ) { yearlySelected = true }
                    }
                    monthly?.let { pkg ->
                        PriceCard(
                            title = "Månedlig",
                            price = pkg.product.price.formatted,
                            sub = "per måned",
                            selected = !yearlySelected,
                            accent = accent,
                            modifier = Modifier.weight(1f)
                        ) { yearlySelected = false }
                    }
                }
            }

            Spacer(Modifier.height(16.dp))

            // Start Pro
            Button(
                onClick = {
                    val pkg = if (yearlySelected) annual else monthly
                    if (pkg != null && activity != null && !working) {
                        working = true
                        scope.launch {
                            when (ProManager.purchase(activity, pkg)) {
                                ProManager.PurchaseOutcome.SUCCESS -> onBack()
                                ProManager.PurchaseOutcome.CANCELLED -> {}
                                ProManager.PurchaseOutcome.FAILED ->
                                    message = "Kjøpet kunne ikke fullføres. Prøv igjen."
                            }
                            working = false
                        }
                    }
                },
                enabled = !working && (annual != null || monthly != null),
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = accent)
            ) {
                if (working) CircularProgressIndicator(Modifier.size(22.dp), color = Color.White, strokeWidth = 2.dp)
                else Text("Start Pro", fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
            }

            Spacer(Modifier.height(10.dp))

            // Auto-fornyelse-tekst
            val renewPrice = (if (yearlySelected) annual else monthly)?.product?.price?.formatted ?: ""
            val period = if (yearlySelected) "år" else "måned"
            Text(
                "Abonnementet fornyes automatisk til $renewPrice per $period og belastes Google-kontoen din. Si opp når som helst i Google Play minst 24 timer før perioden er ute.",
                fontSize = 11.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.fillMaxWidth(),
                textAlign = TextAlign.Center
            )

            Spacer(Modifier.height(14.dp))

            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center
            ) {
                TextButton(onClick = {
                    // Google Play innløser kampanje-/kampanjekoder i Play-appen.
                    runCatching {
                        context.startActivity(
                            Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/redeem"))
                        )
                    }
                }) { Text("Har du en kampanjekode?", fontSize = 13.sp) }

                TextButton(onClick = {
                    if (!working) {
                        working = true
                        scope.launch {
                            val ok = ProManager.restore()
                            if (!ok) message = "Fant ingen tidligere kjøp å gjenopprette."
                            working = false
                        }
                    }
                }) { Text("Gjenopprett kjøp", fontSize = 13.sp) }
            }

            message?.let {
                Spacer(Modifier.height(8.dp))
                Text(
                    it,
                    fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Center
                )
            }

            Spacer(Modifier.height(24.dp))
        }
    }
}

@Composable
private fun ComparisonTable() {
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(MaterialTheme.colorScheme.surface)
            .padding(vertical = 4.dp)
    ) {
        // Header
        Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)) {
            Spacer(Modifier.weight(1f))
            Text("Gratis", fontSize = 13.sp, color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.width(64.dp), textAlign = TextAlign.Center)
            Text("Pro", fontSize = 13.sp, fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.width(64.dp), textAlign = TextAlign.Center)
        }
        HorizontalDivider()
        CompareRow("Antall humidorer", free = "2", pro = "∞")
        HorizontalDivider()
        CompareRow("Journal-eksport (PDF/CSV)", freeCheck = false, proCheck = true)
        HorizontalDivider()
        CompareRow("Avansert statistikk", freeCheck = false, proCheck = true)
        HorizontalDivider()
        CompareRow("Pro-merke på profil", freeCheck = false, proCheck = true)
    }
}

@Composable
private fun CompareRow(
    label: String,
    free: String? = null,
    pro: String? = null,
    freeCheck: Boolean? = null,
    proCheck: Boolean? = null
) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, fontSize = 15.sp, color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.weight(1f))
        Box(Modifier.width(64.dp), contentAlignment = Alignment.Center) {
            when {
                free != null -> Text(free, fontSize = 15.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                freeCheck == true -> Icon(Icons.Filled.Check, null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                else -> Text("–", fontSize = 15.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        Box(Modifier.width(64.dp), contentAlignment = Alignment.Center) {
            when {
                pro != null -> Text(pro, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.primary)
                proCheck == true -> Icon(Icons.Filled.Check, null, tint = MaterialTheme.colorScheme.primary)
                else -> Text("–", fontSize = 15.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
private fun PriceCard(
    title: String,
    price: String,
    sub: String,
    selected: Boolean,
    accent: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Column(
        modifier
            .clip(RoundedCornerShape(12.dp))
            .border(
                width = if (selected) 2.dp else 1.dp,
                color = if (selected) accent else MaterialTheme.colorScheme.outlineVariant,
                shape = RoundedCornerShape(12.dp)
            )
            .background(MaterialTheme.colorScheme.surface)
            .clickable { onClick() }
            .padding(vertical = 16.dp, horizontal = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(title, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurface)
        Spacer(Modifier.height(6.dp))
        Text(price, fontSize = 18.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSurface)
        Spacer(Modifier.height(2.dp))
        Text(sub, fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}
