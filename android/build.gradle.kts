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
    afterEvaluate {
        if (plugins.hasPlugin("com.android.library")) {
            val androidExtension = extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
            if (androidExtension != null) {
                if (androidExtension.namespace == null) {
                    if (name == "flutter_html_to_pdf") {
                        androidExtension.namespace = "com.afur.flutter_html_to_pdf"
                    } else {
                        androidExtension.namespace = "com.example.${name.replace("-", "_")}"
                    }
                }
                androidExtension.compileSdk = 36
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
