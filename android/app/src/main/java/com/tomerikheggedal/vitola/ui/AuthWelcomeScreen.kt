package com.tomerikheggedal.vitola.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.tomerikheggedal.vitola.R

// Velkomst-/login-skjerm ved oppstart. Man kan logge inn / opprette bruker,
// eller hoppe over og bla videre uten konto.
@Composable
fun AuthWelcomeScreen(onLogin: () -> Unit, onSkip: () -> Unit) {
    Surface(color = MaterialTheme.colorScheme.background) {
        Column(
            Modifier.fillMaxSize().padding(horizontal = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Image(
                painter = painterResource(R.drawable.vitola_logo),
                contentDescription = "Vitola",
                modifier = Modifier.size(width = 180.dp, height = 124.dp)
            )
            Spacer(Modifier.height(12.dp))
            Text(
                "Din digitale humidor og tasting-journal.",
                style = MaterialTheme.typography.bodyLarge, textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(Modifier.height(40.dp))

            Button(
                onClick = onLogin,
                shape = RoundedCornerShape(8.dp),
                modifier = Modifier.fillMaxWidth().height(52.dp)
            ) {
                Text("Logg inn eller opprett bruker", fontWeight = FontWeight.SemiBold)
            }
            Spacer(Modifier.height(8.dp))
            Text(
                "med Google",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(Modifier.height(24.dp))

            TextButton(onClick = onSkip) {
                Text("Fortsett uten konto", color = MaterialTheme.colorScheme.primary)
            }
        }
    }
}
