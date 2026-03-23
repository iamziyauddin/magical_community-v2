import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties from file
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.mindmesh.magicalcommunity"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = "27.0.12077973" // Commented out - using default NDK

    compileOptions {
    // AGP 8.7 requires JDK 17 toolchain; source/target can remain 11 if needed
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
    // Align Kotlin JVM target with Java 17 to satisfy AGP 8.7 toolchain
    jvmTarget = JavaVersion.VERSION_17.toString()
        freeCompilerArgs = freeCompilerArgs + listOf("-Xjvm-default=all")
    }

    // Ensure Kotlin toolchain uses Java 17 for AGP 8.7
    kotlin {
        jvmToolchain(17)
    }

    // Signing configurations
    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mindmesh.magicalcommunity"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Use the release signing config if available, otherwise fall back to debug
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Disable code shrinking and resource shrinking for now
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
}

// Workaround: delete stale Flutter asset outputs before Flutter compile tasks,
// avoiding Windows "Cannot create a file when that file already exists" (errno 183)
val cleanFlutterAssets by tasks.register<Delete>("cleanFlutterAssets") {
    delete(layout.buildDirectory.dir("intermediates/flutter"))
}

tasks.matching { it.name.startsWith("compileFlutterBuild") }.configureEach {
    dependsOn(cleanFlutterAssets)
}
