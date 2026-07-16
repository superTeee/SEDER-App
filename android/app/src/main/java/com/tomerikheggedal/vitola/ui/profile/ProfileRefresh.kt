package com.tomerikheggedal.vitola.ui.profile

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue

// Delt signal så profilsiden laster på nytt når noe redigeres i Innstillinger.
object ProfileRefresh {
    var version by mutableIntStateOf(0)
        private set

    fun bump() { version++ }
}
