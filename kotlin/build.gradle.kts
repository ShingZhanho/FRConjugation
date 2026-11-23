plugins {
    kotlin("jvm") version "2.2.21"
    `maven-publish`
}
group = "com.jacobs"
version = "5.0.1"
repositories { mavenCentral() }
java {
    withSourcesJar()
    sourceCompatibility = JavaVersion.VERSION_1_8
    targetCompatibility = JavaVersion.VERSION_1_8
}
kotlin {
    compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8)
}
tasks.processResources {
    from("../catalogue/catalogue.fcr") {
        into("com/jacobs/frconjugation")
    }
}
tasks.processTestResources {
    from("../tests/conformance.tsv", "../tests/typed-api.tsv")
}
dependencies { testImplementation(kotlin("test-junit")) }
tasks.test { useJUnit() }
publishing {
    publications {
        create<MavenPublication>("library") {
            from(components["java"])
            artifactId = "frconjugation"
        }
    }
}
tasks.register<JavaExec>("conformanceDump") {
    dependsOn(tasks.testClasses)
    classpath = sourceSets.test.get().runtimeClasspath
    mainClass.set("com.jacobs.frconjugation.Conformance")
    args(
        layout.buildDirectory
            .file("conformance.bin")
            .get()
            .asFile.absolutePath,
    )
}
