# Changelog

## Unreleased

- All verb-taking APIs trim surrounding Unicode whitespace, lowercase input, and normalize Unicode before catalogue lookup, metadata queries, homonym resolution, and inference. Capitalized or padded known verbs now preserve catalogue gaps when guessing.

## v5.2.0 — 2026-11-24

- Guess APIs now preserve catalogue gaps for known infinitives and infer only unknown infinitives across all language ports. This intentionally changes behavior without changing signatures. [Compatibility details](releases/v5.2.0.md).

## v5.1.1 — 2026-11-24

- Corrected registry installation instructions and removed unpublished/local-only wording from package documentation. No library or catalogue changes. [Release notes](releases/v5.1.1.md).

## v5.1.0 — 2026-11-24

- Added C/C++, Kotlin/JVM, C#, Python, and TypeScript/JavaScript distributions with Swift API parity and a shared bundled catalogue.
- Added registry publishing and native macOS/Linux build validation. Swift public APIs remain unchanged. [Release and development-port migration details](releases/v5.1.0.md).

## v5.0.1 — 2026-11-23

- Added catalogue, raw-inferred, and hybrid common-prefix queries with async overloads.
- Removed deprecated cache APIs and unavailable custom-model loaders. [Migration details](releases/v5.0.1.md).

## v5.0.1-beta.1 — 2026-11-23

Removed the deprecated cache APIs and the unavailable custom-model loaders. Callers using cache controls must update their code. [Migration details](releases/v5.0.1-beta.1.md).

## v5.0.0 — 2026-11-19

- Conjugation now uses bundled spelling rules learned from the v0.5.0 catalogue.
- Custom model loaders are unavailable at compile time. Use `Conjugator()`,
  `Conjugator.getShared()`, or `try await Conjugator.load()`.
- Cache settings and controls are deprecated. Cache sizes are ignored,
  `cacheCount` and `cacheCapacity` return zero, and `clearCache()` has no effect.
- Python tooling learns and compiles the rules. The Python neural inference module has been removed.
- Added raw inference and catalogue-first guessing for finite forms,
  participles and gérondifs. Guessing fills missing slots, including on defective verbs.

## v4.3.0 — 2026-10-30

- Adopt the fixed dataset v0.5.0, including corrected forms, spelling alternatives, participles and variant references.
- Add `blocksElisionAndLiaison(_:homonymIndex:)`.
- Correct `je ulule` / `je yoyote` without breaking auxiliary elision in `j'ai ululé` / `j'ai yoyoté` or passive `j'étais haché`.
- The new public query is additive; source changes are not required.

### Observable data changes

Passive present participles for `devoir` and `redevoir` now use the existing four gendered present-participle tenses. Their former generic `.present` request, including its derived `.gerondifPresent`, returns `nil`; callers must select the appropriate gendered participle. Corrected strings and primary / alternative ordering may change.
