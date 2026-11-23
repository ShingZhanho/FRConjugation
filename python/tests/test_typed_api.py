"""Compare typed public operations with the Swift-authored portable fixtures."""

import asyncio
import unittest
from pathlib import Path

from frconjugation import Conjugator, Mode, Person, Tense, Voice
from test_conformance import decode


def flatten(value, prefix=()):
    if value is None or isinstance(value, str):
        return value
    lines = []

    def walk(node, path):
        for key, child in node.items():
            new_path = (*path, key.value)
            if isinstance(child, dict):
                walk(child, new_path)
            else:
                lines.append("|".join(new_path) + "=" + child)

    walk(value, prefix)
    return "\n".join(sorted(lines))


class TypedAPITests(unittest.TestCase):
    def test_swift_vectors(self):
        c = Conjugator()
        rows = (
            (Path(__file__).resolve().parents[2] / "tests/typed-api.tsv")
            .read_text(encoding="utf-8")
            .splitlines()
        )
        for line in rows[1:]:
            r = line.split("\t")
            with self.subTest(case=r[0], operation=r[1]):
                self.assertEqual(evaluate(c, r), decode(r[9]))

    def test_async(self):
        async def run():
            c = await Conjugator.load()
            self.assertIs(await Conjugator.get_shared_async(), Conjugator.get_shared())
            args = (
                "manger",
                Voice.ACTIVE_AVOIR,
                Mode.INDICATIF,
                Tense.PRESENT,
                Person.FIRST_PLURAL_MASCULINE,
            )
            for name in ("conjugate", "raw_inferred_conjugation", "guess_conjugation"):
                for size in range(1, 6):
                    self.assertEqual(
                        await getattr(c, name + "_async")(*args[:size]),
                        getattr(c, name)(*args[:size]),
                    )
            self.assertEqual(
                await c.participle_async(
                    "prendre", Voice.ACTIVE_AVOIR, Tense.PASSE_FEMININ_PLURIEL
                ),
                "prises",
            )
            self.assertEqual(
                await c.gerondif_async("manger", Voice.ACTIVE_AVOIR, Tense.GERONDIF_PRESENT),
                "en mangeant",
            )
            self.assertEqual(await c.common_prefix_async("manger"), "mang")

        asyncio.run(run())


def evaluate(c, r):
    op, verb = r[1:3]
    selectors = [
        typ(raw) if raw != "-" else None for typ, raw in zip((Voice, Mode, Tense, Person), r[3:7])
    ]
    v, _m, t, _p = selectors
    h = int(r[7]) or None
    if op.startswith("enum_"):
        typ = {"enum_voice": Voice, "enum_mode": Mode, "enum_tense": Tense, "enum_person": Person}[
            op
        ]
        return ",".join(x.value for x in typ)
    if op == "person_pronouns":
        return ",".join(x.pronoun for x in Person)
    if op == "all_verbs":
        return ",".join(c.all_verbs)
    if op == "verb_count":
        return str(c.verb_count)
    names = {
        "has_verb": "has_verb",
        "has_homonyms": "has_homonyms",
        "homonym_count": "homonym_count",
        "homonym_indices": "homonym_indices",
        "h_aspire": "is_h_aspire",
        "blocking": "blocks_elision_and_liaison",
        "reform": "is_1990_reform",
        "variant": "reform_variant",
    }
    if op in names:
        value = getattr(c, names[op])(verb, h) if op == "blocking" else getattr(c, names[op])(verb)
        if isinstance(value, bool):
            return "1" if value else "0"
        if isinstance(value, tuple):
            return ",".join(map(str, value))
        return str(value) if isinstance(value, int) else value
    if op in ("voices", "modes", "tenses", "persons"):
        count = ("voices", "modes", "tenses", "persons").index(op)
        return ",".join(x.value for x in getattr(c, op)(verb, *selectors[:count], homonym_index=h))
    methods = {
        "alternative": "conjugate_alternative",
        "has_alternative": "has_alternative_form",
        "pronoun": "get_pronoun",
        "with_pronoun": "conjugate_with_pronoun",
        "alternative_with_pronoun": "conjugate_alternative_with_pronoun",
        "participle_alternative": "participle_alternative",
        "has_alternative_participle": "has_alternative_participle",
    }
    if op in methods:
        args = (v, t) if "participle" in op else selectors
        value = getattr(c, methods[op])(verb, *args, homonym_index=h)
        return ("1" if value else "0") if isinstance(value, bool) else value
    prefix = {"catalogue": "", "inferred": "raw_inferred_", "guess": "guess_"}[r[8]]
    if op == "finite":
        name = "conjugate" if not prefix else prefix + "conjugation"
        value = getattr(c, name)(verb, *selectors, homonym_index=h)
        return flatten(value, tuple(x.value for x in selectors if x is not None))
    args = (v,) if op == "participles" else (v, t)
    value = getattr(c, prefix + op)(verb, *args, homonym_index=h)
    return flatten(value)
