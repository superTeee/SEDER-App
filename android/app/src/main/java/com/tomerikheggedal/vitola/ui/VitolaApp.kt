package com.tomerikheggedal.vitola.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.outlined.CenterFocusWeak
import androidx.compose.material.icons.outlined.Explore
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import io.github.jan.supabase.gotrue.auth
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.tomerikheggedal.vitola.ui.detail.CigarDetailScreen
import com.tomerikheggedal.vitola.ui.explore.BrandCigarsScreen
import com.tomerikheggedal.vitola.ui.explore.ExploreScreen
import com.tomerikheggedal.vitola.ui.humidor.HumidorDetailScreen
import com.tomerikheggedal.vitola.ui.humidor.HumidorRhHistoryScreen
import com.tomerikheggedal.vitola.ui.humidor.HumidorScreen
import com.tomerikheggedal.vitola.ui.journal.JournalScreen
import com.tomerikheggedal.vitola.ui.profile.ProfileScreen
import com.tomerikheggedal.vitola.ui.profile.SettingsScreen

@Composable
fun VitolaApp() {
    val nav = rememberNavController()

    val backStack by nav.currentBackStackEntryAsState()
    val current = backStack?.destination?.route
    val currentBase = current?.substringBefore("?")

    var humidorTabRequest by remember { mutableStateOf<Int?>(null) }
    // Bumpes av senter-skann-knappen → Utforsk åpner skann-arket.
    var scanTick by remember { mutableIntStateOf(0) }
    // Bumpes når «Kvittering» velges i skann-arket → Humidor åpner kvittering-flyten.
    var receiptTick by remember { mutableIntStateOf(0) }

    var selectedTab by remember { mutableStateOf("explore") }
    LaunchedEffect(currentBase) {
        if (currentBase in listOf("explore", "journal", "humidor", "profile")) {
            selectedTab = currentBase!!
        }
    }

    fun navigateTab(route: String) {
        val alreadyOnTab = selectedTab == route
        if (alreadyOnTab) {
            val popped = nav.popBackStack(route, inclusive = false)
            if (!popped) nav.navigate(route) {
                popUpTo(nav.graph.findStartDestination().id); launchSingleTop = true
            }
        } else {
            nav.navigate(route) {
                popUpTo(nav.graph.findStartDestination().id) { saveState = true }
                launchSingleTop = true; restoreState = true
            }
        }
    }

    val context = androidx.compose.ui.platform.LocalContext.current
    // Founding-medlem-feiring: vises kun én gang (som iOS).
    var foundingNumber by remember { mutableIntStateOf(0) }
    var showFoundingWelcome by remember { mutableStateOf(false) }

    // Hent Pro-status ved oppstart: abonnement fra RevenueCat (no-op til goog_-nøkkel
    // er satt) + founding member fra profilen (is_founding_member → livstids-Pro).
    LaunchedEffect(Unit) {
        com.tomerikheggedal.vitola.data.ProManager.refresh()
        val p = runCatching { com.tomerikheggedal.vitola.data.ProfileRepository.myProfile() }.getOrNull()
        com.tomerikheggedal.vitola.data.ProManager.setFoundingMember(p?.isFoundingMember == true)

        // Tildel founding-nummer og feire én gang (ekskluderer tidlige testere: RPC
        // returnerer null for tester/ekskludert/allerede tildelt → hopp over).
        if (!com.tomerikheggedal.vitola.AppPrefs.hasSeenFoundingWelcome(context)) {
            val n = com.tomerikheggedal.vitola.data.ProfileRepository.claimFoundingNumber()
            if (n != null) { foundingNumber = n; showFoundingWelcome = true }
            else com.tomerikheggedal.vitola.AppPrefs.setFoundingWelcomeSeen(context)
        }
    }

    // Knytt RevenueCat-kunden til Supabase-bruker-ID: logIn ved innlogging,
    // logOut ved utlogging. Reagerer på session-endringer (no-op til goog_-nøkkel er satt).
    val session by com.tomerikheggedal.vitola.data.Supa.client.auth.sessionStatus.collectAsState()
    LaunchedEffect(session) {
        val uid = com.tomerikheggedal.vitola.data.Supa.client.auth.currentUserOrNull()?.id
        if (uid != null) com.tomerikheggedal.vitola.data.ProManager.logIn(uid)
        else com.tomerikheggedal.vitola.data.ProManager.logOut()
    }

    if (showFoundingWelcome) {
        FoundingWelcomeDialog(number = foundingNumber) {
            com.tomerikheggedal.vitola.AppPrefs.setFoundingWelcomeSeen(context)
            showFoundingWelcome = false
        }
    }

    Scaffold(
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        bottomBar = {
            SederTabBar(
                selected = selectedTab,
                onTab = { navigateTab(it) },
                onScan = { navigateTab("explore"); scanTick++ }
            )
        }
    ) { padding ->
        val toProfile: () -> Unit = { nav.navigate("profile") }
        NavHost(
            navController = nav,
            startDestination = "explore",
            modifier = Modifier.padding(padding)
        ) {
            // Det sosiale laget (aktivitetsstrøm, andres profiler, venner) er fjernet
            // for app-butikk-samsvar (tobakksinnhold skal ikke fremstå som et
            // fellesskap som oppmuntrer til konsum). Rutene «activity», «user/{id}»
            // og «friends» er derfor tatt ut av navigasjonen.
            composable("explore") {
                ExploreScreen(
                    onProfile = toProfile,
                    scanTick = scanTick,
                    onReceipt = { navigateTab("humidor"); receiptTick++ },
                    onBrand = { nav.navigate("brand/${it}") },
                    onCigar = { nav.navigate("cigar/${it}") }
                )
            }
            composable("brand/{brand}") { entry ->
                BrandCigarsScreen(
                    brand = entry.arguments?.getString("brand").orEmpty(),
                    onBack = { nav.popBackStack() },
                    onCigar = { nav.navigate("cigar/${it}") }
                )
            }
            composable("cigar/{id}") { entry ->
                CigarDetailScreen(
                    id = entry.arguments?.getString("id").orEmpty(),
                    onBack = { nav.popBackStack() }
                )
            }
            composable("humidor") {
                HumidorScreen(
                    onProfile = toProfile,
                    receiptTick = receiptTick,
                    requestedTab = humidorTabRequest,
                    onTabConsumed = { humidorTabRequest = null },
                    onHumidor = { nav.navigate("humidorDetail/${it}") },
                    onCigar = { nav.navigate("cigar/${it}") },
                    onPaywall = { nav.navigate("paywall") }
                )
            }
            composable("humidorDetail/{id}") { entry ->
                HumidorDetailScreen(
                    id = entry.arguments?.getString("id").orEmpty(),
                    onBack = { nav.popBackStack() },
                    onCigar = { nav.navigate("cigar/${it}") },
                    onHistory = { nav.navigate("humidorRh/${it}") }
                )
            }
            composable("humidorRh/{id}") { entry ->
                HumidorRhHistoryScreen(
                    id = entry.arguments?.getString("id").orEmpty(),
                    onBack = { nav.popBackStack() }
                )
            }
            composable("journal") {
                JournalScreen(
                    onProfile = toProfile,
                    onCigar = { nav.navigate("cigar/${it}") },
                    onPaywall = { nav.navigate("paywall") }
                )
            }
            composable("profile") {
                ProfileScreen(
                    onSettings = { nav.navigate("settings") },
                    onFavorites = {
                        humidorTabRequest = 1
                        nav.navigate("humidor") {
                            popUpTo(nav.graph.findStartDestination().id) { saveState = true }
                            launchSingleTop = true; restoreState = true
                        }
                    }
                )
            }
            composable("settings") {
                SettingsScreen(
                    onBack = { nav.popBackStack() },
                    onPaywall = { nav.navigate("paywall") }
                )
            }
            composable("paywall") {
                PaywallScreen(onBack = { nav.popBackStack() })
            }
        }
    }
}

