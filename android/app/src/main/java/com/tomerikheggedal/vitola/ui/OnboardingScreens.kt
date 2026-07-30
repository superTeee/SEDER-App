package com.tomerikheggedal.vitola.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Block
import androidx.compose.material.icons.filled.CheckBox
import androidx.compose.material.icons.outlined.CheckBoxOutlineBlank
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.tomerikheggedal.vitola.data.ProfileRepository
import kotlinx.coroutines.launch

// ── Aldersbekreftelse (som iOS AgeGateView) ────────────────────────────────
@Composable
fun AgeGateScreen(onVerified: () -> Unit) {
    var blocked by remember { mutableStateOf(false) }

    if (blocked) {
        AgeBlockedScreen(onBack = { blocked = false })
        return
    }

    Column(
        Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)
            .verticalScroll(rememberScrollState()).padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(Modifier.height(48.dp))
        Text("SEDER", style = MaterialTheme.typography.displaySmall, fontWeight = FontWeight.Bold)
        Text("Din digitale humidor", style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant)

        Spacer(Modifier.height(48.dp))
        Text("Bekreft alder", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(8.dp))
        Text("Du må være 18 år eller eldre for å bruke SEDER",
            style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(Modifier.height(20.dp))
        // Egenerklæring med ja/nei i stedet for fødselsår
        Button(onClick = onVerified, modifier = Modifier.width(240.dp)) { Text("Jeg er over 18 år") }
        Spacer(Modifier.height(8.dp))
        TextButton(onClick = { blocked = true }) {
            Text("Jeg er under 18 år", color = MaterialTheme.colorScheme.onSurfaceVariant)
        }

        Spacer(Modifier.height(48.dp))
        Text("Appen er kun for personer over 18 år.\nKjøp og promotering av tobakk er ikke en del av appen.",
            style = MaterialTheme.typography.bodySmall, textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

// Blokkeringsskjerm for under 18
@Composable
fun AgeBlockedScreen(onBack: () -> Unit) {
    Column(
        Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)
            .verticalScroll(rememberScrollState()).padding(horizontal = 32.dp, vertical = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(Icons.Filled.Block, contentDescription = null,
            tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(46.dp))
        Spacer(Modifier.height(20.dp))
        Text("Vi ses om noen år", style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
        Spacer(Modifier.height(12.dp))
        Text(
            "SEDER er en digital humidor og smaksjournal laget for voksne sigarentusiaster. " +
                "Innholdet er kun ment for personer over 18 år, så vi kan dessverre ikke gi deg tilgang ennå.\n\n" +
                "Du er hjertelig velkommen tilbake når du fyller 18.",
            style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant, lineHeight = 22.sp
        )
        Spacer(Modifier.height(28.dp))
        TextButton(onClick = onBack) { Text("Tilbake") }
    }
}

// ── Personvern-samtykke (som iOS PrivacyConsentView) ───────────────────────
@Composable
fun PrivacyConsentScreen(onAccepted: () -> Unit) {
    var accepted by remember { mutableStateOf(false) }
    var showPolicy by remember { mutableStateOf(false) }

    Column(
        Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background).padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(Modifier.height(56.dp))
        Text("Før du fortsetter", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(8.dp))
        Text("Les personvernerklæringen vår og godta vilkårene for å bruke SEDER.",
            style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant)

        Spacer(Modifier.weight(1f))

        OutlinedCard(onClick = { showPolicy = true }, modifier = Modifier.fillMaxWidth()) {
            Row(Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text("Personvernerklæring", fontWeight = FontWeight.SemiBold,
                        style = MaterialTheme.typography.bodyLarge)
                    Text("Trykk for å lese", style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Text("›", style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }

        Spacer(Modifier.height(16.dp))
        Row(
            Modifier.fillMaxWidth().clickable { accepted = !accepted }.padding(vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                if (accepted) Icons.Filled.CheckBox else Icons.Outlined.CheckBoxOutlineBlank,
                contentDescription = null,
                tint = if (accepted) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(Modifier.width(12.dp))
            Text("Jeg har lest og godtar personvernerklæringen til SEDER",
                style = MaterialTheme.typography.bodyMedium)
        }

        Spacer(Modifier.weight(1f))

        Button(onClick = onAccepted, enabled = accepted, modifier = Modifier.fillMaxWidth()) {
            Text("Godta og fortsett")
        }
        Spacer(Modifier.height(8.dp))
        Text("Appen er kun for personer over 18 år.",
            style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(Modifier.height(16.dp))
    }

    if (showPolicy) PrivacyPolicyDialog(onDismiss = { showPolicy = false })
}

@Composable
private fun PrivacyPolicyDialog(onDismiss: () -> Unit) {
    val sections = listOf(
        "Hva vi samler inn" to "E-postadresse (for innlogging), navn/kallenavn (valgfritt), sigarnotater og vurderinger du selv legger inn, og by/sted (valgfritt).",
        "Hva vi ikke samler inn" to "Helseopplysninger, betalingsinformasjon, lokasjonsdata eller data fra tredjepart uten din godkjenning.",
        "Hvordan vi bruker dataene" to "Dataene brukes utelukkende for å drive SEDER-appen: lagre og vise sigarjournalen din, identifisere kontoen din og la deg logge inn. Vi selger ikke dataene dine til tredjepart, og de brukes ikke til reklame.",
        "Hvem ser dataene dine" to "Dataene lagres i Supabase (USA). Vi deler ikke data med andre aktører. Innlogging via Apple eller Google håndteres av henholdsvis Apple og Google etter deres egne personvernregler.",
        "Dine rettigheter" to "Du kan se, korrigere eller slette dataene dine når som helst. Slett kontoen direkte i appen under Innstillinger → Slett konto.",
        "Aldersgrense" to "SEDER er kun beregnet for brukere over 18 år.",
        "Kontakt" to "Spørsmål om personvern? Send e-post til theggedal@gmail.com",
    )
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Personvernerklæring") },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                sections.forEach { (t, b) ->
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(t, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyMedium)
                        Text(b, style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                Text("Sist oppdatert: juli 2026", style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("Lukk") } }
    )
}

// ── Navn-onboarding etter første innlogging (som iOS OnboardingProfileView) ──
@Composable
fun OnboardingNameScreen(onComplete: () -> Unit) {
    val scope = rememberCoroutineScope()
    var name by remember { mutableStateOf(ProfileRepository.authName().orEmpty()) }
    var saving by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val email = remember { ProfileRepository.authEmail() }

    Column(
        Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)
            .verticalScroll(rememberScrollState()).padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(Modifier.height(72.dp))
        Text("Velkommen til SEDER", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(8.dp))
        Text("Sett opp profilen din for å komme i gang",
            style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant)

        Spacer(Modifier.height(40.dp))

        email?.let {
            OutlinedTextField(value = it, onValueChange = {}, enabled = false, readOnly = true,
                label = { Text("Konto") }, singleLine = true, modifier = Modifier.fillMaxWidth())
            Spacer(Modifier.height(12.dp))
        }

        OutlinedTextField(
            value = name, onValueChange = { name = it },
            label = { Text("Visningsnavn") }, placeholder = { Text("Hva vil du hete?") },
            singleLine = true, modifier = Modifier.fillMaxWidth()
        )

        error?.let {
            Spacer(Modifier.height(8.dp))
            Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
        }

        Spacer(Modifier.height(20.dp))
        Button(
            onClick = {
                if (name.isBlank()) return@Button
                saving = true; error = null
                scope.launch {
                    val res = runCatching { ProfileRepository.updateName(name.trim()) }
                    saving = false
                    if (res.isSuccess) onComplete() else error = "Kunne ikke lagre — prøv igjen."
                }
            },
            enabled = !saving && name.isNotBlank(),
            modifier = Modifier.fillMaxWidth()
        ) {
            if (saving) CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp,
                color = MaterialTheme.colorScheme.onPrimary)
            else Text("Kom i gang")
        }
    }
}
