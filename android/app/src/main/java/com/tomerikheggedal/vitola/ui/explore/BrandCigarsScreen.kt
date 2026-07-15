package com.tomerikheggedal.vitola.ui.explore

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.tomerikheggedal.vitola.data.Cigar
import com.tomerikheggedal.vitola.data.CigarRepository

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BrandCigarsScreen(brand: String, onBack: () -> Unit, onCigar: (String) -> Unit) {
    var cigars by remember { mutableStateOf<List<Cigar>>(emptyList()) }
    var loading by remember { mutableStateOf(true) }

    LaunchedEffect(brand) {
        loading = true
        cigars = runCatching { CigarRepository.byBrand(brand) }.getOrDefault(emptyList())
        loading = false
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(brand) },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Tilbake") }
                }
            )
        }
    ) { padding ->
        if (loading) {
            Box(Modifier.padding(padding).fillMaxSize(), Alignment.Center) { CircularProgressIndicator() }
        } else {
            LazyColumn(Modifier.padding(padding).fillMaxSize()) {
                items(cigars, key = { it.id }) { c ->
                    Column(
                        Modifier.fillMaxWidth().clickable { onCigar(c.id) }
                            .padding(horizontal = 16.dp, vertical = 12.dp)
                    ) {
                        Text(c.series ?: c.vitola ?: c.brand, fontWeight = FontWeight.SemiBold)
                        val meta = listOfNotNull(c.commonFormat, c.dimensionsLabel, c.wrapperCountry).joinToString(" · ")
                        if (meta.isNotBlank()) {
                            Text(meta, color = MaterialTheme.colorScheme.onSurfaceVariant,
                                style = MaterialTheme.typography.bodySmall)
                        }
                    }
                    HorizontalDivider()
                }
            }
        }
    }
}
