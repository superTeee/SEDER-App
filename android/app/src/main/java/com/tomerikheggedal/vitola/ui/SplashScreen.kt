package com.tomerikheggedal.vitola.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.tomerikheggedal.vitola.R
import com.tomerikheggedal.vitola.ui.theme.CreamBackground
import kotlinx.coroutines.delay

// Oppstartssekvens — speiler iOS (LaunchSplashView), ca. 3,5 s:
//   0,0 s         foto + overlay (#403E3B, 40 %) fra første frame
//   0,3 → 1,3 s   logoen fader inn
//   1,3 → 3,5 s   hold
//   3,5 s         splashen glir ut til venstre (0,3 s)
// (Starter bevisst med bilde + overlay — den gamle «foto alene»-fasen så ut som
//  en glitch og tok lengre tid.)
@Composable
fun SplashScreen(onFinish: () -> Unit) {
    val screenWidthPx = with(LocalConfiguration.current) { screenWidthDp.toFloat() }

    val dim = remember { Animatable(0.40f) }     // overlay #403E3B til stede fra start
    val logoAlpha = remember { Animatable(0f) }  // logo 0 → 1
    val slideX = remember { Animatable(0f) }     // hele splashen glir ut

    LaunchedEffect(Unit) {
        delay(300)                                               // kort visning av bilde + overlay
        logoAlpha.animateTo(1f, tween(1000))                    // logo inn
        delay(2200)                                              // hold
        slideX.animateTo(-screenWidthPx, tween(300))            // glir ut
        onFinish()
    }

    Box(
        Modifier
            .fillMaxSize()
            .offset(x = slideX.value.dp)
            .background(CreamBackground)
    ) {
        Image(
            painter = painterResource(R.drawable.splash_background),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxSize()
        )
        Box(
            Modifier
                .fillMaxSize()
                .background(Color(0xFF403E3B).copy(alpha = dim.value))
        )
        Image(
            painter = painterResource(R.drawable.vitola_logo),
            contentDescription = "SEDER",
            alpha = logoAlpha.value,
            modifier = Modifier
                .align(Alignment.Center)
                .offset(y = (-32).dp)
                .size(width = 180.dp, height = 166.dp)
        )
    }
}
