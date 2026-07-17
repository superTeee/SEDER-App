package com.tomerikheggedal.vitola.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.tomerikheggedal.vitola.AppPrefs
import com.tomerikheggedal.vitola.data.Supa
import io.github.jan.supabase.gotrue.auth
import kotlinx.coroutines.launch

// Opplåsing ved oppstart når en kode er satt (som iOS PINUnlockView).
// Koden låser kun opp en allerede aktiv sesjon lokalt.
@Composable
fun PinUnlockScreen(onUnlock: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var pin by remember { mutableStateOf("") }
    var attempts by remember { mutableStateOf(0) }

    Column(
        Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background).padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("Skriv inn koden", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(20.dp))
        OutlinedTextField(
            value = pin,
            onValueChange = { v ->
                val digits = v.filter(Char::isDigit).take(4)
                pin = digits
                if (digits.length == 4) {
                    if (AppPrefs.verifyPin(context, digits)) onUnlock()
                    else { attempts++; pin = "" }
                }
            },
            label = { Text("4-sifret kode") },
            singleLine = true,
            visualTransformation = PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
            modifier = Modifier.width(200.dp)
        )
        if (attempts > 0) {
            Spacer(Modifier.height(10.dp))
            Text("Feil kode. Forsøk igjen (${(5 - attempts).coerceAtLeast(0)} igjen).",
                color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall,
                textAlign = TextAlign.Center)
        }
        Spacer(Modifier.height(24.dp))
        TextButton(onClick = { scope.launch { Supa.client.auth.signOut() } }) {
            Text("Logg ut i stedet")
        }
    }
}

// Sett eller endre 4-sifret kode (fra Innstillinger).
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PinSetupSheet(onDismiss: () -> Unit, onSet: () -> Unit) {
    val context = LocalContext.current
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var pin by remember { mutableStateOf("") }
    var confirm by remember { mutableStateOf("") }

    val valid = pin.length == 4 && pin == confirm

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface) {
        Column(
            Modifier.fillMaxWidth().padding(horizontal = 24.dp).padding(bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Text("Sett kodelås", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Text("En 4-sifret kode kreves for å åpne appen. Den låser kun opp lokalt og erstatter ikke passordet ditt.",
                style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)

            OutlinedTextField(
                value = pin, onValueChange = { pin = it.filter(Char::isDigit).take(4) },
                label = { Text("Ny kode") }, singleLine = true,
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = confirm, onValueChange = { confirm = it.filter(Char::isDigit).take(4) },
                label = { Text("Bekreft kode") }, singleLine = true,
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                modifier = Modifier.fillMaxWidth()
            )
            if (confirm.length == 4 && pin != confirm) {
                Text("Kodene er ikke like.", color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall)
            }

            Button(
                onClick = { AppPrefs.setPin(context, pin); onSet() },
                enabled = valid, modifier = Modifier.fillMaxWidth()
            ) { Text("Lagre kode") }
        }
    }
}
