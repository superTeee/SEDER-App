package com.tomerikheggedal.vitola.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// Vitola-paletten (samme toner som iOS): krem bakgrunn, varm tobakks-accent.
val Accent = Color(0xFF8F7B51)
val CreamBackground = Color(0xFFEDEAE0)
val CardLight = Color(0xFFFFFFFF)
val TextPrimaryLight = Color(0xFF1C1B18)
val TextSecondaryLight = Color(0xFF6E695E)

val DarkBackground = Color(0xFF14130F)
val CardDark = Color(0xFF201E18)
val TextPrimaryDark = Color(0xFFFAF9F6)
val TextSecondaryDark = Color(0xFFBFBAAC)

private val LightColors = lightColorScheme(
    primary = Accent,
    onPrimary = Color.White,
    background = CreamBackground,
    onBackground = TextPrimaryLight,
    surface = CardLight,
    onSurface = TextPrimaryLight,
    surfaceVariant = CardLight,
    onSurfaceVariant = TextSecondaryLight,
)

private val DarkColors = darkColorScheme(
    primary = Accent,
    onPrimary = Color.White,
    background = DarkBackground,
    onBackground = TextPrimaryDark,
    surface = CardDark,
    onSurface = TextPrimaryDark,
    surfaceVariant = CardDark,
    onSurfaceVariant = TextSecondaryDark,
)

@Composable
fun VitolaTheme(
    dark: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = if (dark) DarkColors else LightColors,
        content = content
    )
}