// Egen tab-bar: 4 faner (Utforsk · Journal | Humidor · Profil) med hevet
// senter-skann-knapp, som iOS. Aktiv fane = aksent-flate bak hvitt ikon.
// Aktivitet-fanen er fjernet sammen med resten av det sosiale laget.
@Composable
private fun SederTabBar(selected: String, onTab: (String) -> Unit, onScan: () -> Unit) {
    Box(Modifier.fillMaxWidth()) {
        Surface(color = MaterialTheme.colorScheme.surface, shadowElevation = 8.dp) {
            Row(
                Modifier.fillMaxWidth().navigationBarsPadding().height(62.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                TabItem("Utforsk", Icons.Outlined.Explore, selected == "explore",
                    Modifier.weight(1f)) { onTab("explore") }
                TabItem("Journal", Icons.AutoMirrored.Outlined.MenuBook, selected == "journal",
                    Modifier.weight(1f)) { onTab("journal") }
                Spacer(Modifier.width(66.dp))
                TabItem("Humidor", Icons.Filled.Inventory2, selected == "humidor",
                    Modifier.weight(1f)) { onTab("humidor") }
                TabItem("Profil", Icons.Outlined.Person, selected == "profile",
                    Modifier.weight(1f)) { onTab("profile") }
            }
        }
        // Hevet senter-skann
        Surface(
            shape = CircleShape,
            color = MaterialTheme.colorScheme.primary,
            shadowElevation = 6.dp,
            modifier = Modifier.align(Alignment.TopCenter).offset(y = (-16).dp).size(58.dp)
        ) {
            Box(Modifier.clickable(onClick = onScan), contentAlignment = Alignment.Center) {
                Icon(Icons.Outlined.CenterFocusWeak, "Skann",
                    tint = MaterialTheme.colorScheme.onPrimary, modifier = Modifier.size(28.dp))
            }
        }
    }
}

@Composable
private fun TabItem(label: String, icon: ImageVector, selected: Boolean, modifier: Modifier, onClick: () -> Unit) {
    val accent = MaterialTheme.colorScheme.primary
    val inactive = MaterialTheme.colorScheme.onSurfaceVariant
    Column(
        modifier.clickable(onClick = onClick).padding(vertical = 6.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            Modifier.size(width = 46.dp, height = 32.dp).clip(RoundedCornerShape(10.dp))
                .background(if (selected) androidx.compose.ui.graphics.Color(0xFFE0D2BA)
                            else androidx.compose.ui.graphics.Color.Transparent),
            contentAlignment = Alignment.Center
        ) {
            Icon(icon, label, tint = if (selected) accent else inactive,
                modifier = Modifier.size(24.dp))
        }
        Text(label, fontSize = 11.sp, color = if (selected) accent else inactive)
    }
}
