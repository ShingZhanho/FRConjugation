"""Internal FCR1 decoder; consumes only the bundled package resource."""

import struct
import unicodedata
from collections import Counter
from importlib.resources import files
from threading import Lock

_MISSING = 0xFFFFFFFF
_ALPHABET = frozenset(" '-12;_abcdefghijklmnopqrstuvwxyzâçèéêîïôûœ")


def nfc(value: str) -> str:
    return unicodedata.normalize("NFC", value)


def verb_key(value: str) -> str:
    # Unicode White_Space, excluding Python-only C0 information separators.
    return nfc(
        value.strip(
            "\t\n\v\f\r \u0085\u00a0\u1680\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u2028\u2029\u202f\u205f\u3000"
        ).lower()
    )


def lemma_index(value: str) -> tuple[str, str]:
    lemma, separator, index = value.rpartition("_")
    if separator and lemma and index and all("0" <= c <= "9" for c in index):
        return lemma, index
    return value, ""


class Catalogue:
    def __init__(self) -> None:
        data = files(__package__).joinpath("catalogue.fcr").read_bytes()

        def word(at: int) -> int:
            if at < 0 or at + 4 > len(data):
                raise ValueError("Invalid catalogue offset")
            return struct.unpack_from("<I", data, at)[0]

        if len(data) < 40 or data[:4] != b"FCR1" or word(4) != 1:
            raise ValueError("Invalid catalogue header")
        sections = tuple(word(8 + i * 4) for i in range(8))
        if sections[0] != 40 or sections[-1] != len(data) or sorted(sections) != list(sections):
            raise ValueError("Invalid catalogue directory")

        def record(section: int, index: int) -> tuple[int, int]:
            base = sections[section]
            payload = base + 8 + word(base) * 4
            start = payload + word(base + 4 + index * 4)
            end = payload + word(base + 8 + index * 4)
            if not payload <= start <= end <= sections[section + 1]:
                raise ValueError("Invalid catalogue record")
            return start, end

        strings = []
        for i in range(word(sections[0])):
            start, end = record(0, i)
            strings.append(data[start:end].decode("utf-8"))
        self.slots = tuple(strings[word(at)] for at in range(sections[1], sections[2], 4))
        self.slot_ids = {slot: i for i, slot in enumerate(self.slots)}
        self.suffixes = {
            strings[word(at)]: word(at + 4) for at in range(sections[3], sections[4], 8)
        }
        width = (len(self.slots) + 15) // 16
        self.templates = tuple(
            tuple(word(at + i * 4) for i in range(width))
            for at in range(sections[4], sections[5], width * 4)
        )
        self.blocks = tuple(
            tuple(word(at + i * 4) for i in range(16)) for at in range(sections[5], sections[6], 64)
        )
        self.programs = tuple(
            tuple(
                (strings[word(at)], word(at + 4), strings[word(at + 8)])
                for at in range(*record(6, i), 12)
            )
            for i in range(word(sections[6]))
        )
        self.entries = {}
        self.homonyms = {}
        frequencies = Counter()
        for at in range(sections[2], sections[3], 12):
            key = strings[word(at)]
            model = next(self.models(key))
            variant = word(at + 8)
            self.entries[key] = (
                word(at + 4),
                None if variant == _MISSING else strings[variant],
                model,
            )
            frequencies[model] += 1
            lemma, index = lemma_index(key)
            if index:
                self.homonyms.setdefault(lemma, []).append(int(index))
        self.homonyms = {key: tuple(sorted(indices)) for key, indices in self.homonyms.items()}
        ranked = sorted(frequencies, key=lambda m: (-frequencies[m], m))
        self.fallbacks = tuple(
            next(m for m in ranked if self.program(m, slot)) for slot in range(len(self.slots))
        )

    def resolve(self, value: str, homonym: int | None) -> str:
        if value in self.entries or value not in self.homonyms:
            return value
        return f"{value}_{homonym if homonym is not None else self.homonyms[value][0]}"

    def models(self, key: str):
        lemma, index = lemma_index(key)
        marked = f"^{index}|{lemma}"
        for at in range(len(marked) + 1):
            model = self.suffixes.get(marked[at:])
            if model is not None:
                yield model

    def program(self, model: int, slot: int) -> int:
        return self.blocks[self.templates[model][slot // 16]][slot % 16]

    def render(self, model: int, slot: int, lemma: str, fallback: bool = False) -> str | None:
        program = self.program(model, slot)
        if program == 0:
            return None
        alternatives = []
        for prefix, trim, suffix in self.programs[program]:
            if trim == _MISSING:
                retained = ""
            elif trim > len(lemma):
                if not fallback:
                    return None
                retained = lemma
            else:
                retained = lemma[: len(lemma) - trim]
            alternatives.append(prefix + retained + suffix)
        result = ";".join(alternatives)
        return lemma if fallback and not result else result

    def raw(self, value: str, slot: int, homonym: int | None, mode: str) -> str | None:
        if mode != "inferred":
            key = self.resolve(verb_key(value), homonym)
            entry = self.entries.get(key)
            if entry is not None:
                result = self.render(entry[2], slot, lemma_index(key)[0])
                if result is not None:
                    return result
            if mode == "catalogue" or self.resolve(verb_key(value), None) in self.entries:
                return None
        value = verb_key(value)
        if not value or not set(value) <= _ALPHABET:
            return None
        key = self.resolve(value, homonym)
        lemma = lemma_index(key)[0]
        for model in self.models(key):
            result = self.render(model, slot, lemma)
            if result:
                return result
        return self.render(self.fallbacks[slot], slot, lemma, True)


_bundled_lock = Lock()
_bundled_catalogue: Catalogue | None = None


def bundled() -> Catalogue:
    global _bundled_catalogue
    with _bundled_lock:
        if _bundled_catalogue is None:
            _bundled_catalogue = Catalogue()
        return _bundled_catalogue
