package com.tomerikheggedal.vitola

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Density
import com.tomerikheggedal.vitola.data.Supa
import com.tomerikheggedal.vitola.ui.AuthWelcomeScreen
import com.tomerikheggedal.vitola.ui.SplashScreen
import com.tomerikheggedal.vitola.ui.VitolaApp
import com.tomerikheggedal.vitola.ui.theme.CreamBackground
import com.tomerikheggedal.vitola.ui.theme.ThemeState
import com.tomerikheggedal.vitola.ui.theme.VitolaTheme
import io.github.jan.supabase.gotrue.SessionStatus
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.gotrue.handleDeeplinks
import io.github.jan.supabase.gotrue.providers.Google
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Fanger OAuth-redirecten hvis appen startes fra login-lenken.
        Supa.client.handleDeeplinks(intent)
        ThemeState.load(this)
        enableEdgeToEdge()
        setContent {
            VitolaTheme(dark = ThemeState.isDark(isSystemInDarkTheme())) {
                // Begrens skrift-skalering så svært stor systemtekst ikke bryter
                // layouten (faste høyder: søkefelt, chips, FAB). Moderat forstørring
                // (opp til 1,3×) fungerer fortsatt.
                val d = LocalDensity.current
                val capped = Density(d.density, d.fontScale.coerceIn(1f, 1.3f))
                CompositionLocalProvider(LocalDensity provides capped) {
                    val scope = rememberCoroutineScope()
                    val session by Supa.client.auth.sessionStatus.collectAsState()
                    val isAuthed = session is SessionStatus.Authenticated
                    val loadingSession = session is SessionStatus.LoadingFromStorage
                    var skipped by remember { mutableStateOf(false) }
                    var showSplash by remember { mutableStateOf(true) }

                    when {
                        isAuthed || skipped -> Box {
                            VitolaApp()
                            if (showSplash) SplashScreen(onFinish = { showSplash = false })
                        }
                        // Vent på lagret sesjon før velkomstskjermen vises (unngå blink).
                        loadingSession -> Box(Modifier.fillMaxSize().background(CreamBackground))
                        else -> AuthWelcomeScreen(
                            onLogin = { scope.launch { Supa.client.auth.signInWith(Google) } },
                            onSkip = { skipped = true }
                        )
                    }
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Appen kjører allerede når redirecten kommer tilbake fra nettleseren.
        Supa.client.handleDeeplinks(intent)
    }
}
