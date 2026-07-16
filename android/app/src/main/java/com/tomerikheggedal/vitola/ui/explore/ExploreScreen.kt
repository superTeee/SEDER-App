package com.tomerikheggedal.vitola.ui.explore

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.tomerikheggedal.vitola.data.BrandSummary
import com.tomerikheggedal.vitola.data.Cigar
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

    private var searchJob: Job? = null

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

            OutlinedTextField(
                value = vm.query,
                onValueChange = vm::onQuery,
                placeholder = { Text("Søk merke, serie eller vitola") },
                leadingIcon = { Icon(Icons.Filled.Search, null) },
                singleLine = true,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)
            )

            when {
                vm.loading -> Box(Modifier.fillMaxSize(), Alignment.Center) { CircularProgressIndicator() }
                vm.error != null -> Box(Modifier.fillMaxSize(), Alignment.Center) {
                    Text(vm.error!!, color = MaterialTheme.colorScheme.error)
                }
                vm.query.isNotBlank() -> LazyColumn(
                    Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(bottom = 96.dp)
                ) {
                    // Søketreff gruppert per merke, ett kort per merke (som iOS).
                    val groups = vm.results.groupBy { it.brand }
                    groups.forEach { (brand, cigars) ->
                        item(key = "h_$brand") { SectionLabel(brand) }
                        item(key = "c_$brand") {
                            ListCard {
                                cigars.forEachIndexed { i, cigar ->
                                    NavRow(
                                        title = listOfNotNull(cigar.series, cigar.vitola)
                                            .joinToString(" · ").ifBlank { cigar.brand },
                                        detail = listOfNotNull(cigar.commonFormat, cigar.dimensionsLabel)
                                            .joinToString(" · ").ifBlank { null },
                                    ) { onCigar(cigar.id) }
                                    if (i < cigars.lastIndex) RowDivider()
                                }
                            }
                        }
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
