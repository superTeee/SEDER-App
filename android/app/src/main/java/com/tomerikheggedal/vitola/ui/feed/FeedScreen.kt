package com.tomerikheggedal.vitola.ui.feed

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.tomerikheggedal.vitola.data.FeedPost
import com.tomerikheggedal.vitola.data.FeedRepository
import com.tomerikheggedal.vitola.data.Supa
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
private val DATE_FMT = DateTimeFormatter.ofPattern("d. MMM", NO)

private fun relativeTime(iso: String): String {
    val instant = runCatching { OffsetDateTime.parse(iso).toInstant() }
        .recoverCatching { Instant.parse(iso) }.getOrNull() ?: return ""
    val diff = (Instant.now().epochSecond - instant.epochSecond).coerceAtLeast(0)
    return when {
        diff < 60 -> "Nå"
        diff < 3600 -> "${diff / 60} min"
        diff < 86400 -> "${diff / 3600} t"
        diff < 604800 -> "${diff / 86400} d"
        else -> instant.atZone(ZoneId.systemDefault()).format(DATE_FMT)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FeedScreen(onUser: (String) -> Unit = {}) {
    val scope = rememberCoroutineScope()
    val status by Supa.client.auth.sessionStatus.collectAsState()
    val isAuthed = status is SessionStatus.Authenticated

    val context = LocalContext.current
    var posts by remember { mutableStateOf<List<FeedPost>>(emptyList()) }
    var loading by remember { mutableStateOf(false) }
    var openPost by remember { mutableStateOf<FeedPost?>(null) }
    var showNewPost by remember { mutableStateOf(false) }

    suspend fun reload() {
        posts = runCatching { FeedRepository.feed() }.getOrDefault(emptyList())
    }

    LaunchedEffect(isAuthed) {
        if (isAuthed) { loading = true; reload(); loading = false } else posts = emptyList()
    }

    // Detaljvisning erstatter lista når et innlegg er åpnet (som iOS PostDetailView).
    val detailPost = openPost
    if (detailPost != null) {
        PostDetailScreen(
            post = detailPost,
            onBack = { openPost = null; scope.launch { reload() } },
            onShare = { sharePost(context, detailPost) },
            onUser = onUser
        )
        return
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Feed", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                ),
                actions = {
                    if (isAuthed) {
                        IconButton(onClick = { showNewPost = true }) {
                            Icon(Icons.Filled.Add, contentDescription = "Nytt innlegg")
                        }
                    }
                }
            )
        }
    ) { padding ->
        Box(Modifier.padding(padding).fillMaxSize()) {
            when {
                !isAuthed -> LoginPrompt { scope.launch { Supa.client.auth.signInWith(Google) } }
                loading -> CircularProgressIndicator(Modifier.align(Alignment.Center))
                posts.isEmpty() -> Text(
                    "Ingen innlegg ennå.",
                    textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.align(Alignment.Center).padding(32.dp)
                )
                else -> LazyColumn(
                    Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(posts, key = { it.id }) { post ->
                        PostCard(
                            post = post,
                            onComments = { openPost = post },
                            onShare = { sharePost(context, post) },
                            onOpen = { openPost = post },
                            onAuthor = { onUser(post.userId) }
                        )
                    }
                }
            }
        }
    }

    if (showNewPost) {
        NewPostSheet(
            onDismiss = { showNewPost = false },
            onPosted = { showNewPost = false; scope.launch { reload() } }
        )
    }
}

