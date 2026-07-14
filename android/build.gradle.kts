allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ إجبار استخدام إصدار أقل من androidx.core
configurations.all {
    resolutionStrategy {
        force("androidx.core:core:1.13.1")
        force("androidx.core:core-ktx:1.13.1")
    }
}

rootProject.layout.buildDirectory.value(
    layout.projectDirectory.dir("../build")
)

subprojects {
    project.layout.buildDirectory.value(
        rootProject.layout.buildDirectory.dir(project.name)
    )
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
