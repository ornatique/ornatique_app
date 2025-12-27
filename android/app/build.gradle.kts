    import java.util.Properties
import java.io.FileInputStream
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.10.0"))
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.8.22")
    //implementation("com.android.tools:desugar_jdk_libs:2.0.3")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // TODO: Add the dependencies for Firebase products you want to use
    // When using the BoM, don't specify versions in Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")


    // Add the dependencies for any other desired Firebase products
    // https://firebase.google.com/docs/android/setup#available-libraries
}

// Load keystore.properties file from project root
val keystoreProperties = Properties().apply {
    val file = rootProject.file("keystore.properties")
    if (file.exists()) {
        load(FileInputStream(file))
        println("keyAlias = ${getProperty("keyAlias")}")
        println("keyPassword = ${getProperty("keyPassword")}")
        println("storeFile = ${getProperty("storeFile")}")
        println("storePassword = ${getProperty("storePassword")}")
    } else {
        throw GradleException("keystore.properties file not found at path: $file")
    }
}
android {
    namespace = "com.ornatique"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ornatique"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
                ?: throw GradleException("keyAlias missing in keystore.properties")
            keyPassword = keystoreProperties.getProperty("keyPassword")
                ?: throw GradleException("keyPassword missing in keystore.properties")
            storeFile = file(
                keystoreProperties.getProperty("storeFile")
                    ?: throw GradleException("storeFile missing in keystore.properties")
            )
            storePassword = keystoreProperties.getProperty("storePassword")
                ?: throw GradleException("storePassword missing in keystore.properties")
        }
    }

    buildTypes {
        getByName("debug") {
            // Optional: you can specify debug signingConfig here if needed
        }
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            // Uncomment if you want to enable minify and shrink resources
            // isMinifyEnabled = false
            // isShrinkResources = false
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }
}

flutter {
    source = "../.."
}
