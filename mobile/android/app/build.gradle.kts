import java.util.Properties
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// 載入 keystore 配置
fun getKeystoreProperties(flavorName: String): Properties {
    val keystorePropertiesFile = rootProject.file("app/keystore/${flavorName}/key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(keystorePropertiesFile.inputStream())
    }
    return keystoreProperties
}

android {
    namespace = "com.relaygo.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("customerRelease") {
            val customerKeystoreProperties = getKeystoreProperties("customer")
            keyAlias = customerKeystoreProperties["keyAlias"] as String?
            keyPassword = customerKeystoreProperties["keyPassword"] as String?
            storeFile = customerKeystoreProperties["storeFile"]?.let { file("keystore/customer/$it") }
            storePassword = customerKeystoreProperties["storePassword"] as String?
        }
        create("driverRelease") {
            val driverKeystoreProperties = getKeystoreProperties("driver")
            keyAlias = driverKeystoreProperties["keyAlias"] as String?
            keyPassword = driverKeystoreProperties["keyPassword"] as String?
            storeFile = driverKeystoreProperties["storeFile"]?.let { file("keystore/driver/$it") }
            storePassword = driverKeystoreProperties["storePassword"] as String?
        }
    }

    flavorDimensions += "app"
    productFlavors {
        create("customer") {
            dimension = "app"
            applicationId = "com.relaygo.customer"
            versionNameSuffix = "-customer"
            resValue("string", "app_name", "Relay GO")
            signingConfig = signingConfigs.getByName("customerRelease")
        }
        create("driver") {
            dimension = "app"
            applicationId = "com.relaygo.driver"
            versionNameSuffix = "-driver"
            resValue("string", "app_name", "Relay GO Driver")
            signingConfig = signingConfigs.getByName("driverRelease")
        }
    }

    buildTypes {
        release {
            // 簽名配置將在 productFlavors 中設定
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
