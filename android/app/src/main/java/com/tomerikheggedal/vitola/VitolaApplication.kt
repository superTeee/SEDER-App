package com.tomerikheggedal.vitola

import android.app.Application
import coil.ImageLoader
import coil.ImageLoaderFactory
import coil.disk.DiskCache
import coil.memory.MemoryCache
import com.tomerikheggedal.vitola.data.ProManager

// Felles Coil-oppsett for alle AsyncImage-kall (motsvarer iOS/Kingfisher-polish):
//  • myk innfading når bildet er ferdig lastet
//  • minne- + diskcache slik at andre gangs lasting er umiddelbar
class VitolaApplication : Application(), ImageLoaderFactory {

    override fun onCreate() {
        super.onCreate()
        // Konfigurer RevenueCat (no-op til goog_-nøkkel er satt i ProConfig).
        ProManager.configure(this)
    }

    override fun newImageLoader(): ImageLoader =
        ImageLoader.Builder(this)
            .crossfade(200)                       // innfading (som iOS .fade(0.15))
            .memoryCache {
                MemoryCache.Builder(this)
                    .maxSizePercent(0.25)         // opptil 25 % av app-minnet
                    .build()
            }
            .diskCache {
                DiskCache.Builder()
                    .directory(cacheDir.resolve("image_cache"))
                    .maxSizeBytes(150L * 1024 * 1024)  // 150 MB på disk
                    .build()
            }
            // Supabase-URLene er versjonert (?v=...) ved nye opplastinger, så vi
            // kan cache aggressivt uansett cache-headere fra serveren.
            .respectCacheHeaders(false)
            .build()
}
