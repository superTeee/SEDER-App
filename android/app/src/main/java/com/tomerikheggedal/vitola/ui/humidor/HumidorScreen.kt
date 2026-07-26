package com.tomerikheggedal.vitola.ui.humidor

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.ui.res.painterResource
import com.tomerikheggedal.vitola.R
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.Logout
import androidx.compose.material.icons.filled.ReceiptLong
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import coil.compose.AsyncImage
import com.tomerikheggedal.vitola.data.Cigar
import com.tomerikheggedal.vitola.data.HumidorRepository
import com.tomerikheggedal.vitola.data.HumidorRow
import com.tomerikheggedal.vitola.data.HumidorUi
import com.tomerikheggedal.vitola.data.ReceiptParseResult
import com.tomerikheggedal.vitola.data.ReceiptRepository
import com.tomerikheggedal.vitola.data.RhStatus
import com.tomerikheggedal.vitola.data.Supa
import com.tomerikheggedal.vitola.data.FavoriteRepository
import com.tomerikheggedal.vitola.data.WishlistRepository
import com.tomerikheggedal.vitola.data.rhStatus
import io.github.jan.supabase.gotrue.SessionStatus
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.gotrue.providers.Google
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HumidorScreen(
    onProfile: () -> Unit = {},
    requestedTab: Int? = null,
    onTabConsumed: () -> Unit = {},
    onHumidor: (String) -> Unit = {},
    onCigar: (String) -> Unit = {},
) {
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val status by Supa.client.auth.sessionStatus.collectAsState()
    val isAuthed = status is SessionStatus.Authenticated

    var humidors by remember { mutableStateOf<List<HumidorUi>>(emptyList()) }
    var loading by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var showAdd by remember { mutableStateOf(false) }
    var reloadKey by remember { mutableStateOf(0) }

    // Kvittering → bulk-add
    var showAddMenu by remember { mutableStateOf(false) }
    var showReceiptSource by remember { mutableStateOf(false) }
    var parsingReceipt by remember { mutableStateOf(false) }
    var receiptResult by remember { mutableStateOf<ReceiptParseResult?>(null) }
    var receiptError by remember { mutableStateOf<String?>(null) }

    fun runParse(jpeg: ByteArray?) {
        if (jpeg == null) return
        parsingReceipt = true
        scope.launch {
            val res = runCatching { ReceiptRepository.parseReceipt(jpeg) }.getOrNull()
            parsingReceipt = false
            when {
                res == null -> receiptError = "Klarte ikke å lese kvitteringen. Sjekk nettet og prøv igjen."
                res.matched.isEmpty() && res.unmatched.isEmpty() ->
                    receiptError = "Fant ingen sigarer på kvitteringen. Prøv et tydeligere bilde."
                else -> receiptResult = res
            }
        }
    }

    val receiptCamera = rememberLauncherForActivityResult(
        ActivityResultContracts.TakePicturePreview()
    ) { bmp -> if (bmp != null) runParse(bitmapToJpegR(bmp)) }
    val receiptGallery = rememberLauncherForActivityResult(
        ActivityResultContracts.PickVisualMedia()
    ) { uri -> if (uri != null) scope.launch { runParse(uriToJpegR(context, uri)) } }

    // Segmentert fane: 0 = Humidor, 1 = Favoritter, 2 = Ønskeliste (som iOS).
    var tab by remember { mutableStateOf(0) }
    // Åpne på forespurt fane (f.eks. når man kom fra «Favoritter» på profilen), og
    // nullstill forespørselen etterpå så vanlig navigasjon ikke overstyrer valget.
    LaunchedEffect(requestedTab) {
        if (requestedTab != null) { tab = requestedTab; onTabConsumed() }
    }
    var wishlist by remember { mutableStateOf<List<Cigar>>(emptyList()) }
    var loadingWishlist by remember { mutableStateOf(false) }
    var favorites by remember { mutableStateOf<List<Cigar>>(emptyList()) }
    var loadingFavorites by remember { mutableStateOf(false) }

    // Last humidorene når man er (blir) innlogget, eller etter at en ny er lagt til.
    LaunchedEffect(isAuthed, reloadKey) {
        if (isAuthed) {
            loading = true; error = null
            try { humidors = HumidorRepository.myHumidors() }
            catch (e: Exception) { error = e.message ?: "Kunne ikke laste humidorer" }
            loading = false
        } else {
            humidors = emptyList()
        }
    }

    // Last ønskelista/favoritter hver gang fanen vises (så endringer reflekteres).
    LaunchedEffect(isAuthed, tab) {
        if (isAuthed && tab == 2) {
            loadingWishlist = true
            wishlist = runCatching { WishlistRepository.list() }.getOrDefault(emptyList())
            loadingWishlist = false
        }
        if (isAuthed && tab == 1) {
            loadingFavorites = true
            favorites = runCatching { FavoriteRepository.list() }.getOrDefault(emptyList())
            loadingFavorites = false
        }
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Humidor", fontWeight = FontWeight.Bold) },
                navigationIcon = { com.tomerikheggedal.vitola.ui.components.TopBarProfileAvatar(onProfile) },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                ),
                actions = {
                    if (isAuthed) {
                        Box {
                            IconButton(onClick = { showAddMenu = true }) {
                                Icon(Icons.Filled.Add, contentDescription = "Legg til")
                            }
                            DropdownMenu(expanded = showAddMenu, onDismissRequest = { showAddMenu = false }) {
                                DropdownMenuItem(
                                    text = { Text("Ny humidor") },
                                    leadingIcon = { Icon(Icons.Filled.Inventory2, null) },
                                    onClick = { showAddMenu = false; showAdd = true }
                                )
                                DropdownMenuItem(
                                    text = { Text("Legg til sigarer fra kvittering") },
                                    leadingIcon = { Icon(Icons.Filled.ReceiptLong, null) },
                                    onClick = { showAddMenu = false; showReceiptSource = true }
                                )
                            }
                        }
                        IconButton(onClick = { scope.launch { Supa.client.auth.signOut() } }) {
                            Icon(Icons.Filled.Logout, contentDescription = "Logg ut")
                        }
                    }
                }
            )
        }
    ) { padding ->
        Column(Modifier.padding(padding).fillMaxSize()) {
            // Segment-velger (Humidor / Ønskeliste) — kun innlogget.
            if (isAuthed) {
                // Valgt segment bruker accent-fargen, og hele omrisset (stroke) er accent.
                val segColors = SegmentedButtonDefaults.colors(
                    activeContainerColor = MaterialTheme.colorScheme.primary,
                    activeContentColor = MaterialTheme.colorScheme.onPrimary,
                    activeBorderColor = MaterialTheme.colorScheme.primary,
                    inactiveBorderColor = MaterialTheme.colorScheme.primary,
                )
                SingleChoiceSegmentedButtonRow(
                    Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp)
                ) {
                    SegmentedButton(
                        selected = tab == 0, onClick = { tab = 0 }, colors = segColors,
                        shape = SegmentedButtonDefaults.itemShape(index = 0, count = 3)
                    ) { Text("Humidor") }
                    SegmentedButton(
                        selected = tab == 1, onClick = { tab = 1 }, colors = segColors,
                        shape = SegmentedButtonDefaults.itemShape(index = 1, count = 3)
                    ) { Text("Favoritter") }
                    SegmentedButton(
                        selected = tab == 2, onClick = { tab = 2 }, colors = segColors,
                        shape = SegmentedButtonDefaults.itemShape(index = 2, count = 3)
                    ) { Text("Ønskeliste") }
                }
            }

            Box(Modifier.fillMaxSize()) {
                when {
                    !isAuthed -> LoginPrompt { scope.launch { Supa.client.auth.signInWith(Google) } }

                    tab == 1 -> when {
                        loadingFavorites -> CircularProgressIndicator(Modifier.align(Alignment.Center))
                        favorites.isEmpty() -> Column(
                            Modifier.align(Alignment.Center).padding(32.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text("Ingen favoritter ennå.", style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.SemiBold)
                            Spacer(Modifier.height(6.dp))
                            Text("Åpne en sigar og trykk på stjernen øverst for å legge den til her.",
                                textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        else -> LazyColumn(Modifier.fillMaxSize()) {
                            item {
                                Text("Favoritter (${favorites.size})",
                                    style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold,
                                    modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 6.dp, bottom = 4.dp))
                            }
                            items(favorites, key = { it.id }) { c ->
                                WishlistRow(cigar = c, onClick = { onCigar(c.id) })
                                HorizontalDivider(color = MaterialTheme.colorScheme.surfaceVariant)
                            }
                        }
                    }

                    tab == 2 -> when {
                        loadingWishlist -> CircularProgressIndicator(Modifier.align(Alignment.Center))
                        wishlist.isEmpty() -> Column(
                            Modifier.align(Alignment.Center).padding(32.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text("Ønskelisten er tom.", style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.SemiBold)
                            Spacer(Modifier.height(6.dp))
                            Text("Finn sigarer i Utforsk og trykk bokmerket for å lagre dem her.",
                                textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        else -> LazyColumn(Modifier.fillMaxSize()) {
                            item {
                                Text("Ønskeliste (${wishlist.size})",
                                    style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold,
                                    modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 6.dp, bottom = 4.dp))
                            }
                            items(wishlist, key = { it.id }) { c ->
                                WishlistRow(cigar = c, onClick = { onCigar(c.id) })
                                HorizontalDivider(color = MaterialTheme.colorScheme.surfaceVariant)
                            }
                        }
                    }

                    loading -> CircularProgressIndicator(Modifier.align(Alignment.Center))
                    error != null -> Text(
                        error!!,
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.align(Alignment.Center).padding(24.dp)
                    )
                    humidors.isEmpty() -> Column(
                        Modifier.align(Alignment.Center).padding(32.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            "Du har ingen humidorer ennå.",
                            textAlign = TextAlign.Center,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(Modifier.height(16.dp))
                        Button(onClick = { showAdd = true }) { Text("Opprett humidor") }
                    }
                    else -> LazyColumn(
                        Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        items(humidors, key = { it.row.id }) { h -> HumidorCard(h) { onHumidor(h.row.id) } }
                    }
                }
            }
        }
    }

    if (showAdd) {
        AddHumidorSheet(
            onDismiss = { showAdd = false },
            onCreated = { showAdd = false; reloadKey++ }
        )
    }

    // Kilde-valg for kvittering: kamera eller galleri.
    if (showReceiptSource) {
        AlertDialog(
            onDismissRequest = { showReceiptSource = false },
            title = { Text("Legg til sigarer fra kvittering") },
            text = { Text("Ta bilde av kvitteringen, eller velg et bilde fra galleriet.") },
            confirmButton = {
                TextButton(onClick = { showReceiptSource = false; receiptCamera.launch(null) }) { Text("Ta bilde") }
            },
            dismissButton = {
                TextButton(onClick = {
                    showReceiptSource = false
                    receiptGallery.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                }) { Text("Velg fra galleri") }
            }
        )
    }

    // Laster mens kvitteringen leses (kan ta noen sekunder).
    if (parsingReceipt) {
        Dialog(onDismissRequest = {}) {
            Surface(shape = RoundedCornerShape(12.dp), color = MaterialTheme.colorScheme.surface) {
                Row(Modifier.padding(24.dp), verticalAlignment = Alignment.CenterVertically) {
                    CircularProgressIndicator(Modifier.size(22.dp), strokeWidth = 2.dp)
                    Spacer(Modifier.width(14.dp))
                    Text("Leser kvitteringen…", fontWeight = FontWeight.Medium)
                }
            }
        }
    }

    receiptError?.let { msg ->
        AlertDialog(
            onDismissRequest = { receiptError = null },
            confirmButton = { TextButton(onClick = { receiptError = null }) { Text("OK") } },
            title = { Text("Kunne ikke lese kvitteringen") },
            text = { Text(msg) }
        )
    }

    receiptResult?.let { res ->
        ReceiptConfirmSheet(
            result = res,
            humidors = humidors.map { it.row },
            onDismiss = { receiptResult = null },
            onFinished = { receiptResult = null; reloadKey++ }
        )
    }
}

// Kamera-thumbnail → JPEG. (Galleri gir høyere oppløsning for lange kvitteringer.)
private fun bitmapToJpegR(bitmap: android.graphics.Bitmap): ByteArray {
    val out = java.io.ByteArrayOutputStream()
    bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 90, out)
    return out.toByteArray()
}

// Galleri-URI → nedskalert JPEG. Kvitteringer har mye liten tekst — behold 2000px.
private fun uriToJpegR(context: android.content.Context, uri: android.net.Uri, maxDim: Int = 2000): ByteArray? {
    val input = context.contentResolver.openInputStream(uri) ?: return null
    val bmp = android.graphics.BitmapFactory.decodeStream(input) ?: return null
    input.close()
    val scale = maxDim.toFloat() / maxOf(bmp.width, bmp.height)
    val scaled = if (scale < 1f)
        android.graphics.Bitmap.createScaledBitmap(bmp, (bmp.width * scale).toInt(), (bmp.height * scale).toInt(), true)
    else bmp
    val out = java.io.ByteArrayOutputStream()
    scaled.compress(android.graphics.Bitmap.CompressFormat.JPEG, 80, out)
    return out.toByteArray()
}

// Rad i ønskelista: sigarnavn + format, tappbar til detalj.
@Composable
private fun WishlistRow(cigar: Cigar, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f)) {
            Text(cigar.brand, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.SemiBold)
            val sub = listOfNotNull(cigar.series, cigar.vitola).joinToString(" · ")
            if (sub.isNotBlank()) Text(sub, style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun LoginPrompt(onLogin: () -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            "Logg inn for å bruke din egen humidor og journal.",
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(Modifier.height(16.dp))
        Button(onClick = onLogin) { Text("Logg inn med Google") }
    }
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun AddHumidorSheet(onDismiss: () -> Unit, onCreated: () -> Unit, existing: HumidorRow? = null) {
    val scope = rememberCoroutineScope()
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val editing = existing != null

    var name by remember { mutableStateOf(existing?.name ?: "") }
    var type by remember { mutableStateOf<String?>(existing?.type ?: "Desktop") }
    var location by remember { mutableStateOf(existing?.location ?: "") }
    var capacityText by remember { mutableStateOf(existing?.capacity?.toString() ?: "") }
    var targetRh by remember { mutableStateOf(existing?.targetRh?.toString() ?: "") }
    var rhMin by remember { mutableStateOf(existing?.rhMin?.toString() ?: "") }
    var rhMax by remember { mutableStateOf(existing?.rhMax?.toString() ?: "") }
    var saving by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState) {
        Column(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(if (editing) "Rediger humidor" else "Ny humidor",
                style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)

            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                label = { Text("Navn") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )

            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Type", style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                // 2-kolonners grid av radio-kort (navn + forklaring synlig fra start).
                HumidorRepository.types.chunked(2).forEach { rowTypes ->
                    Row(
                        Modifier.fillMaxWidth().height(IntrinsicSize.Max),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        rowTypes.forEach { t ->
                            HumidorTypeCard(
                                modifier = Modifier.weight(1f).fillMaxHeight(),
                                type = t,
                                explanation = HumidorRepository.typeExplanations[t] ?: "",
                                selected = type == t,
                                onClick = { type = t }
                            )
                        }
                        if (rowTypes.size == 1) Spacer(Modifier.weight(1f))
                    }
                }
            }

            OutlinedTextField(
                value = location,
                onValueChange = { location = it },
                label = { Text("Plassering (valgfritt)") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )

            OutlinedTextField(
                value = capacityText,
                onValueChange = { v -> capacityText = v.filter { it.isDigit() } },
                label = { Text("Kapasitet (valgfritt)") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth()
            )

            // Luftfuktighet (RH)
            Text("Luftfuktighet (RH)", style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text("RH står for relativ luftfuktighet — hvor fuktig det er inne i humidoren. Sett gjerne et mål (f.eks. 69 %) og et valgfritt område.",
                style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            OutlinedTextField(
                value = targetRh,
                onValueChange = { targetRh = it.filter { c -> c.isDigit() }.take(3) },
                label = { Text("Mål-RH (%)") }, singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth()
            )
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = rhMin, onValueChange = { rhMin = it.filter { c -> c.isDigit() }.take(3) },
                    label = { Text("Fra (%)") }, singleLine = true, modifier = Modifier.weight(1f),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                )
                OutlinedTextField(
                    value = rhMax, onValueChange = { rhMax = it.filter { c -> c.isDigit() }.take(3) },
                    label = { Text("Til (%)") }, singleLine = true, modifier = Modifier.weight(1f),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                )
            }

            error?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyMedium) }

            Button(
                onClick = {
                    if (saving) return@Button
                    saving = true; error = null
                    scope.launch {
                        try {
                            if (editing) {
                                HumidorRepository.updateHumidor(
                                    id = existing!!.id,
                                    name = name.trim(),
                                    type = type,
                                    location = location.trim(),
                                    capacity = capacityText.toIntOrNull(),
                                    targetRh = targetRh.toIntOrNull(),
                                    rhMin = rhMin.toIntOrNull(),
                                    rhMax = rhMax.toIntOrNull(),
                                )
                            } else {
                                HumidorRepository.createHumidor(
                                    name = name.trim(),
                                    type = type,
                                    location = location.trim(),
                                    capacity = capacityText.toIntOrNull(),
                                    targetRh = targetRh.toIntOrNull(),
                                    rhMin = rhMin.toIntOrNull(),
                                    rhMax = rhMax.toIntOrNull(),
                                )
                            }
                            onCreated()
                        } catch (e: Exception) {
                            error = e.message ?: "Kunne ikke lagre humidor"
                            saving = false
                        }
                    }
                },
                enabled = !saving && name.isNotBlank(),
                modifier = Modifier.fillMaxWidth()
            ) {
                if (saving) CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp, color = MaterialTheme.colorScheme.onPrimary)
                else {
                    Icon(Icons.Filled.Check, null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(8.dp))
                    Text(if (editing) "Lagre endringer" else "Opprett humidor")
                }
            }
        }
    }
}

