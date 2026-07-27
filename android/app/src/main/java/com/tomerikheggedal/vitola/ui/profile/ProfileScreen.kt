package com.tomerikheggedal.vitola.ui.profile

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddPhotoAlternate
import androidx.compose.material.icons.filled.Air
import androidx.compose.material.icons.filled.Eco
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.Layers
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.LocalOffer
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Spa
import androidx.compose.material.icons.filled.Straighten
import androidx.compose.material.icons.outlined.Group
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.WorkspacePremium
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.tomerikheggedal.vitola.data.JournalRepository
import com.tomerikheggedal.vitola.data.Profile
import com.tomerikheggedal.vitola.data.memberStats
import com.tomerikheggedal.vitola.data.FavoriteRepository
import com.tomerikheggedal.vitola.data.ProfileFavorites
import com.tomerikheggedal.vitola.data.ProfileRepository
import com.tomerikheggedal.vitola.data.ProfileStats
import com.tomerikheggedal.vitola.data.Supa
import com.tomerikheggedal.vitola.data.TastingLog
import io.github.jan.supabase.gotrue.SessionStatus
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.gotrue.providers.Google
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.Instant
import java.time.OffsetDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

private val NO = Locale("nb", "NO")
private val LOG_FMT = DateTimeFormatter.ofPattern("d. MMMM yyyy, HH:mm", NO)

