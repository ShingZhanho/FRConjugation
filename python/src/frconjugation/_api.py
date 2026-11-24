"""Typed Swift-equivalent operations, layered on the slot reader."""

import asyncio
from threading import Lock

from ._catalogue import verb_key
from .types import Mode, Person, Tense, Voice

_shared_lock = Lock()
_shared_readers = {}


class _API:
    @classmethod
    def get_shared(cls):
        """Return a lazily initialized shared reader; loading errors propagate."""
        with _shared_lock:
            if cls not in _shared_readers:
                _shared_readers[cls] = cls()
            return _shared_readers[cls]

    @classmethod
    async def load(cls):
        """Create a reader off the event loop. Cancellation does not stop worker work."""
        return await asyncio.to_thread(cls)

    @classmethod
    async def get_shared_async(cls):
        """Obtain the shared reader off the event loop."""
        return await asyncio.to_thread(cls.get_shared)

    def _conjugate(self, verb, voice, mode, tense, person, homonym_index, prediction):
        values = (voice, mode, tense, person)
        types = (Voice, Mode, Tense, Person)
        selected = []
        for value, typ in zip(values, types):
            if value is None:
                break
            selected.append(typ(value).value)
        if any(value is not None for value in values[len(selected) :]):
            raise ValueError("Specify voice, mode, tense and person in order")
        if len(selected) == 4:
            return self.form(verb, "|".join(selected), prediction, homonym_index)
        result = {}
        for slot, value in self.forms(verb, prediction, homonym_index).items():
            parts = slot.split("|")
            if parts[1] == "participe" or parts[: len(selected)] != selected:
                continue
            keys = [typ(part) for typ, part in zip(types, parts)][len(selected) :]
            level = result
            for key in keys[:-1]:
                level = level.setdefault(key, {})
            level[keys[-1]] = value
        return (result or None) if not selected else result

    @property
    def verb_count(self) -> int:
        """Distinct base infinitive count, collapsing indexed homonyms."""
        return len(self.all_verbs)

    def has_homonyms(self, verb: str) -> bool:
        """Whether the base infinitive has an indexed homonym group."""
        return bool(self.homonym_indices(verb))

    def homonym_count(self, verb: str) -> int:
        """Indexed entry count, or one without a group (including unknown inputs)."""
        return len(self.homonym_indices(verb)) or 1

    def _metadata(self, verb, homonym=None, resolve=False):
        key = verb_key(verb)
        if resolve:
            key = self._catalogue.resolve(key, homonym)
        return self._catalogue.entries.get(key, (0, None, 0))

    def is_h_aspire(self, verb: str) -> bool:
        """Whether this exact catalogue key has an aspirated initial h."""
        return bool(self._metadata(verb)[0] & 1)

    def blocks_elision_and_liaison(self, verb: str, homonym_index: int | None = None) -> bool:
        """Lexical blocking for the resolved entry; compound auxiliaries may elide."""
        return bool(self._metadata(verb, homonym_index, True)[0] & 2)

    def is_1990_reform(self, verb: str) -> bool:
        """Whether this exact entry is marked as a 1990 reform variant."""
        return bool(self._metadata(verb)[0] & 4)

    def reform_variant(self, verb: str) -> str | None:
        """Reform variant for this exact entry, or None when absent."""
        return self._metadata(verb)[1]

    def _structure(self, verb, filters, typ, homonym):
        labels = [x.value for x in filters]
        return tuple(
            sorted(
                {
                    typ(slot.split("|")[len(labels)])
                    for slot in self.forms(verb, homonym_index=homonym)
                    if slot.split("|")[: len(labels)] == labels
                },
                key=lambda x: x.value,
            )
        )

    def voices(self, verb: str, homonym_index: int | None = None) -> tuple[Voice, ...]:
        """Catalogue voices with forms, sorted by raw label; unknown verbs return empty."""
        return self._structure(verb, (), Voice, homonym_index)

    def modes(self, verb: str, voice: Voice, homonym_index: int | None = None) -> tuple[Mode, ...]:
        """Catalogue moods with forms in the voice, sorted by raw label."""
        return self._structure(verb, (Voice(voice),), Mode, homonym_index)

    def tenses(
        self, verb: str, voice: Voice, mode: Mode, homonym_index: int | None = None
    ) -> tuple[Tense, ...]:
        """Catalogue tenses with forms, including participles where selected."""
        return self._structure(verb, (Voice(voice), Mode(mode)), Tense, homonym_index)

    def persons(
        self, verb: str, voice: Voice, mode: Mode, tense: Tense, homonym_index: int | None = None
    ) -> tuple[Person, ...]:
        """Persons grouped by identical full spellings in declaration order; no participles."""
        if Mode(mode) == Mode.PARTICIPE:
            return ()
        groups = {}
        for person in Person:
            raw = self.form(
                verb,
                f"{Voice(voice).value}|{Mode(mode).value}|{Tense(tense).value}|{person.value}",
                homonym_index=homonym_index,
                spelling="all",
            )
            if raw is not None:
                groups.setdefault(raw, []).append(person)
        return tuple(p for group in groups.values() for p in group)

    def conjugate_alternative(
        self,
        verb: str,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonym_index: int | None = None,
    ) -> str | None:
        """Alternative finite spelling, or primary when no alternative exists."""
        return self.form(
            verb,
            f"{voice.value}|{mode.value}|{tense.value}|{person.value}",
            homonym_index=homonym_index,
            spelling="alternative",
        )

    def has_alternative_form(
        self,
        verb: str,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonym_index: int | None = None,
    ) -> bool:
        """Whether a catalogue finite form contains semicolon-separated alternatives."""
        return ";" in (
            self.form(
                verb,
                f"{voice.value}|{mode.value}|{tense.value}|{person.value}",
                homonym_index=homonym_index,
                spelling="all",
            )
            or ""
        )

    def participle_alternative(
        self, verb: str, voice: Voice, tense: Tense, homonym_index: int | None = None
    ) -> str | None:
        """Alternative participle spelling, falling back to primary."""
        return self.form(
            verb,
            f"{voice.value}|participe|{tense.value}|-",
            homonym_index=homonym_index,
            spelling="alternative",
        )

    def has_alternative_participle(
        self, verb: str, voice: Voice, tense: Tense, homonym_index: int | None = None
    ) -> bool:
        """Whether this catalogue participle has alternative spellings."""
        return ";" in (
            self.form(
                verb,
                f"{voice.value}|participe|{tense.value}|-",
                homonym_index=homonym_index,
                spelling="all",
            )
            or ""
        )

    def get_pronoun(
        self,
        verb: str,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonym_index: int | None = None,
    ) -> str | None:
        """Contextual primary subject prefix including trailing space/apostrophe."""
        return self.pronoun(
            verb, f"{voice.value}|{mode.value}|{tense.value}|{person.value}", homonym_index
        )

    def conjugate_with_pronoun(
        self,
        verb: str,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonym_index: int | None = None,
    ) -> str | None:
        """Catalogue finite form with subject; imperatives are bare."""
        return self.with_pronoun(
            verb, f"{voice.value}|{mode.value}|{tense.value}|{person.value}", homonym_index
        )

    def conjugate_alternative_with_pronoun(
        self,
        verb: str,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonym_index: int | None = None,
    ) -> str | None:
        """Alternative catalogue finite form with its contextual subject."""
        return self.with_pronoun(
            verb,
            f"{voice.value}|{mode.value}|{tense.value}|{person.value}",
            homonym_index,
            "alternative",
        )

    def conjugate(
        self,
        verb: str,
        voice: Voice | None = None,
        mode: Mode | None = None,
        tense: Tense | None = None,
        person: Person | None = None,
        homonym_index: int | None = None,
    ) -> str | dict | None:
        """Catalogue finite forms; omit trailing selectors for typed nested dictionaries.

        With no selectors, missing output is None; scoped bulk queries return an
        empty dictionary. Single queries return a string or None. Inference may
        be unattested and preserves semicolon alternatives. Exact entry keys take
        precedence over homonym_index; the default selects the first homonym.
        """
        return self._conjugate(verb, voice, mode, tense, person, homonym_index, "catalogue")

    def participle(
        self, verb: str, voice: Voice, tense: Tense, homonym_index: int | None = None
    ) -> str | None:
        """Catalogue participle selected by gendered tense, or None if unsupported."""
        return self.form(
            verb, f"{voice.value}|participe|{tense.value}|-", "catalogue", homonym_index
        )

    def participles(
        self, verb: str, voice: Voice, homonym_index: int | None = None
    ) -> dict[Tense, str]:
        """All available catalogue participles keyed by typed tense; missing values omitted."""
        return {
            tense: value
            for tense in Tense
            if (value := self.participle(verb, voice, tense, homonym_index)) is not None
        }

    def raw_inferred_conjugation(
        self,
        verb: str,
        voice: Voice | None = None,
        mode: Mode | None = None,
        tense: Tense | None = None,
        person: Person | None = None,
        homonym_index: int | None = None,
    ) -> str | dict | None:
        """Inferred finite forms; omit trailing selectors for typed nested dictionaries.

        With no selectors, missing output is None; scoped bulk queries return an
        empty dictionary. Single queries return a string or None. Inference may
        be unattested and preserves semicolon alternatives. Exact entry keys take
        precedence over homonym_index; the default selects the first homonym.
        """
        return self._conjugate(verb, voice, mode, tense, person, homonym_index, "inferred")

    def raw_inferred_participle(
        self, verb: str, voice: Voice, tense: Tense, homonym_index: int | None = None
    ) -> str | None:
        """Inferred participle selected by gendered tense, or None if unsupported."""
        return self.form(
            verb, f"{voice.value}|participe|{tense.value}|-", "inferred", homonym_index
        )

    def raw_inferred_participles(
        self, verb: str, voice: Voice, homonym_index: int | None = None
    ) -> dict[Tense, str]:
        """All available inferred participles keyed by typed tense; missing values omitted."""
        return {
            tense: value
            for tense in Tense
            if (value := self.raw_inferred_participle(verb, voice, tense, homonym_index))
            is not None
        }

    def raw_inferred_gerondif(
        self, verb: str, voice: Voice, tense: Tense, homonym_index: int | None = None
    ) -> str | None:
        """Inferred gérondif; each inferred alternative receives en."""
        return self.gerondif(verb, voice.value, tense.value, "inferred", homonym_index)

    def guess_conjugation(
        self,
        verb: str,
        voice: Voice | None = None,
        mode: Mode | None = None,
        tense: Tense | None = None,
        person: Person | None = None,
        homonym_index: int | None = None,
    ) -> str | dict | None:
        """Guess finite forms; omit trailing selectors for typed nested dictionaries.

        With no selectors, missing output is None; scoped bulk queries return an
        empty dictionary. Single queries return a string or None. Inference may
        be unattested and preserves semicolon alternatives. Exact entry keys take
        precedence over homonym_index; the default selects the first homonym.
        """
        return self._conjugate(verb, voice, mode, tense, person, homonym_index, "guess")

    def guess_participle(
        self, verb: str, voice: Voice, tense: Tense, homonym_index: int | None = None
    ) -> str | None:
        """Guess participle selected by gendered tense, or None if unsupported."""
        return self.form(verb, f"{voice.value}|participe|{tense.value}|-", "guess", homonym_index)

    def guess_participles(
        self, verb: str, voice: Voice, homonym_index: int | None = None
    ) -> dict[Tense, str]:
        """All available guess participles keyed by typed tense; missing values omitted."""
        return {
            tense: value
            for tense in Tense
            if (value := self.guess_participle(verb, voice, tense, homonym_index)) is not None
        }

    def guess_gerondif(
        self, verb: str, voice: Voice, tense: Tense, homonym_index: int | None = None
    ) -> str | None:
        """Guess gérondif; each inferred alternative receives en."""
        return self.gerondif(verb, voice.value, tense.value, "guess", homonym_index)

    async def conjugate_alternative_async(
        self,
        verb: str,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonym_index: int | None = None,
    ):
        """Run conjugate_alternative off the event loop; cancellation does not stop worker work."""
        return await asyncio.to_thread(
            self.conjugate_alternative, verb, voice, mode, tense, person, homonym_index
        )

    async def participle_alternative_async(
        self, verb: str, voice: Voice, tense: Tense, homonym_index: int | None = None
    ):
        """Run participle_alternative off the event loop; cancellation does not stop worker work."""
        return await asyncio.to_thread(
            self.participle_alternative, verb, voice, tense, homonym_index
        )

    async def get_pronoun_async(
        self,
        verb: str,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonym_index: int | None = None,
    ):
        """Run get_pronoun off the event loop; cancellation does not stop worker work."""
        return await asyncio.to_thread(
            self.get_pronoun, verb, voice, mode, tense, person, homonym_index
        )

    async def conjugate_with_pronoun_async(
        self,
        verb: str,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonym_index: int | None = None,
    ):
        """Run conjugate_with_pronoun off the event loop; cancellation does not stop worker work."""
        return await asyncio.to_thread(
            self.conjugate_with_pronoun, verb, voice, mode, tense, person, homonym_index
        )

    async def conjugate_alternative_with_pronoun_async(
        self,
        verb: str,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonym_index: int | None = None,
    ):
        """Run conjugate_alternative_with_pronoun off the event loop; cancellation does not stop worker work."""
        return await asyncio.to_thread(
            self.conjugate_alternative_with_pronoun, verb, voice, mode, tense, person, homonym_index
        )

    async def conjugate_async(
        self,
        verb: str,
        voice: Voice | None = None,
        mode: Mode | None = None,
        tense: Tense | None = None,
        person: Person | None = None,
        homonym_index: int | None = None,
    ):
        """Run conjugate off the event loop; cancellation does not stop worker work."""
        return await asyncio.to_thread(
            self.conjugate, verb, voice, mode, tense, person, homonym_index
        )

    async def participle_async(
        self, verb: str, voice: Voice, tense: Tense, homonym_index: int | None = None
    ):
        """Run participle off the event loop; cancellation does not stop worker work."""
        return await asyncio.to_thread(self.participle, verb, voice, tense, homonym_index)

    async def participles_async(self, verb: str, voice: Voice, homonym_index: int | None = None):
        """Run participles off the event loop; cancellation does not stop worker work."""
        return await asyncio.to_thread(self.participles, verb, voice, homonym_index)

    async def raw_inferred_conjugation_async(
        self,
        verb: str,
        voice: Voice | None = None,
        mode: Mode | None = None,
        tense: Tense | None = None,
        person: Person | None = None,
        homonym_index: int | None = None,
    ):
        """Run raw_inferred_conjugation off the event loop; cancellation does not stop worker work."""
        return await asyncio.to_thread(
            self.raw_inferred_conjugation, verb, voice, mode, tense, person, homonym_index
        )

    async def raw_inferred_participle_async(
        self, verb: str, voice: Voice, tense: Tense, homonym_index: int | None = None
    ):
        """Run raw_inferred_participle off the event loop; cancellation does not stop worker work."""
        return await asyncio.to_thread(
            self.raw_inferred_participle, verb, voice, tense, homonym_index
        )

    async def raw_inferred_participles_async(
        self, verb: str, voice: Voice, homonym_index: int | None = None
    ):
        """Run raw_inferred_participles off the event loop; cancellation does not stop worker work."""
        return await asyncio.to_thread(self.raw_inferred_participles, verb, voice, homonym_index)

    async def raw_inferred_gerondif_async(
        self, verb: str, voice: Voice, tense: Tense, homonym_index: int | None = None
    ):
        """Run raw_inferred_gerondif off the event loop; cancellation does not stop worker work."""
        return await asyncio.to_thread(
            self.raw_inferred_gerondif, verb, voice, tense, homonym_index
        )

    async def guess_conjugation_async(
        self,
        verb: str,
        voice: Voice | None = None,
        mode: Mode | None = None,
        tense: Tense | None = None,
        person: Person | None = None,
        homonym_index: int | None = None,
    ):
        """Run guess_conjugation off the event loop; cancellation does not stop worker work."""
        return await asyncio.to_thread(
            self.guess_conjugation, verb, voice, mode, tense, person, homonym_index
        )

    async def guess_participle_async(
        self, verb: str, voice: Voice, tense: Tense, homonym_index: int | None = None
    ):
        """Run guess_participle off the event loop; cancellation does not stop worker work."""
        return await asyncio.to_thread(self.guess_participle, verb, voice, tense, homonym_index)

    async def guess_participles_async(
        self, verb: str, voice: Voice, homonym_index: int | None = None
    ):
        """Run guess_participles off the event loop; cancellation does not stop worker work."""
        return await asyncio.to_thread(self.guess_participles, verb, voice, homonym_index)

    async def guess_gerondif_async(
        self, verb: str, voice: Voice, tense: Tense, homonym_index: int | None = None
    ):
        """Run guess_gerondif off the event loop; cancellation does not stop worker work."""
        return await asyncio.to_thread(self.guess_gerondif, verb, voice, tense, homonym_index)

    async def common_prefix_async(self, verb: str, homonym_index: int | None = None) -> str | None:
        """Run common_prefix off the event loop; worker work is not cancelled."""
        return await asyncio.to_thread(self.common_prefix, verb, homonym_index)

    async def raw_inferred_common_prefix_async(
        self, verb: str, homonym_index: int | None = None
    ) -> str | None:
        """Run raw_inferred_common_prefix off the event loop; worker work is not cancelled."""
        return await asyncio.to_thread(self.raw_inferred_common_prefix, verb, homonym_index)

    async def guess_common_prefix_async(
        self, verb: str, homonym_index: int | None = None
    ) -> str | None:
        """Run guess_common_prefix off the event loop; worker work is not cancelled."""
        return await asyncio.to_thread(self.guess_common_prefix, verb, homonym_index)

    async def gerondif_async(
        self, verb: str, voice: Voice, tense: Tense, homonym_index: int | None = None
    ) -> str | None:
        """Derive a catalogue gérondif off the event loop."""
        return await asyncio.to_thread(
            self.gerondif, verb, voice.value, tense.value, homonym_index=homonym_index
        )
