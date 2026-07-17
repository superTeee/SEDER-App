package com.tomerikheggedal.vitola.ui

import android.graphics.Bitmap
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.compose.runtime.Composable
import com.canhub.cropper.CropImageContract
import com.canhub.cropper.CropImageContractOptions
import com.canhub.cropper.CropImageOptions

// Gjenbrukbar «velg + beskjær»-knapp (iOS bruker Mantis). Åpner galleri, lar
// brukeren beskjære (fast forhold hvis oppgitt, ellers fritt), og gir tilbake
// Uri-en til det beskårne bildet. Returnerer en lambda som starter flyten.
@Composable
fun rememberCropPicker(aspectX: Int = 0, aspectY: Int = 0, onCropped: (Uri) -> Unit): () -> Unit {
    val launcher = rememberLauncherForActivityResult(CropImageContract()) { result ->
        if (result.isSuccessful) result.uriContent?.let(onCropped)
    }
    return {
        launcher.launch(
            CropImageContractOptions(
                uri = null,
                cropImageOptions = CropImageOptions(
                    imageSourceIncludeCamera = false,
                    imageSourceIncludeGallery = true,
                    aspectRatioX = if (aspectX > 0) aspectX else 1,
                    aspectRatioY = if (aspectY > 0) aspectY else 1,
                    fixAspectRatio = aspectX > 0 && aspectY > 0,
                    outputCompressFormat = Bitmap.CompressFormat.JPEG,
                    outputCompressQuality = 85,
                )
            )
        )
    }
}
