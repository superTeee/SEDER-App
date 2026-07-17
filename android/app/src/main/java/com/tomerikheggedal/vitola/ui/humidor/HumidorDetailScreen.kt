package com.tomerikheggedal.vitola.ui.humidor

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.tomerikheggedal.vitola.data.Cigar
import com.tomerikheggedal.vitola.data.HumidorContentRow
import com.tomerikheggedal.vitola.data.HumidorRepository
import com.tomerikheggedal.vitola.data.HumidorRow
import com.tomerikheggedal.vitola.data.HumidorUi
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
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<String?>(null) }
    var reloadKey by remember { mutableStateOf(0) }

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
