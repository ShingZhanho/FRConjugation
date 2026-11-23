# Kotlin/JVM

Package identity: `com.jacobshing:frconjugation`. Import
`com.jacobshing.frconjugation.*` to include the typed extension methods.
The library emits Java 8 bytecode and bundles its rules without runtime dependencies.
Use a JDK supported by Gradle 9.9.2 to build (locally validated with JDK 27).

```sh
cd kotlin
./gradlew build
./gradlew sourcesJar
./gradlew publishToMavenLocal
```

Install from [Maven Central](https://central.sonatype.com/artifact/com.jacobshing/frconjugation)
by configuring `mavenCentral()` and
`implementation("com.jacobshing:frconjugation:5.1.1")` in the consuming project.
Use `mavenLocal()` instead when testing a locally published build.

```kotlin
import com.jacobshing.frconjugation.*

val c = Conjugator.getShared()
val form = c.conjugate("manger", Voice.ACTIVE_AVOIR, Mode.INDICATIF,
    Tense.PRESENT, Person.FIRST_PLURAL_MASCULINE) // "mangeons"
val forms = c.conjugate("manger")
val prefix = c.commonPrefix("manger") // "mang"
```

`conjugate`, `rawInferredConjugation`, and `guessConjugation` each have five
scopes, from one person to all voices. Bulk results are nested maps ordered as
voice → mode → tense → person; supplied selectors remove leading levels.
Missing single/all-voice results are nullable; other missing collections are empty.
`participle`, `participles`, and `gerondif` have raw-inference and guess counterparts.
Participle collections map tense to spelling, without person keys.

`conjugateAlternative`, `participleAlternative`, and `hasAlternative…` expose
catalogue variants. Use `getPronoun`, `conjugateWithPronoun`, and
`conjugateAlternativeWithPronoun` for subjects. Prefix methods are `commonPrefix`,
`rawInferredCommonPrefix`, and `guessCommonPrefix`; an empty prefix is valid.

`voices`, `modes`, `tenses`, and `persons` discover available structure.
`allVerbs`, `verbCount`, `hasVerb`, `hasHomonyms`, `homonymCount`, `homonymIndices`,
`isHAspire`, `blocksElisionAndLiaison`, `is1990Reform`, and `reformVariant` expose
listing and metadata. Optional `homonymIndex` selects a positive indexed entry.
Enums expose `label` and `fromLabel`; Person also exposes `pronoun` and `shortLabel`.

Suspend functions ending in `Async`, plus `Conjugator.load()` and
`Conjugator.getSharedAsync()`, dispatch to a bounded daemon worker pool. They do
not require kotlinx.coroutines or interrupt running work on cancellation.
Resource failures throw `ConjugationException`. Synchronous calls run on the caller.
KDoc in the sources JAR documents individual signatures and contracts.
