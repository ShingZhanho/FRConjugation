# FRConjugation for Kotlin/JVM

French verb conjugation using bundled spelling rules learned from the Académie
française catalogue. Query recorded forms, predict unknown verbs, and find shared
spelling for highlighting. Conjugation works offline without a separate model download.

Targets JVM 8 or later. The rules are included in the JAR.

## Install

Add Maven Central and the dependency to your Gradle Kotlin build script:

```kotlin
repositories {
    mavenCentral()
}

dependencies {
    implementation("com.jacobshing:frconjugation:5.2.0")
}
```

Import `com.jacobshing.frconjugation.*` to include the typed extension methods.

## Quick start

```kotlin
import com.jacobshing.frconjugation.*

val c = Conjugator.getShared()
val form = c.conjugate("manger", Voice.ACTIVE_AVOIR, Mode.INDICATIF,
    Tense.PRESENT, Person.FIRST_PLURAL_MASCULINE) // "mangeons"
val forms = c.conjugate("manger")
val prefix = c.commonPrefix("manger") // "mang"
```

## Forms and metadata

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

## Asynchronous use

Suspend functions ending in `Async`, plus `Conjugator.load()` and
`Conjugator.getSharedAsync()`, dispatch to a bounded daemon worker pool. They do
not require kotlinx.coroutines or interrupt running work on cancellation.
Resource failures throw `ConjugationException`. Synchronous calls run on the caller.
KDoc in the sources JAR documents individual signatures and contracts.

## Catalogue and prediction

Catalogue methods return recorded forms. Guess methods return exactly the same
results for known infinitives, including missing forms of defective verbs, and
predict only unknown infinitives. Raw inference can also predict forms for known
verbs; predictions are experimental and may be unattested.

All verb inputs are trimmed, lowercased, and NFC-normalized before lookup.
Internal whitespace is preserved. Common prefixes describe shared spelling across
forms, excluding auxiliaries and pronouns; they are not grammatical stems. An
empty prefix is a valid result, distinct from a missing result.

## More information

See the [source and build instructions](https://github.com/ShingZhanho/FRConjugation#build-and-use) for development,
or [report an issue](https://github.com/ShingZhanho/FRConjugation/issues).
Provided as-is for [personal and educational use](https://github.com/ShingZhanho/FRConjugation#licence).