private fun strengthLabel(s: Double?): String? = s?.let {
    when { it < 2.0 -> "Mild"; it < 3.0 -> "Medium"; it < 4.0 -> "Fyldig"; else -> "Sterk" }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(onSettings: () -> Unit = {}, onFriends: () -> Unit = {}, onFavorites: () -> Unit = {}) {
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val status by Supa.client.auth.sessionStatus.collectAsState()
    val isAuthed = status is SessionStatus.Authenticated

    var profile by remember { mutableStateOf<Profile?>(null) }
    var stats by remember { mutableStateOf(ProfileStats(0, 0, 0, 0)) }
    var favorites by remember { mutableStateOf<ProfileFavorites?>(null) }
    var myFavorites by remember { mutableStateOf<List<com.tomerikheggedal.vitola.data.FavoriteListItem>>(emptyList()) }
    var lastLog by remember { mutableStateOf<TastingLog?>(null) }
    var loading by remember { mutableStateOf(false) }
    var reloadKey by remember { mutableStateOf(0) }
    var uploadingAvatar by remember { mutableStateOf(false) }
    var uploadingCover by remember { mutableStateOf(false) }
    var showBioEditor by remember { mutableStateOf(false) }
    var selfProfile by remember { mutableStateOf<com.tomerikheggedal.vitola.data.FriendProfile?>(null) }
    var showMerker by remember { mutableStateOf(false) }

    val pickAvatar = com.tomerikheggedal.vitola.ui.rememberCropPicker(1, 1) { uri ->
        uploadingAvatar = true
        scope.launch {
            runCatching {
                val jpeg = withContext(Dispatchers.IO) { compressImage(context, uri, 800) }
                if (jpeg != null) ProfileRepository.uploadAvatar(jpeg)
            }
            uploadingAvatar = false
            reloadKey++
        }
    }
    val pickCover = com.tomerikheggedal.vitola.ui.rememberCropPicker(16, 9) { uri ->
        uploadingCover = true
        scope.launch {
            runCatching {
                val jpeg = withContext(Dispatchers.IO) { compressImage(context, uri, 1400) }
                if (jpeg != null) ProfileRepository.uploadCover(jpeg)
            }
            uploadingCover = false
            reloadKey++
        }
    }

    LaunchedEffect(isAuthed, reloadKey, ProfileRefresh.version) {
        if (isAuthed) {
            loading = true
            profile = runCatching { ProfileRepository.myProfile() }.getOrNull()
            stats = runCatching { ProfileRepository.myStats() }.getOrDefault(ProfileStats(0, 0, 0, 0))
            favorites = runCatching { ProfileRepository.myFavorites() }.getOrNull()
            val myUid = Supa.client.auth.currentUserOrNull()?.id
            myFavorites = if (myUid != null)
                runCatching { FavoriteRepository.favoriteList(myUid) }.getOrDefault(emptyList())
            else emptyList()
            lastLog = runCatching { JournalRepository.lastLog() }.getOrNull()
            selfProfile = if (myUid != null)
                runCatching { com.tomerikheggedal.vitola.data.FriendRepository.profile(myUid) }.getOrNull()
            else null
            loading = false
        } else {
            profile = null; stats = ProfileStats(0, 0, 0, 0); favorites = null; myFavorites = emptyList(); lastLog = null
        }
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Profil", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                ),
                actions = {
                    IconButton(onClick = onFriends) {
                        Icon(Icons.Filled.Group, contentDescription = "Venner")
                    }
                    IconButton(onClick = onSettings) {
                        Icon(Icons.Filled.Settings, contentDescription = "Innstillinger")
                    }
                }
            )
        }
    ) { padding ->
        Box(Modifier.padding(padding).fillMaxSize()) {
            when {
                !isAuthed -> LoginPrompt { scope.launch { Supa.client.auth.signInWith(Google) } }
                loading -> CircularProgressIndicator(Modifier.align(Alignment.Center))
                else -> Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
                    // Cover + overlappende avatar (som iOS)
                    Box(Modifier.fillMaxWidth()) {
                        CoverBanner(
                            url = profile?.coverUrl,
                            uploading = uploadingCover,
                            onClick = pickCover
                        )
                        Box(
                            Modifier.align(Alignment.BottomCenter).offset(y = 44.dp)
                                .clip(CircleShape).background(MaterialTheme.colorScheme.background).padding(3.dp)
                        ) {
                            Avatar(
                                url = profile?.avatarUrl ?: ProfileRepository.authAvatar(),
                                uploading = uploadingAvatar,
                                onClick = pickAvatar
                            )
                        }
                    }
                    Spacer(Modifier.height(52.dp))

                    Column(Modifier.fillMaxWidth().padding(horizontal = 20.dp),
                        horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            profile?.displayName ?: ProfileRepository.authName() ?: "SEDER-bruker",
                            style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold,
                            fontSize = 20.sp
                        )
                        Spacer(Modifier.height(6.dp))
                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                            verticalAlignment = Alignment.CenterVertically) {
                            selfProfile?.let { sp ->
                                val level = com.tomerikheggedal.vitola.data.MemberLevel.current(sp.memberStats())
                                Text(level.title, style = MaterialTheme.typography.labelMedium,
                                    fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.clip(RoundedCornerShape(50))
                                        .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f))
                                        .clickable { showMerker = true }
                                        .padding(horizontal = 10.dp, vertical = 4.dp))
                            }
                            if (profile?.isFoundingMember == true) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(5.dp),
                                    modifier = Modifier.clip(RoundedCornerShape(50))
                                        .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f))
                                        .padding(horizontal = 10.dp, vertical = 4.dp)
                                ) {
                                    Icon(Icons.Outlined.WorkspacePremium, null,
                                        tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(14.dp))
                                    Text("Tidlig tester", style = MaterialTheme.typography.labelMedium,
                                        fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.primary)
                                }
                            }
                        }
                        val place = listOfNotNull(profile?.city, profile?.country).joinToString(", ")
                        if (place.isNotBlank()) {
                            Spacer(Modifier.height(2.dp))
                            Text(place, style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        Spacer(Modifier.height(10.dp))
                        val bio = profile?.bio
                        Text(
                            if (bio.isNullOrBlank()) "Legg til bio…" else bio,
                            style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center,
                            color = if (bio.isNullOrBlank()) MaterialTheme.colorScheme.primary
                                    else MaterialTheme.colorScheme.onSurface,
                            modifier = Modifier.clip(RoundedCornerShape(6.dp)).clickable { showBioEditor = true }
                                .padding(horizontal = 8.dp, vertical = 4.dp)
                        )
                    }

                    // Stats
                    Box(Modifier.padding(horizontal = 16.dp)) { StatsCard(stats, myFavorites.size, onFriends, onFavorites) }

                    // Sist røkt
                    lastLog?.let { log ->
                        SectionLabel("Sist røkt")
                        LastSmokedCard(log)
                    }

                    // Favoritter
                    if (myFavorites.isNotEmpty()) {
                        SectionLabel("Favoritter")
                        FavoritesList(myFavorites)
                    }

                    // Smaksprofil
                    SectionLabel("Smaksprofil")
                    HeroFavoriteCard(favorites)
                    Spacer(Modifier.height(10.dp))
                    FavoritesGrid(favorites)

                    Spacer(Modifier.height(32.dp))
                }
            }
        }
    }

    if (showBioEditor) {
        BioEditorDialog(
            current = profile?.bio ?: "",
            onDismiss = { showBioEditor = false },
            onSave = { newBio ->
                showBioEditor = false
                scope.launch { runCatching { ProfileRepository.saveBio(newBio) }; reloadKey++ }
            }
        )
    }

    if (showMerker) {
        selfProfile?.let { MerkerSheet(it) { showMerker = false } }
    }
}

