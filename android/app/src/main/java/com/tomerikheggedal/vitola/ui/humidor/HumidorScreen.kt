package com.tomerikheggedal.vitola.ui.humidor

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

// Stubb — Humidor krever innlogging (neste steg: Google-auth + humidors-tabell).
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HumidorScreen() {
    Scaffold(
        topBar = { CenterAlignedTopAppBar(title = { Text("Humidor") }) }
    ) { padding ->
        Box(Modifier.padding(padding).fillMaxSize().padding(32.dp), Alignment.Center) {
            Text(
                "Humidor kommer neste steg — den krever innlogging, som vi setter opp med Google-auth.",
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
