package com.tomerikheggedal.vitola.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.outlined.DynamicFeed
import androidx.compose.material.icons.outlined.Explore
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.navArgument
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.tomerikheggedal.vitola.ui.detail.CigarDetailScreen
import com.tomerikheggedal.vitola.ui.explore.BrandCigarsScreen
import com.tomerikheggedal.vitola.ui.explore.ExploreScreen
import com.tomerikheggedal.vitola.ui.feed.FeedScreen
import com.tomerikheggedal.vitola.ui.humidor.HumidorDetailScreen
import com.tomerikheggedal.vitola.ui.humidor.HumidorScreen
import com.tomerikheggedal.vitola.ui.journal.JournalScreen
import com.tomerikheggedal.vitola.ui.profile.FriendsScreen
import com.tomerikheggedal.vitola.ui.profile.ProfileScreen
import com.tomerikheggedal.vitola.ui.profile.SettingsScreen
import com.tomerikheggedal.vitola.ui.profile.UserProfileScreen
import com.tomerikheggedal.vitola.ui.theme.ThemeState

private data class Tab(val route: String, val label: String)

@Composable
fun VitolaApp() {
    val nav = rememberNavController()
    val tabs = listOf(
        Tab("feed", "Feed"), Tab("explore", "Utforsk"), Tab("humidor", "Humidor"),
        Tab("journal", "Journal"), Tab("profile", "Profil")
    )

    val backStack by nav.currentBackStackEntryAsState()
    val current = backStack?.destination?.route
    // Basisrute uten query-argumenter (f.eks. "humidor?tab={tab}" → "humidor").
    val currentBase = current?.substringBefore("?")

    // Behold markert fane også når man går innover i detaljer (som iOS).
    // Oppdateres kun når man lander på en topp-fane, ellers holdes forrige.
    var selectedTab by remember { mutableStateOf("explore") }
    LaunchedEffect(currentBase) {
        if (currentBase in listOf("feed", "explore", "humidor", "journal", "profile")) {
            selectedTab = currentBase!!
        }
    }

    // Hvit tab-tekst i dark mode; accent i light mode (hvit ville forsvunnet på hvit bar).
    val darkMode = ThemeState.isDark(isSystemInDarkTheme())
    val tabTextColor = if (darkMode) Color.White else MaterialTheme.colorScheme.primary

    Scaffold(
        // Ikke legg statusbar-padding på innholdet — hver skjerms egen TopAppBar
        // håndterer det. Ellers dobles luften over titlene.
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        bottomBar = {
            // Tab-baren står alltid synlig (som iOS) — også innover i detaljer.
            NavigationBar(containerColor = MaterialTheme.colorScheme.surface) {
                tabs.forEach { tab ->
                    NavigationBarItem(
                        selected = selectedTab == tab.route,
                            colors = NavigationBarItemDefaults.colors(
                                selectedIconColor = if (darkMode) Color.White else MaterialTheme.colorScheme.primary,
                                unselectedIconColor = MaterialTheme.colorScheme.primary,
                                selectedTextColor = tabTextColor,
                                unselectedTextColor = tabTextColor,
                                indicatorColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f),
                            ),
                            onClick = {
                                nav.navigate(tab.route) {
                                    popUpTo(nav.graph.findStartDestination().id) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            icon = {
                                Icon(
                                    when (tab.route) {
                                        "feed" -> Icons.Outlined.DynamicFeed
                                        "explore" -> Icons.Outlined.Explore
                                        "journal" -> Icons.AutoMirrored.Outlined.MenuBook
                                        "profile" -> Icons.Outlined.Person
                                        else -> Icons.Filled.Inventory2
                                    },
                                    contentDescription = tab.label
                                )
                            },
                        label = { Text(tab.label) }
                    )
                }
            }
        }
    ) { padding ->
        NavHost(
            navController = nav,
            startDestination = "explore",
            modifier = Modifier.padding(padding)
        ) {
            composable("feed") {
                FeedScreen(onUser = { nav.navigate("user/${it}") })
            }
            composable("user/{id}") { entry ->
                UserProfileScreen(
                    userId = entry.arguments?.getString("id").orEmpty(),
                    onBack = { nav.popBackStack() }
                )
            }
            composable("explore") {
                ExploreScreen(
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
            composable(
                "humidor?tab={tab}",
                arguments = listOf(navArgument("tab") { type = NavType.IntType; defaultValue = 0 })
            ) { entry ->
                HumidorScreen(
                    initialTab = entry.arguments?.getInt("tab") ?: 0,
                    onHumidor = { nav.navigate("humidorDetail/${it}") },
                    onCigar = { nav.navigate("cigar/${it}") }
                )
            }
            composable("humidorDetail/{id}") { entry ->
                HumidorDetailScreen(
                    id = entry.arguments?.getString("id").orEmpty(),
                    onBack = { nav.popBackStack() },
                    onCigar = { nav.navigate("cigar/${it}") }
                )
            }
            composable("journal") {
                JournalScreen(onCigar = { nav.navigate("cigar/${it}") })
            }
            composable("profile") {
                ProfileScreen(
                    onSettings = { nav.navigate("settings") },
                    onFriends = { nav.navigate("friends") },
                    onFavorites = { nav.navigate("humidor?tab=1") }
                )
            }
            composable("settings") { SettingsScreen(onBack = { nav.popBackStack() }) }
            composable("friends") {
                FriendsScreen(
                    onBack = { nav.popBackStack() },
                    onUser = { nav.navigate("user/${it}") }
                )
            }
        }
    }
}
