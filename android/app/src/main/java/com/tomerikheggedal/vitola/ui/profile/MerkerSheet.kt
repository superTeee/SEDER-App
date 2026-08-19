package com.tomerikheggedal.vitola.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Spa
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.outlined.AddCircle
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.EmojiEvents
import androidx.compose.material.icons.outlined.Groups
import androidx.compose.material.icons.outlined.Inventory2
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.ThumbUp
import androidx.compose.material.icons.outlined.WorkspacePremium
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tomerikheggedal.vitola.data.FriendProfile
import com.tomerikheggedal.vitola.data.MemberLevel
import com.tomerikheggedal.vitola.data.SecondaryBadge
import com.tomerikheggedal.vitola.data.memberStats
import com.tomerikheggedal.vitola.data.secondaryBadges

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MerkerSheet(profile: FriendProfile, onDismiss: () -> Unit) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val stats = remember(profile) { profile.memberStats() }
    val current = remember(stats) { MemberLevel.current(stats) }
    val badges = remember(profile) { secondaryBadges(profile, stats) }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.background) {
        Column(
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(bottom = 28.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            Text("Merker", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(start = 20.dp, top = 4.dp))

            // Ansiennitet
            Column(Modifier.padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                SectionLabelM("ANSIENNITET")
                MemberLevel.values().forEach { level ->
                    LevelRow(level, earned = level.ordinal <= current.ordinal, isCurrent = level == current)
                }
            }

            // Opptjente merker
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                SectionLabelM("OPPTJENTE MERKER", Modifier.padding(horizontal = 16.dp))
                LazyRow(
                    contentPadding = PaddingValues(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(badges) { SecondaryCard(it) }
                }
            }
        }
    }
}

@Composable
private fun SectionLabelM(text: String, modifier: Modifier = Modifier) {
    Text(text, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.onSurfaceVariant, letterSpacing = 0.6.sp, modifier = modifier)
}

private fun levelIcon(level: MemberLevel): ImageVector = when (level) {
    MemberLevel.SIGARENTUSIAST -> Icons.Outlined.Spa
    MemberLevel.KJENNER -> Icons.Outlined.Star
    MemberLevel.SAMLER -> Icons.Outlined.Inventory2
    MemberLevel.KURATOR -> Icons.Outlined.WorkspacePremium
    MemberLevel.SIGARAFICIONADO -> Icons.Outlined.EmojiEvents
}

private fun badgeIcon(key: String): ImageVector = when (key) {
    "seal" -> Icons.Outlined.WorkspacePremium
    "pencil" -> Icons.Outlined.Edit
    "thumb" -> Icons.Outlined.ThumbUp
    "add" -> Icons.Outlined.AddCircle
    "people" -> Icons.Outlined.Groups
    else -> Icons.Outlined.Star
}

@Composable
private fun LevelRow(level: MemberLevel, earned: Boolean, isCurrent: Boolean) {
    val accent = MaterialTheme.colorScheme.primary
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp))
            .background(MaterialTheme.colorScheme.surface)
            .then(if (isCurrent) Modifier.border(1.5.dp, accent, RoundedCornerShape(12.dp)) else Modifier)
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            Modifier.size(42.dp).clip(CircleShape)
                .background(accent.copy(alpha = if (earned) 0.14f else 0.06f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(levelIcon(level), null, modifier = Modifier.size(18.dp),
                tint = if (earned) accent else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f))
        }
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(level.title, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.SemiBold,
                color = if (earned) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant)
            Text(level.criteria, style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Spacer(Modifier.width(8.dp))
        if (earned) {
            Text("Samlet", style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.SemiBold,
                color = accent,
                modifier = Modifier.clip(RoundedCornerShape(50)).background(accent.copy(alpha = 0.12f))
                    .padding(horizontal = 9.dp, vertical = 3.dp))
        } else {
            Icon(Icons.Filled.Lock, null, modifier = Modifier.size(14.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f))
        }
    }
}

@Composable
private fun SecondaryCard(b: SecondaryBadge) {
    val accent = MaterialTheme.colorScheme.primary
    Column(
        Modifier.width(128.dp).clip(RoundedCornerShape(12.dp))
            .background(MaterialTheme.colorScheme.surface).padding(vertical = 14.dp, horizontal = 10.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Icon(badgeIcon(b.iconKey), null, modifier = Modifier.size(24.dp),
            tint = if (b.earned) accent else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f))
        Text(b.title, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.Center)
        Text(b.subtitle, style = MaterialTheme.typography.bodySmall, textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
        if (b.earned) {
            Text("Samlet", style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.SemiBold,
                color = accent,
                modifier = Modifier.clip(RoundedCornerShape(50)).background(accent.copy(alpha = 0.12f))
                    .padding(horizontal = 8.dp, vertical = 2.dp))
        } else {
            Icon(Icons.Filled.Lock, null, modifier = Modifier.size(12.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f))
        }
    }
}