// Radio-kort for humidortype i grid: radioknapp + tittel øverst, forklaring under.
@Composable
private fun HumidorTypeCard(
    modifier: Modifier = Modifier,
    type: String,
    explanation: String,
    selected: Boolean,
    onClick: () -> Unit,
) {
    Column(
        modifier
            .clip(RoundedCornerShape(8.dp))
            .border(
                1.dp,
                if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant,
                RoundedCornerShape(8.dp)
            )
            .background(
                if (selected) MaterialTheme.colorScheme.primary.copy(alpha = 0.06f)
                else MaterialTheme.colorScheme.surface
            )
            .selectable(selected = selected, role = Role.RadioButton, onClick = onClick)
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            RadioButton(selected = selected, onClick = null, modifier = Modifier.size(20.dp))
            Spacer(Modifier.width(8.dp))
            Text(type, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium)
        }
        if (explanation.isNotBlank()) {
            Text(explanation, style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

// Vertikalt kort likt journal/iOS: bilde (eller ikon) på topp, så navn + meta + antall.
@Composable
private fun HumidorCard(h: HumidorUi, onClick: () -> Unit) {
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(6.dp))
            .background(MaterialTheme.colorScheme.surface)
            .clickable(onClick = onClick)
            .padding(12.dp)
    ) {
        // Bilde med antall-chip øverst til høyre (10px marg).
        Box(
            Modifier.fillMaxWidth().height(154.dp).clip(RoundedCornerShape(6.dp))
        ) {
            val img = h.row.imageUrl
            if (img != null) {
                AsyncImage(
                    model = img, contentDescription = null,
                    contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize()
                )
            } else {
                Box(
                    Modifier.fillMaxSize().background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Filled.Inventory2, contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(34.dp)
                    )
                }
            }
            // Antall-chip: sigar-ikon + tall (som iOS).
            val countLabel = h.row.capacity?.let { "${h.count}/$it" } ?: "${h.count}"
            Row(
                Modifier.align(Alignment.TopEnd).padding(10.dp)
                    .clip(RoundedCornerShape(50))
                    .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.92f))
                    .padding(horizontal = 14.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    painterResource(R.drawable.ic_cigar), contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurface, modifier = Modifier.size(18.dp)
                )
                Spacer(Modifier.width(5.dp))
                Text(countLabel, style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurface)
            }
        }
        Spacer(Modifier.height(8.dp))
        Row(
            Modifier.padding(vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(Modifier.weight(1f)) {
                Text(h.row.name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                val meta = listOfNotNull(h.row.type, h.row.location).joinToString(" · ")
                if (meta.isNotBlank()) {
                    Text(meta, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                if (h.value > 0) {
                    val kr = "%,d".format(h.value.toLong()).replace(',', ' ')
                    Text("$kr kr", style = MaterialTheme.typography.bodySmall,
                        fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.primary)
                }
            }
            // RH-indikator til høyre: farget boble + verdi (grå + 0 % når ingenting er målt).
            val rh = h.latestRh
            val status = rhStatus(rh?.rh, h.row.targetRh, h.row.rhMin, h.row.rhMax)
            val dot = if (rh == null) {
                MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
            } else when (status) {
                RhStatus.STABLE -> Color(0xFF3FA34D)
                RhStatus.SLIGHTLY_LOW, RhStatus.SLIGHTLY_HIGH -> Color(0xFFE0A400)
                RhStatus.TOO_DRY, RhStatus.TOO_WET -> Color(0xFFD64545)
                RhStatus.NONE -> MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
            }
            val rhText = rh?.let {
                val v = if (it.rh % 1.0 == 0.0) it.rh.toInt().toString() else String.format("%.1f", it.rh)
                "$v % RH"
            } ?: "0 % RH"
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(12.dp).clip(CircleShape).background(dot))
                Spacer(Modifier.width(7.dp))
                Text(rhText, style = MaterialTheme.typography.titleMedium, fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurface)
            }
        }
    }
}
