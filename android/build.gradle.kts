// Top-level build file where you can add configuration options common to all sub-projects/modules.

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Android Gradle Pluginのバージョンを最新の安定版に更新
        classpath("com.android.tools.build:gradle:8.4.2") 
        // Kotlin Gradle PluginのバージョンをAGPの推奨バージョンに合わせる
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.23") 
        classpath("com.google.gms:google-services:4.4.2") // Google Services Plugin (Firebase用)
    }
}

// allprojectsブロックはsettings.gradle.ktsで一元管理されるため削除済み

// カスタムビルドディレクトリの設定 (Kotlin DSL構文に修正)
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
