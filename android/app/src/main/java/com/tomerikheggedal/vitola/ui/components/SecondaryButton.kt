package com.tomerikheggedal.vitola.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tomerikheggedal.vitola.ui.theme.Accent

// ÉN samkjørt sekundærknapp for hele appen (speiler iOS: outline med 1.2px
// Accent-kant, hvit/lys tekst og ikon, ingen fyllfarge). Brukes overalt en
// sekundær handling vises, så knappene aldri ser forskjellige ut igjen.
@Composable
fun SecondaryButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier.fillMaxWidth(),
    enabled: Boolean = true,
    content: @Composable RowScope.() -> Unit
) {
    OutlinedButton(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier,
        border = BorderStroke(1.2.dp, Accent),
        colors = ButtonDefaults.outlinedButtonColors(
            contentColor = MaterialTheme.colorScheme.onBackground
        ),
        content = content
    )
}
