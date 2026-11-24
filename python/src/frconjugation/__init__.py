"""French conjugation from bundled FCR rules, with no runtime dependencies.

All verb queries trim Unicode whitespace, lowercase and NFC-normalize input.
Inference accepts space, apostrophe, hyphen,
1, 2, semicolon, underscore, a-z and âçèéêîïôûœ. Predictions can be unattested.
Only the bundled model is supported. Methods ending in _async run work off the
event loop. Other calls are synchronous; immutable shared
catalogue reads may run concurrently. Missing results are None; an empty common
prefix is a valid result. This package does not require Swift or native libraries.
"""

import re
import unicodedata
from dataclasses import dataclass
from enum import Enum

from ._api import _API
from ._catalogue import bundled, lemma_index, nfc, verb_key
from .types import Mode, Person, Tense, Voice

__all__ = [
    "ConjugationError",
    "Conjugator",
    "Mode",
    "Person",
    "Prediction",
    "Spelling",
    "Tense",
    "VerbEntry",
    "Voice",
]


class ConjugationError(RuntimeError):
    """The bundled conjugation model could not be loaded."""


class Prediction(str, Enum):
    """Select exact lookup, rule prediction, or catalogue-first guessing."""

    CATALOGUE = "catalogue"
    """Trimmed, lowercase, NFC-normalized catalogue lookup."""
    INFERRED = "inferred"
    """Normalize and predict supported input, including unknown verbs."""
    GUESS = "guess"
    """Use catalogue data for known infinitives; infer only unknown infinitives."""


class Spelling(str, Enum):
    """Select catalogue spellings; inference always preserves alternatives."""

    PRIMARY = "primary"
    """First semicolon-separated spelling."""
    ALTERNATIVE = "alternative"
    """Remainder after the first semicolon, or primary if none exists."""
    ALL = "all"
    """All spellings, separated by semicolons."""


@dataclass(frozen=True)
class VerbEntry:
    """Metadata for one entry.

    Attributes:
        key: Exact infinitive key, including an optional homonym suffix.
        flags: Bits 0: h aspiré, 1: elision/liaison blocking, 2: 1990 reform.
        variant: Source reform-variant key, or None when absent.
    """

    key: str
    flags: int
    variant: str | None

    @property
    def is_h_aspire(self) -> bool:
        """Whether an initial h blocks elision and liaison."""
        return bool(self.flags & 1)

    @property
    def blocks_elision_and_liaison(self) -> bool:
        """Lexical elision/liaison blocking; auxiliaries may still elide."""
        return bool(self.flags & 2)

    @property
    def is_1990_reform(self) -> bool:
        """Whether this entry is marked as a 1990 reform variant."""
        return bool(self.flags & 4)


_TRAILING = re.compile(
    r"-(?:(?:m|t)['’]en|moi|toi|nous|vous|le|la|les|lui|leur|en|y)(?:-(?:en|y))?$"
)
_LEADING = re.compile(r"^(?:(?:j|m|t|s|n|l|qu)['’])+")
_GERONDIFS = {"gerondif_present": "present"} | {
    "gerondif_passe_" + gender: "passe_compound_" + gender for gender in ("sm", "sf", "pm", "pf")
}
_SUBJECTS = dict(
    zip(
        ("1sm", "1sf", "2sm", "2sf", "3sm", "3sf", "3sn", "1pm", "1pf", "2pm", "2pf", "3pm", "3pf"),
        (
            "je",
            "je",
            "tu",
            "tu",
            "il",
            "elle",
            "on",
            "nous",
            "nous",
            "vous",
            "vous",
            "ils",
            "elles",
        ),
    )
)


def _validate(verb: str, homonym: int | None) -> None:
    if not isinstance(verb, str):
        raise TypeError("verb must be a string")
    if homonym is not None and (type(homonym) is not int or homonym <= 0):
        raise ValueError("homonym_index must be a positive integer or None")


