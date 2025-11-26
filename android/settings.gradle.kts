pluginManagement {
    // 강제 Flutter SDK 경로 지정 (한글 경로로 인한 Gradle includeBuild 문제 회피)
    val flutterSdkPath = "C:/src/flutter"

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    // Google Services Gradle plugin for Firebase (Android)
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")