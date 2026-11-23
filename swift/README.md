# Swift

Swift 5.6+, macOS 10.15+ or iOS 13+. No external dependencies.

Add the package in Xcode or your manifest:

```swift
.package(url: "https://github.com/ShingZhanho/FRConjugation.git", from: "5.0.1")
```

Import `FRConjugation`. Run builds from the repository root:

```sh
swift build -c release
swift test -c release
```

The root manifest points to this directory. Preserve resource symlinks when
checking out the repository. The standalone Xcode project uses the JSON project
format; regenerate with Xcode 27.2+ and `xcodegen generate --spec swift/project.yml`.

## API

### `Conjugator`

```swift
// Shared singleton (recommended) -- sync
let fr = Conjugator.getShared()

// Shared singleton -- async (won't block the main thread)
let fr = try await Conjugator.getShared()

// Async factory (creates a new instance, non-blocking)
let fr = try await Conjugator.load()

// Load from bundled resources (new instance each time)
let fr = try Conjugator()
```

#### Conjugation

```swift
// Single form
fr.conjugate("parler", voice: .activeAvoir, mode: .indicatif,
             tense: .present, person: .firstSingularMasculine)
// -> "parle"

// All persons for a voice + mode + tense
let forms: [Person: String] = fr.conjugate("avoir", voice: .activeAvoir,
                                           mode: .indicatif, tense: .present)
// [.firstSingularMasculine: "ai", .secondSingularMasculine: "as", ...]

// All tenses and persons for a voice + mode
let indic: [Tense: [Person: String]] = fr.conjugate("finir",
    voice: .activeAvoir, mode: .indicatif)

// All modes, tenses and persons for a voice
let all: [Mode: [Tense: [Person: String]]] = fr.conjugate("aller",
    voice: .activeEtre)

// Everything for a verb (all voices)
let full: [Voice: [Mode: [Tense: [Person: String]]]]? = fr.conjugate("battre")
```

#### Shared spelling for highlighting

```swift
fr.commonPrefix("manger")             // "mang"
fr.commonPrefix("finir")              // "fin", including finîmes
fr.commonPrefix("aller")              // ""
fr.commonPrefix("blorper")            // nil
fr.rawInferredCommonPrefix("blorper") // computed from predictions
fr.guessCommonPrefix("pleuvoir")      // catalogue plus inferred missing slots
```

These methods return the longest common prefix across all available voices,
moods, tenses, participles, and spelling alternatives. They exclude auxiliaries,
leading pronouns, and attached imperative pronouns. Gérondifs use the same
lexical forms as their underlying participles. Accents are significant and
canonical Unicode spellings are normalized. The result describes shared
spelling for display, rather than a grammatical stem.

All three accept `homonymIndex: Int? = nil` and have synchronous and asynchronous
overloads. Catalogue lookup uses exact input. Raw inference normalizes and
validates input like `rawInferredConjugation()`. Guessing preserves all catalogue
alternatives and infers each missing slot, including those of defective verbs.
`nil` means no usable forms, while `""` means a valid empty prefix. Predictions
for arbitrary supported strings remain experimental.

#### Experimental inference and guessing

Each family supports rule inference and catalogue-first guessing.

| Catalogue API | Raw prediction | Catalogue-first guess |
|---|---|---|
| `conjugate()` | `rawInferredConjugation()` | `guessConjugation()` |
| `participle()` | `rawInferredParticiple()` | `guessParticiple()` |
| `participles()` | `rawInferredParticiples()` | `guessParticiples()` |
| `gerondif()` | `rawInferredGerondif()` | `guessGerondif()` |
| `commonPrefix()` | `rawInferredCommonPrefix()` | `guessCommonPrefix()` |

Raw methods lowercase input, trim surrounding whitespace, and try matching
suffixes from longest to shortest. If these rules cannot supply a supported
slot, inference uses the most common catalogue template that supplies it.
Unsupported input or slot combinations return `nil` or an empty collection.
Predictions may include `;` alternatives and unattested spellings.

Guess methods preserve available catalogue answers and infer missing forms,
including in bulk lookups. For defective verbs, use the catalogue methods when
you need only attested forms.

```swift
// Finite forms retain conjugate's signatures and Person argument.
fr.guessConjugation("télétravailler", voice: .activeAvoir, mode: .indicatif,
                    tense: .present, person: .firstSingularMasculine)
fr.rawInferredConjugation("faire", voice: .pronominal, mode: .subjonctif,
                          tense: .present, person: .thirdPluralFeminine)

// Participle gender/number is encoded in Tense; no Person is required.
fr.guessParticiple("enquêter", voice: .activeAvoir, tense: .passeFemininSingulier)
// -> "enquêtée"
let rawParts = fr.rawInferredParticiples("blorper", voice: .activeAvoir)
let parts = fr.guessParticiples("enquêter", voice: .activeAvoir)

// Gérondifs use the existing gerondifPresent / gerondifPasse... tense cases.
fr.guessGerondif("parler", voice: .activeAvoir, tense: .gerondifPresent)
// -> "en parlant"
fr.rawInferredGerondif("blorper", voice: .activeAvoir,
                       tense: .gerondifPasseFemininPluriel)

// Async single-form overloads also match each catalogue family.
let guessedPart = await fr.guessParticiple("podcaster", voice: .activeAvoir,
                                          tense: .passeMasculinSingulier)
```

