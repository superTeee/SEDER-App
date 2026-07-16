package com.tomerikheggedal.vitola.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// Gruppe-kort likt iOS: hvit (surface) bakgrunn, 6dp avrundet, 16dp sidemarg.
// Radene legges inni som children med innrykkede skillelinjer mellom seg.
@Composable
fun ListCard(
    modifier: Modifier = Modifier,
    content: @Composable ColumnScopeRows.() -> Unit,
) {
    Column(
        modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .clip(RoundedCornerShape(6.dp))
            .background(MaterialTheme.colorScheme.surface)
    ) {
        ColumnScopeRows.content()
    }
}

// Marker-objekt så vi kan bruke RowDivider bevisst mellom rader.
object ColumnScopeRows

// Innrykket skillelinje (matcher iOS Divider().padding(.leading, 16)).
@Composable
fun ColumnScopeRows.RowDivider() {
    HorizontalDivider(
        modifier = Modifier.padding(start = 16.dp),
        color = MaterialTheme.colorScheme.surfaceVariant
    )
}

// Standard navigasjonsrad: tittel + valgfri undertittel/detalj + chevron.
@Composable
fun ColumnScopeRows.NavRow(
    title: String,
    subtitle: String? = null,
    detail: String? = null,
    titleBold: Boolean = false,
    onClick: () -> Unit,
) {
    Row(
        Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                title,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Medium,
                letterSpacing = 0.sp,
                color = MaterialTheme.colorScheme.onSurface
            )
            if (subtitle != null && subtitle.isNotBlank()) {
                Text(subtitle, style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (detail != null && detail.isNotBlank()) {
                Text(detail, style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.primary)
            }
        }
        Icon(
            Icons.AutoMirrored.Filled.KeyboardArrowRight,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f),
            modifier = Modifier.size(20.dp)
        )
    }
}

// Fritt innhold i en rad (når NavRow ikke passer).
@Composable
fun ColumnScopeRows.CardRow(
    onClick: (() -> Unit)? = null,
    content: @Composable RowScope.() -> Unit,
) {
    Row(
        Modifier
            .fillMaxWidth()
            .let { if (onClick != null) it.clickable(onClick = onClick) else it }
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        content = content
    )
}

// Liten seksjonsoverskrift (footnote bold, uppercased) — matcher iOS.
@Composable
fun SectionLabel(text: String, topPadding: Int = 18) {
    Text(
        text.uppercase(),
        style = MaterialTheme.typography.labelMedium,
        fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = topPadding.dp, bottom = 6.dp)
    )
}
