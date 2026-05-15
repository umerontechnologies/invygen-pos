import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (!keystorePropertiesFile.exists()) {
    throw GradleException("key.properties not found at: ${keystorePropertiesFile.absolutePath}")
}
keystoreProperties.load(FileInputStream(keystorePropertiesFile))

android {
    namespace = "com.umeron.invygen"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

 //   packaging {
 //   jniLibs {
 //       useLegacyPackaging = true
 //       keepDebugSymbols += listOf("**/*.so")
 //   }
// }

splits {
    abi {
        isEnable = false
    }
}

androidResources {
    noCompress += "so"
}

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.umeron.invygen"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
isShrinkResources = false


        }
    }
}

flutter {
    source = "../.."
}