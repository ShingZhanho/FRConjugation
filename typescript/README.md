# TypeScript / JavaScript

Native TypeScript reader for browsers and Node.js 20+, with no runtime dependencies.
The npm package identity is `@jacobs/frconjugation`; it has not yet been published.
It ships ES modules, type declarations, API comments, and the bundled rules.
No separate data download, custom binary, or server is required.

## Build and install

From the repository root:

```sh
cd typescript
npm ci
npm test
npm pack
```

Install the resulting `.tgz` in your application with `npm install /path/to/package.tgz`.
`npm run build` embeds the canonical `../catalogue/catalogue.fcr` into generated
JavaScript before compiling. Node.js is the only language toolchain needed.
The package is ESM; use `import`, or dynamic `import()` from CommonJS.

```ts
import { Conjugator, Voice, Mode, Tense, Person } from "@jacobs/frconjugation";

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

Catalogue lookups use exact NFC-normalized spelling. Raw inference trims Unicode
whitespace and lowercases supported input. Guessing preserves catalogue forms
and fills missing slots, including those of defective verbs. Predictions may be
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
import { AsyncConjugator, Voice, Mode, Tense, Person } from "@jacobs/frconjugation";

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

`npm test` checks all 101 shared and 218 typed Swift-authored cases through both
sync and Node worker APIs, worker lifecycle behavior, and compile-time types.

```sh
npm run test:browser       # same fixtures in installed Chrome and its Web Worker
npm run verify:catalogue   # all catalogue outputs and fixed inference comparison
```

The optional browser check uses Playwright and installed Chrome; set
`BROWSER_CHANNEL` to another installed Playwright-supported channel if needed.
The exhaustive comparison checks the established cross-language stream hash;
it requires no Swift or Python installation. Node.js 24 and Chrome were locally
validated on macOS on 2026-11-24; other browsers have not been verified.