// Del et innlegg via Androids delingsark.
private fun sharePost(context: android.content.Context, post: FeedPost) {
    val body = buildString {
        append(post.authorName).append(" på Vitola")
        post.content?.takeIf { it.isNotBlank() }?.let { append(":\n").append(it) }
        post.cigarDisplayName?.let { append("\n🚬 ").append(it) }
        append("\n\nhttps://vitola.app")
    }
    val intent = android.content.Intent(android.content.Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(android.content.Intent.EXTRA_TEXT, body)
    }
    runCatching { context.startActivity(android.content.Intent.createChooser(intent, "Del innlegg")) }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun NewPostSheet(onDismiss: () -> Unit, onPosted: () -> Unit) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    var text by remember { mutableStateOf("") }
    var imageUri by remember { mutableStateOf<android.net.Uri?>(null) }
    var posting by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    val picker = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri != null) imageUri = uri
    }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface) {
        Column(Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(bottom = 28.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Text("Nytt innlegg", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            OutlinedTextField(
                value = text, onValueChange = { text = it },
                placeholder = { Text("Hva røyker du? Del tanker, smaksnotater…") },
                modifier = Modifier.fillMaxWidth(), minLines = 4
            )

            // Valgt bilde med fjern-kryss.
            imageUri?.let { uri ->
                Box(Modifier.fillMaxWidth()) {
                    AsyncImage(model = uri, contentDescription = null, contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxWidth().height(180.dp).clip(RoundedCornerShape(8.dp)))
                    IconButton(onClick = { imageUri = null },
                        modifier = Modifier.align(Alignment.TopEnd)) {
                        Icon(Icons.Filled.Close, "Fjern bilde", tint = androidx.compose.ui.graphics.Color.White)
                    }
                }
            }

            TextButton(
                onClick = { picker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)) },
                contentPadding = PaddingValues(0.dp)
            ) {
                Icon(Icons.Filled.CameraAlt, null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(6.dp))
                Text(if (imageUri == null) "Legg til bilde" else "Bytt bilde")
            }

            error?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyMedium) }
            Button(
                onClick = {
                    if (posting || (text.isBlank() && imageUri == null)) return@Button
                    posting = true; error = null
                    scope.launch {
                        try {
                            val jpeg = imageUri?.let { withContext(Dispatchers.IO) { compressImage(context, it) } }
                            FeedRepository.createPost(text, jpeg)
                            onPosted()
                        } catch (e: Exception) { error = e.message ?: "Kunne ikke publisere"; posting = false }
                    }
                },
                enabled = !posting && (text.isNotBlank() || imageUri != null),
                modifier = Modifier.fillMaxWidth()
            ) {
                if (posting) CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp,
                    color = MaterialTheme.colorScheme.onPrimary)
                else Text("Publiser", fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

// Skalerer til maks 1200px bredde og komprimerer til JPEG (som iOS).
private fun compressImage(context: android.content.Context, uri: android.net.Uri, maxWidth: Int = 1200): ByteArray? {
    val bitmap = context.contentResolver.openInputStream(uri)?.use {
        android.graphics.BitmapFactory.decodeStream(it)
    } ?: return null
    val scaled = if (bitmap.width > maxWidth) {
        val h = (bitmap.height.toLong() * maxWidth / bitmap.width).toInt().coerceAtLeast(1)
        android.graphics.Bitmap.createScaledBitmap(bitmap, maxWidth, h, true)
    } else bitmap
    val out = java.io.ByteArrayOutputStream()
    scaled.compress(android.graphics.Bitmap.CompressFormat.JPEG, 85, out)
    return out.toByteArray()
}

@Composable
private fun PostCard(
    post: FeedPost,
    onComments: () -> Unit,
    onShare: () -> Unit,
    onOpen: (() -> Unit)? = null,
    onAuthor: (() -> Unit)? = null,
) {
    val scope = rememberCoroutineScope()
    // Lokalt optimistisk like-state.
    var liked by remember(post.id) { mutableStateOf(post.likedByMe) }
    var likeCount by remember(post.id) { mutableStateOf(post.likeCount) }

    Column(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp)
            .clip(RoundedCornerShape(8.dp)).background(MaterialTheme.colorScheme.surface)
            .let { if (onOpen != null) it.clickable(onClick = onOpen) else it }
            .padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        // Forfatter (klikkbar → begrenset profil)
        Row(
            Modifier.let { if (onAuthor != null) it.clip(RoundedCornerShape(8.dp)).clickable(onClick = onAuthor) else it },
            verticalAlignment = Alignment.CenterVertically
        ) {
            AuthorAvatar(post.authorAvatarUrl, 36.dp)
            Spacer(Modifier.width(10.dp))
            Column(Modifier.weight(1f)) {
                Text(post.authorName, fontWeight = FontWeight.SemiBold,
                    style = MaterialTheme.typography.bodyLarge)
                Text(relativeTime(post.createdAt), style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }

        post.content?.takeIf { it.isNotBlank() }?.let {
            Text(it, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurface)
        }

        // Bilde (innlegg eller tasting-foto)
        (post.imageUrl ?: post.tastingPhotoUrl)?.let { url ->
            AsyncImage(model = url, contentDescription = null, contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxWidth().height(200.dp).clip(RoundedCornerShape(6.dp)))
        }

        // Sigar-kobling
        post.cigarDisplayName?.let { name ->
            Row(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(6.dp))
                    .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f))
                    .padding(10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(name, Modifier.weight(1f), style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium)
                post.cigarRating?.let { r ->
                    Text(
                        "$r" + (post.cigarScoreLabel?.let { " · $it" } ?: ""),
                        style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.clip(RoundedCornerShape(6.dp))
                            .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f))
                            .padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
            }
        }

        // Likes + kommentarer
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(18.dp)) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.clip(RoundedCornerShape(6.dp)).clickable {
                    val wasLiked = liked
                    liked = !wasLiked
                    likeCount += if (wasLiked) -1 else 1
                    scope.launch { runCatching { FeedRepository.toggleLike(post.id) } }
                }.padding(4.dp)
            ) {
                Icon(
                    if (liked) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder,
                    contentDescription = "Lik",
                    tint = if (liked) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(Modifier.width(6.dp))
                Text("$likeCount", style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.clip(RoundedCornerShape(6.dp)).clickable(onClick = onComments).padding(4.dp)
            ) {
                Icon(Icons.Outlined.ChatBubbleOutline, "Kommentarer",
                    tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(6.dp))
                Text("${post.commentCount}", style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Spacer(Modifier.weight(1f))
            Icon(Icons.Outlined.Share, "Del",
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.clip(RoundedCornerShape(6.dp)).clickable(onClick = onShare)
                    .padding(4.dp).size(20.dp))
        }
    }
}

@Composable
private fun AuthorAvatar(url: String?, size: androidx.compose.ui.unit.Dp) {
    if (url != null) {
        AsyncImage(model = url, contentDescription = null, contentScale = ContentScale.Crop,
            modifier = Modifier.size(size).clip(CircleShape))
    } else {
        Box(Modifier.size(size).clip(CircleShape)
            .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)), contentAlignment = Alignment.Center) {
            Icon(Icons.Filled.Person, null, tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(size * 0.55f))
        }
    }
}