class Conjugator(_API):
    """Synchronous reader sharing the bundled catalogue.

    Construction loads the resource lazily; resource and decoding failures raise
    ConjugationError with the original cause. No custom model argument is accepted. Methods using
    homonym_index accept a positive index or None for the first indexed entry;
    exact suffixed keys take precedence. Invalid indices raise ValueError.
    Enum parameters accept enum members or their string values; invalid values
    raise ValueError. Unsupported forms/inputs return None, not an exception.
    """

    def __init__(self) -> None:
        """Initialize a reader of the shared, bundled catalogue."""
        try:
            self._catalogue = bundled()
        except Exception as error:
            raise ConjugationError("Failed to load bundled conjugation model") from error

    @property
    def slots(self) -> tuple[str, ...]:
        """All voice|mode|tense|person labels; participles use '-' as person."""
        return self._catalogue.slots

    @property
    def entries(self) -> tuple[VerbEntry, ...]:
        """Snapshot of all entries, including separately indexed homonyms."""
        return tuple(
            VerbEntry(key, entry[0], entry[1]) for key, entry in self._catalogue.entries.items()
        )

    @property
    def all_verbs(self) -> tuple[str, ...]:
        """Distinct base infinitives in French-oriented accent/ligature-insensitive order."""

        def sort_key(value):
            folded = unicodedata.normalize("NFKD", value.replace("œ", "oe").replace("æ", "ae"))
            return "".join(c for c in folded if not unicodedata.combining(c)), value

        return tuple(sorted({lemma_index(key)[0] for key in self._catalogue.entries}, key=sort_key))

    def has_verb(self, verb: str) -> bool:
        """Test normalized membership, accepting base names or indexed keys."""
        _validate(verb, None)
        key = verb_key(verb)
        return key in self._catalogue.entries or key in self._catalogue.homonyms

    def homonym_indices(self, verb: str) -> tuple[int, ...]:
        """Ascending indices for a base name, or an empty tuple without a group."""
        _validate(verb, None)
        return self._catalogue.homonyms.get(verb_key(verb), ())

    def form(
        self,
        verb: str,
        slot: str,
        prediction: Prediction = Prediction.CATALOGUE,
        homonym_index: int | None = None,
        spelling: Spelling = Spelling.PRIMARY,
    ) -> str | None:
        """Return a form for a slot label, or None if absent/unsupported.

        verb is an infinitive or exact homonym key; slot is a label from slots.
        prediction chooses catalogue lookup, raw inference or unknown-verb
        guessing. spelling applies only to catalogue results; raw predictions
        always retain semicolon-separated alternatives. See the class contract
        for homonym selection and argument errors. Invalid slot labels return None.
        """
        _validate(verb, homonym_index)
        if not isinstance(slot, str):
            raise TypeError("slot must be a string")
        prediction, spelling = Prediction(prediction), Spelling(spelling)
        ident = self._catalogue.slot_ids.get(slot)
        if ident is None:
            return None
        if prediction != Prediction.INFERRED:
            known = self._catalogue.raw(verb, ident, homonym_index, "catalogue")
            if known is not None:
                first, separator, rest = known.partition(";")
                return (
                    known
                    if spelling == Spelling.ALL
                    else rest
                    if spelling == Spelling.ALTERNATIVE and separator
                    else first
                )
            if prediction == Prediction.CATALOGUE or self.has_verb(verb):
                return None
        return self._catalogue.raw(verb, ident, homonym_index, "inferred")

    def forms(
        self,
        verb: str,
        prediction: Prediction = Prediction.CATALOGUE,
        homonym_index: int | None = None,
    ) -> dict[str, str]:
        """Map every available slot to a form, omitting missing values.

        Uses form's argument semantics and primary catalogue spellings. Includes
        participles, unlike Swift's finite-only nested conjugate overloads.
        """
        return {
            slot: value
            for slot in self.slots
            if (value := self.form(verb, slot, prediction, homonym_index)) is not None
        }

    def _prefix(self, verb: str, homonym: int | None, mode: str) -> str | None:
        _validate(verb, homonym)
        result = None
        for slot in range(len(self.slots)):
            raw = self._catalogue.raw(verb, slot, homonym, mode)
            if raw is None:
                continue
            for alternative in raw.split(";"):
                words = nfc(alternative).split()
                word = _LEADING.sub("", _TRAILING.sub("", words[-1])) if words else ""
                if not word:
                    continue
                if result is None:
                    result = word
                else:
                    length = 0
                    for a, b in zip(result, word):
                        if a != b:
                            break
                        length += 1
                    result = result[:length]
                if not result:
                    return ""
        return result

    def common_prefix(self, verb: str, homonym_index: int | None = None) -> str | None:
        """Shared spelling across all catalogue forms and alternatives.

        Excludes auxiliaries and attached pronouns; this is not a grammatical
        stem. None means no usable forms; empty is valid. Accents matter.
        """
        return self._prefix(verb, homonym_index, "catalogue")

    def raw_inferred_common_prefix(self, verb: str, homonym_index: int | None = None) -> str | None:
        """Like common_prefix, using raw predictions for all supported slots."""
        return self._prefix(verb, homonym_index, "inferred")

    def guess_common_prefix(self, verb: str, homonym_index: int | None = None) -> str | None:
        """Use common_prefix for known infinitives, otherwise raw inference."""
        return self._prefix(verb, homonym_index, "guess")

    def gerondif(
        self,
        verb: str,
        voice: str,
        tense: str,
        prediction: Prediction = Prediction.CATALOGUE,
        homonym_index: int | None = None,
    ) -> str | None:
        """Derive a gérondif in a catalogue voice.

        tense is gerondif_present or gerondif_passe_sm/sf/pm/pf. Returns None
        when unavailable. Catalogue uses the primary participle; predictions
        prefix every alternative with 'en '. Other arguments follow form.
        """
        _validate(verb, homonym_index)
        prediction = Prediction(prediction)
        voice = voice.value if isinstance(voice, Voice) else voice
        tense = tense.value if isinstance(tense, Tense) else tense
        source = _GERONDIFS.get(tense)
        if source is None:
            return None
        value = self.form(verb, f"{voice}|participe|{source}|-", prediction, homonym_index)
        return (
            None if value is None else ";".join("en " + part.strip() for part in value.split(";"))
        )

    def _subject(self, verb: str, slot: str, homonym: int | None, form: str) -> str | None:
        parts = slot.split("|")
        if len(parts) != 4 or parts[1] in ("imperatif", "participe"):
            return None
        subject = _SUBJECTS.get(parts[3])
        if subject is None:
            return None
        entry = self._catalogue.entries.get(self._catalogue.resolve(verb_key(verb), homonym))
        flags = entry[0] if entry else 0
        first = form[:1].lower()
        vowel = bool(first) and first in "aeiouàâéèêëîïôùûüœæy"
        if first == "h":
            vowel = not flags & 1
        if (
            parts[0] != "voix_passive"
            and parts[2] in ("present", "imparfait", "passe_simple", "futur_simple")
            and flags & 2
        ):
            vowel = False
        result = "j'" if subject == "je" and vowel else subject + " "
        return (
            ("qu'" if parts[3].startswith("3") else "que ") + result
            if parts[1] == "subjonctif"
            else result
        )

    def pronoun(
        self,
        verb: str,
        slot: str,
        homonym_index: int | None = None,
        spelling: Spelling = Spelling.PRIMARY,
    ) -> str | None:
        """Catalogue subject prefix, including a trailing space or apostrophe.

        Returns None for missing forms, participles and imperatives. spelling
        must be PRIMARY or ALTERNATIVE; ALL raises ValueError. Other arguments
        follow form. No inference is performed.
        """
        if Spelling(spelling) == Spelling.ALL:
            raise ValueError("pronouns require primary or alternative spelling")
        value = self.form(verb, slot, homonym_index=homonym_index, spelling=spelling)
        return None if value is None else self._subject(verb, slot, homonym_index, value)

    def with_pronoun(
        self,
        verb: str,
        slot: str,
        homonym_index: int | None = None,
        spelling: Spelling = Spelling.PRIMARY,
    ) -> str | None:
        """Catalogue form with its subject, or bare imperative/participle.

        Returns None when absent. Accepts pronoun's arguments and spelling
        restrictions. No inference is performed.
        """
        if Spelling(spelling) == Spelling.ALL:
            raise ValueError("pronouns require primary or alternative spelling")
        value = self.form(verb, slot, homonym_index=homonym_index, spelling=spelling)
        return (
            None
            if value is None
            else (self._subject(verb, slot, homonym_index, value) or "") + value
        )
