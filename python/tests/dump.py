"""Write the optional cross-runtime comparison stream using Python alone."""

import argparse
import struct

from frconjugation import Conjugator, Prediction, Spelling


def dump(path):
    c = Conjugator()
    with open(path, "wb") as output:

        def emit(value):
            data = None if value is None else value.encode("utf-8")
            output.write(struct.pack("<I", 0xFFFFFFFF if data is None else len(data)))
            if data is not None:
                output.write(data)

        for slot in c.slots:
            emit(slot)
        for entry in sorted(c.entries, key=lambda e: e.key):
            emit(entry.key)
            emit(str(entry.flags))
            emit(entry.variant)
            for slot in c.slots:
                emit(c.form(entry.key, slot, spelling=Spelling.ALL))
        for verb in (
            "blorper",
            "x",
            "er",
            "_",
            "manger",
            "finir",
            "pleuvoir",
            "aller",
            "ressortir_2",
            "réinventer",
            "télétravailler",
        ):
            for slot in c.slots:
                emit(c.form(verb, slot, Prediction.INFERRED))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output")
    dump(parser.parse_args().output)
