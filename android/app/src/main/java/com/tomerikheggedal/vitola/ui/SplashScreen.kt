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

// Oppstartssekvens — speiler iOS (LaunchSplashView):
//   0,0 → 1,0 s   fotoet alene
//   1,0 → 2,0 s   sort lag fader inn til 10 %
//   2,0 → 3,0 s   hold
//   3,0 → 4,0 s   logoen fader inn
//   4,0 → 6,5 s   hold
//   6,5 s         splashen glir ut til venstre (0,3 s)
@Composable
fun SplashScreen(onFinish: () -> Unit) {
    val screenWidthPx = with(LocalConfiguration.current) { screenWidthDp.toFloat() }

    val dim = remember { Animatable(0f) }        // overlay #403E3B 0 → 0,40
    val logoAlpha = remember { Animatable(0f) }  // logo 0 → 1
    val slideX = remember { Animatable(0f) }     // hele splashen glir ut

    LaunchedEffect(Unit) {
        delay(1000)                                              // 1. foto alene
        dim.animateTo(0.40f, tween(1500))                       // 2. overlay-lag fader rolig inn
        delay(800)                                               // 3. hold
        logoAlpha.animateTo(1f, tween(1000))                    // 4. logo inn
        delay(2500)                                              // 5. hold
        slideX.animateTo(-screenWidthPx, tween(300))            // 6. glir ut
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
            contentDescription = "Vitola",
            alpha = logoAlpha.value,
            modifier = Modifier
                .align(Alignment.Center)
                .offset(y = (-32).dp)
                .size(width = 180.dp, height = 166.dp)
        )
    }
}
