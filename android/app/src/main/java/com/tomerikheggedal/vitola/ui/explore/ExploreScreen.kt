package com.tomerikheggedal.vitola.ui.explore

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.HelpOutline
import androidx.compose.material.icons.outlined.History
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.tomerikheggedal.vitola.data.BrandSummary
import com.tomerikheggedal.vitola.data.Cigar
import com.tomerikheggedal.vitola.data.CigarFilter
import com.tomerikheggedal.vitola.data.CigarRepository
import com.tomerikheggedal.vitola.data.ScanHit
import com.tomerikheggedal.vitola.data.ScanOutcome
import com.tomerikheggedal.vitola.data.ScanRepository
import com.tomerikheggedal.vitola.data.SearchHistory
import com.tomerikheggedal.vitola.data.SearchHit
import com.tomerikheggedal.vitola.data.WishlistRepository
import com.tomerikheggedal.vitola.ui.detail.SmokingLogSheet
import com.tomerikheggedal.vitola.ui.humidor.AddToHumidorSheet
import com.tomerikheggedal.vitola.ui.components.ListCard
import com.tomerikheggedal.vitola.ui.components.NavRow
import com.tomerikheggedal.vitola.ui.components.RowDivider
import com.tomerikheggedal.vitola.ui.components.SectionLabel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class ExploreViewModel : ViewModel() {
    var query by mutableStateOf("")
        private set
    var brands by mutableStateOf<List<BrandSummary>>(emptyList())
        private set
    var topRated by mutableStateOf<List<Cigar>>(emptyList())
        private set
    var featured by mutableStateOf<Cigar?>(null)
        private set
    var results by mutableStateOf<List<SearchHit>>(emptyList())
        private set
    var loading by mutableStateOf(true)
        private set
    var error by mutableStateOf<String?>(null)
        private set

    // Avansert søk
    var filter by mutableStateOf(CigarFilter())
        private set
    var filterResults by mutableStateOf<List<Cigar>>(emptyList())
        private set
    var filterLoading by mutableStateOf(false)
        private set

    private var searchJob: Job? = null

    fun applyFilter(f: CigarFilter) {
        filter = f
        if (!f.isActive) { filterResults = emptyList(); return }
        viewModelScope.launch {
            filterLoading = true; error = null
            try { filterResults = CigarRepository.filtered(f) }
            catch (e: Exception) { error = e.message ?: "Filtrering feilet" }
            filterLoading = false
        }
    }

    fun clearFilter() { filter = CigarFilter(); filterResults = emptyList() }

    init { load() }

    private fun load() {
        viewModelScope.launch {
            loading = true; error = null
            try {
                topRated = CigarRepository.topRated()   // best effort — feiler stille
            } catch (_: Exception) { }
            try {
                featured = CigarRepository.featured()    // best effort — feiler stille
            } catch (_: Exception) { }
            try { brands = CigarRepository.brands() }
            catch (e: Exception) { error = e.message ?: "Kunne ikke laste merker" }
            loading = false
        }
    }

    fun onQuery(q: String) {
        query = q
        error = null
        searchJob?.cancel()
        if (q.isBlank()) { results = emptyList(); return }
        searchJob = viewModelScope.launch {
            delay(300) // debounce
            try {
                results = CigarRepository.search(q)
            } catch (e: kotlinx.coroutines.CancellationException) {
                throw e   // avbrutt av neste tastetrykk — ikke en ekte feil
            } catch (e: Exception) {
                error = e.message ?: "Søk feilet"
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ExploreScreen(
    onProfile: () -> Unit = {},
    scanTick: Int = 0,
    onBrand: (String) -> Unit,
    onCigar: (String) -> Unit,
    vm: ExploreViewModel = viewModel()
) {
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val snackbar = remember { SnackbarHostState() }
    var showFilter by remember { mutableStateOf(false) }
    var recent by remember { mutableStateOf(SearchHistory.load(context)) }
    var scanning by remember { mutableStateOf(false) }
    var scanResults by remember { mutableStateOf<List<ScanHit>?>(null) }
    // Siste skann (bånd-tekst + bilde) — brukes til å registrere løsningen når
    // brukeren velger riktig sigar (datahjul for bildegjenkjenning).
    var scanCtx by remember { mutableStateOf<Pair<String, ByteArray>?>(null) }
    var pendingShape by remember { mutableStateOf<ScanOutcome?>(null) }
    var pendingWrapper by remember { mutableStateOf<ScanOutcome?>(null) }
    var showManualAdd by remember { mutableStateOf(false) }
    // Ingen treff → vennlig skjerm + manuell innlegging (speiler iOS-flyten).
    var showNoMatch by remember { mutableStateOf(false) }
    var showScanManualAdd by remember { mutableStateOf(false) }
    // Skann-ark åpnet av senter-knappen i tab-baren (band / kamerarull).
    var showScanChooser by remember { mutableStateOf(false) }
    LaunchedEffect(scanTick) { if (scanTick > 0) showScanChooser = true }
    // Hurtighandlinger (long-trykk) — som iOS contextMenu.
    var quickCigar by remember { mutableStateOf<Cigar?>(null) }
    var qaAddHumidor by remember { mutableStateOf<Cigar?>(null) }
    var qaLog by remember { mutableStateOf<Cigar?>(null) }

    // Registrer at brukeren løste en skanning: last opp bånd-bildet + koble
    // bånd-tekst → sigar (datahjul for bildegjenkjenning). Best effort, og
    // gjør ingenting hvis det ikke fantes en fersk skann-kontekst.
    fun resolveTo(cigarId: String) {
        scanCtx?.let { (ocr, jpg) -> scope.launch { ScanRepository.resolveScan(ocr, cigarId, jpg) } }
        scanCtx = null
        onCigar(cigarId)
    }

    // Håndter resultatet av en full skann (OCR → DB → AI + avklaring).
    fun finishOutcome(outcome: ScanOutcome) {
        when {
            outcome.autoSelected != null -> resolveTo(outcome.autoSelected!!.id)
            outcome.needsShape -> pendingShape = outcome
            outcome.needsWrapper -> pendingWrapper = outcome
            outcome.hits.isEmpty() -> {
                // Aldri blindvei: vennlig ingen-treff-skjerm (prøv på nytt / legg inn manuelt).
                showNoMatch = true
            }
            outcome.hits.size == 1 -> resolveTo(outcome.hits.first().cigar.id)
            else -> scanResults = outcome.hits
        }
    }

    fun runScan(jpeg: ByteArray?) {
        if (jpeg == null) return
        scanning = true
        scope.launch {
            val outcome = runCatching { ScanRepository.scanBand(jpeg) }.getOrNull()
            scanning = false
            if (outcome == null) { snackbar.showSnackbar("Skanningen feilet. Prøv igjen."); return@launch }
            scanCtx = outcome.ocrText to jpeg
            finishOutcome(outcome)
        }
    }

    val cameraLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.TakePicturePreview()
    ) { bitmap -> if (bitmap != null) runScan(bitmapToJpeg(bitmap)) }
    val galleryLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.PickVisualMedia()
    ) { uri -> if (uri != null) scope.launch { runScan(uriToJpeg(context, uri)) } }

    // Kamera for form-/wrapper-avklaring (bilde av hele sigaren).
    val shapeCam = rememberLauncherForActivityResult(ActivityResultContracts.TakePicturePreview()) { bmp ->
        val pending = pendingShape
        pendingShape = null
        if (bmp == null || pending == null) return@rememberLauncherForActivityResult
        scanning = true
        scope.launch {
            val resolved = runCatching { ScanRepository.resolveShape(pending.candidates, bitmapToJpeg(bmp)) }.getOrNull()
            scanning = false
            if (resolved != null) resolveTo(resolved.id) else scanResults = pending.hits
        }
    }
    val wrapperCam = rememberLauncherForActivityResult(ActivityResultContracts.TakePicturePreview()) { bmp ->
        val pending = pendingWrapper
        pendingWrapper = null
        if (bmp == null || pending == null) return@rememberLauncherForActivityResult
        scanning = true
        scope.launch {
            val resolved = runCatching { ScanRepository.resolveWrapper(pending.candidates, bitmapToJpeg(bmp)) }.getOrNull()
            scanning = false
            if (resolved != null) resolveTo(resolved.id) else scanResults = pending.hits
        }
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        snackbarHost = { SnackbarHost(snackbar) },
        topBar = {
            TopAppBar(
                title = { Text("Utforsk", fontWeight = FontWeight.Bold) },
                navigationIcon = { com.tomerikheggedal.vitola.ui.components.TopBarProfileAvatar(onProfile) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        }
    ) { padding ->
        Column(Modifier.padding(padding).fillMaxSize()) {

            // Søkefelt + filterknapp (avansert søk), som iOS.
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                OutlinedTextField(
                    value = vm.query,
                    onValueChange = vm::onQuery,
                    placeholder = {
                        Text("Søk merke, serie, form eller smak", maxLines = 1, overflow = TextOverflow.Ellipsis)
                    },
                    leadingIcon = { Icon(Icons.Filled.Search, null) },
                    singleLine = true,
                    shape = searchShape,
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                    keyboardActions = KeyboardActions(onSearch = {
                        if (vm.query.isNotBlank()) recent = SearchHistory.add(context, vm.query)
                    }),
                    colors = OutlinedTextFieldDefaults.colors(
                        // 5% accent i hvile, 10% accent når feltet er aktivt (som iOS).
                        unfocusedContainerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.05f),
                        focusedContainerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.10f),
                        // Ingen synlig ramme.
                        unfocusedBorderColor = Color.Transparent,
                        focusedBorderColor = Color.Transparent,
                    ),
                    modifier = Modifier.weight(1f)
                )
                FilterButton(active = vm.filter.isActive) { showFilter = true }
            }

            when {
                vm.loading -> Box(Modifier.fillMaxSize(), Alignment.Center) { CircularProgressIndicator() }
                vm.error != null -> Box(Modifier.fillMaxSize(), Alignment.Center) {
                    Text(vm.error!!, color = MaterialTheme.colorScheme.error)
                }
                vm.query.isNotBlank() -> LazyColumn(
                    Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(bottom = 96.dp)
                ) {
                    item {
                        val n = vm.results.size
                        Text(
                            if (n == 0) "Ingen resultater for «${vm.query}»"
                            else "Resultater for «${vm.query}» ($n)",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = if (n == 0) MaterialTheme.colorScheme.onSurfaceVariant
                                    else MaterialTheme.colorScheme.onSurface,
                            modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 12.dp, bottom = 6.dp)
                        )
                    }
                    searchHitGroups(vm.results, onCigar) { quickCigar = it }
                    // Fant ikke sigaren? La brukeren legge den inn selv (som iOS).
                    item {
                        OutlinedButton(
                            onClick = { showManualAdd = true },
                            modifier = Modifier.fillMaxWidth().padding(16.dp)
                        ) {
                            Icon(Icons.Filled.Add, null, modifier = Modifier.size(18.dp))
                            Spacer(Modifier.width(8.dp))
                            Text(if (vm.results.isEmpty()) "Legg til sigaren manuelt" else "Fant ikke sigaren? Legg til manuelt")
                        }
                    }
                }
                vm.filterLoading -> Box(Modifier.fillMaxSize(), Alignment.Center) { CircularProgressIndicator() }
                vm.filter.isActive -> LazyColumn(
                    Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(bottom = 96.dp)
                ) {
                    item {
                        Row(
                            Modifier.fillMaxWidth().padding(start = 16.dp, end = 8.dp, top = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                "${vm.filterResults.size} treff",
                                style = MaterialTheme.typography.labelMedium,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.weight(1f)
                            )
                            TextButton(onClick = { vm.clearFilter() }) { Text("Nullstill") }
                        }
                    }
                    if (vm.filterResults.isEmpty()) {
                        item {
                            Text(
                                "Ingen treff. Prøv å løsne på filtrene.",
                                textAlign = TextAlign.Center,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.fillMaxWidth().padding(32.dp)
                            )
                        }
                    } else {
                        brandGroups(vm.filterResults, onCigar) { quickCigar = it }
                    }
                }
                else -> LazyColumn(
                    Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(bottom = 96.dp)
                ) {
                    // Siste søk (som iOS) — lokalt lagret historikk.
                    if (recent.isNotEmpty()) {
                        item { SectionLabel("Siste søk") }
                        item {
                            ListCard {
                                recent.forEachIndexed { i, term ->
                                    RecentRow(
                                        term = term,
                                        onTap = { vm.onQuery(term) },
                                        onRemove = { recent = SearchHistory.remove(context, term) }
                                    )
                                    if (i < recent.lastIndex) RowDivider()
                                }
                            }
                        }
                    }

                    if (vm.topRated.isNotEmpty()) {
                        item { SectionLabel("Brukernes topp 3") }
                        item {
                            ListCard {
                                vm.topRated.forEachIndexed { i, cigar ->
                                    TopCigarRow(rank = i + 1, cigar = cigar) { onCigar(cigar.id) }
                                    if (i < vm.topRated.lastIndex) RowDivider()
                                }
                            }
                        }
                    }

                    // Dagens utvalgte — deterministisk per dag (som iOS).
                    vm.featured?.let { c ->
                        item { SectionLabel("Dagens utvalgte") }
                        item { FeaturedCard(c) { onCigar(c.id) } }
                    }

                    // Alfabetisk merkeliste, ett kort per bokstav (som iOS).
                    val byLetter = vm.brands.groupBy { it.brand.first().uppercaseChar() }.toSortedMap()
                    item { SectionLabel("Alle merker") }
                    byLetter.forEach { (letter, brands) ->
                        item(key = "l_$letter") { SectionLabel(letter.toString(), topPadding = 10) }
                        item(key = "b_$letter") {
                            ListCard {
                                brands.forEachIndexed { i, b ->
                                    NavRow(title = b.brand, subtitle = b.subtitle) { onBrand(b.brand) }
                                    if (i < brands.lastIndex) RowDivider()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (showFilter) {
        FilterSheet(
            initial = vm.filter,
            onDismiss = { showFilter = false },
            onApply = { showFilter = false; vm.applyFilter(it) }
        )
    }

    // Form-avklaring: samme bånd matchet flere størrelser.
    pendingShape?.let { p ->
        ScanConfirmOverlay(
            title = "Fant flere størrelser",
            body = "Samme bånd brukes på flere varianter av denne sigaren. Ta ett bilde av HELE sigaren, så ser vi formen og velger riktig variant.",
            onTakePhoto = { shapeCam.launch(null) },
            onSkip = { scanResults = p.hits; pendingShape = null }
        )
    }
    // Wrapper-avklaring: samme serie, ulik wrapper-type.
    pendingWrapper?.let { p ->
        ScanConfirmOverlay(
            title = "Fant flere varianter",
            body = "Denne serien finnes med flere wrapper-typer. Ta ett bilde av HELE sigaren, så ser vi fargen på bladet og velger riktig variant.",
            onTakePhoto = { wrapperCam.launch(null) },
            onSkip = { scanResults = p.hits; pendingWrapper = null }
        )
    }

    // Skanner-overlay mens AI-en jobber.
    if (scanning) {
        Box(Modifier.fillMaxSize().background(androidx.compose.ui.graphics.Color.Black.copy(alpha = 0.55f)),
            contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                CircularProgressIndicator(color = Color.White)
                Spacer(Modifier.height(14.dp))
                Text("Gjenkjenner sigaren…", color = Color.White,
                    style = MaterialTheme.typography.bodyLarge)
            }
        }
    }

    // Flere kandidater → la brukeren velge.
    scanResults?.let { hits ->
        ScanResultsSheet(
            hits = hits,
            onDismiss = { scanResults = null },
            onPick = { scanResults = null; resolveTo(it) }
        )
    }

    // Legg til sigar manuelt (fra søk).
    if (showManualAdd) {
        AddCigarSheet(
            initialBrand = vm.query,
            onDismiss = { showManualAdd = false },
            onCreated = { newId -> showManualAdd = false; resolveTo(newId) }
        )
    }

    // Ingen treff → vennlig skjerm (prøv på nytt / legg inn manuelt).
    if (showNoMatch) {
        NoMatchSheet(
            onDismiss = { showNoMatch = false },
            onRetry = { showNoMatch = false; cameraLauncher.launch(null) },
            onManualAdd = { showNoMatch = false; showScanManualAdd = true }
        )
    }
    // Manuell innlegging fra ingen-treff (motiverende + merke-autocomplete).
    if (showScanManualAdd) {
        ManualAddCigarSheet(
            ocrText = scanCtx?.first ?: "",
            onDismiss = { showScanManualAdd = false },
            onAdded = {
                showScanManualAdd = false
                scope.launch { snackbar.showSnackbar("Lagt i humidoren – takk for bidraget!") }
            }
        )
    }

    // Skann-ark fra senter-knappen (sigarbånd / bilde fra kamerarull).
    if (showScanChooser) {
        val chooserState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
        ModalBottomSheet(onDismissRequest = { showScanChooser = false }, sheetState = chooserState,
            containerColor = MaterialTheme.colorScheme.surface) {
            Column(Modifier.fillMaxWidth().padding(bottom = 24.dp)) {
                Text("Skann", fontWeight = FontWeight.SemiBold,
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.padding(start = 20.dp, top = 4.dp, bottom = 12.dp))
                ScanOption(Icons.Filled.CameraAlt, "Sigarbånd", "Skann båndet på sigaren") {
                    showScanChooser = false; cameraLauncher.launch(null)
                }
                ScanOption(Icons.Filled.PhotoLibrary, "Bilde fra kamerarull", "Velg et bilde du har tatt") {
                    showScanChooser = false
                    galleryLauncher.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                }
            }
        }
    }

    // Hurtighandlinger (long-trykk på en sigar-rad).
    quickCigar?.let { c ->
        CigarQuickActionsSheet(
            cigar = c,
            onDismiss = { quickCigar = null },
            onAddHumidor = { quickCigar = null; qaAddHumidor = c },
            onLog = { quickCigar = null; qaLog = c },
            onWishlist = {
                quickCigar = null
                scope.launch { runCatching { WishlistRepository.add(c.id) } }
                android.widget.Toast.makeText(context, "Lagt i ønskelisten ✓", android.widget.Toast.LENGTH_SHORT).show()
            },
            onShare = { quickCigar = null; shareCigar(context, c) }
        )
    }
    qaAddHumidor?.let { c ->
        AddToHumidorSheet(
            cigar = c,
            onDismiss = { qaAddHumidor = null },
            onAdded = { name ->
                qaAddHumidor = null
                android.widget.Toast.makeText(context, "Lagt i $name ✓", android.widget.Toast.LENGTH_SHORT).show()
            }
        )
    }
    qaLog?.let { c ->
        SmokingLogSheet(
            cigar = c,
            humidorEntryId = null,
            onDismiss = { qaLog = null },
            onLogged = {
                qaLog = null
                android.widget.Toast.makeText(context, "Lagt i journalen ✓", android.widget.Toast.LENGTH_SHORT).show()
            }
        )
    }
}

// Deler en sigar via Androids delingsark.
private fun shareCigar(context: android.content.Context, cigar: Cigar) {
    val name = listOfNotNull(cigar.brand, cigar.series, cigar.vitola).joinToString(" ")
    val body = "$name — sjekk ut denne sigaren i SEDER\n\nhttps://vitola.app"
    val intent = android.content.Intent(android.content.Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(android.content.Intent.EXTRA_TEXT, body)
    }
    runCatching { context.startActivity(android.content.Intent.createChooser(intent, "Del sigar")) }
}

// Hurtigmeny (bunn-ark) med sigar-handlinger.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CigarQuickActionsSheet(
    cigar: Cigar,
    onDismiss: () -> Unit,
    onAddHumidor: () -> Unit,
    onLog: () -> Unit,
    onWishlist: () -> Unit,
    onShare: () -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface) {
        Column(Modifier.fillMaxWidth().padding(bottom = 24.dp)) {
            Text(
                listOfNotNull(cigar.brand, cigar.series, cigar.vitola).joinToString(" "),
                style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
            )
            QuickActionRow(Icons.Filled.Inventory2, "Legg i humidor", onAddHumidor)
            QuickActionRow(Icons.Filled.LocalFireDepartment, "Marker som røkt", onLog)
            QuickActionRow(Icons.Outlined.BookmarkBorder, "Legg i ønskeliste", onWishlist)
            QuickActionRow(Icons.Filled.Share, "Del", onShare)
        }
    }
}

@Composable
private fun QuickActionRow(icon: androidx.compose.ui.graphics.vector.ImageVector, label: String, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 20.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(22.dp))
        Spacer(Modifier.width(16.dp))
        Text(label, style = MaterialTheme.typography.bodyLarge)
    }
}

// Full-skjerm avklaring: be om ett bilde av hele sigaren (form/wrapper) — som iOS.
@Composable
private fun ScanConfirmOverlay(title: String, body: String, onTakePhoto: () -> Unit, onSkip: () -> Unit) {
    Box(
        Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background),
        contentAlignment = Alignment.Center
    ) {
        Column(
            Modifier.fillMaxWidth().padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            Icon(Icons.Outlined.HelpOutline, null, tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(48.dp))
            Text(title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center)
            Text(body, style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
            Button(onClick = onTakePhoto, modifier = Modifier.fillMaxWidth()) {
                Icon(Icons.Filled.CameraAlt, null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(8.dp))
                Text("Ta bilde av hele sigaren")
            }
            TextButton(onClick = onSkip) { Text("Hopp over, vis alle treff") }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ScanResultsSheet(hits: List<ScanHit>, onDismiss: () -> Unit, onPick: (String) -> Unit) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface) {
        Column(Modifier.fillMaxWidth().padding(bottom = 24.dp)) {
            Text("Mulige treff", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(start = 20.dp, bottom = 8.dp))
            hits.forEach { hit ->
                Column(Modifier.fillMaxWidth().clickable { onPick(hit.cigar.id) }
                    .padding(horizontal = 20.dp, vertical = 12.dp)) {
                    Text(hit.cigar.fullName, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium)
                    if (hit.reason.isNotBlank()) {
                        Text(hit.reason, style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                HorizontalDivider(color = MaterialTheme.colorScheme.surfaceVariant)
            }
        }
    }
}

// Bitmap (kamera) → komprimert JPEG.
private fun bitmapToJpeg(bitmap: android.graphics.Bitmap): ByteArray {
    val out = java.io.ByteArrayOutputStream()
    bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 80, out)
    return out.toByteArray()
}

// Galleri-Uri → nedskalert JPEG (maks 1400px).
private fun uriToJpeg(context: android.content.Context, uri: android.net.Uri, maxDim: Int = 1400): ByteArray? {
    val bitmap = context.contentResolver.openInputStream(uri)?.use {
        android.graphics.BitmapFactory.decodeStream(it)
    } ?: return null
    val longest = maxOf(bitmap.width, bitmap.height)
    val scaled = if (longest > maxDim) {
        val r = maxDim.toFloat() / longest
        android.graphics.Bitmap.createScaledBitmap(bitmap,
            (bitmap.width * r).toInt().coerceAtLeast(1), (bitmap.height * r).toInt().coerceAtLeast(1), true)
    } else bitmap
    val out = java.io.ByteArrayOutputStream()
    scaled.compress(android.graphics.Bitmap.CompressFormat.JPEG, 80, out)
    return out.toByteArray()
}

// Søketreff gruppert per merke; viser hva treffet matchet på (smaksnote som accent-tag).
private fun LazyListScope.searchHitGroups(
    hits: List<SearchHit>, onCigar: (String) -> Unit, onLong: (Cigar) -> Unit = {},
) {
    hits.groupBy { it.cigar.brand }.forEach { (brand, list) ->
        item(key = "sh_$brand") { SectionLabel(brand) }
        item(key = "sc_$brand") {
            ListCard {
                list.forEachIndexed { i, hit ->
                    val c = hit.cigar
                    NavRow(
                        title = listOfNotNull(c.series, c.vitola).joinToString(" · ").ifBlank { c.brand },
                        subtitle = listOfNotNull(c.commonFormat, c.dimensionsLabel).joinToString(" · ").ifBlank { null },
                        detail = hit.matchedFlavor?.let { "Smak: $it" },
                        onLongClick = { onLong(c) },
                    ) { onCigar(c.id) }
                    if (i < list.lastIndex) RowDivider()
                }
            }
        }
    }
}

// Søketreff/filtertreff gruppert per merke, ett kort per merke (som iOS).
private fun LazyListScope.brandGroups(
    cigars: List<Cigar>, onCigar: (String) -> Unit, onLong: (Cigar) -> Unit = {},
) {
    cigars.groupBy { it.brand }.forEach { (brand, list) ->
        item(key = "h_$brand") { SectionLabel(brand) }
        item(key = "c_$brand") {
            ListCard {
                list.forEachIndexed { i, cigar ->
                    NavRow(
                        title = listOfNotNull(cigar.series, cigar.vitola)
                            .joinToString(" · ").ifBlank { cigar.brand },
                        detail = listOfNotNull(cigar.commonFormat, cigar.dimensionsLabel)
                            .joinToString(" · ").ifBlank { null },
                        onLongClick = { onLong(cigar) },
                    ) { onCigar(cigar.id) }
                    if (i < list.lastIndex) RowDivider()
                }
            }
        }
    }
}

// Filterknapp ved søkefeltet — samme form/høyde som søkefeltet, accent-fylt.
@Composable
private fun FilterButton(active: Boolean, onClick: () -> Unit) {
    Box {
        Box(
            Modifier
                .size(56.dp)
                .clip(searchShape)
                .background(MaterialTheme.colorScheme.primary)
                .clickable(onClick = onClick),
            contentAlignment = Alignment.Center
        ) {
            Icon(Icons.Filled.Tune, contentDescription = "Avansert søk",
                tint = MaterialTheme.colorScheme.onPrimary)
        }
        if (active) {
            Box(
                Modifier
                    .align(Alignment.TopEnd)
                    .padding(4.dp)
                    .size(10.dp)
                    .clip(androidx.compose.foundation.shape.CircleShape)
                    .background(Color.White)
            )
        }
    }
}

// Delt form for søkefelt + filterknapp så de matcher.
private val searchShape = RoundedCornerShape(6.dp)

// Topp 3-rad: nummerert medalje-badge + sigarinfo + score-badge + chevron.
@Composable
private fun TopCigarRow(rank: Int, cigar: Cigar, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        RankBadge(rank)
        Spacer(Modifier.width(14.dp))
        Column(Modifier.weight(1f)) {
            Text(cigar.brand, style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Medium, letterSpacing = 0.sp)
            cigar.series?.let { Text(it, style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant) }
            cigar.vitola?.let { Text(it, style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant) }
        }
        cigar.avgRating?.let { ScoreBadge(it) }
        Spacer(Modifier.width(8.dp))
        ChevronIcon()
    }
}

// Dagens utvalgte-kort: flamme-ikonboks + info + score + chevron (som iOS).
@Composable
private fun FeaturedCard(cigar: Cigar, onClick: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .clip(searchShape)
            .background(MaterialTheme.colorScheme.surface)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            Modifier.size(52.dp).clip(RoundedCornerShape(8.dp))
                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(Icons.Filled.LocalFireDepartment, null,
                tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(24.dp))
        }
        Spacer(Modifier.width(14.dp))
        Column(Modifier.weight(1f)) {
            Text(cigar.brand, style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Medium, letterSpacing = 0.sp)
            cigar.series?.let { Text(it, style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1) }
            (cigar.vitola ?: cigar.commonFormat)?.let { Text(it, style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant) }
        }
        cigar.avgRating?.let { rating ->
            Column(
                Modifier.clip(RoundedCornerShape(6.dp))
                    .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f))
                    .padding(horizontal = 10.dp, vertical = 7.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(String.format("%.1f", rating), style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
                Text("score", style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        Spacer(Modifier.width(8.dp))
        ChevronIcon()
    }
}

// Rad i «Siste søk»: klokke-ikon + søkeord + fjern-kryss (som iOS).
@Composable
private fun RecentRow(term: String, onTap: () -> Unit, onRemove: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable(onClick = onTap).padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(Icons.Outlined.History, null, tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(20.dp))
        Spacer(Modifier.width(12.dp))
        Text(term, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium,
            letterSpacing = 0.sp, color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.weight(1f))
        IconButton(onClick = onRemove, modifier = Modifier.size(28.dp)) {
            Icon(Icons.Filled.Close, "Fjern", tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(16.dp))
        }
    }
}

// Nummerert medalje-badge — renere enn emoji, med diskré metall-toner.
@Composable
private fun RankBadge(rank: Int) {
    val (bg, fg) = when (rank) {
        1 -> Color(0xFFC8A94B) to Color.White   // gull
        2 -> Color(0xFFAEB4BD) to Color.White   // sølv
        3 -> Color(0xFFB98A5E) to Color.White   // bronse
        else -> MaterialTheme.colorScheme.surfaceVariant to MaterialTheme.colorScheme.onSurfaceVariant
    }
    Box(
        Modifier.size(26.dp).clip(androidx.compose.foundation.shape.CircleShape).background(bg),
        contentAlignment = Alignment.Center
    ) {
        Text("$rank", color = fg, fontWeight = FontWeight.Bold,
            style = MaterialTheme.typography.labelLarge, letterSpacing = 0.sp)
    }
}

@Composable
private fun ScoreBadge(rating: Double) {
    Text(
        String.format("%.1f", rating),
        style = MaterialTheme.typography.labelLarge,
        fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier
            .clip(androidx.compose.foundation.shape.CircleShape)
            .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f))
            .padding(horizontal = 10.dp, vertical = 5.dp)
    )
}

@Composable
private fun ChevronIcon() {
    Icon(
        Icons.AutoMirrored.Filled.KeyboardArrowRight,
        contentDescription = null,
        tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f),
        modifier = Modifier.size(20.dp)
    )
}

// «Skann sigar»-FAB som iOS: pill med kamera-ikon, åpner en meny.
// Ett valg i skann-arket (ikon-flate + tittel + undertittel).
@Composable
private fun ScanOption(icon: ImageVector, title: String, subtitle: String, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 20.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            Modifier.size(44.dp).clip(RoundedCornerShape(11.dp))
                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.14f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(icon, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(22.dp))
        }
        Spacer(Modifier.width(14.dp))
        Column(Modifier.weight(1f)) {
            Text(title, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyLarge)
            Text(subtitle, style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun ScanFab(onCamera: () -> Unit, onGallery: () -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    Box {
        ExtendedFloatingActionButton(
            onClick = { expanded = true },
            containerColor = MaterialTheme.colorScheme.primary,
            contentColor = MaterialTheme.colorScheme.onPrimary,
            shape = androidx.compose.foundation.shape.CircleShape,   // helt pill-formet
            icon = { Icon(Icons.Filled.CameraAlt, contentDescription = null) },
            text = { Text("Skann sigar", fontWeight = FontWeight.SemiBold) }
        )
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            DropdownMenuItem(
                text = { Text("Skann magebeltet") },
                leadingIcon = { Icon(Icons.Filled.CameraAlt, null) },
                onClick = { expanded = false; onCamera() }
            )
            DropdownMenuItem(
                text = { Text("Bilde fra kamerarull") },
                leadingIcon = { Icon(Icons.Filled.PhotoLibrary, null) },
                onClick = { expanded = false; onGallery() }
            )
        }
    }
}
