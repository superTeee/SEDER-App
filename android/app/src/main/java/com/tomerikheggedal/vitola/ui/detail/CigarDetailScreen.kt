package com.tomerikheggedal.vitola.ui.detail

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AddAPhoto
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Straighten
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.sp
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.tomerikheggedal.vitola.data.Cigar
import com.tomerikheggedal.vitola.data.CigarRepository
import com.tomerikheggedal.vitola.data.FlavorIcon
import com.tomerikheggedal.vitola.data.FavoriteRepository
import com.tomerikheggedal.vitola.data.HumidorRepository
import com.tomerikheggedal.vitola.data.Supa
import com.tomerikheggedal.vitola.data.WishlistRepository
import com.tomerikheggedal.vitola.ui.components.SecondaryButton
import com.tomerikheggedal.vitola.ui.humidor.AddToHumidorSheet
import com.tomerikheggedal.vitola.ui.rememberCropPicker
import io.github.jan.supabase.gotrue.auth
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CigarDetailScreen(id: String, onBack: () -> Unit) {
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    var cigar by remember { mutableStateOf<Cigar?>(null) }
    var loading by remember { mutableStateOf(true) }
    var addMsg by remember { mutableStateOf<String?>(null) }
    var showAddSheet by remember { mutableStateOf(false) }
    var showLogSheet by remember { mutableStateOf(false) }
    var sharePromptEntryId by remember { mutableStateOf<String?>(null) }
    var showReportSheet by remember { mutableStateOf(false) }
    var humidorEntryId by remember { mutableStateOf<String?>(null) }
    var entryPhotoUrl by remember { mutableStateOf<String?>(null) }
    var uploadingPhoto by remember { mutableStateOf(false) }
    var inWishlist by remember { mutableStateOf(false) }
    var isFavorite by remember { mutableStateOf(false) }
    var reloadKey by remember { mutableStateOf(0) }

    LaunchedEffect(id, reloadKey) {
        loading = true
        cigar = runCatching { CigarRepository.byId(id) }.getOrNull()
        humidorEntryId = runCatching { HumidorRepository.entryIdForCigar(id) }.getOrNull()
        entryPhotoUrl = humidorEntryId?.let { eid ->
            runCatching { HumidorRepository.entryPhotoUrl(eid) }.getOrNull()
        }
        inWishlist = runCatching { WishlistRepository.isInWishlist(id) }.getOrDefault(false)
        isFavorite = runCatching { FavoriteRepository.isFavorite(id) }.getOrDefault(false)
        loading = false
    }

    // Bilde-velger (crop 16:9) for humidor-oppføringens hero-bilde.
    val pickEntryPhoto = rememberCropPicker(16, 9) { uri ->
        val eid = humidorEntryId ?: return@rememberCropPicker
        uploadingPhoto = true
        scope.launch {
            runCatching {
                val jpeg = withContext(Dispatchers.IO) { detailUriToJpeg(context, uri) }
                if (jpeg != null) entryPhotoUrl = HumidorRepository.uploadEntryPhoto(eid, jpeg)
            }
            uploadingPhoto = false
        }
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = { Text(cigar?.brand ?: "", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Tilbake") }
                },
                actions = {
                    val authed = Supa.client.auth.currentUserOrNull() != null
                    IconButton(onClick = {
                        if (authed) scope.launch {
                            isFavorite = runCatching { FavoriteRepository.toggle(id) }.getOrDefault(isFavorite)
                        }
                    }) {
                        Icon(
                            if (isFavorite) Icons.Filled.Star else Icons.Outlined.StarBorder,
                            contentDescription = if (isFavorite) "Fjern favoritt" else "Legg til favoritt",
                            tint = if (isFavorite) MaterialTheme.colorScheme.primary else LocalContentColor.current
                        )
                    }
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
            ) {
                // Hero-bilde i full bredde (som iOS) — utenfor sideluften.
                if (humidorEntryId != null) {
                    HeroPhoto(photoUrl = entryPhotoUrl, uploading = uploadingPhoto, onPick = pickEntryPhoto)
                }

                Column(
                    Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(top = 20.dp),
                    verticalArrangement = Arrangement.spacedBy(28.dp)
                ) {
                c.series?.let { Text(it, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.SemiBold) }

                // Opprinnelse + format/vitola som ikon-rader (som iOS: kartnål + mål).
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    c.countryOrigin?.takeIf { it.isNotBlank() }?.let { IconInfoRow(Icons.Filled.Place, it) }
                    val sizeText = listOfNotNull(c.commonFormat ?: c.vitola, c.dimensionsLabel)
                        .joinToString(" · ").ifBlank { null }
                    sizeText?.let { IconInfoRow(Icons.Filled.Straighten, it) }
                }

                // Innlogging-sjekk for handlinger (brukes av knappene nederst og «Meld feil»).
                val authed = Supa.client.auth.currentUserOrNull() != null
                fun requireAuth(action: () -> Unit) {
                    addMsg = null
                    if (!authed) addMsg = "Logg inn på Profil-fanen først." else action()
                }

                Row(verticalAlignment = Alignment.CenterVertically) {
                    val verifLabel = c.verificationLabel
                    if (verifLabel != null) {
                        Icon(Icons.Filled.Verified, null, tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(6.dp))
                        Text(verifLabel, style = MaterialTheme.typography.bodyMedium)
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
                    FlavorNotesCard(notes)
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

                // Handlingsknapper nederst (som iOS), 12px mellomrom. Sekundære (outline)
                // knapper får accent-kant i mørk modus.
                Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    if (humidorEntryId != null) {
                        Button(onClick = { requireAuth { showLogSheet = true } }, modifier = Modifier.fillMaxWidth()) {
                            Icon(Icons.AutoMirrored.Outlined.MenuBook, null, modifier = Modifier.size(18.dp))
                            Spacer(Modifier.width(8.dp))
                            Text("Loggfør sigar")
                        }
                    } else {
                        Button(onClick = { requireAuth { showAddSheet = true } }, modifier = Modifier.fillMaxWidth()) {
                            Text("Legg i humidor")
                        }
                        SecondaryButton(
                            onClick = { requireAuth { showLogSheet = true } }
                        ) {
                            Icon(Icons.AutoMirrored.Outlined.MenuBook, null, modifier = Modifier.size(18.dp))
                            Spacer(Modifier.width(8.dp))
                            Text("Loggfør sigar")
                        }
                    }
                    SecondaryButton(
                        onClick = {
                            requireAuth {
                                scope.launch {
                                    inWishlist = runCatching { WishlistRepository.toggle(id) }.getOrDefault(inWishlist)
                                }
                            }
                        }
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
                }

                Spacer(Modifier.height(40.dp))
                }
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
                reloadKey++   // oppdater status → knappen blir «Loggfør sigar»
            }
        )
    }
    if (showLogSheet && c != null) {
        SmokingLogSheet(
            cigar = c,
            humidorEntryId = humidorEntryId,
            onDismiss = { showLogSheet = false },
            onLogged = { logId ->
                showLogSheet = false
                addMsg = "Lagt i journalen ✓"
                if (logId.isNotBlank()) sharePromptEntryId = logId
            }
        )
    }
    sharePromptEntryId?.let { eid ->
        ShareAfterSaveSheet(entryId = eid, onDismiss = { sharePromptEntryId = null })
    }
    if (showReportSheet && c != null) {
        CigarReportSheet(
            cigar = c,
            onDismiss = { showReportSheet = false },
            onSent = { showReportSheet = false; addMsg = "Takk — rettelsen er sendt inn ✓" }
        )
    }
}

// Smaksnoter som et kort med header + 4-kolonners ikon-rutenett (som iOS).
@Composable
private fun FlavorNotesCard(notes: List<String>) {
    val icons = notes.mapNotNull { FlavorIcon.forNote(it) }.distinctBy { it.drawable }.take(8)
    Column(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(4.dp))
            .background(MaterialTheme.colorScheme.surface)
    ) {
        Text(
            "SMAKSNOTER",
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            letterSpacing = 0.6.sp,
            modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 18.dp)
        )
        if (icons.isEmpty()) {
            Text(
                "Ingen smaksnoter registrert ennå.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(start = 16.dp, end = 16.dp, bottom = 20.dp)
            )
        } else {
            Column(
                Modifier.fillMaxWidth().padding(horizontal = 12.dp).padding(bottom = 20.dp),
                verticalArrangement = Arrangement.spacedBy(18.dp)
            ) {
                icons.chunked(4).forEach { row ->
                    Row(Modifier.fillMaxWidth()) {
                        row.forEach { m ->
                            Column(
                                Modifier.weight(1f),
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(5.dp)
                            ) {
                                Icon(
                                    painter = painterResource(m.drawable),
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.size(40.dp)
                                )
                                Text(
                                    m.label,
                                    style = MaterialTheme.typography.labelMedium,
                                    fontWeight = FontWeight.SemiBold,
                                    color = MaterialTheme.colorScheme.onSurface,
                                    maxLines = 1
                                )
                            }
                        }
                        // Fyll ut resten av raden så kolonnene forblir like brede
                        repeat(4 - row.size) { Spacer(Modifier.weight(1f)) }
                    }
                }
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

// Ikon + tekst (som iOS' info-rader: kartnål for opprinnelse, mål for størrelse).
@Composable
private fun IconInfoRow(icon: ImageVector, text: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = MaterialTheme.colorScheme.onSurface, modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(10.dp))
        Text(text, style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurface)
    }
}

// Hero-bilde for en humidor-oppføring: viser bildet, eller en «Last opp bilde»-flate.
@Composable
private fun HeroPhoto(photoUrl: String?, uploading: Boolean, onPick: () -> Unit) {
    Box(
        Modifier.fillMaxWidth().height(220.dp)
            .background(MaterialTheme.colorScheme.surface)
            .clickable(enabled = !uploading) { onPick() },
        contentAlignment = Alignment.Center
    ) {
        if (photoUrl != null) {
            AsyncImage(
                model = photoUrl, contentDescription = null,
                contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize()
            )
        }
        when {
            uploading -> CircularProgressIndicator()
            photoUrl == null -> Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(Icons.Filled.AddAPhoto, null, tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(32.dp))
                Spacer(Modifier.height(8.dp))
                Text("Last opp bilde", color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        if (photoUrl != null && !uploading) {
            Row(
                Modifier.align(Alignment.TopEnd).padding(10.dp)
                    .clip(RoundedCornerShape(20.dp))
                    .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.85f))
                    .clickable { onPick() }
                    .padding(horizontal = 12.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(Icons.Filled.AddAPhoto, null, tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(6.dp))
                Text("Bytt bilde", style = MaterialTheme.typography.labelMedium)
            }
        }
    }
}

// Galleri-Uri → nedskalert JPEG (maks 1400px) for hero-opplasting.
private fun detailUriToJpeg(context: android.content.Context, uri: android.net.Uri, maxDim: Int = 1400): ByteArray? {
    val bitmap = context.contentResolver.openInputStream(uri)?.use {
        android.graphics.BitmapFactory.decodeStream(it)
    } ?: return null
    val longest = maxOf(bitmap.width, bitmap.height)
    val scaled = if (longest > maxDim) {
        val r = maxDim.toFloat() / longest
        android.graphics.Bitmap.createScaledBitmap(bitmap,
            (bitmap.width * r).toInt().coerceAtLeast(1), (bitmap.height * r).toInt().coerceAtLeast(1), true)
    } else bitmap
    val out = java.io.ByteArrayOutputStream()
    scaled.compress(android.graphics.Bitmap.CompressFormat.JPEG, 80, out)
    return out.toByteArray()
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
