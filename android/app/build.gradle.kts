import org.gradle.jvm.toolchain.JavaLanguageVersion

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin") // バージョン指定は引き続きここには不要
}

android {
    namespace = "com.example.fujitake_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Java 17を使用するように設定
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.fujitake_app"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// ★★★ この repositories ブロックを以下の内容で追加・更新してください ★★★
repositories {
    google() // Google Mavenリポジトリは必須
    mavenCentral() // Maven Centralリポジトリも必須

    // Flutterのローカルビルド済みアーティファクトのためのリポジトリ
    // これらのパスは、Flutterがビルド時にエンジンAARファイルを配置する場所です。
    // これらが正しくないと、x86_64_debugなどのアーティファクトが見つかりません。
    // 前回もお伝えしましたが、改めて正確に記述されているか確認してください。
    maven { url = uri("$buildDir/host/outputs/repo") } // Android Gradle Plugin 7.x以降でよく使われる
    maven { url = uri("$flutter.buildDir/intermediates/flutter/debug") }
    maven { url = uri("$flutter.buildDir/intermediates/flutter/profile") }
    maven { url = uri("$flutter.buildDir/intermediates/flutter/release") }

    // （参考：これらは通常不要ですが、もし上記で解決しない場合に試す候補）
    // maven { url = uri("$flutter.sdkPath/bin/cache/artifacts/engine/") }
}


flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
    implementation("androidx.multidex:multidex:2.0.1")
}