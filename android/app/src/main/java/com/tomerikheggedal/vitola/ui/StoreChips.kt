package com.tomerikheggedal.vitola.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// «Kjøpt hos»-forslag (som iOS' KnownStores). Feltet er fritt — chipsene gjør bare
// det vanlige norske kjøpet raskt og konsistent.
object KnownStores {
    val norway = listOf("Sol Cigar", "Augusto Cigars", "M. Sørensen", "No Smoke", "Nordic Cigars", "Fuego Cigars")

    /** Brukerens egne butikker først (mest relevant), så de norske som ikke alt er med. */
    fun merged(userStores: List<String>): List<String> {
        val out = userStores.toMutableList()
        for (s in norway) if (out.none { it.equals(s, ignoreCase = true) }) out.add(s)
        return out
    }
}

// Horisontalt scrollbar rad av butikk-chips. Trykk = fyll feltet; aktivt valg = aksent.
@Composable
fun StoreChips(suggestions: List<String>, current: String, onPick: (String) -> Unit) {
    if (suggestions.isEmpty()) return
    Row(
        Modifier.horizontalScroll(rememberScrollState()).padding(top = 6.dp)
    ) {
        suggestions.forEach { name ->
            val on = name.equals(current.trim(), ignoreCase = true)
            Text(
                name,
                fontSize = 13.sp,
                color = if (on) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurface,
                modifier = Modifier
                    .padding(end = 8.dp)
                    .clip(RoundedCornerShape(20.dp))
                    .background(if (on) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surface)
                    .clickable { onPick(if (on) "" else name) }
                    .padding(horizontal = 12.dp, vertical = 7.dp)
            )
        }
    }
}
