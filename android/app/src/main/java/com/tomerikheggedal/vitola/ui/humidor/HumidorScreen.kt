package com.tomerikheggedal.vitola.ui.humidor

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.tomerikheggedal.vitola.data.HumidorRepository
import com.tomerikheggedal.vitola.data.HumidorUi
import com.tomerikheggedal.vitola.data.Supa
import io.github.jan.supabase.gotrue.SessionStatus
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.gotrue.providers.Google
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HumidorScreen(onHumidor: (String) -> Unit = {}) {
    val scope = rememberCoroutineScope()
    val status by Supa.client.auth.sessionStatus.collectAsState()
    val isAuthed = status is SessionStatus.Authenticated

    var humidors by remember { mutableStateOf<List<HumidorUi>>(emptyList()) }
    var loading by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var showAdd by remember { mutableStateOf(false) }
    var reloadKey by remember { mutableStateOf(0) }

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
        Box(Modifier.padding(padding).fillMaxSize()) {
            when {
                !isAuthed -> LoginPrompt { scope.launch { Supa.client.auth.signInWith(Google) } }
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

    if (showAdd) {
        AddHumidorSheet(
            onDismiss = { showAdd = false },
            onCreated = { showAdd = false; reloadKey++ }
        )
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
fun AddHumidorSheet(onDismiss: () -> Unit, onCreated: () -> Unit) {
    val scope = rememberCoroutineScope()
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    var name by remember { mutableStateOf("") }
    var type by remember { mutableStateOf<String?>(null) }
    var location by remember { mutableStateOf("") }
    var capacityText by remember { mutableStateOf("") }
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
            Text("Ny humidor", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)

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
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    HumidorRepository.types.forEach { t ->
                        FilterChip(
                            selected = type == t,
                            onClick = { type = if (type == t) null else t },
                            label = { Text(t) }
                        )
                    }
                }
                // Forklaring på valgt type — så nybegynnere skjønner forskjellen.
                type?.let { t ->
                    HumidorRepository.typeExplanations[t]?.let { desc ->
                        Text(desc, style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
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

            error?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyMedium) }

            Button(
                onClick = {
                    if (saving) return@Button
                    saving = true; error = null
                    scope.launch {
                        try {
                            HumidorRepository.createHumidor(
                                name = name.trim(),
                                type = type,
                                location = location.trim(),
                                capacity = capacityText.toIntOrNull()
                            )
                            onCreated()
                        } catch (e: Exception) {
                            error = e.message ?: "Kunne ikke opprette humidor"
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
                    Text("Opprett humidor")
                }
            }
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
