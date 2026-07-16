package com.tomerikheggedal.vitola.ui.explore

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
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
    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                title = { Text("Utforsk") },
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
                    contentPadding = PaddingValues(bottom = 24.dp)
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
                    contentPadding = PaddingValues(bottom = 24.dp)
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
