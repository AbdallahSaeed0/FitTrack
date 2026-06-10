allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Force all Flutter plugin subprojects to compile against the app compileSdk.
// Fixes stale compileSdkVersion on older plugins (e.g. android:attr/lStar not found).
subprojects {
    fun configureLibraryCompileSdk() {
        extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
            compileSdk = 36
        }
    }
    pluginManager.withPlugin("com.android.library") {
        configureLibraryCompileSdk()
    }
    if (state.executed) {
        configureLibraryCompileSdk()
    } else {
        afterEvaluate { configureLibraryCompileSdk() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
