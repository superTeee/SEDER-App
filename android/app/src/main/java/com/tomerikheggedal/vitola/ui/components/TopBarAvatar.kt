package com.tomerikheggedal.vitola.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.tomerikheggedal.vitola.data.ProfileRepository

// Profil-avatar øverst til venstre (erstatter Profil-fanen, som iOS). Henter
// egen profil én gang og viser bildet, ellers et person-ikon.
@Composable
fun TopBarProfileAvatar(onClick: () -> Unit) {
    var url by remember { mutableStateOf<String?>(null) }
    LaunchedEffect(Unit) {
        url = runCatching { ProfileRepository.myProfile()?.avatarUrl }.getOrNull()
    }
    Box(
        Modifier.padding(start = 6.dp).size(34.dp).clip(CircleShape).clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        val u = url
        if (u != null) {
            AsyncImage(
                model = u, contentDescription = "Profil", contentScale = ContentScale.Crop,
                modifier = Modifier.size(34.dp).clip(CircleShape)
            )
        } else {
            Box(
                Modifier.size(34.dp).clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Filled.Person, null, tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(20.dp))
            }
        }
    }
}
