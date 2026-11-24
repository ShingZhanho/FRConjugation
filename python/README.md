# Python

Distribution identity: **jacobszh-frconjugation**. Import name: **frconjugation**.
Requires Python 3.10+; no runtime dependencies or other language toolchains.

Install from [PyPI](https://pypi.org/project/jacobszh-frconjugation/) with
`python3 -m pip install jacobszh-frconjugation`.

To build and test from the repository root:

```sh
python3 -m pip install ./python
python3 -m unittest discover -s python/tests
```

```python
from frconjugation import Conjugator, Prediction, Voice, Mode, Tense, Person

c = Conjugator()
c.form("manger", "voix_active_avoir|indicatif|present|1pm")  # "mangeons"
c.form(
    "blorper", "voix_active_avoir|indicatif|present|1pm", prediction=Prediction.GUESS
)  # "blorpons"
c.common_prefix("manger")  # "mang"
c.conjugate(
    "manger", Voice.ACTIVE_AVOIR, Mode.INDICATIF, Tense.PRESENT, Person.FIRST_PLURAL_MASCULINE
)  # "mangeons"
c.conjugate("manger")  # nested typed dictionaries of finite forms
```

Use `slots` to discover form labels, `entries` for source metadata, and
`all_verbs` for distinct infinitives. Missing results are `None`; an empty prefix
is valid. Synchronous calls run on the caller. Methods ending in `_async` use worker
threads through `asyncio`; cancelling an await does not interrupt worker work. Full API contracts are available through Python
`help()` and source docstrings; the package includes type annotations and
`py.typed`. Inference is experimental and can produce unattested forms.

The checked-in resource is a symlink to the shared catalogue. Wheels and source
distributions contain the actual resource bytes, so an installed package works
without the repository. Preserve symlinks in a source checkout. Build packaging
artifacts with `python3 -m build ./python` after installing the Python `build`
frontend in your environment. Source checkout tests may instead use
`PYTHONPATH=python/src python3 -m unittest discover -s python/tests`.

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

Guess APIs use catalogue data exclusively for known infinitives, preserving missing
forms. Only unknown infinitives use raw inference. Membership uses the same exact
lookup semantics as catalogue queries; only inference trims and lowercases input.
