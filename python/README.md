# FRConjugation for Python

French verb conjugation using bundled spelling rules learned from the Académie
française catalogue. Query recorded forms, predict unknown verbs, and find shared
spelling for highlighting. Conjugation works offline without a separate model download.

Requires Python 3.10 or later. No runtime dependencies.

## Install

```sh
python -m pip install jacobszh-frconjugation
```

The distribution is named `jacobszh-frconjugation`; import it as `frconjugation`.
The installed package includes the rules, type annotations, and `py.typed`.

## Quick start

```python
from frconjugation import Conjugator, Voice, Mode, Tense, Person

c = Conjugator()
c.conjugate(
    "manger", Voice.ACTIVE_AVOIR, Mode.INDICATIF, Tense.PRESENT, Person.FIRST_PLURAL_MASCULINE
)  # "mangeons"
c.conjugate("manger")  # nested dictionaries of finite forms
c.common_prefix("manger")  # "mang"
c.guess_conjugation(
    "blorper", Voice.ACTIVE_AVOIR, Mode.INDICATIF, Tense.PRESENT, Person.FIRST_PLURAL_MASCULINE
)  # "blorpons" (prediction)
```

Use `form` and `forms` for raw slot queries, `slots` to discover form labels, `entries` for source metadata, and
`all_verbs` for distinct infinitives. Missing results are `None`; an empty prefix
is valid. Synchronous calls run on the caller. Methods ending in `_async` use worker
threads through `asyncio`; cancelling an await does not interrupt worker work. Full API contracts are available through Python
`help()` and source docstrings; the package includes type annotations and
`py.typed`. Inference is experimental and can produce unattested forms.

## Forms and metadata

`conjugate`, `raw_inferred_conjugation`, and `guess_conjugation` accept optional
trailing voice/mode/tense/person selectors. Omitting selectors returns nested
voice → mode → tense → person dictionaries; supplied leading selectors remove
those levels. Missing single or all-voice results are `None`; missing scoped
collections are empty dictionaries. Nonpersonal forms use `participle`,
`participles`, and `gerondif`, with corresponding `raw_inferred_…` and `guess_…`
methods. Participles map tense to spelling and require no person.

Use `conjugate_alternative`, `participle_alternative`, and `has_alternative_…`
for catalogue alternatives; `get_pronoun`, `conjugate_with_pronoun`, and
`conjugate_alternative_with_pronoun` for subjects. `voices`, `modes`, `tenses`,
and `persons` discover catalogue structure. `has_verb`, `verb_count`,
`has_homonyms`, `homonym_count`, `homonym_indices`, `is_h_aspire`,
`blocks_elision_and_liaison`, `is_1990_reform`, and `reform_variant` expose metadata.
Pass a positive `homonym_index` where supported to select an indexed entry.

## Asynchronous use

`Conjugator.get_shared()` reuses a reader; `load()` and `get_shared_async()`
initialize off the caller thread. Loading failures raise `ConjugationError`.
Enum constructors parse catalogue labels; Person exposes `pronoun` and
`short_label`.

```python
# Inside an async function:
c = await Conjugator.load()
form = await c.guess_conjugation_async(
    "blorper", Voice.ACTIVE_AVOIR, Mode.INDICATIF, Tense.PRESENT, Person.FIRST_PLURAL_MASCULINE
)
```

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
