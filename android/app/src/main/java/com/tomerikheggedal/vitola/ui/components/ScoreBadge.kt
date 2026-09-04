package com.tomerikheggedal.vitola.ui.components

import androidx.compose.foundation.border
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tomerikheggedal.vitola.ui.theme.Accent

// ÉN samkjørt scoring-badge for hele appen (speiler iOS ScoreBadge):
// firkantet med 2px radius, KUN outline i Accent-farge + hvit/lys tekst,
// ingen fyllfarge. Brukes overalt en poengsum vises, så de aldri ser
// forskjellige ut igjen.
@Composable
fun ScoreBadge(text: String, modifier: Modifier = Modifier, fontSize: TextUnit = 14.sp) {
    Text(
        text,
        fontSize = fontSize,
        fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.onBackground,
        modifier = modifier
            .clip(RoundedCornerShape(2.dp))
            .border(1.2.dp, Accent, RoundedCornerShape(2.dp))
            .padding(horizontal = 10.dp, vertical = 5.dp)
    )
}
