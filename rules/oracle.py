"""SQLite-only oracle. No learner, rule file, or compiler imports."""

import argparse
import hashlib
import json
import sqlite3
from pathlib import Path


def make_oracle(database, output):
    con = sqlite3.connect(database.resolve().as_uri() + "?mode=ro", uri=True)
    vocabulary = set()
    for v, m, t, p in con.execute(
        "SELECT voix,mode,temps,personne FROM conjugaisons GROUP BY 1,2,3,4"
    ):
        for individual in p.split(";"):
            vocabulary.add("|".join([v, m, t, individual]))
    for v, t in con.execute("SELECT voix,forme FROM participes GROUP BY 1,2"):
        vocabulary.add(f"{v}|participe|{t}|-")
    slots = sorted(vocabulary)
    oracle = []
    verbs = list(con.execute("SELECT * FROM verbes ORDER BY infinitif"))
    for ident, lemma, h, reform, variant, blocking in verbs:
        expected = {}

        def add(slot, value):
            if slot in expected and expected[slot] != value:
                raise ValueError((lemma, slot))
            expected[slot] = value

        for v, m, t, p, value in con.execute(
            "SELECT voix,mode,temps,personne,conjugaison FROM conjugaisons WHERE verbe_id=?",
            (ident,),
        ):
            for individual in p.split(";"):
                add("|".join([v, m, t, individual]), value)
        for v, t, value in con.execute(
            "SELECT voix,forme,participe FROM participes WHERE verbe_id=?", (ident,)
        ):
            add(f"{v}|participe|{t}|-", value)
        digest = hashlib.sha256()
        for key in slots:
            data = None if key not in expected else expected[key].encode()
            digest.update((0xFFFFFFFF if data is None else len(data)).to_bytes(4, "little"))
            if data is not None:
                digest.update(data)
        oracle.append(
            dict(
                key=lemma,
                flags=h + 2 * blocking + 4 * reform,
                variant=variant,
                digest=digest.hexdigest(),
                present=len(expected),
            )
        )
    output.write_text(json.dumps(dict(slots=slots, verbs=oracle)), encoding="utf-8")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("db", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    make_oracle(args.db, args.output)
