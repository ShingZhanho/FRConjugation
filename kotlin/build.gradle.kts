plugins {
    kotlin("jvm") version "2.2.21"
    id("org.jetbrains.dokka") version "2.2.0"
    id("com.vanniktech.maven.publish") version "0.37.0"
}
group = "com.jacobshing"
version = "5.1.1"
repositories { mavenCentral() }
java {
    sourceCompatibility = JavaVersion.VERSION_1_8
    targetCompatibility = JavaVersion.VERSION_1_8
}
kotlin {
    compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8)
}
tasks.processResources {
    from("../catalogue/catalogue.fcr") { into("com/jacobshing/frconjugation") }
}
tasks.processTestResources {
    from("../tests/conformance.tsv", "../tests/typed-api.tsv")
}
dependencies { testImplementation(kotlin("test-junit")) }
tasks.test { useJUnit() }
mavenPublishing {
    coordinates("com.jacobshing", "frconjugation", project.version.toString())
    publishToMavenCentral()
    if (providers.gradleProperty("signingInMemoryKey").isPresent) {
        signAllPublications()
    }
    pom {
        name.set("FRConjugation")
        description.set("French conjugation using bundled spelling rules")
        url.set("https://github.com/ShingZhanho/FRConjugation")
        licenses {
            license {
                name.set("Personal and educational use")
                url.set("https://github.com/ShingZhanho/FRConjugation#licence")
                distribution.set("repo")
            }
        }
        developers {
            developer {
                id.set("ShingZhanho")
                name.set("Jacob Shing")
                url.set("https://jacobshing.com")
            }
        }
        scm {
            url.set("https://github.com/ShingZhanho/FRConjugation")
            connection.set("scm:git:https://github.com/ShingZhanho/FRConjugation.git")
            developerConnection.set("scm:git:ssh://git@github.com/ShingZhanho/FRConjugation.git")
        }
    }
}
tasks.register<JavaExec>("conformanceDump") {
    dependsOn(tasks.testClasses)
    classpath = sourceSets.test.get().runtimeClasspath
    mainClass.set("com.jacobshing.frconjugation.Conformance")
    args(layout.buildDirectory.file("conformance.bin").get().asFile.absolutePath)
}
