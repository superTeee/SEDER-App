package com.tomerikheggedal.vitola.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddAPhoto
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.DeleteOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage

// ÉN samkjørt «endre bilde»-flate for hele appen (speiler iOS EditPhotoPill +
// UploadPhotoPlaceholder): stort kvadratisk bilde med «Endre»-pille øverst til
// høyre, en «Fjern bilde»-knapp under, og en outline-placeholder når det ikke
// finnes noe bilde. Brukeren kjenner igjen det samme mønsteret overalt.
@Composable
fun EditablePhoto(
    model: Any?,
    onPick: () -> Unit,
    onRemove: () -> Unit,
    modifier: Modifier = Modifier.fillMaxWidth(),
) {
    val shape = RoundedCornerShape(12.dp)
    if (model != null) {
        Box(modifier.aspectRatio(1f).clip(shape).clickable(onClick = onPick)) {
            AsyncImage(
                model = model, contentDescription = null, contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize()
            )
            // «Endre»-pille øverst til høyre.
            Row(
                Modifier.align(Alignment.TopEnd).padding(10.dp)
                    .clip(CircleShape).background(Color.Black.copy(alpha = 0.55f))
                    .clickable(onClick = onPick)
                    .padding(horizontal = 12.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(Icons.Filled.CameraAlt, null, tint = Color.White, modifier = Modifier.size(14.dp))
                Spacer(Modifier.width(5.dp))
                Text("Endre", color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Medium)
            }
        }
        Spacer(Modifier.height(8.dp))
        TextButton(onClick = onRemove, modifier = Modifier.fillMaxWidth()) {
            Icon(Icons.Filled.DeleteOutline, null, tint = MaterialTheme.colorScheme.error,
                modifier = Modifier.size(16.dp))
            Spacer(Modifier.width(6.dp))
            Text("Fjern bilde", color = MaterialTheme.colorScheme.error)
        }
    } else {
        Box(
            modifier.aspectRatio(1f).clip(shape)
                .border(1.2.dp, MaterialTheme.colorScheme.primary, shape)
                .clickable(onClick = onPick),
            contentAlignment = Alignment.Center
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Icon(Icons.Filled.AddAPhoto, null, tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(28.dp))
                Spacer(Modifier.height(6.dp))
                Text("Legg til bilde", color = MaterialTheme.colorScheme.onBackground, fontSize = 14.sp)
            }
        }
    }
}
