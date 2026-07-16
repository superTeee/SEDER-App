package com.tomerikheggedal.vitola.ui.humidor

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.tomerikheggedal.vitola.data.Cigar
import com.tomerikheggedal.vitola.data.HumidorContentRow
import com.tomerikheggedal.vitola.data.HumidorRepository
import com.tomerikheggedal.vitola.data.HumidorRow

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HumidorDetailScreen(id: String, onBack: () -> Unit, onCigar: (String) -> Unit) {
    var humidor by remember { mutableStateOf<HumidorRow?>(null) }
    var contents by remember { mutableStateOf<List<HumidorContentRow>>(emptyList()) }
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(id) {
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
                title = { Text(humidor?.name ?: "") },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Tilbake") }
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
                item { HumidorHeader(humidor, contents.sumOf { it.quantity ?: 1 }) }

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
                    items(contents, key = { it.cigar!!.id }) { row ->
                        row.cigar?.let { ContentRow(it, row.quantity ?: 1) { onCigar(it.id) } }
                        HorizontalDivider(color = MaterialTheme.colorScheme.surfaceVariant)
                    }
                }
                item { Spacer(Modifier.height(40.dp)) }
            }
        }
    }
}

@Composable
private fun HumidorHeader(humidor: HumidorRow?, totalCount: Int) {
    Column {
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

@Composable
private fun ContentRow(cigar: Cigar, quantity: Int, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 20.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f)) {
            Text(cigar.brand, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyLarge)
            val sub = listOfNotNull(cigar.series, cigar.vitola).joinToString(" · ")
            if (sub.isNotBlank()) {
                Text(sub, color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodySmall)
            }
            cigar.dimensionsLabel?.let {
                Text(it, color = MaterialTheme.colorScheme.primary, style = MaterialTheme.typography.labelMedium,
                    modifier = Modifier.padding(top = 2.dp))
            }
        }
        if (quantity > 1) {
            Text("×$quantity", color = MaterialTheme.colorScheme.onSurfaceVariant,
                style = MaterialTheme.typography.titleMedium)
        }
    }
}
