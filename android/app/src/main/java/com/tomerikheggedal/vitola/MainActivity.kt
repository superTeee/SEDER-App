package com.tomerikheggedal.vitola

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.tomerikheggedal.vitola.ui.VitolaApp
import com.tomerikheggedal.vitola.ui.theme.VitolaTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            VitolaTheme {
                VitolaApp()
            }
        }
    }
}