The conjugation inference APIs have all five synchronous and two asynchronous
`conjugate` overloads, including `homonymIndex`. They handle finite forms only:
`.participe` requests return `nil`/empty, and their bulk results contain no
participles or gérondifs. Nonpersonal collections use `[Tense: String]`, matching
`participles()`, and never duplicate values under person keys. The single-form
participle/gérondif APIs have sync and async variants; participle collections
have the existing synchronous collection shape. Raw gérondifs prepend `en ` to
every alternative in their raw source participle.

Catalogue lookups use the exact input. Inference normalizes the spelling and
resolves known homonyms using the same `homonymIndex`.

#### Variant (Alternative) Forms

Some conjugated forms have alternative spellings (e.g. 1990 reform
variants).  The standard `conjugate` and `participle` methods always
return the primary form.  Use the following methods to access variants:

```swift
// Check if a specific form has an alternative
fr.hasAlternativeForm("abreger", voice: .activeAvoir, mode: .indicatif,
                      tense: .present, person: .firstSingularMasculine)
// -> true

// Get the alternative form
fr.conjugateAlternative("abreger", voice: .activeAvoir, mode: .indicatif,
                        tense: .present, person: .firstSingularMasculine)
// -> "abrege" (1990 reform spelling)

// Participle variants
fr.hasAlternativeParticiple("verb", voice: .activeAvoir, tense: .present)
fr.participleAlternative("verb", voice: .activeAvoir, tense: .present)
```

All variant methods have async overloads.

#### Pronoun & Conjugation with Pronoun

`getPronoun` returns the contextual French subject pronoun for a
conjugated form.  It handles elision (`je` becomes `j'` before a vowel
or h-muet) and prepends `que`/`qu'` for the subjonctif mood.

`conjugateWithPronoun` and `conjugateAlternativeWithPronoun` combine
the pronoun and conjugated form into a single string.  For imperatif, the bare conjugated form is returned. Use the dedicated
participle methods for personless forms.

```swift
fr.getPronoun("aimer", voice: .activeAvoir, mode: .indicatif,
              tense: .present, person: .firstSingularMasculine)
// -> "j'"   (trailing apostrophe -- elision before vowel)

fr.getPronoun("parler", voice: .activeAvoir, mode: .indicatif,
              tense: .present, person: .firstSingularMasculine)
// -> "je "  (trailing space -- no elision)

fr.getPronoun("parler", voice: .activeAvoir, mode: .subjonctif,
              tense: .present, person: .thirdSingularMasculine)
// -> "qu'il "  (que contracts before il)

fr.getPronoun("parler", voice: .activeAvoir, mode: .imperatif,
              tense: .present, person: .secondSingularMasculine)
// -> nil  (no subject pronoun for imperatif)

fr.conjugateWithPronoun("aimer", voice: .activeAvoir, mode: .indicatif,
                        tense: .present, person: .firstSingularMasculine)
// -> "j'aime"

fr.conjugateWithPronoun("parler", voice: .activeAvoir, mode: .subjonctif,
                        tense: .present, person: .thirdSingularMasculine)
// -> "qu'il parle"

fr.conjugateWithPronoun("parler", voice: .activeAvoir, mode: .imperatif,
                        tense: .present, person: .secondSingularMasculine)
// -> "parle"  (bare form for imperatif)

```

`blocksElisionAndLiaison()` reports lexical blocking separately from
`isHAspire()`, including the non-h initials *ululer* and *yoyoter*. Pronoun
construction preserves `je ulule` / `je yoyote` while allowing auxiliary elision
in `j'ai ululé` / `j'ai yoyoté` and passive `j'étais haché`.

All pronoun methods have async overloads.

#### Homonyms

Some French verbs share the same infinitive but conjugate differently
depending on meaning (e.g. *ressortir* -- 3rd group "to stand out" vs
2nd group "to be under the jurisdiction of").  In the database these are
stored as `ressortir_1` and `ressortir_2`, but the public API uses the
bare infinitive with an optional `homonymIndex`.

```swift
fr.hasHomonyms("ressortir")       // true
fr.homonymCount("ressortir")      // 2
fr.homonymIndices("ressortir")    // [1, 2]

// Defaults to index 1 when omitted
fr.conjugate("ressortir", voice: .activeAvoir, mode: .indicatif,
             tense: .present, person: .firstSingularMasculine)
// -> "ressors"  (3rd group)

// Explicitly select index 2
fr.conjugate("ressortir", voice: .activeAvoir, mode: .indicatif,
             tense: .present, person: .firstSingularMasculine,
             homonymIndex: 2)
// -> "ressortis"  (2nd group)

// Non-homonym verbs are unaffected
fr.hasHomonyms("parler")          // false
fr.homonymCount("parler")         // 1
```

