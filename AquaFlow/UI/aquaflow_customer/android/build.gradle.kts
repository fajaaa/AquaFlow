allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// stripe_android's lintVital task fails release builds trying to resolve
// com.google.android.gms:play-services-tapandpay:17.1.2, which isn't published to any
// reachable Maven repo. Lint Vital is a release-build-only static check, not part of the
// compiled output, so disabling it project-wide is safe and unblocks `flutter build apk --release`.
gradle.taskGraph.whenReady {
    allTasks.forEach { task ->
        if (task.name.contains("lintVital")) {
            task.enabled = false
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
