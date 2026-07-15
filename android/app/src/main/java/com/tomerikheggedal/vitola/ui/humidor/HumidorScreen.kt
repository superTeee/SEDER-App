package com.tomerikheggedal.vitola.ui.humidor

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.tomerikheggedal.vitola.data.Supa
import io.github.jan.supabase.gotrue.SessionStatus
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.gotrue.providers.Google
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HumidorScreen() {
    val scope = rememberCoroutineScope()
    val status by Supa.client.auth.sessionStatus.collectAsState()

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Humidor") },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        }
    ) { padding ->
        Box(
            Modifier.padding(padding).fillMaxSize().padding(24.dp),
            contentAlignment = Alignment.Center
        ) {
            when (status) {
                is SessionStatus.Authenticated -> {
                    val email = Supa.client.auth.currentUserOrNull()?.email ?: "ukjent"
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Text("Logget inn som", color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Text(email, style = MaterialTheme.typography.titleMedium)
                        Text(
                            "Humidor-innholdet kommer som neste steg.",
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            textAlign = TextAlign.Center
                        )
                        OutlinedButton(onClick = { scope.launch { Supa.client.auth.signOut() } }) {
                            Text("Logg ut")
                        }
                    }
                }
                is SessionStatus.NotAuthenticated -> {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Text(
                            "Logg inn for å bruke din egen humidor og journal.",
                            textAlign = TextAlign.Center,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Button(onClick = { scope.launch { Supa.client.auth.signInWith(Google) } }) {
                            Text("Logg inn med Google")
                        }
                    }
                }
                else -> CircularProgressIndicator() // laster fra lagring / nettverksfeil
            }
        }
    }
}
