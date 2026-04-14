plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.teapodstream.teapodstream"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    defaultConfig {
        applicationId = "com.teapodstream.teapodstream"
        minSdk = 29  // Required by teapod-tun2socks AAR (getConnectionOwnerUid)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Ограничиваем архитектуры в APK согласно целевой платформе
        val targetPlatform = project.findProperty("target-platform") as String?
        val targetAbi = when (targetPlatform) {
            "android-arm64" -> "arm64-v8a"
            "android-x64" -> "x86_64"
            else -> null
        }
        
        if (targetAbi != null) {
            ndk {
                abiFilters.clear()
                abiFilters.add(targetAbi)
            }
        }
    }

    packaging {
        jniLibs {
            val targetPlatform = project.findProperty("target-platform") as String?
            val targetAbi = when (targetPlatform) {
                "android-arm64" -> "arm64-v8a"
                "android-x64" -> "x86_64"
                else -> null
            }
            if (targetAbi != null) {
                listOf("arm64-v8a", "armeabi-v7a", "x86", "x86_64").forEach { abi ->
                    if (abi != targetAbi) {
                        excludes.add("lib/$abi/**")
                    }
                }
            }
        }
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Динамический выбор AAR в зависимости от целевой архитектуры
    val targetPlatform = project.findProperty("target-platform") as String?
    val abi = when (targetPlatform) {
        "android-arm64" -> "arm64-v8a"
        "android-x64" -> "x86_64"
        else -> null
    }

    if (abi != null) {
        implementation(files("libs/teapod-tun2socks-$abi.aar"))
    } else {
        // Для debug-сборок или если архитектура не указана явно, подключаем все доступные для данного ABI
        implementation(fileTree("libs") { include("teapod-tun2socks-*.aar") })
    }
}

flutter {
    source = "../.."
}
