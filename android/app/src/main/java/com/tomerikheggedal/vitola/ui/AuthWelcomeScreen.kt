package com.tomerikheggedal.vitola.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.tomerikheggedal.vitola.R
import com.tomerikheggedal.vitola.data.Supa
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.gotrue.providers.Apple
import io.github.jan.supabase.gotrue.providers.Google
import io.github.jan.supabase.gotrue.providers.builtin.Email
import kotlinx.coroutines.launch

// Velkomst-/login-skjerm ved oppstart. Google, Apple eller e-post — eller hopp
// over og bla videre uten konto.
@Composable
fun AuthWelcomeScreen(onSkip: () -> Unit) {
    val scope = rememberCoroutineScope()
    var showEmail by remember { mutableStateOf(false) }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var busy by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var info by remember { mutableStateOf<String?>(null) }

    fun oauth(block: suspend () -> Unit) {
        busy = true; error = null; info = null
        scope.launch {
            runCatching { block() }.onFailure { error = "Innlogging feilet. Prøv igjen." }
            busy = false
        }
    }

    fun emailSignIn() {
        if (email.isBlank() || password.length < 6) { error = "Fyll inn e-post og passord (minst 6 tegn)."; return }
        busy = true; error = null; info = null
        scope.launch {
            val signIn = runCatching {
                Supa.client.auth.signInWith(Email) { this.email = email.trim(); this.password = password }
            }
            if (signIn.isFailure) {
                // Ingen konto? Prøv å registrere.
                val signUp = runCatching {
                    Supa.client.auth.signUpWith(Email) { this.email = email.trim(); this.password = password }
                }
                if (signUp.isFailure) error = "Innlogging feilet. Sjekk e-post og passord."
                else if (Supa.client.auth.currentUserOrNull() == null) {
                    info = "Konto opprettet. Sjekk e-posten din for å bekrefte, og logg så inn."
                }
            }
            busy = false
        }
    }

    Surface(color = MaterialTheme.colorScheme.background) {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Spacer(Modifier.height(48.dp))
            Image(
                painter = painterResource(R.drawable.vitola_logo),
                contentDescription = "SEDER",
                modifier = Modifier.size(width = 180.dp, height = 124.dp)
            )
            Spacer(Modifier.height(12.dp))
            Text(
                "Din digitale humidor og tasting-journal.",
                style = MaterialTheme.typography.bodyLarge, textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(Modifier.height(36.dp))

            // Google + Apple: like knapper (fylt, samme vekt) med merke-ikoner, som iOS.
            Button(
                onClick = { oauth { Supa.client.auth.signInWith(Google) } },
                enabled = !busy, shape = RoundedCornerShape(8.dp),
                modifier = Modifier.fillMaxWidth().height(52.dp)
            ) {
                Image(painterResource(R.drawable.ic_google), contentDescription = null, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(10.dp))
                Text("Fortsett med Google", fontWeight = FontWeight.SemiBold)
            }

            Spacer(Modifier.height(10.dp))

            Button(
                onClick = { oauth { Supa.client.auth.signInWith(Apple) } },
                enabled = !busy, shape = RoundedCornerShape(8.dp),
                modifier = Modifier.fillMaxWidth().height(52.dp)
            ) {
                Icon(painterResource(R.drawable.ic_apple), contentDescription = null, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(10.dp))
                Text("Fortsett med Apple", fontWeight = FontWeight.SemiBold)
            }

            Spacer(Modifier.height(10.dp))

            if (showEmail) {
                OutlinedTextField(
                    value = email, onValueChange = { email = it },
                    label = { Text("E-post") }, singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(8.dp))
                OutlinedTextField(
                    value = password, onValueChange = { password = it },
                    label = { Text("Passord") }, singleLine = true,
                    visualTransformation = PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(10.dp))
                Button(
                    onClick = { emailSignIn() }, enabled = !busy,
                    shape = RoundedCornerShape(8.dp), modifier = Modifier.fillMaxWidth().height(52.dp)
                ) { Text(if (busy) "Logger inn…" else "Logg inn / Registrer", fontWeight = FontWeight.SemiBold) }
            } else {
                TextButton(onClick = { showEmail = true }) {
                    Text("Bruk e-post i stedet", color = MaterialTheme.colorScheme.primary)
                }
            }

            error?.let {
                Spacer(Modifier.height(10.dp))
                Text(it, color = MaterialTheme.colorScheme.error, textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.bodySmall)
            }
            info?.let {
                Spacer(Modifier.height(10.dp))
                Text(it, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.bodySmall)
            }

            Spacer(Modifier.height(20.dp))
            TextButton(onClick = onSkip) {
                Text("Fortsett uten konto", color = MaterialTheme.colorScheme.primary)
            }
            Spacer(Modifier.height(32.dp))
        }
    }
}
