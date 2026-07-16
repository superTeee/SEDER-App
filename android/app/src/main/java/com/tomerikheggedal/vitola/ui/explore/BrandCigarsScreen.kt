package com.tomerikheggedal.vitola.ui.explore

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tomerikheggedal.vitola.data.Cigar
import com.tomerikheggedal.vitola.data.CigarRepository
import com.tomerikheggedal.vitola.ui.components.ListCard
import com.tomerikheggedal.vitola.ui.components.NavRow
import com.tomerikheggedal.vitola.ui.components.RowDivider

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
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = { Text(brand) },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Tilbake") }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        }
    ) { padding ->
        if (loading) {
            Box(Modifier.padding(padding).fillMaxSize(), Alignment.Center) { CircularProgressIndicator() }
        } else {
            LazyColumn(
                Modifier.padding(padding).fillMaxSize(),
                contentPadding = PaddingValues(top = 8.dp, bottom = 24.dp)
            ) {
                item {
                    ListCard {
                        cigars.forEachIndexed { i, c ->
                            NavRow(
                                title = c.series ?: c.vitola ?: c.brand,
                                titleBold = true,
                                subtitle = listOfNotNull(c.commonFormat, c.dimensionsLabel, c.wrapperCountry)
                                    .joinToString(" · ").ifBlank { null },
                            ) { onCigar(c.id) }
                            if (i < cigars.lastIndex) RowDivider()
                        }
                    }
                }
            }
        }
    }
}
