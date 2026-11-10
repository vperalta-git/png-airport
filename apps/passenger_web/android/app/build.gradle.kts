import java.util.Base64

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") apply false
}

val offlineDemo = (project.findProperty("dart-defines") as? String)
    ?.split(",")
    ?.any { encoded -> String(Base64.getDecoder().decode(encoded), Charsets.UTF_8) == "AEROTRANS_OFFLINE_DEMO=true" } == true
val allRolesDemo = offlineDemo && (project.findProperty("dart-defines") as? String)
    ?.split(",")
    ?.any { encoded -> String(Base64.getDecoder().decode(encoded), Charsets.UTF_8) == "AEROTRANS_ALL_ROLES_DEMO=true" } == true
val connectedReview = (project.findProperty("dart-defines") as? String)
    ?.split(",")
    ?.any { encoded -> String(Base64.getDecoder().decode(encoded), Charsets.UTF_8) == "AEROTRANS_CONNECTED_REVIEW=true" } == true
require(!(offlineDemo && connectedReview)) { "Connected review and offline demo flags cannot be combined." }

// Explicit-options builds must not add Google Services generated resources at
// all: merely skipping its task can still package stale output from another mode.
if (!offlineDemo && !connectedReview) {
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "com.pngtransfer.png_transfer_client"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.pngtransfer.png_transfer_client"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
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
                applicationIdSuffix = if (allRolesDemo) ".offline.allroles" else ".offline"
                versionNameSuffix = if (allRolesDemo) "-offline-all-roles" else "-offline-demo"
                isMinifyEnabled = false
                isShrinkResources = false
            } else if (connectedReview) {
                applicationIdSuffix = ".connected"
                isMinifyEnabled = false
                isShrinkResources = false
            }
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
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
    android.sourceSets.getByName("release").manifest.srcFile(
        if (allRolesDemo) "src/offlineAllRoles/AndroidManifest.xml" else "src/offline/AndroidManifest.xml"
    )
} else if (connectedReview) {
    // Firebase is initialized explicitly with the isolated demo project options.
    // HTTP exceptions exist only for the known local emulator hosts.
    android.sourceSets.getByName("release").manifest.srcFile("src/connected/AndroidManifest.xml")
    android.sourceSets.getByName("release").res.srcDir("src/connected/res")
}
