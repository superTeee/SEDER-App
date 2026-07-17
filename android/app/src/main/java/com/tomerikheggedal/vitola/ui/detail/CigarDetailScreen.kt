package com.tomerikheggedal.vitola.ui.detail

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.tomerikheggedal.vitola.data.Cigar
import com.tomerikheggedal.vitola.data.CigarRepository
import com.tomerikheggedal.vitola.data.FlavorIcon
import com.tomerikheggedal.vitola.data.HumidorRepository
import com.tomerikheggedal.vitola.data.Supa
import com.tomerikheggedal.vitola.data.WishlistRepository
import com.tomerikheggedal.vitola.ui.humidor.AddToHumidorSheet
import io.github.jan.supabase.gotrue.auth
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CigarDetailScreen(id: String, onBack: () -> Unit) {
    val scope = rememberCoroutineScope()
    var cigar by remember { mutableStateOf<Cigar?>(null) }
    var loading by remember { mutableStateOf(true) }
    var addMsg by remember { mutableStateOf<String?>(null) }
    var showAddSheet by remember { mutableStateOf(false) }
    var showLogSheet by remember { mutableStateOf(false) }
    var showReportSheet by remember { mutableStateOf(false) }
    var humidorEntryId by remember { mutableStateOf<String?>(null) }
    var inWishlist by remember { mutableStateOf(false) }
    var reloadKey by remember { mutableStateOf(0) }

    LaunchedEffect(id, reloadKey) {
        loading = true
        cigar = runCatching { CigarRepository.byId(id) }.getOrNull()
        humidorEntryId = runCatching { HumidorRepository.entryIdForCigar(id) }.getOrNull()
        inWishlist = runCatching { WishlistRepository.isInWishlist(id) }.getOrDefault(false)
        loading = false
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = { Text(cigar?.brand ?: "", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Tilbake") }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        }
    ) { padding ->
        val c = cigar
        when {
            loading -> Box(Modifier.padding(padding).fillMaxSize(), Alignment.Center) { CircularProgressIndicator() }
            c == null -> Box(Modifier.padding(padding).fillMaxSize(), Alignment.Center) { Text("Fant ikke sigaren") }
            else -> Column(
                Modifier.padding(padding).fillMaxSize().verticalScroll(rememberScrollState())
                    .padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(20.dp)
            ) {
                c.series?.let { Text(it, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.SemiBold) }

                InfoRow("Opprinnelse", c.countryOrigin)
                InfoRow("Format", listOfNotNull(c.commonFormat, c.dimensionsLabel).joinToString(" · ").ifBlank { null })

                // Handlingsknapper — speiler iOS:
                // I humidor → primær «Marker som røkt». Ellers → «Legg i humidor» + sekundær «Marker som røkt».
                val authed = Supa.client.auth.currentUserOrNull() != null
                fun requireAuth(action: () -> Unit) {
                    addMsg = null
                    if (!authed) addMsg = "Logg inn på Profil-fanen først." else action()
                }
                if (humidorEntryId != null) {
                    Button(onClick = { requireAuth { showLogSheet = true } }, modifier = Modifier.fillMaxWidth()) {
                        Icon(Icons.Filled.LocalFireDepartment, null, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("Marker som røkt")
                    }
                } else {
                    Button(onClick = { requireAuth { showAddSheet = true } }, modifier = Modifier.fillMaxWidth()) {
                        Text("Legg i humidor")
                    }
                    OutlinedButton(onClick = { requireAuth { showLogSheet = true } }, modifier = Modifier.fillMaxWidth()) {
                        Icon(Icons.Filled.LocalFireDepartment, null, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("Marker som røkt")
                    }
                }

                // Ønskeliste-knapp (som iOS): full bredde, bokmerke + veksel-tekst.
                OutlinedButton(
                    onClick = {
                        requireAuth {
                            scope.launch {
                                inWishlist = runCatching { WishlistRepository.toggle(id) }.getOrDefault(inWishlist)
                            }
                        }
                    },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(
                        if (inWishlist) Icons.Filled.Bookmark else Icons.Outlined.BookmarkBorder,
                        null, modifier = Modifier.size(18.dp)
                    )
                    Spacer(Modifier.width(8.dp))
                    Text(if (inWishlist) "I ønskelisten" else "Legg i ønskeliste")
                }
                addMsg?.let {
                    Text(it, color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodyMedium)
                }

                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (c.isVerified) {
                        Icon(Icons.Filled.Verified, null, tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(6.dp))
                        Text("Verifisert mot produsent", style = MaterialTheme.typography.bodyMedium)
                        Spacer(Modifier.width(6.dp))
                        Text("·", color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Spacer(Modifier.width(6.dp))
                    }
                    Text(
                        "Meld feil",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.clip(RoundedCornerShape(6.dp))
                            .clickable { requireAuth { showReportSheet = true } }
                            .padding(vertical = 2.dp, horizontal = 2.dp)
                    )
                }

                c.flavorNotes?.takeIf { it.isNotEmpty() }?.let { notes ->
                    Section("SMAKSNOTER") {
                        FlavorNotes(notes)
                    }
                }

                Section("KONSTRUKSJON") {
                    InfoRow("Dekkblad", c.wrapperLeaf ?: c.wrapperCountry)
                    InfoRow("Omblad", c.binder)
                    InfoRow("Innmat", c.filler?.joinToString(", "))
                }

                c.strength?.let { Rating("Styrke", it) }
                c.body?.let { Rating("Kropp", it) }
                c.flavorIntensity?.let { Rating("Smaksintensitet", it) }
                c.sweetness?.let { Rating("Sødme", it) }

                c.description?.takeIf { it.isNotBlank() }?.let {
                    Text(it, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Spacer(Modifier.height(40.dp))
            }
        }
    }

    val c = cigar
    if (showAddSheet && c != null) {
        AddToHumidorSheet(
            cigar = c,
            onDismiss = { showAddSheet = false },
            onAdded = { humidorName ->
                showAddSheet = false
                addMsg = "Lagt i $humidorName ✓"
                reloadKey++   // oppdater status → knappen blir «Marker som røkt»
            }
        )
    }
    if (showLogSheet && c != null) {
        SmokingLogSheet(
            cigar = c,
            humidorEntryId = humidorEntryId,
            onDismiss = { showLogSheet = false },
            onLogged = {
                showLogSheet = false
                addMsg = "Lagt i journalen ✓"
            }
        )
    }
    if (showReportSheet && c != null) {
        CigarReportSheet(
            cigar = c,
            onDismiss = { showReportSheet = false },
            onSent = { showReportSheet = false; addMsg = "Takk — rettelsen er sendt inn ✓" }
        )
    }
}

// Smaksnoter som pills: tintet ikon + norsk etikett når noten har et ikon,
// ellers bare teksten (ingen tom plassholder).
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun FlavorNotes(notes: List<String>) {
    FlowRow(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        notes.forEach { note ->
            val match = FlavorIcon.forNote(note)
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                modifier = Modifier
                    .clip(RoundedCornerShape(20.dp))
                    .background(MaterialTheme.colorScheme.surfaceVariant)
                    .padding(horizontal = 12.dp, vertical = 8.dp)
            ) {
                if (match != null) {
                    Icon(
                        painter = painterResource(match.drawable),
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(20.dp)
                    )
                }
                Text(
                    match?.label ?: note,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }
        }
    }
}

@Composable
private fun Section(title: String, content: @Composable ColumnScope.() -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(title, style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant, fontWeight = FontWeight.SemiBold)
        content()
    }
}

@Composable
private fun InfoRow(label: String, value: String?) {
    if (value.isNullOrBlank()) return
    Row {
        Text(label, fontWeight = FontWeight.SemiBold, modifier = Modifier.width(120.dp))
        Text(value, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun Rating(label: String, value: Double) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(label.uppercase(), style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            for (i in 1..5) {
                Box(
                    Modifier.weight(1f).height(8.dp).clip(RoundedCornerShape(4.dp))
                        .background(
                            if (i <= value) MaterialTheme.colorScheme.primary
                            else MaterialTheme.colorScheme.surfaceVariant
                        )
                )
            }
        }
    }
}
