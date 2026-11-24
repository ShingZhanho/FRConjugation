# FRConjugation for C and C++

French verb conjugation using bundled spelling rules learned from the Académie
française catalogue. Query recorded forms, predict unknown verbs, and find shared
spelling for highlighting. Conjugation works offline without a separate model download.

Use the C++17 interface or the C11-compatible C API. Both use the same native
library and bundled rules; no Python, Swift, or managed runtime is needed.

## Install and link

Download a matching native archive from the
[releases page](https://github.com/ShingZhanho/FRConjugation/releases/latest).
Add its headers to your include path and its library directory to your linker
search path. The native library requires a compatible ICU installation.

To build from source, extract the full source archive, then run these commands
from its top-level directory. You need a C++17 compiler, Make, pkg-config, and
ICU development libraries:

```sh
make -C native
make -C native install PREFIX="$HOME/.local"
```

Link `libfrconjugation` and ICU (`pkg-config --libs icu-uc icu-i18n`), using
`-pthread` where required. Link C applications with the C++ linker to include the
C++ runtime. For shared linking, make the library available to your platform's
dynamic loader. Make discovers Homebrew ICU on macOS; elsewhere set
`PKG_CONFIG_PATH` to your ICU installation as needed.

## C++

```cpp
#include <frconjugation.hpp>
using namespace frconjugation;

Conjugator c;
auto form = c.conjugate("manger", Voice::ActiveAvoir, Mode::Indicatif,
                        Tense::Present, Person::FirstPluralMasculine); // "mangeons"
auto forms = c.conjugate("manger");
auto prefix = c.common_prefix("manger"); // "mang"
```

`conjugate`, `raw_inferred_conjugation`, and `guess_conjugation` each have five
scopes. Nested maps follow voice → mode → tense → person; supplied selectors
remove leading levels. Single/all-voice absence is `std::nullopt`; other missing
collections are empty. `participle`, `participles`, and `gerondif` have raw and
guess counterparts; participle collections map tense to spelling.

`conjugate_alternative`, `participle_alternative`, and `has_alternative_…` expose
variants. `get_pronoun`, `conjugate_with_pronoun`, and
`conjugate_alternative_with_pronoun` handle subjects. `common_prefix` accepts a
prediction mode; named `raw_inferred_common_prefix` and `guess_common_prefix`
helpers are also available.

`voices`, `modes`, `tenses`, `persons`, `all_verbs`, `verb_count`, `has_verb`,
`has_homonyms`, `homonym_count`, `homonym_indices`, `is_h_aspire`,
`blocks_elision_and_liaison`, `is_1990_reform`, and `reform_variant` expose
structure and metadata. Homonym zero means default; positive indices select an
entry. Scoped enums have `label` helpers and optional `…_from_label` parsers;
Person also has `pronoun` and `short_label` helpers.

`get_shared()` returns a shared reader. Async methods ending in `_async`,
including `load_async` and `get_shared_async`, return futures and retain the
engine independently of the caller's lifetime. Destroying the last unconsumed
`std::async` future can wait for completion. Loading errors use `ConjugationError`.

## C

Include `frconjugation_api.h`. The typed API uses tagged requests and owned
responses; `frconjugation.h` also exposes the original slot-based functions.

```c
#include <frconjugation_api.h>

frc_engine *engine = NULL;
if (frc_create(&engine) == FRC_OK) {
    frc_request request = frc_request_init(FRC_QUERY_CONJUGATE, "manger");
    request.voice = FRC_VOICE_ACTIVE_AVOIR;
    request.mood = FRC_MOOD_INDICATIF;
    request.tense = FRC_TENSE_PRESENT;
    request.person = FRC_PERSON_FIRST_PLURAL_MASCULINE;
    frc_response *response = NULL;
    frc_status status = frc_query(engine, &request, &response);
    /* Read response accessors when status is FRC_OK. */
    frc_response_free(response);
    frc_destroy(engine);
}
```

Operations cover finite forms, participles, gérondifs, prefixes, pronouns,
alternatives, structure, listings, homonyms, and lexical metadata. Set
`prediction` for catalogue/raw/guess and `spelling` for catalogue alternatives.
Omit trailing grammatical selectors with `ANY` for bulk scopes. Bulk results
contain typed `frc_form_row` records carrying all four grammatical coordinates,
rather than nested dictionaries. Missing single/all-voice queries return
`FRC_MISSING`; scoped empty results succeed with zero rows.

Responses own their fields; borrowed strings/arrays expire when the response is
freed. `frc_query_async` copies the request and input before returning, allowing
the caller to destroy its engine immediately. The callback owns the response,
must free it, and must not throw. Keep callback context alive until completion.
Scheduling failure returns an error without a callback. Initialization also has
async variants. Shared handles wrap the same immutable data but need not have
identical pointer values. There is no cancellation of running work.

C and C++ strings crossing the C ABI must be NUL-terminated UTF-8 without embedded
NULs. Headers contain the complete Doxygen API contracts and status descriptions.

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
