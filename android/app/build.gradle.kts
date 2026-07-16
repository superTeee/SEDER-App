plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("org.jetbrains.kotlin.plugin.serialization")
}

android {
    namespace = "com.tomerikheggedal.vitola"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.tomerikheggedal.vitola"
        minSdk = 26
        targetSdk = 34
        versionCode = 3
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        compose = true
    }
}

dependencies {
    // Compose
    val composeBom = platform("androidx.compose:compose-bom:2024.09.03")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.activity:activity-compose:1.9.2")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.6")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.6")
    implementation("androidx.navigation:navigation-compose:2.8.1")

    // Bilder (iOS bruker Kingfisher; Coil er Android-motparten)
    implementation("io.coil-kt:coil-compose:2.7.0")

    // Supabase (samme backend som iOS). Postgrest = data, Auth = innlogging.
    // Eksplisitte versjoner (uten BOM) — BOM-en ga ikke versjon til auth-kt.
    implementation("io.github.jan-tennert.supabase:postgrest-kt:2.6.0")
    // I 2.x heter auth-modulen fortsatt gotrue-kt (pakke: io.github.jan.supabase.gotrue).
    implementation("io.github.jan-tennert.supabase:gotrue-kt:2.6.0")
    // Storage — for bilde-opplasting (feed-innlegg).
    implementation("io.github.jan-tennert.supabase:storage-kt:2.6.0")
    implementation("io.ktor:ktor-client-android:2.3.12")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.1")

    // Custom Tabs for nettleser-basert OAuth-redirect
    implementation("androidx.browser:browser:1.8.0")

    debugImplementation("androidx.compose.ui:ui-tooling")
    implementation("androidx.compose.ui:ui-tooling-preview")
}
