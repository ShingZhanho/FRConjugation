# FRConjugation

French verb conjugation for Swift, C/C++, Kotlin, C#, Python, and
TypeScript/JavaScript, using spelling rules learned from the Académie française catalogue. The shared binary covers
6,358 entries (6,298 distinct infinitives), including homonyms, compound forms,
spelling alternatives, participles, and gérondifs.

## Principles

The longest matching infinitive suffix selects a template. Each grammatical
slot selects an edit that trims the infinitive and adds a prefix and ending.
All implementations read the same bundled `catalogue/catalogue.fcr`; normal
builds require neither training nor another language's toolchain.

- **Catalogue queries** return recorded forms and preserve missing forms of
  defective verbs.
- **Raw inference** predicts from spelling rules, including for unknown verbs.
- **Guessing** preserves catalogue answers and predicts only missing slots.
  Predictions are experimental and may be unattested.
- **Common prefixes** identify shared spelling for highlighting across forms,
  excluding auxiliaries and pronouns. They are not grammatical stems.

Typed APIs expose single forms and collections, grammatical structure, pronouns,
spelling alternatives, homonyms, and lexical metadata. Each language also offers
asynchronous operations. The bundled catalogue is immutable; custom model
loading and cache management are not public APIs.

## Build and use

Run from the repository root. Each linked README describes installation, API
usage, result conventions, and language-specific requirements.

| Language | Requirements | Build | Test |
| --- | --- | --- | --- |
| [Swift](swift/README.md) | Swift 5.6+ | `swift build -c release` | `swift test -c release` |
| [C/C++](native/README.md) | C++17, Make, pkg-config, ICU; C11 for C tests | `make -C native` | `make -C native test` |
| [Kotlin/JVM](kotlin/README.md) | JDK compatible with bundled Gradle | `cd kotlin && ./gradlew build` | Included in build |
| [C#](dotnet/README.md) | .NET SDK; .NET 10 for tests | `dotnet build dotnet/JacobS.FRConjugation -c Release` | `dotnet run --project dotnet/Tests -c Release` |
| [TypeScript/JavaScript](typescript/README.md) | Node.js 20+ | `cd typescript && npm ci && npm run build` | `cd typescript && npm test` |
| [Python](python/README.md) | Python 3.10+ | `python3 -m pip install ./python` | `python3 -m unittest discover -s python/tests` |

Keep symlinks intact in source checkouts. Shared behavioral fixtures live in
[`tests/`](tests/README.md); each implementation reads them using its own
toolchain. Local validation has covered macOS; other platforms require their
own verification.

## Rules and data

The [rule tools](rules/README.md) learn and compile the model from `verbs.db`,
a release artifact of
[verbe-conjugaison-academie-francaise](https://github.com/ShingZhanho/verbe-conjugaison-academie-francaise).
The [rule format](rules/FORMAT.md) documents the readable and binary encoding.

Version 4.3.0 and earlier used a neural model; see the
[v4.3.0 source](https://github.com/ShingZhanho/FRConjugation/tree/5707eac18bcc748d911ca9f7375317ed563bc6ae).

## Licence

This project is provided as-is for personal and educational use.
