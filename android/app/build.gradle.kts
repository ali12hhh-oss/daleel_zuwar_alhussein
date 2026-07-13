plugins {
    id("com.android.application")
    id("kotlin-android")
    // يجب أن يُطبَّق إضافة Flutter Gradle بعد إضافتي أندرويد وكوتلن
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.daleelzuwar.alhussein"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // معرّف التطبيق الفريد (Application ID) — غيّره إذا أردت نشره على متجر مختلف
        applicationId = "com.daleelzuwar.alhussein"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // مبدئياً نوقّع نسخة الإصدار بمفتاح التصحيح الافتراضي (Debug) لتسهيل
            // أول بناء تجريبي؛ عند الرغبة بالنشر الفعلي على متجر جوجل بلاي يجب
            // إنشاء مفتاح توقيع خاص (راجع قسم "التوقيع للنشر" في README).
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("androidx.multidex:multidex:2.0.1")
}