@Composable
private fun SectionLabel(text: String) {
    Text(text.uppercase(), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.onSurfaceVariant, letterSpacing = 0.sp,
        modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 22.dp, bottom = 10.dp))
}

@Composable
private fun CoverBanner(url: String?, uploading: Boolean, onClick: () -> Unit) {
    Box(
        Modifier.fillMaxWidth().height(140.dp).clickable(onClick = onClick)
            .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.10f))
    ) {
        if (url != null) {
            AsyncImage(model = url, contentDescription = null, contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize())
        } else {
            Row(Modifier.align(Alignment.Center), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.AddPhotoAlternate, null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(Modifier.width(6.dp))
                Text("Legg til toppbilde", style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        if (uploading) {
            Box(Modifier.matchParentSize().background(androidx.compose.ui.graphics.Color.Black.copy(alpha = 0.4f)),
                contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = androidx.compose.ui.graphics.Color.White)
            }
        }
    }
}

@Composable
private fun Avatar(url: String?, uploading: Boolean, onClick: () -> Unit) {
    val size = 96.dp
    Box(contentAlignment = Alignment.Center) {
        if (url != null) {
            AsyncImage(model = url, contentDescription = null, contentScale = ContentScale.Crop,
                modifier = Modifier.size(size).clip(CircleShape).clickable(onClick = onClick))
        } else {
            Box(Modifier.size(size).clip(CircleShape).clickable(onClick = onClick)
                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)),
                contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.Person, null, tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(46.dp))
            }
        }
        if (uploading) CircularProgressIndicator(Modifier.size(28.dp), strokeWidth = 3.dp)
    }
}

// 4-cellers stats-kort med ikoner og skillelinjer — som iOS.
@Composable
private fun StatsCard(stats: ProfileStats, favoritesCount: Int, onFriends: () -> Unit, onFavorites: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp))
            .background(MaterialTheme.colorScheme.surface).padding(vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        StatCell(Icons.Filled.Inventory2, stats.humidorEntries, "I humidor", Modifier.weight(1f))
        StatDivider()
        StatCell(Icons.Filled.LocalFireDepartment, stats.cigars, "Røkt", Modifier.weight(1f))
        StatDivider()
        StatCell(Icons.Outlined.Star, favoritesCount, "Favoritter",
            Modifier.weight(1f).clip(RoundedCornerShape(6.dp)).clickable(onClick = onFavorites))
        StatDivider()
        StatCell(Icons.Outlined.Group, stats.friends, "Venner",
            Modifier.weight(1f).clip(RoundedCornerShape(6.dp)).clickable(onClick = onFriends))
    }
}

