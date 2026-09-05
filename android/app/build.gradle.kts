import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// La firma release non è memorizzata nel repository. In locale Gradle legge
// android/key.properties; in CI usa le variabili create dai GitHub Actions
// Secrets. Le variabili d'ambiente hanno precedenza, così password e alias non
// vengono mai scritti in un file della checkout CI.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { stream ->
        keystoreProperties.load(stream)
    }
}

fun releaseSigningValue(environmentVariable: String, propertyName: String): String? =
    System.getenv(environmentVariable)?.takeIf { it.isNotBlank() }
        ?: keystoreProperties.getProperty(propertyName)?.takeIf { it.isNotBlank() }

val releaseStoreFile = releaseSigningValue("ANDROID_KEYSTORE_PATH", "storeFile")
val releaseStorePassword = releaseSigningValue("ANDROID_KEYSTORE_PASSWORD", "storePassword")
val releaseKeyAlias = releaseSigningValue("ANDROID_KEY_ALIAS", "keyAlias")
val releaseKeyPassword = releaseSigningValue("ANDROID_KEY_PASSWORD", "keyPassword")
val isReleaseSigningConfigured = listOf(
    releaseStoreFile,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { !it.isNullOrBlank() }

android {
    namespace = "it.idroriparto.idroriparto"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "it.idroriparto.idroriparto"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            abiFilters.clear()
            abiFilters.add("arm64-v8a")
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = releaseKeyAlias
            keyPassword = releaseKeyPassword
            storeFile = releaseStoreFile?.let { file(it) }
            storePassword = releaseStorePassword
        }
    }

    buildTypes {
        release {
            // Mai firmare le release con la chiave debug: una firma stabile è
            // necessaria affinché Android le installi come aggiornamenti.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// Una build debug resta possibile senza chiavi private. Qualunque task di
// release, invece, fallisce prima di produrre un APK non aggiornabile.
tasks.configureEach {
    if (name.contains("Release", ignoreCase = true)) {
        doFirst {
            check(isReleaseSigningConfigured) {
                "La firma Android release non è configurata. Crea android/key.properties " +
                    "oppure configura i GitHub Actions Secrets descritti in docs/android-signing.md."
            }
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
