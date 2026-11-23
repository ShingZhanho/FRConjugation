"""Shared behavioral cases plus Python-specific argument and ownership checks."""

import unittest
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from frconjugation import Conjugator, Prediction, Spelling


def decode(text):
    if text == r"\N":
        return None
    result = []
    chars = iter(text)
    for char in chars:
        result.append(
            char if char != "\\" else {"n": "\n", "t": "\t", "r": "\r", "\\": "\\"}[next(chars)]
        )
    return "".join(result)


class ConformanceTests(unittest.TestCase):
    def test_shared_cases(self):
        rows = (
            (Path(__file__).resolve().parents[2] / "tests/conformance.tsv")
            .read_text(encoding="utf-8")
            .splitlines()
        )
        self.assertEqual(
            rows[0], "id\toperation\tmode\tverb\tselector\thomonym\tspelling\texpected"
        )
        self.assertGreater(len(rows), 1)
        ids = set()
        c = Conjugator()
        for line in rows[1:]:
            row = line.split("\t")
            self.assertEqual(len(row), 8)
            ident, operation, mode, verb, selector, index, spelling, expected = row
            self.assertNotIn(ident, ids)
            ids.add(ident)
            with self.subTest(case=ident):
                verb, selector, expected = map(decode, (verb, selector, expected))
                mode, spelling, homonym = Prediction(mode), Spelling(spelling), int(index) or None
                if operation == "form":
                    actual = c.form(verb, selector, mode, homonym, spelling)
                elif operation == "prefix":
                    actual = {
                        Prediction.CATALOGUE: c.common_prefix,
                        Prediction.INFERRED: c.raw_inferred_common_prefix,
                        Prediction.GUESS: c.guess_common_prefix,
                    }[mode](verb, homonym)
                elif operation == "gerondif":
                    voice, tense = selector.split("|")
                    actual = c.gerondif(verb, voice, tense, mode, homonym)
                elif operation in ("pronoun", "with_pronoun"):
                    actual = getattr(c, operation)(verb, selector, homonym, spelling)
                else:
                    self.fail("Unknown operation")
                self.assertEqual(actual, expected)

    def test_python_contract(self):
        c = Conjugator()
        slot = "voix_active_avoir|indicatif|present|1pm"
        self.assertEqual(len(c.entries), 6358)
        self.assertEqual(len(c.slots), 820)
        self.assertEqual(len(c.all_verbs), 6298)
        self.assertEqual(c.homonym_indices("ressortir"), (1, 2))
        self.assertTrue(c.has_verb("ressortir"))
        for index in (0, -1, True, 1.5):
            with self.assertRaises(ValueError):
                c.form("manger", slot, homonym_index=index)
        with self.assertRaises(TypeError):
            Conjugator("custom.fcr")
        with self.assertRaises(ValueError):
            c.form("manger", slot, prediction="typo")
        with self.assertRaises(ValueError):
            c.pronoun("manger", slot, spelling=Spelling.ALL)
        with ThreadPoolExecutor(max_workers=8) as pool:
            self.assertEqual(
                list(pool.map(lambda _: c.form("manger", slot), range(100))), ["mangeons"] * 100
            )
        forms = c.forms("manger")
        self.assertEqual(forms[slot], "mangeons")
        forms.clear()
        self.assertEqual(c.form("manger", slot), "mangeons")


if __name__ == "__main__":
    unittest.main()
