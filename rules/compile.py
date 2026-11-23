"""Compile the JSON Lines spelling rules into language-independent FCR1 tables."""

import argparse
import collections
import json
import struct
from pathlib import Path


def words(values):
    return struct.pack(f"<{len(values)}I", *values)


def indexed(rows):
    offsets = [0]
    payload = bytearray()
    for row in rows:
        payload.extend(row)
        offsets.append(len(payload))
    return words([len(offsets) - 1, *offsets]) + payload


def compile_rules(source):
    records = collections.defaultdict(list)
    for line in source.read_text().splitlines():
        name, row = json.loads(line)
        records[name].append(row)
    if records.pop("format") != [1] or set(records) != {
        "slot",
        "verb",
        "suffix",
        "template",
        "block",
        "program",
    }:
        raise ValueError("Invalid rule syntax/version")
    pool = {}

    def sid(value):
        return pool.setdefault(value, len(pool))

    slots = records["slot"]
    assert slots == sorted(set(slots))
    missing = 0xFFFFFFFF
    sections = [b"", words([sid(s) for s in slots])]
    for name in ("verb", "suffix"):
        rows = records[name]
        keys = [r[0] for r in rows]
        assert keys == sorted(set(keys))
        entries = []
        for key, value, *extra in rows:
            entries.extend((sid(key), value))
            if name == "verb":
                (variant,) = extra
                entries.append(missing if variant is None else sid(variant))
            else:
                assert 0 <= value < len(records["template"])
        sections.append(words(entries))
    for name, width, limit in (
        ("template", (len(slots) + 15) // 16, len(records["block"])),
        ("block", 16, len(records["program"])),
    ):
        rows = records[name]
        assert all(len(r) == width and all(0 <= i < limit for i in r) for r in rows)
        sections.append(b"".join(words(r) for r in rows))
    assert records["program"][0] == []
    programs = []
    for program in records["program"]:
        operands = []
        for pre, trim, post in program:
            assert trim is None or 0 <= trim < missing
            operands.extend((sid(pre), missing if trim is None else trim, sid(post)))
        programs.append(words(operands))
    sections.append(indexed(programs))
    sections[0] = indexed(s.encode() for s in pool)
    offsets = [40]
    for section in sections:
        offsets.append(offsets[-1] + len(section))
    return b"FCR1" + words([1, *offsets]) + b"".join(sections)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.write_bytes(compile_rules(args.source))
