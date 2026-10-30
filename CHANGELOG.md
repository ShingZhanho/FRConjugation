# Changelog

## Unreleased

- Add raw neural prediction and catalogue-first guessing families for finite
  conjugations, participles and gérondifs. Each guess method preserves its matching
  catalogue API's answers and infers only missing forms.
- Match `conjugate` overloads with `rawInferredConjugation` / `guessConjugation`,
  `participle` with `rawInferredParticiple` / `guessParticiple`, `participles` with
  `rawInferredParticiples` / `guessParticiples`, and `gerondif` with
  `rawInferredGerondif` / `guessGerondif`. Retain homonym selection and async
  single-form variants. Existing catalogue APIs are unchanged.
- Keep conjugation inference finite-only. Nonpersonal forms use gendered tenses
  and `[Tense: String]` collections without dummy Person arguments or duplicates.
- Add regression checks and a reproducible 170-case evaluation, plus raw output
  coverage for all 820 model-supported base form combinations across the families.

## v4.3.0 — 2026-10-30

- Adopt the fixed dataset v0.5.0, including corrected forms, spelling alternatives, participles and variant references.
- Add `blocksElisionAndLiaison(_:homonymIndex:)`.
- Correct `je ulule` / `je yoyote` without breaking auxiliary elision in `j'ai ululé` / `j'ai yoyoté` or passive `j'étais haché`.
- The new public query is additive; source changes are not required.

### Observable data changes

Passive present participles for `devoir` and `redevoir` now use the existing four gendered present-participle tenses. Their former generic `.present` request, including its derived `.gerondifPresent`, returns `nil`; callers must select the appropriate gendered participle. Corrected strings and primary / alternative ordering may change.
