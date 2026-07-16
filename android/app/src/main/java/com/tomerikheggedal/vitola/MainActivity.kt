package com.tomerikheggedal.vitola

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.tomerikheggedal.vitola.data.Supa
import com.tomerikheggedal.vitola.ui.SplashScreen
import com.tomerikheggedal.vitola.ui.VitolaApp
import com.tomerikheggedal.vitola.ui.theme.VitolaTheme
import io.github.jan.supabase.gotrue.handleDeeplinks

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Fanger OAuth-redirecten hvis appen startes fra login-lenken.
        Supa.client.handleDeeplinks(intent)
        enableEdgeToEdge()
        setContent {
            VitolaTheme {
                var showSplash by remember { mutableStateOf(true) }
                Box {
                    VitolaApp()
                    if (showSplash) SplashScreen(onFinish = { showSplash = false })
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
