# Changelog

## Unreleased

- All verb-taking APIs trim surrounding Unicode whitespace, lowercase input, and normalize Unicode before catalogue lookup, metadata queries, homonym resolution, and inference. Capitalized or padded known verbs now preserve catalogue gaps when guessing.

## v5.2.0 — 2026-11-24

- **Breaking behavior:** guess APIs now return catalogue results for known infinitives, preserving missing forms instead of predicting them. This applies to single forms, collections, participles, gérondifs, common prefixes, and async queries across all languages.
- Unknown infinitives still use inference. Use raw-inference APIs to predict hypothetical forms for known verbs.

## v5.1.1 — 2026-11-24

- Corrected package installation instructions and registry links. No code or catalogue changes.

## v5.1.0 — 2026-11-24

- Added C/C++, Kotlin/JVM, C#, Python, and TypeScript/JavaScript packages with Swift API parity and a shared bundled catalogue.
- Added native macOS/Linux archives and packages on Maven Central, NuGet, PyPI, and npm.

## v5.0.1 — 2026-11-23

- Added `commonPrefix()`, `rawInferredCommonPrefix()`, and `guessCommonPrefix()`, including async overloads, for highlighting shared spelling across forms.
- **Breaking:** removed deprecated cache APIs: `cacheSize:`, `defaultCacheSize`, `cacheCount`, `cacheCapacity`, and `clearCache()`.
- Removed the already-unavailable `modelDirectory:` loaders.

## v5.0.1-beta.1 — 2026-11-23

- **Breaking:** removed deprecated cache APIs: `cacheSize:`, `defaultCacheSize`, `cacheCount`, `cacheCapacity`, and `clearCache()`.
- Removed the already-unavailable `modelDirectory:` loaders.

## v5.0.0 — 2026-11-19

- Replaced the neural model with bundled spelling rules.
- Added raw inference and catalogue-first guessing for finite forms, participles, and gérondifs.
- Deprecated cache controls; cache settings now have no effect.
- **Breaking:** custom-model loaders are unavailable at compile time. Use the bundled `Conjugator()`, `getShared()`, or `load()` loaders.
- **Breaking:** removed the Python neural inference module.

## v4.3.0 — 2026-10-30

- Updated to dataset v0.5.0 and retrained the model with corrected forms, alternatives, participles, and variant references.
- Added `blocksElisionAndLiaison(_:homonymIndex:)` and corrected pronoun elision.
- **Breaking data change:** passive present participles of `devoir` and `redevoir` now require gendered tense selections. Generic `.present` and derived `.gerondifPresent` queries return `nil`.
