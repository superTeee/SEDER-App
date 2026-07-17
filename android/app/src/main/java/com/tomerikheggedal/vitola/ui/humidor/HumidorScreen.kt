package com.tomerikheggedal.vitola.ui.humidor

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.Logout
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.tomerikheggedal.vitola.data.Cigar
import com.tomerikheggedal.vitola.data.HumidorRepository
import com.tomerikheggedal.vitola.data.HumidorRow
import com.tomerikheggedal.vitola.data.HumidorUi
import com.tomerikheggedal.vitola.data.Supa
import com.tomerikheggedal.vitola.data.WishlistRepository
import io.github.jan.supabase.gotrue.SessionStatus
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.gotrue.providers.Google
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HumidorScreen(onHumidor: (String) -> Unit = {}, onCigar: (String) -> Unit = {}) {
    val scope = rememberCoroutineScope()
    val status by Supa.client.auth.sessionStatus.collectAsState()
    val isAuthed = status is SessionStatus.Authenticated

    var humidors by remember { mutableStateOf<List<HumidorUi>>(emptyList()) }
    var loading by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var showAdd by remember { mutableStateOf(false) }
    var reloadKey by remember { mutableStateOf(0) }

    // Segmentert fane: 0 = Humidor, 1 = Ønskeliste (som iOS).
    var tab by remember { mutableStateOf(0) }
    var wishlist by remember { mutableStateOf<List<Cigar>>(emptyList()) }
    var loadingWishlist by remember { mutableStateOf(false) }

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

    // Last ønskelista hver gang fanen vises (så bokmerke-endringer reflekteres).
    LaunchedEffect(isAuthed, tab) {
        if (isAuthed && tab == 1) {
            loadingWishlist = true
            wishlist = runCatching { WishlistRepository.list() }.getOrDefault(emptyList())
            loadingWishlist = false
        }
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Humidor", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                ),
                actions = {
                    if (isAuthed) {
                        IconButton(onClick = { showAdd = true }) {
                            Icon(Icons.Filled.Add, contentDescription = "Ny humidor")
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
                SingleChoiceSegmentedButtonRow(
                    Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp)
                ) {
                    SegmentedButton(
                        selected = tab == 0, onClick = { tab = 0 },
                        shape = SegmentedButtonDefaults.itemShape(index = 0, count = 2)
                    ) { Text("Humidor") }
                    SegmentedButton(
                        selected = tab == 1, onClick = { tab = 1 },
                        shape = SegmentedButtonDefaults.itemShape(index = 1, count = 2)
                    ) { Text("Ønskeliste") }
                }
            }

            Box(Modifier.fillMaxSize()) {
                when {
                    !isAuthed -> LoginPrompt { scope.launch { Supa.client.auth.signInWith(Google) } }

                    tab == 1 -> when {
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
        val img = h.row.imageUrl
        if (img != null) {
            AsyncImage(
                model = img,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(154.dp)
                    .clip(RoundedCornerShape(6.dp))
            )
        } else {
            Box(
                Modifier
                    .fillMaxWidth()
                    .height(154.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Filled.Inventory2, contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(34.dp)
                )
            }
        }
        Spacer(Modifier.height(8.dp))
        Row(verticalAlignment = Alignment.Top) {
            Column(Modifier.weight(1f)) {
                Text(h.row.name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                val meta = listOfNotNull(h.row.type, h.row.location).joinToString(" · ")
                if (meta.isNotBlank()) {
                    Text(meta, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            val countLabel = h.row.capacity?.let { "${h.count}/$it" } ?: "${h.count}"
            Text(countLabel, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
