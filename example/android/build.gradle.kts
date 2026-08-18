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
// Some plugins hardcode an old compileSdk in their own build.gradle while the
// AndroidX libraries they depend on require 34+, which fails
// :<plugin>:checkDebugAarMetadata. Of the 130 resolved packages only
// image_cropper 9.1.0 does this (it pins 33). Raise just the modules that sit
// below the floor and leave every compliant module untouched.
// Delete this once image_cropper is upgraded (12.2.1 ships a modern config).
//
// This must be registered BEFORE the evaluationDependsOn(":app") block below:
// that block evaluates :app immediately, and afterEvaluate cannot be added to
// an already-evaluated project.
val compileSdkFloor = 34

subprojects {
    afterEvaluate {
        val androidExtension = extensions.findByName("android")
        if (androidExtension != null) {
            androidExtension.withGroovyBuilder {
                val current = ("getCompileSdkVersion"() as? String)
                    ?.substringAfter("android-")
                    ?.toIntOrNull()
                if (current != null && current < compileSdkFloor) {
                    logger.lifecycle(
                        "Raising ${project.name} compileSdk $current -> $compileSdkFloor",
                    )
                    "setCompileSdkVersion"(compileSdkFloor)
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
