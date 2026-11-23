"""Learn an exact paradigm classifier and spelling edits from a SQLite catalogue."""

import argparse
import collections
import json
import re
import sqlite3
from pathlib import Path


def split_key(key):
    match = re.fullmatch(r"([^_|^]+)(?:_([0-9]+))?", key)
    if match is None:
        raise ValueError(f"Unsupported spelling in catalogue: {key!r}")
    return match.group(1), match.group(2) or ""


def edit(lemma, alternative):
    """Keep the longest initial stem shared with the last lexical word."""
    start = alternative.rfind(" ") + 1
    positions = [start] + [i + 1 for i in range(start, len(alternative)) if alternative[i] in "'’"]
    best_length = 0
    best_start = start
    for position in positions:
        length = 0
        for left, right in zip(lemma, alternative[position:]):
            if left != right:
                break
            length += 1
        if length > best_length:
            best_length, best_start = length, position
    if not best_length:
        return ("", None, alternative)
    return (
        alternative[:best_start],
        len(lemma) - best_length,
        alternative[best_start + best_length :],
    )


def suffix_decisions(assignments):
    votes = collections.defaultdict(collections.Counter)
    for verb, template in assignments:
        lemma, homonym = split_key(verb)
        marked = "^" + homonym + "|" + lemma
        for i in range(len(marked) + 1):
            votes[marked[i:]][template] += 1
    best = {suffix: min(counts, key=lambda t: (-counts[t], t)) for suffix, counts in votes.items()}
    return sorted(
        (suffix, winner)
        for suffix, winner in best.items()
        if not suffix or winner != best[suffix[1:]]
    )


def write_rules(path, sections):
    # JSON Lines keeps one definition on each line for inspection and diffing.
    with path.open("w", encoding="utf-8", newline="\n") as out:
        for name, records in sections:
            for value in records:
                print(
                    json.dumps([name, value], ensure_ascii=False, separators=(",", ":")), file=out
                )


def learn(db, output):
    con = sqlite3.connect(db.resolve().as_uri() + "?mode=ro", uri=True)
    verbs = list(
        con.execute("""
        SELECT id, infinitif, h_aspire, bloque_elision_liaison, rectification_1990,
               rectification_1990_variante FROM verbes ORDER BY infinitif""")
    )
    observed = set()
    for voice, mood, tense, persons in con.execute(
        "SELECT DISTINCT voix, mode, temps, personne FROM conjugaisons"
    ):
        observed.update("|".join((voice, mood, tense, p)) for p in persons.split(";"))
    for voice, tense in con.execute("SELECT DISTINCT voix, forme FROM participes"):
        observed.add("|".join((voice, "participe", tense, "-")))
    slots = sorted(observed)
    slot_ids = {s: i for i, s in enumerate(slots)}
    programs, blocks, templates = {}, {}, {}
    lexicon, assignments = [], []
    counts = collections.Counter()
    for ident, key, h, blocking, reform, variant in verbs:
        lemma, _ = split_key(key)
        row = [0] * (16 * ((len(slots) + 15) // 16))
        # Forms frequently repeat across persons and compound tenses within a verb.
        local = {}
        for voice, mood, tense, persons, output_text in con.execute(
            """
                SELECT voix, mode, temps, personne, conjugaison FROM conjugaisons
                WHERE verbe_id=? UNION ALL SELECT voix, 'participe', forme, '-', participe
                FROM participes WHERE verbe_id=?""",
            (ident, ident),
        ):
            if output_text not in local:
                code = tuple(edit(lemma, alt) for alt in output_text.split(";"))
                local[output_text] = programs.setdefault(code, len(programs) + 1)
            for person in persons.split(";"):
                slot = slot_ids["|".join((voice, mood, tense, person))]
                if row[slot] not in (0, local[output_text]):
                    raise ValueError(f"Conflicting forms for {key}, {slots[slot]}")
                row[slot] = local[output_text]
        block_ids = tuple(
            blocks.setdefault(tuple(row[i : i + 16]), len(blocks)) for i in range(0, len(row), 16)
        )
        template = templates.setdefault(block_ids, len(templates))
        lexicon.append([key, h + 2 * blocking + 4 * reform, variant])
        assignments.append((key, template))
        counts[template] += 1
    decisions = suffix_decisions(assignments)
    write_rules(
        output,
        [
            ("format", [1]),
            ("slot", slots),
            ("verb", lexicon),
            ("suffix", decisions),
            ("template", templates.keys()),
            ("block", blocks.keys()),
            ("program", [(), *programs.keys()]),
        ],
    )
    print(
        json.dumps(
            dict(
                verbs=len(verbs),
                slots=len(slots),
                templates=len(templates),
                singleton_templates=sum(n == 1 for n in counts.values()),
                largest_template=max(counts.values()),
                suffixes=len(decisions),
                blocks=len(blocks),
                programs=len(programs),
                all_literal_programs=sum(all(t is None for _, t, _ in p) for p in programs),
            ),
            indent=2,
        )
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("database", type=Path)
    parser.add_argument("rules", type=Path)
    args = parser.parse_args()
    learn(args.database, args.rules)
