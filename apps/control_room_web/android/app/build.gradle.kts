import java.util.Base64

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val offlineDemo = (project.findProperty("dart-defines") as? String)
    ?.split(",")
    ?.any { encoded -> String(Base64.getDecoder().decode(encoded), Charsets.UTF_8) == "AEROTRANS_OFFLINE_DEMO=true" } == true

android {
    namespace = "com.pngtransfer.png_transfer_control_room"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.pngtransfer.png_transfer_control_room"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".demo"
            versionNameSuffix = "-demo"
        }
        release {
            if (offlineDemo) {
                applicationIdSuffix = ".offline"
                versionNameSuffix = "-offline-demo"
                isMinifyEnabled = false
                isShrinkResources = false
            }
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Offline entrypoints bypass Firebase and use a manifest with no network permission.
if (offlineDemo) {
    android.sourceSets.getByName("release").manifest.srcFile("src/offline/AndroidManifest.xml")
    tasks.matching { it.name.endsWith("GoogleServices") }.configureEach { onlyIf { false } }
}
