package com.tomerikheggedal.vitola.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// ÉN samkjørt scoring-badge for hele appen (speiler iOS ScoreBadge):
// firkantet med 2px radius og lys latte bakgrunn. Brukes overalt en poengsum
// vises, så de aldri ser forskjellige ut igjen.
val ScoreBadgeLatte = Color(0xFFEADFC9)
val ScoreBadgeInk = Color(0xFF5C4A2C)

@Composable
fun ScoreBadge(text: String, modifier: Modifier = Modifier, fontSize: TextUnit = 14.sp) {
    Text(
        text,
        fontSize = fontSize,
        fontWeight = FontWeight.SemiBold,
        color = ScoreBadgeInk,
        modifier = modifier
            .clip(RoundedCornerShape(2.dp))
            .background(ScoreBadgeLatte)
            .padding(horizontal = 10.dp, vertical = 5.dp)
    )
}