The `homonymIndex` parameter is available on **all** conjugation,
participle, structure query, and pronoun methods (both sync and async).
For non-homonym verbs it is silently ignored.

#### Participles

```swift
fr.participle("parler", voice: .activeAvoir, tense: .present)
// -> "parlant"

fr.participle("partir", voice: .activeEtre, tense: .passeFemininPluriel)
// -> "parties"

// All participle forms for a voice
let parts: [Tense: String] = fr.participles("prendre", voice: .activeAvoir)
// [.present: "prenant", .passeMasculinSingulier: "pris",
//  .passeFemininSingulier: "prise", ...]
```

Passive present participles use the gendered `.presentMasculinSingulier`,
`.presentFemininSingulier`, `.presentMasculinPluriel`, and
`.presentFemininPluriel` tenses. A generic `.present` request returns `nil` when
that voice has only gendered present slots.

#### Gérondif

The gérondif is derived from participles by prepending *en*.  Use the
dedicated `gerondif()` method -- gérondif forms are **not** returned by
`conjugate()`, `participle()`, or structure query methods.

```swift
fr.gerondif("parler", voice: .activeAvoir, tense: .gerondifPresent)
// -> "en parlant"

fr.gerondif("parler", voice: .activeAvoir, tense: .gerondifPasseMasculinSingulier)
// -> "en ayant parlé"

// Returns nil if the underlying participle is unavailable
fr.gerondif("xyzzy", voice: .activeAvoir, tense: .gerondifPresent)
// -> nil
```

When a voice has only gendered present participles and no generic `.present`
slot, `.gerondifPresent` returns `nil`; no default gender is inferred by the
catalogue API.

Five gérondif tenses are available:
`.gerondifPresent`, `.gerondifPasseMasculinSingulier`,
`.gerondifPasseFemininSingulier`, `.gerondifPasseMasculinPluriel`,
`.gerondifPasseFemininPluriel`.

Async overload available.  Supports `homonymIndex`.

#### Structure Queries

```swift
fr.voices("aller")
// -> [.activeEtre, .pronominal]

fr.modes("aller", voice: .activeEtre)
// -> [.indicatif, .subjonctif, .conditionnel, .imperatif, .participe]

fr.tenses("aller", voice: .activeEtre, mode: .indicatif)
// -> [.present, .imparfait, .passeSimple, .futurSimple, ...]

fr.persons("aller", voice: .activeEtre, mode: .indicatif, tense: .present)
// -> [.firstSingularMasculine, .secondSingularMasculine, ...]
```

#### Other Queries

```swift
fr.hasVerb("parler")            // true
fr.isHAspire("haïr")            // true
fr.blocksElisionAndLiaison("ululer") // true; isHAspire("ululer") is false
fr.is1990Reform("ceder")        // true
fr.reformVariante("ceder")      // Optional("ceder")
fr.verbCount                    // 6298 (homonym groups counted once)
fr.allVerbs                     // ["abaisser", "abandonner", ..., "zozoter"]

fr.hasHomonyms("ressortir")     // true
fr.homonymCount("ressortir")    // 2
fr.homonymIndices("ressortir")  // [1, 2]
```

### Enums

| Enum | Cases |
|:-----|:------|
| `Voice` | `.activeAvoir` `.activeEtre` `.active` `.passive` `.pronominal` |
| `Mode` | `.indicatif` `.subjonctif` `.conditionnel` `.imperatif` `.participe` |
| `Tense` | `.present` `.imparfait` `.passeSimple` `.futurSimple` `.passeCompose` `.plusQueParfait` `.passeAnterieur` `.futurAnterieur` `.passe` `.passeMasculinSingulier` `.passeFemininSingulier` `.passeMasculinPluriel` `.passeFemininPluriel` `.passeCompoundMasculinSingulier` `.passeCompoundFemininSingulier` `.passeCompoundMasculinPluriel` `.passeCompoundFemininPluriel` `.presentMasculinSingulier` `.presentFemininSingulier` `.presentMasculinPluriel` `.presentFemininPluriel` `.gerondifPresent` `.gerondifPasseMasculinSingulier` `.gerondifPasseFemininSingulier` `.gerondifPasseMasculinPluriel` `.gerondifPasseFemininPluriel` |
| `Person` | `.firstSingularMasculine` `.firstSingularFeminine` `.secondSingularMasculine` `.secondSingularFeminine` `.thirdSingularMasculine` `.thirdSingularFeminine` `.thirdSingularNeutral` `.firstPluralMasculine` `.firstPluralFeminine` `.secondPluralMasculine` `.secondPluralFeminine` `.thirdPluralMasculine` `.thirdPluralFeminine` |

Each `Person` case has a `.pronoun` property (`"je"`, `"tu"`, `"il"`, ...) and a `.shortLabel` (`"1sm"`, `"3pf"`, ...).

---
