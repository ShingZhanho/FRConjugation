# FRConjugation for .NET

French verb conjugation using bundled spelling rules learned from the Académie
française catalogue. Query recorded forms, predict unknown verbs, and find shared
spelling for highlighting. Conjugation works offline without a separate model download.

Targets .NET Standard 2.1 with no runtime package dependencies.

## Install

```sh
dotnet add package ShingZhanho.FRConjugation
```

Use the `ShingZhanho.FRConjugation` namespace. The package includes the rules and
XML API documentation for editor completion.

## Quick start

```csharp
using ShingZhanho.FRConjugation;

var c = Conjugator.GetShared();
var form = c.Conjugate("manger", Voice.ActiveAvoir, Mode.Indicatif,
    Tense.Present, Person.FirstPluralMasculine); // "mangeons"
var forms = c.Conjugate("manger");
var prefix = c.CommonPrefix("manger"); // "mang"
```

## Forms and metadata

`Conjugate`, `RawInferredConjugation`, and `GuessConjugation` have five scopes,
from one person to all voices. Nested dictionaries follow voice → mode → tense →
person; supplied selectors remove leading levels. Single/all-voice absence is
null; other missing collections are empty. `Participle`, `Participles`, and
`Gerondif` have raw-inference and guess counterparts. Participle collections map
tense to spelling without person keys.

Use `ConjugateAlternative`, `ParticipleAlternative`, and `HasAlternative…` for
variants; `GetPronoun`, `ConjugateWithPronoun`, and
`ConjugateAlternativeWithPronoun` for subjects. Prefix strategies are
`CommonPrefix`, `RawInferredCommonPrefix`, and `GuessCommonPrefix`.

`Voices`, `Modes`, `Tenses`, and `Persons` discover structure. `AllVerbs`,
`VerbCount`, `HasVerb`, `HasHomonyms`, `HomonymCount`, `HomonymIndices`,
`IsHAspire`, `BlocksElisionAndLiaison`, `Is1990Reform`, and `ReformVariant`
provide metadata. Optional positive `homonymIndex` selects an indexed entry.
Grammar enums have `Label()` extensions; Person has `Pronoun()` and `ShortLabel()`.
`Grammar.Parse…` and `TryParse…` convert catalogue labels.

## Asynchronous use

Methods ending in `Async` return Tasks dispatched through the .NET thread pool.
`LoadAsync()` creates a reader; `GetSharedAsync()` obtains the shared reader.
Synchronous methods run on the caller; no API interrupts already running work.
Resource failures throw `ConjugationException` with the underlying cause.

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
