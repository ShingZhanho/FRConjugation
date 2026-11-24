# FRConjugation for TypeScript and JavaScript

French verb conjugation using bundled spelling rules learned from the Académie
française catalogue. Query recorded forms, predict unknown verbs, and find shared
spelling for highlighting. Conjugation works offline without a separate model download.

Supports browsers and Node.js 20 or later, with no runtime dependencies.
The package includes ES modules, TypeScript declarations, and API documentation.

## Install

```sh
npm install @jacobshing/frconjugation
```

Use ES module imports, or dynamic `import()` from CommonJS.

## Quick start

```ts
import { Conjugator, Voice, Mode, Tense, Person } from "@jacobshing/frconjugation";

const c = Conjugator.getShared();
c.conjugate("manger", Voice.ActiveAvoir, Mode.Indicatif,
    Tense.Present, Person.FirstPluralMasculine); // "mangeons"
c.conjugate("manger", Voice.ActiveAvoir, Mode.Indicatif, Tense.Present);
// Partial<Record<Person, string>>
c.conjugate("manger"); // nested voice → mode → tense → person objects
c.commonPrefix("manger"); // "mang"
```

## API

All names use camelCase. Grammar enums are `Voice`, `Mode`, `Tense`, and `Person`;
their string values are catalogue labels. `parseLabel(Voice, label)` returns a
typed value or null. `personPronoun(person)` returns its context-free subject;
the Person enum value itself is the short label.

| Purpose | Methods |
| --- | --- |
| Finite forms, from one person to all voices | `conjugate`, `rawInferredConjugation`, `guessConjugation` |
| Single participle | `participle`, `rawInferredParticiple`, `guessParticiple` |
| Participles keyed by tense | `participles`, `rawInferredParticiples`, `guessParticiples` |
| Gérondif | `gerondif`, `rawInferredGerondif`, `guessGerondif` |
| Shared lexical spelling | `commonPrefix`, `rawInferredCommonPrefix`, `guessCommonPrefix` |
| Alternative catalogue spelling | `conjugateAlternative`, `participleAlternative`, `hasAlternativeForm`, `hasAlternativeParticiple` |
| Contextual subject / combined form | `getPronoun`, `conjugateWithPronoun`, `conjugateAlternativeWithPronoun` |
| Catalogue structure | `voices`, `modes`, `tenses`, `persons` |
| Membership and homonyms | `hasVerb`, `hasHomonyms`, `homonymCount`, `homonymIndices` |
| Lexical metadata | `isHAspire`, `blocksElisionAndLiaison`, `is1990Reform`, `reformVariant` |

`allVerbs`, `verbCount`, `entries`, and `slots` are synchronous properties.
`form` and `forms` expose raw slot labels for integrations that need them;
`pronoun` and `withPronoun` accept raw slots too. Public declarations include
parameter types and documentation.

Finite methods have five typed overload scopes. Omit trailing selectors to
receive nested objects; missing keys are omitted. A missing single form or
all-voice result is `null`, while a scoped collection is an empty object.
Nonpersonal forms use their dedicated APIs without a Person argument.

A positive `homonymIndex` selects an indexed entry; an omitted index selects the
first, and an exact suffixed key takes precedence. It is the final argument;
for bulk finite queries, use `undefined` for omitted selectors:

```ts
c.conjugate("ressortir", undefined, undefined, undefined, undefined, 2);
// An exact key is also accepted:
c.conjugate("ressortir_2");
```

All verb inputs are trimmed, lowercased and NFC-normalized before lookup.
Guessing uses catalogue data for known infinitives, preserving missing forms,
and infers only unknown infinitives. Predictions may be
unattested. Catalogue methods select primary spellings; alternative methods fall
back to primary when no alternative exists. Raw predictions preserve semicolon
alternatives. Prefixes represent shared spelling, not grammatical stems;
`""` is a valid prefix and differs from `null`.

`Conjugator` uses immutable shared data within each JavaScript realm. Returned
arrays and objects are detached from that data. Invalid homonym indices throw
`RangeError`; loading failures throw `ConjugationError` with the original cause.
Synchronous construction and queries run on the caller thread.

## Worker-backed asynchronous API

```ts
import { AsyncConjugator, Voice, Mode, Tense, Person } from "@jacobshing/frconjugation";

const c = await AsyncConjugator.load();
try {
    const form = await c.guessConjugation("blorper", Voice.ActiveAvoir,
        Mode.Indicatif, Tense.Present, Person.FirstPluralMasculine);
    const prefix = await c.commonPrefix("manger");
} finally {
    c.close();
}
```

AsyncConjugator mirrors the instance methods with Promise results. Properties
become `getAllVerbs()`, `getVerbCount()`, `getEntries()`, and `getSlots()`.
Each instance owns one Web Worker or Node worker thread. Reuse it across queries;
`close()` terminates it and rejects pending requests. Workers process requests
serially. Worker failures reject pending calls; create a new reader to retry.
Worker-side errors cross the boundary as ordinary Error objects with messages.
There is no per-query cancellation or process-wide shared worker.

For browsers, serve the emitted ESM files over HTTP(S), or use a bundler that
supports module workers created with `new Worker(new URL(..., import.meta.url))`.
Keep the worker's modules accessible and allow them under your site's worker CSP.
No Node modules are imported by the browser path. Sync-only applications can
use `Conjugator` without starting a worker.

## Verification

For source-build checks and browser tests, see the
[shared test guide](https://github.com/ShingZhanho/FRConjugation/blob/main/tests/README.md)
and [npm scripts](https://github.com/ShingZhanho/FRConjugation/blob/main/typescript/package.json).

## More information

See the [source and build instructions](https://github.com/ShingZhanho/FRConjugation#build-and-use) for development,
or [report an issue](https://github.com/ShingZhanho/FRConjugation/issues).
Provided as-is for [personal and educational use](https://github.com/ShingZhanho/FRConjugation#licence).
