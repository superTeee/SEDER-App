package com.tomerikheggedal.vitola

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.tomerikheggedal.vitola.data.Supa
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
                VitolaApp()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Appen kjører allerede når redirecten kommer tilbake fra nettleseren.
        Supa.client.handleDeeplinks(intent)
    }
}
