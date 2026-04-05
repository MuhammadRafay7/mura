import com.android.build.gradle.BaseExtension

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Updated to AGP 9.1.0 for full API 36 support in 2026
        classpath("com.android.tools.build:gradle:9.1.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Force all plugins to use the modern AGP version
    configurations.all {
        resolutionStrategy {
            eachDependency {
                if (requested.group == "com.android.tools.build" && requested.name == "gradle") {
                    useVersion("9.1.0")
                }
            }
        }
    }
}

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android")
            if (android is BaseExtension) {
                // Force all dependencies to compile against API 36 (Android 16)
                android.compileSdkVersion(36)
                android.buildToolsVersion = "36.0.0"
                
                android.defaultConfig {
                    targetSdk = 36
                    multiDexEnabled = true 
                }
            }
        }
    }
}

// Build directory logic
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}