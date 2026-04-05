plugins {
    id("com.android.application")
    id("kotlin-android") // Put this back to match audioplayers
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mura.mura"
    compileSdk = 36 

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Use the traditional block because builtInKotlin is disabled
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.mura.mura"
        minSdk = 24 
        targetSdk = 36 
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("debug")
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}