# Changelog

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
