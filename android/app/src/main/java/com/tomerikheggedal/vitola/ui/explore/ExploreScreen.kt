package com.tomerikheggedal.vitola.ui.explore

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
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
            CenterAlignedTopAppBar(
                title = { Text("Utforsk") },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
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
                vm.query.isNotBlank() -> LazyColumn(Modifier.fillMaxSize()) {
                    items(vm.results, key = { it.id }) { cigar ->
                        CigarRow(cigar) { onCigar(cigar.id) }
                        HorizontalDivider()
                    }
                }
                else -> LazyColumn(Modifier.fillMaxSize()) {
                    if (vm.topRated.isNotEmpty()) {
                        item { SectionHeader("BRUKERNES TOPP 3") }
                        items(vm.topRated, key = { "top_${it.id}" }) { cigar ->
                            CigarRow(cigar) { onCigar(cigar.id) }
                            HorizontalDivider()
                        }
                        item { SectionHeader("ALLE MERKER") }
                    }
                    items(vm.brands, key = { it.brand }) { b ->
                        BrandRow(b) { onBrand(b.brand) }
                        HorizontalDivider()
                    }
                }
            }
        }
    }
}

@Composable
private fun SectionHeader(title: String) {
    Text(
        title,
        style = MaterialTheme.typography.labelMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        fontWeight = FontWeight.SemiBold,
        modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 18.dp, bottom = 8.dp)
    )
}

@Composable
private fun BrandRow(b: BrandSummary, onClick: () -> Unit) {
    Column(
        Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Text(b.brand, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyLarge)
        Text(b.subtitle, color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodySmall)
    }
}

@Composable
private fun CigarRow(cigar: Cigar, onClick: () -> Unit) {
    Column(
        Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Text(cigar.brand, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyLarge)
        val sub = listOfNotNull(cigar.series, cigar.vitola).joinToString(" · ")
        if (sub.isNotBlank()) {
            Text(sub, color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodySmall)
        }
        val chip = listOfNotNull(cigar.commonFormat, cigar.dimensionsLabel).joinToString(" · ")
        if (chip.isNotBlank()) {
            Text(chip, color = MaterialTheme.colorScheme.primary, style = MaterialTheme.typography.labelMedium,
                modifier = Modifier.padding(top = 2.dp))
        }
    }
}
