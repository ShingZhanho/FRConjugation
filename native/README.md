# C and C++

Requires C++17, Make, pkg-config, and ICU development libraries. C tests also
require C11. No Python, Swift, or managed runtime is needed. From the repository root:

```sh
make -C native
make -C native test
make -C native install PREFIX=/your/prefix
```

Link `libfrconjugation` and ICU (`pkg-config --libs icu-uc icu-i18n`), using
`-pthread` where required. Make discovers Homebrew ICU on macOS; elsewhere set
`PKG_CONFIG_PATH` as needed. `CXX` selects the target compiler; `HOST_CXX` selects
the compiler for the resource embedder. Use separate `BUILD` directories for
configurations. Cross-compilation also requires target ICU and compiler flags.

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

Guess APIs use catalogue data exclusively for known infinitives, preserving missing
forms. Only unknown infinitives use raw inference. All verb inputs are trimmed, lowercased and NFC-normalized before catalogue
membership is checked.
