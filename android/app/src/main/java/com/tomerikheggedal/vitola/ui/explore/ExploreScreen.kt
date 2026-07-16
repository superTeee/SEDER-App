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
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.tomerikheggedal.vitola.data.BrandSummary
import com.tomerikheggedal.vitola.data.Cigar
import com.tomerikheggedal.vitola.data.CigarFilter
import com.tomerikheggedal.vitola.data.CigarRepository
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
    var results by mutableStateOf<List<Cigar>>(emptyList())
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
    val snackbar = remember { SnackbarHostState() }
    var showFilter by remember { mutableStateOf(false) }
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
                    placeholder = { Text("Søk merke, serie eller vitola") },
                    leadingIcon = { Icon(Icons.Filled.Search, null) },
                    singleLine = true,
                    shape = searchShape,
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                    colors = OutlinedTextFieldDefaults.colors(
                        // 50% gjennomsiktig hvit i hvile, 100% hvit når feltet er aktivt.
                        unfocusedContainerColor = Color.White.copy(alpha = 0.5f),
                        focusedContainerColor = Color.White,
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
                    brandGroups(vm.results, onCigar)
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
                    if (vm.topRated.isNotEmpty()) {
                        item { SectionLabel("Brukernes topp 3") }
                        item {
                            ListCard {
                                vm.topRated.forEachIndexed { i, cigar ->
                                    NavRow(
                                        title = cigar.brand,
                                        titleBold = true,
                                        subtitle = listOfNotNull(cigar.series, cigar.vitola)
                                            .joinToString(" · ").ifBlank { null },
                                        detail = cigar.dimensionsLabel,
                                    ) { onCigar(cigar.id) }
                                    if (i < vm.topRated.lastIndex) RowDivider()
                                }
                            }
                        }
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
                    .background(MaterialTheme.colorScheme.error)
            )
        }
    }
}

// Delt form for søkefelt + filterknapp så de matcher.
private val searchShape = RoundedCornerShape(12.dp)

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
