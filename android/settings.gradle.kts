import java.io.File
import java.io.FileInputStream
import java.io.InputStream
import java.util.Properties
import org.gradle.kotlin.dsl.* // 'extra' プロパティを使用するためにインポートは残しておく

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    plugins {
        id("dev.flutter.flutter-plugin-apply") version "1.0.0" apply false
        // Android Gradle Pluginのバージョンは、ご自身のAndroid Studioやプロジェクトの要件に合わせてください
        id("com.android.application") version "8.4.1" apply false
        id("org.jetbrains.kotlin.android") version "1.9.0" apply false
        id("org.gradle.toolchains.foojay-resolver-convention") version "0.8.0" apply false
    }
}

// local.propertiesからFlutter SDKパスを取得するロジック
val properties = Properties()
val localPropertiesFile = File(settings.rootDir, "local.properties")
if (localPropertiesFile.exists()) {
    FileInputStream(localPropertiesFile).use { input: InputStream -> properties.load(input) }
}
val flutterSdkPath = System.getenv("FLUTTER_ROOT") ?: properties.getProperty("flutter.sdk")

// Flutter SDKパスが設定されていることを確認
assert(flutterSdkPath != null) { "flutter.sdk not set in local.properties or FLUTTER_ROOT environment variable." }

// ★★★ ここを変更: rootProject.extra.set の行を削除 ★★★
// rootProject.extra.set("flutterSdkPath", flutterSdkPath) // この行を削除

// FlutterのGradleツールをビルドに含める
// この includeBuild が、FlutterのビルドシステムにSDKパスを認識させる主要な方法です
includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "fujitake_app"

include(":app")