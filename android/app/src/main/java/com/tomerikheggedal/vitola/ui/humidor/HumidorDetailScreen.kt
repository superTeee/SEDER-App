package com.tomerikheggedal.vitola.ui.humidor

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.tomerikheggedal.vitola.data.Cigar
import com.tomerikheggedal.vitola.data.HumidorContentRow
import com.tomerikheggedal.vitola.data.HumidorRepository
import com.tomerikheggedal.vitola.data.HumidorRow
import com.tomerikheggedal.vitola.data.HumidorUi
import com.tomerikheggedal.vitola.data.RhReading
import com.tomerikheggedal.vitola.data.RhStatus
import com.tomerikheggedal.vitola.data.rhStatus
import com.tomerikheggedal.vitola.ui.components.ListCard
import com.tomerikheggedal.vitola.ui.components.NavRow
import com.tomerikheggedal.vitola.ui.components.RowDivider
import com.tomerikheggedal.vitola.ui.components.SectionLabel
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HumidorDetailScreen(id: String, onBack: () -> Unit, onCigar: (String) -> Unit) {
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    var humidor by remember { mutableStateOf<HumidorRow?>(null) }
    var contents by remember { mutableStateOf<List<HumidorContentRow>>(emptyList()) }
    var readings by remember { mutableStateOf<List<com.tomerikheggedal.vitola.data.RhReading>>(emptyList()) }
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<String?>(null) }
    var reloadKey by remember { mutableStateOf(0) }
    var showRhSheet by remember { mutableStateOf(false) }

    var menuOpen by remember { mutableStateOf(false) }
    var showEdit by remember { mutableStateOf(false) }
    var showDelete by remember { mutableStateOf(false) }
    var uploadingCover by remember { mutableStateOf(false) }
    var entryMenu by remember { mutableStateOf<HumidorContentRow?>(null) }
    var showMove by remember { mutableStateOf<HumidorContentRow?>(null) }

    val pickCover = com.tomerikheggedal.vitola.ui.rememberCropPicker(16, 9) { uri ->
        scope.launch {
            uploadingCover = true
            val jpeg = uriToJpeg(context, uri)
            if (jpeg != null) runCatching { HumidorRepository.uploadCover(id, jpeg) }
            uploadingCover = false
            reloadKey++
        }
    }

    LaunchedEffect(id, reloadKey) {
        loading = true; error = null
        try {
            humidor = HumidorRepository.humidorById(id)
            contents = HumidorRepository.humidorContents(id)
            readings = runCatching { HumidorRepository.readings(id) }.getOrDefault(emptyList())
        } catch (e: Exception) {
            error = e.message ?: "Kunne ikke laste humidoren"
        }
        loading = false
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = { Text(humidor?.name ?: "", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Tilbake") }
                },
                actions = {
                    Box {
                        IconButton(onClick = { menuOpen = true }) {
                            Icon(Icons.Filled.MoreVert, contentDescription = "Mer")
                        }
                        DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                            DropdownMenuItem(text = { Text("Rediger humidor") },
                                onClick = { menuOpen = false; showEdit = true })
                            DropdownMenuItem(text = { Text("Bytt forsidebilde") },
                                onClick = { menuOpen = false; pickCover() })
                            DropdownMenuItem(text = { Text("Slett humidor") },
                                onClick = { menuOpen = false; showDelete = true })
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        }
    ) { padding ->
        when {
            loading -> Box(Modifier.padding(padding).fillMaxSize(), Alignment.Center) { CircularProgressIndicator() }
            error != null -> Box(Modifier.padding(padding).fillMaxSize(), Alignment.Center) {
                Text(error!!, color = MaterialTheme.colorScheme.error, modifier = Modifier.padding(24.dp))
            }
            else -> LazyColumn(Modifier.padding(padding).fillMaxSize()) {
                item { HumidorHeader(humidor, contents.sumOf { it.quantity ?: 1 }, uploadingCover) }

                item {
                    humidor?.let { RhCard(it, readings, onRegister = { showRhSheet = true }) }
                }

                if (contents.isEmpty()) {
                    item {
                        Text(
                            "Ingen sigarer i denne humidoren ennå.",
                            textAlign = TextAlign.Center,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.fillMaxWidth().padding(32.dp)
                        )
                    }
                } else {
                    item { SectionLabel("Sigarer") }
                    item {
                        ListCard {
                            contents.forEachIndexed { i, row ->
                                val c = row.cigar!!
                                val qty = row.quantity ?: 1
                                NavRow(
                                    title = c.brand,
                                    titleBold = true,
                                    subtitle = listOfNotNull(c.series, c.vitola).joinToString(" · ")
                                        .ifBlank { null },
                                    detail = listOfNotNull(
                                        c.dimensionsLabel,
                                        if (qty > 1) "×$qty" else null
                                    ).joinToString(" · ").ifBlank { null },
                                    onLongClick = { entryMenu = row },
                                ) { onCigar(c.id) }
                                if (i < contents.lastIndex) RowDivider()
                            }
                        }
                    }
                    item {
                        Text("Hold inne en sigar for å flytte eller fjerne den.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp))
                    }
                }
                item { Spacer(Modifier.height(40.dp)) }
            }
        }
    }

    // Rediger humidor
    if (showEdit) {
        AddHumidorSheet(
            existing = humidor,
            onDismiss = { showEdit = false },
            onCreated = { showEdit = false; reloadKey++ }
        )
    }

    // Slett humidor
    if (showDelete) {
        AlertDialog(
            onDismissRequest = { showDelete = false },
            title = { Text("Slett humidor?") },
            text = { Text("Humidoren slettes. Sigarene du har lagt i den beholdes i samlingen din.") },
            confirmButton = {
                TextButton(onClick = {
                    showDelete = false
                    scope.launch { runCatching { HumidorRepository.deleteHumidor(id) }; onBack() }
                }) { Text("Slett", color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = { TextButton(onClick = { showDelete = false }) { Text("Avbryt") } }
        )
    }

    // Handlinger på en oppføring (flytt / fjern)
    entryMenu?.let { row ->
        EntryActionsSheet(
            cigar = row.cigar,
            onMove = { entryMenu = null; showMove = row },
            onRemove = {
                entryMenu = null
                scope.launch { row.id?.let { runCatching { HumidorRepository.removeEntry(it) } }; reloadKey++ }
            },
            onDismiss = { entryMenu = null }
        )
    }

    // Velg humidor å flytte til
    showMove?.let { row ->
        MoveHumidorPickerSheet(
            currentId = id,
            onPick = { targetId ->
                showMove = null
                scope.launch { row.id?.let { runCatching { HumidorRepository.moveEntry(it, targetId) } }; reloadKey++ }
            },
            onDismiss = { showMove = null }
        )
    }

    // Registrer RH-måling
    if (showRhSheet) {
        RhReadingSheet(
            onDismiss = { showRhSheet = false },
            onSave = { rh, temp, note, measuredAt ->
                showRhSheet = false
                scope.launch {
                    runCatching { HumidorRepository.addReading(id, rh, temp, note, measuredAt) }
                    reloadKey++
                }
            }
        )
    }
}

@Composable
private fun HumidorHeader(humidor: HumidorRow?, totalCount: Int, uploadingCover: Boolean) {
    Column {
        Box {
            val img = humidor?.imageUrl
            if (img != null) {
                AsyncImage(
                    model = img,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxWidth().height(200.dp)
                )
            } else {
                Box(
                    Modifier
                        .fillMaxWidth()
                        .height(160.dp)
                        .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Filled.Inventory2, contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(40.dp)
                    )
                }
            }
            if (uploadingCover) {
                Box(Modifier.matchParentSize().background(androidx.compose.ui.graphics.Color.Black.copy(alpha = 0.4f)),
                    contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = androidx.compose.ui.graphics.Color.White)
                }
            }
        }

        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            humidor?.name?.let {
                Text(it, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.SemiBold)
            }
            val meta = listOfNotNull(humidor?.type, humidor?.location).joinToString(" · ")
            if (meta.isNotBlank()) {
                Text(meta, color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodyMedium)
            }
            val cap = humidor?.capacity
            Text(
                if (cap != null) "$totalCount / $cap sigarer" else "$totalCount sigarer",
                color = MaterialTheme.colorScheme.primary,
                style = MaterialTheme.typography.labelLarge
            )
        }
    }
}

// Bunn-ark: flytt eller fjern en sigar-oppføring.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun EntryActionsSheet(cigar: Cigar?, onMove: () -> Unit, onRemove: () -> Unit, onDismiss: () -> Unit) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface) {
        Column(Modifier.fillMaxWidth().padding(bottom = 24.dp)) {
            cigar?.let {
                Text(listOfNotNull(it.brand, it.series, it.vitola).joinToString(" "),
                    style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp))
            }
            Text("Flytt til en annen humidor",
                style = MaterialTheme.typography.bodyLarge,
                modifier = Modifier.fillMaxWidth().clickable(onClick = onMove)
                    .padding(horizontal = 20.dp, vertical = 16.dp))
            Text("Fjern fra humidor",
                style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.error,
                modifier = Modifier.fillMaxWidth().clickable(onClick = onRemove)
                    .padding(horizontal = 20.dp, vertical = 16.dp))
        }
    }
}