// Favorittliste-seksjon (navn + vitola). Vises på egen profil og venners.
@Composable
private fun FavoritesList(items: List<com.tomerikheggedal.vitola.data.FavoriteListItem>) {
    Column(Modifier.padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        items.forEach { fav ->
            Row(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(6.dp))
                    .background(MaterialTheme.colorScheme.surface).padding(horizontal = 14.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(Icons.Filled.Star, null, tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text(fav.brand, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold,
                        maxLines = 1)
                    val sub = listOfNotNull(fav.series, fav.vitola).joinToString(" · ")
                    if (sub.isNotBlank()) {
                        Text(sub, style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1)
                    }
                }
            }
        }
    }
}

@Composable
private fun StatDivider() {
    Box(Modifier.width(1.dp).height(40.dp).background(MaterialTheme.colorScheme.surfaceVariant))
}

@Composable
private fun StatCell(icon: ImageVector, value: Int, label: String, modifier: Modifier = Modifier) {
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Icon(icon, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(20.dp))
        Text("$value", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        Text(label, style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
    }
}

// ── Smaksprofil ──
@Composable
private fun HeroFavoriteCard(fav: ProfileFavorites?) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp).clip(RoundedCornerShape(8.dp))
            .background(MaterialTheme.colorScheme.surface).padding(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(Modifier.size(42.dp).clip(RoundedCornerShape(6.dp))
            .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)), contentAlignment = Alignment.Center) {
            Icon(Icons.Filled.EmojiEvents, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(22.dp))
        }
        Spacer(Modifier.width(13.dp))
        Column(Modifier.weight(1f)) {
            Text("Favorittsigar", style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(fav?.favoriteCigar?.takeIf { it.isNotBlank() } ?: "Kommer når du logger",
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = if (fav?.favoriteCigar.isNullOrBlank()) FontWeight.Normal else FontWeight.SemiBold,
                color = if (fav?.favoriteCigar.isNullOrBlank()) MaterialTheme.colorScheme.onSurfaceVariant
                        else MaterialTheme.colorScheme.onSurface, maxLines = 1)
        }
        fav?.favoriteCigarScore?.let { score ->
            Text("$score", style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onPrimary,
                modifier = Modifier.clip(RoundedCornerShape(6.dp)).background(MaterialTheme.colorScheme.primary)
                    .padding(horizontal = 10.dp, vertical = 3.dp))
        }
    }
}

@Composable
private fun FavoritesGrid(fav: ProfileFavorites?) {
    val items = listOf(
        Triple(Icons.Filled.LocalOffer, "Merke", fav?.favoriteBrand),
        Triple(Icons.Filled.Straighten, "Vitola", fav?.favoriteVitola),
        Triple(Icons.Filled.Public, "Land", fav?.favoriteCountry),
        Triple(Icons.Filled.Spa, "Dekkblad", fav?.favoriteWrapper),
        Triple(Icons.Filled.Eco, "Omblad", fav?.favoriteBinder),
        Triple(Icons.Filled.Layers, "Innmat", fav?.favoriteFiller),
        Triple(Icons.Filled.LocalFireDepartment, "Styrke", strengthLabel(fav?.favoriteStrength)),
        Triple(Icons.Filled.Air, "Smaksnoter", fav?.favoriteFlavor),
    )
    Column(Modifier.padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        items.chunked(2).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                row.forEach { (icon, label, value) ->
                    FavoriteCell(icon, label, value, Modifier.weight(1f))
                }
                if (row.size == 1) Spacer(Modifier.weight(1f))
            }
        }
    }
}

