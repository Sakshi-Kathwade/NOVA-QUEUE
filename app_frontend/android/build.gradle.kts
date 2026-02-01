buildscript {
    
    repositories {
        google()
        mavenCentral()  // Already present, but ensure it's prioritized
        // Add this if needed: maven { url = uri("https://repo1.maven.org/maven2/") }
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.4")
    }}

allprojects {
    repositories {
        google()
        mavenCentral()
        // Add this if needed: maven { url = uri("https://repo1.maven.org/maven2/") }
    }
}

// ...existing code...

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