// Bunn-ark: velg hvilken humidor sigaren skal flyttes til.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun MoveHumidorPickerSheet(currentId: String, onPick: (String) -> Unit, onDismiss: () -> Unit) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var options by remember { mutableStateOf<List<HumidorUi>?>(null) }
    LaunchedEffect(Unit) {
        options = runCatching { HumidorRepository.myHumidors() }.getOrDefault(emptyList())
            .filter { it.row.id != currentId }
    }
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface) {
        Column(Modifier.fillMaxWidth().padding(bottom = 24.dp)) {
            Text("Flytt til", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp))
            val list = options
            when {
                list == null -> Box(Modifier.fillMaxWidth().padding(24.dp), Alignment.Center) {
                    CircularProgressIndicator()
                }
                list.isEmpty() -> Text("Du har ingen andre humidorer å flytte til.",
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp))
                else -> list.forEach { h ->
                    Text(h.row.name, style = MaterialTheme.typography.bodyLarge,
                        modifier = Modifier.fillMaxWidth().clickable { onPick(h.row.id) }
                            .padding(horizontal = 20.dp, vertical = 16.dp))
                }
            }
        }
    }
}

// RH-kort: sist målte RH + mål/status + Registrer RH-knapp + historikk.
@Composable
private fun RhCard(humidor: HumidorRow, readings: List<RhReading>, onRegister: () -> Unit) {
    val latest = readings.firstOrNull()
    val status = rhStatus(latest?.rh, humidor.targetRh, humidor.rhMin, humidor.rhMax)
    val stale = latest?.let { rhIsStale(it.measuredAt) } ?: false
    val badgeColor = when (status) {
        RhStatus.STABLE -> MaterialTheme.colorScheme.primary
        RhStatus.NONE -> MaterialTheme.colorScheme.onSurfaceVariant
        else -> MaterialTheme.colorScheme.onSurface
    }

    Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)) {
        Text("LUFTFUKTIGHET (RH)", style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(bottom = 8.dp))

        Column(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp))
                .background(MaterialTheme.colorScheme.surface).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(verticalAlignment = Alignment.Top) {
                Column(Modifier.weight(1f)) {
                    Text(
                        if (latest != null) "${rhStr(latest.rh)} % RH" else "— % RH",
                        style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold,
                        color = if (latest != null) MaterialTheme.colorScheme.onSurface
                                else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    humidor.rhTargetLabel?.let {
                        Text("Mål: $it", style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                Text(
                    status.label, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold,
                    color = badgeColor,
                    modifier = Modifier.clip(RoundedCornerShape(50)).background(badgeColor.copy(alpha = 0.12f))
                        .padding(horizontal = 10.dp, vertical = 5.dp)
                )
            }
            latest?.let {
                Row {
                    Text("Sist målt ${rhRelative(it.measuredAt)}",
                        style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    if (stale) {
                        Text(" · Ikke målt nylig", style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.primary)
                    }
                }
            }
            OutlinedButton(onClick = onRegister, modifier = Modifier.fillMaxWidth()) {
                Icon(Icons.Filled.Add, null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(8.dp))
                Text("Registrer RH")
            }
        }

        if (readings.isNotEmpty()) {
            Spacer(Modifier.height(14.dp))
            Text("HISTORIKK", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(bottom = 8.dp))
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp)).background(MaterialTheme.colorScheme.surface)) {
                val shown = readings.take(20)
                shown.forEachIndexed { i, r ->
                    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically) {
                        Text("${rhStr(r.rh)} %", style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium)
                        r.temperature?.let {
                            Text(" · ${rhStr(it)} °C", style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        Spacer(Modifier.weight(1f))
                        Text(rhRelative(r.measuredAt), style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    if (i < shown.lastIndex) HorizontalDivider(Modifier.padding(start = 16.dp),
                        color = MaterialTheme.colorScheme.surfaceVariant)
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun RhReadingSheet(onDismiss: () -> Unit, onSave: (Double, Double?, String?, String) -> Unit) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var rh by remember { mutableStateOf("") }
    var temp by remember { mutableStateOf("") }
    var note by remember { mutableStateOf("") }
    val rhVal = rh.replace(',', '.').toDoubleOrNull()

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface) {
        Column(
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp).padding(bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Text("Registrer RH", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Text("RH = relativ luftfuktighet — hvor fuktig det er inne i humidoren akkurat nå. Du registrerer selve målingen fra hygrometeret ditt; appen måler ikke automatisk. Tidspunkt settes til nå.",
                style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)

            OutlinedTextField(
                value = rh, onValueChange = { rh = it.filter { c -> c.isDigit() || c == '.' || c == ',' } },
                label = { Text("Målt RH (%)") }, singleLine = true, modifier = Modifier.fillMaxWidth(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
            )
            OutlinedTextField(
                value = temp, onValueChange = { temp = it.filter { c -> c.isDigit() || c == '.' || c == ',' || c == '-' } },
                label = { Text("Temperatur °C (valgfritt)") }, singleLine = true, modifier = Modifier.fillMaxWidth(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
            )
            OutlinedTextField(
                value = note, onValueChange = { note = it },
                label = { Text("Notat (valgfritt)") }, minLines = 2, modifier = Modifier.fillMaxWidth()
            )
            Button(
                onClick = {
                    rhVal?.let {
                        onSave(it, temp.replace(',', '.').toDoubleOrNull(), note, java.time.Instant.now().toString())
                    }
                },
                enabled = rhVal != null, modifier = Modifier.fillMaxWidth()
            ) { Text("Lagre måling") }
        }
    }
}

private fun rhStr(v: Double): String = if (v % 1.0 == 0.0) v.toInt().toString() else String.format("%.1f", v)

private fun rhInstant(iso: String): java.time.Instant? =
    runCatching { java.time.OffsetDateTime.parse(iso).toInstant() }
        .recoverCatching { java.time.Instant.parse(iso) }.getOrNull()

private fun rhRelative(iso: String): String {
    val inst = rhInstant(iso) ?: return ""
    val diff = (java.time.Instant.now().epochSecond - inst.epochSecond).coerceAtLeast(0)
    return when {
        diff < 60 -> "nå nettopp"
        diff < 3600 -> "for ${diff / 60} min siden"
        diff < 86400 -> "for ${diff / 3600} t siden"
        diff < 604800 -> "for ${diff / 86400} d siden"
        else -> inst.atZone(java.time.ZoneId.systemDefault())
            .format(java.time.format.DateTimeFormatter.ofPattern("d. MMM yyyy", java.util.Locale("nb", "NO")))
    }
}

private fun rhIsStale(iso: String): Boolean {
    val inst = rhInstant(iso) ?: return false
    return java.time.Instant.now().epochSecond - inst.epochSecond > 7 * 86400
}

// Galleri-Uri → nedskalert JPEG (maks 1400px).
private fun uriToJpeg(context: android.content.Context, uri: android.net.Uri, maxDim: Int = 1400): ByteArray? {
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
