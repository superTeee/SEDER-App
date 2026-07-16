package com.tomerikheggedal.vitola.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Inventory2
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
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.tomerikheggedal.vitola.ui.detail.CigarDetailScreen
import com.tomerikheggedal.vitola.ui.explore.BrandCigarsScreen
import com.tomerikheggedal.vitola.ui.explore.ExploreScreen
import com.tomerikheggedal.vitola.ui.humidor.HumidorDetailScreen
import com.tomerikheggedal.vitola.ui.humidor.HumidorScreen
import com.tomerikheggedal.vitola.ui.profile.ProfileScreen

private data class Tab(val route: String, val label: String)

@Composable
fun VitolaApp() {
    val nav = rememberNavController()
    val tabs = listOf(Tab("explore", "Utforsk"), Tab("humidor", "Humidor"), Tab("profile", "Profil"))

    val backStack by nav.currentBackStackEntryAsState()
    val current = backStack?.destination?.route

    Scaffold(
        bottomBar = {
            // Vis bunnlinja kun på topp-fanene, ikke på detalj-/merkeskjermer.
            if (current == "explore" || current == "humidor" || current == "profile") {
                NavigationBar(containerColor = MaterialTheme.colorScheme.surface) {
                    tabs.forEach { tab ->
                        NavigationBarItem(
                            selected = current == tab.route,
                            colors = NavigationBarItemDefaults.colors(
                                selectedIconColor = MaterialTheme.colorScheme.primary,
                                unselectedIconColor = MaterialTheme.colorScheme.primary,
                                selectedTextColor = MaterialTheme.colorScheme.primary,
                                unselectedTextColor = MaterialTheme.colorScheme.primary,
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
                                        "explore" -> Icons.Outlined.Explore
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
        }
    ) { padding ->
        NavHost(
            navController = nav,
            startDestination = "explore",
            modifier = Modifier.padding(padding)
        ) {
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
            composable("humidor") {
                HumidorScreen(onHumidor = { nav.navigate("humidorDetail/${it}") })
            }
            composable("humidorDetail/{id}") { entry ->
                HumidorDetailScreen(
                    id = entry.arguments?.getString("id").orEmpty(),
                    onBack = { nav.popBackStack() },
                    onCigar = { nav.navigate("cigar/${it}") }
                )
            }
            composable("profile") { ProfileScreen() }
        }
    }
}
