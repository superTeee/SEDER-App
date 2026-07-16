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
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.outlined.History
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
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
import com.tomerikheggedal.vitola.data.SearchHistory
import com.tomerikheggedal.vitola.data.SearchHit
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
    onBrand: (String) -> Unit,
    onCigar: (String) -> Unit,
    vm: ExploreViewModel = viewModel()
) {
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val snackbar = remember { SnackbarHostState() }
    var showFilter by remember { mutableStateOf(false) }
    var recent by remember { mutableStateOf(SearchHistory.load(context)) }
    fun scanComingSoon() = scope.launch { snackbar.showSnackbar("Bildegjenkjenning kommer snart") }

    // Kamera (miniatyr) og bildevelger — åpner ekte kamera/galleri.
    // Gjenkjenningen er ikke portet ennå, så resultatet viser en «kommer snart»-melding.
    val cameraLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.TakePicturePreview()
    ) { bitmap -> if (bitmap != null) scanComingSoon() }
    val galleryLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.PickVisualMedia()
    ) { uri -> if (uri != null) scanComingSoon() }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        snackbarHost = { SnackbarHost(snackbar) },
        floatingActionButton = {
            ScanFab(
                onCamera = { cameraLauncher.launch(null) },
                onGallery = {
                    galleryLauncher.launch(
                        PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                    )
                }
            )
        },
        topBar = {
            TopAppBar(
                title = { Text("Utforsk", fontWeight = FontWeight.Bold) },
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
                        // 50% gjennomsiktig hvit i hvile, 100% hvit når feltet er aktivt.
                        unfocusedContainerColor = Color.White.copy(alpha = 0.5f),
                        focusedContainerColor = Color.White,
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
                    searchHitGroups(vm.results, onCigar)
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
                        brandGroups(vm.filterResults, onCigar)
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
}

// Søketreff gruppert per merke; viser hva treffet matchet på (smaksnote som accent-tag).
private fun LazyListScope.searchHitGroups(hits: List<SearchHit>, onCigar: (String) -> Unit) {
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
                    ) { onCigar(c.id) }
                    if (i < list.lastIndex) RowDivider()
                }
            }
        }
    }
}

// Søketreff/filtertreff gruppert per merke, ett kort per merke (som iOS).
private fun LazyListScope.brandGroups(cigars: List<Cigar>, onCigar: (String) -> Unit) {
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
// Uten strekkode-valget — bare kamera og kamerarull.
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