@Composable
private fun FavoriteCell(icon: ImageVector, label: String, value: String?, modifier: Modifier = Modifier) {
    Column(modifier.clip(RoundedCornerShape(6.dp)).background(MaterialTheme.colorScheme.surface).padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(5.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Icon(icon, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(14.dp))
            Text(label, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Text(value?.takeIf { it.isNotBlank() } ?: "Kommer når du logger",
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = if (value.isNullOrBlank()) FontWeight.Normal else FontWeight.SemiBold,
            color = if (value.isNullOrBlank()) MaterialTheme.colorScheme.onSurfaceVariant
                    else MaterialTheme.colorScheme.onSurface, maxLines = 1)
    }
}

// ── Sist røkt ──
@Composable
private fun LastSmokedCard(log: TastingLog) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp).clip(RoundedCornerShape(6.dp))
            .background(MaterialTheme.colorScheme.surface).padding(14.dp),
        verticalAlignment = Alignment.Top
    ) {
        val photo = log.photoUrl
        if (photo != null) {
            AsyncImage(model = photo, contentDescription = null, contentScale = ContentScale.Crop,
                modifier = Modifier.size(68.dp).clip(RoundedCornerShape(8.dp)))
        } else {
            Box(Modifier.size(68.dp).clip(RoundedCornerShape(8.dp))
                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)), contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.LocalFireDepartment, null, tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(28.dp))
            }
        }
        Spacer(Modifier.width(14.dp))
        Column(Modifier.weight(1f)) {
            val c = log.cigar
            Text(c?.brand ?: "Ukjent sigar", style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.SemiBold, maxLines = 1)
            c?.series?.let { Text(it, style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1) }
            val time = runCatching { OffsetDateTime.parse(log.smokedAt).toInstant() }
                .recoverCatching { Instant.parse(log.smokedAt) }.getOrNull()
                ?.atZone(ZoneId.systemDefault())?.format(LOG_FMT)
            if (time != null) {
                Spacer(Modifier.height(2.dp))
                Text(time, style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        log.rating?.let { r ->
            Spacer(Modifier.width(8.dp))
            Text("$r", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimary,
                modifier = Modifier.clip(RoundedCornerShape(6.dp)).background(MaterialTheme.colorScheme.primary)
                    .padding(horizontal = 10.dp, vertical = 6.dp))
        }
    }
}

@Composable
private fun BioEditorDialog(current: String, onDismiss: () -> Unit, onSave: (String) -> Unit) {
    var text by remember { mutableStateOf(current) }
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = { TextButton(onClick = { onSave(text) }) { Text("Lagre") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Avbryt") } },
        title = { Text("Bio", fontWeight = FontWeight.Bold) },
        text = {
            OutlinedTextField(value = text, onValueChange = { text = it },
                placeholder = { Text("Skriv litt om deg selv…") },
                modifier = Modifier.fillMaxWidth(), minLines = 3)
        }
    )
}

@Composable
private fun LoginPrompt(onLogin: () -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("Logg inn for å se profilen din.", textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(Modifier.height(16.dp))
        Button(onClick = onLogin) { Text("Logg inn med Google") }
    }
}

// Skalerer til maks maxDim og komprimerer til JPEG.
private fun compressImage(context: android.content.Context, uri: android.net.Uri, maxDim: Int): ByteArray? {
    val bitmap = context.contentResolver.openInputStream(uri)?.use {
        android.graphics.BitmapFactory.decodeStream(it)
    } ?: return null
    val longest = maxOf(bitmap.width, bitmap.height)
    val scaled = if (longest > maxDim) {
        val ratio = maxDim.toFloat() / longest
        android.graphics.Bitmap.createScaledBitmap(
            bitmap, (bitmap.width * ratio).toInt().coerceAtLeast(1),
            (bitmap.height * ratio).toInt().coerceAtLeast(1), true)
    } else bitmap
    val out = java.io.ByteArrayOutputStream()
    scaled.compress(android.graphics.Bitmap.CompressFormat.JPEG, 85, out)
    return out.toByteArray()
}