@Composable
private fun LoginPrompt(onLogin: () -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("Logg inn for å se feeden.", textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(Modifier.height(16.dp))
        Button(onClick = onLogin) { Text("Logg inn med Google") }
    }
}

// Innlegg i detalj (som iOS PostDetailView): innlegget + kommentarer + kommentarfelt.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PostDetailScreen(post: FeedPost, onBack: () -> Unit, onShare: () -> Unit, onUser: (String) -> Unit) {
    val scope = rememberCoroutineScope()
    val isAuthed = Supa.client.auth.currentUserOrNull() != null
    var comments by remember { mutableStateOf<List<com.tomerikheggedal.vitola.data.FeedComment>>(emptyList()) }
    var input by remember { mutableStateOf("") }
    var sending by remember { mutableStateOf(false) }

    suspend fun load() { comments = runCatching { FeedRepository.comments(post.id) }.getOrDefault(emptyList()) }
    LaunchedEffect(post.id) { load() }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = { Text("Innlegg", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Tilbake") }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        },
        bottomBar = {
            if (isAuthed) {
                Row(
                    Modifier.fillMaxWidth().background(MaterialTheme.colorScheme.surface)
                        .padding(horizontal = 16.dp, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedTextField(
                        value = input, onValueChange = { input = it },
                        placeholder = { Text("Skriv en kommentar…") },
                        modifier = Modifier.weight(1f), maxLines = 3
                    )
                    Spacer(Modifier.width(8.dp))
                    Button(
                        onClick = {
                            if (sending || input.isBlank()) return@Button
                            sending = true
                            scope.launch {
                                runCatching { FeedRepository.addComment(post.id, input) }
                                input = ""; load(); sending = false
                            }
                        },
                        enabled = !sending && input.isNotBlank()
                    ) { Text("Send") }
                }
            }
        }
    ) { padding ->
        LazyColumn(
            Modifier.padding(padding).fillMaxSize(),
            contentPadding = PaddingValues(vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            item { PostCard(post = post, onComments = {}, onShare = onShare, onOpen = null, onAuthor = { onUser(post.userId) }) }
            item {
                Text("Kommentarer", style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(start = 20.dp, top = 8.dp))
            }
            if (comments.isEmpty()) {
                item {
                    Text("Ingen kommentarer ennå. Vær den første!",
                        style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp))
                }
            } else {
                items(comments, key = { it.id }) { c ->
                    Row(Modifier.padding(horizontal = 20.dp, vertical = 4.dp)) {
                        AuthorAvatar(c.authorAvatarUrl, 32.dp)
                        Spacer(Modifier.width(10.dp))
                        Column(Modifier.weight(1f)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(c.authorName, fontWeight = FontWeight.SemiBold,
                                    style = MaterialTheme.typography.bodyMedium)
                                Spacer(Modifier.width(8.dp))
                                Text(relativeTime(c.createdAt), style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                            Text(c.content, style = MaterialTheme.typography.bodyMedium)
                        }
                    }
                }
            }
        }
    }
}
