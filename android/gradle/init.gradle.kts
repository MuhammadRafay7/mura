import com.android.build.gradle.BaseExtension

allprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android")
            if (android is BaseExtension) {
                android.buildToolsVersion = "35.0.0"
                android.compileSdkVersion(35)
            }
        }
    }
}