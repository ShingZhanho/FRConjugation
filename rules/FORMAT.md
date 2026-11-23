# FCR1 catalogue format

## File layout

All integers are unsigned 32-bit little-endian values, including offsets. Read unaligned values. Each half-open range begins at the corresponding directory offset and ends at the next offset.

| Bytes or section | Encoding |
|---|---|
| 0–3 | ASCII FCR1 |
| 4–7 | Version 1 |
| 8–39 | Eight absolute byte offsets. The first is 40 and the last is the file size. |
| 0. String pool | Indexed records of UTF-8 bytes. Empty strings have length zero. |
| 1. Slots | One string ID per logical slot. Split its text on the vertical bar into voice, mood, tense and person. Participles use mood `participe` and person `-`. |
| 2. Lexicon | Three words per row. Key string ID, flags, variant string ID. Bits 0, 1 and 2 indicate aspirated h, blocked elision and liaison, and 1990 reform respectively. A variant ID of 0xffffffff means absent. |
| 3. Suffix rules | Two words per row. Suffix string ID and template ID. The empty suffix gives the default. |
| 4. Templates | Each row contains ceil(slotCount / 16) block IDs. |
| 5. Blocks | Each row contains 16 program IDs. Padding beyond the final slot is zero. |
| 6. Programs | Indexed records. Each record contains zero or more triples of words. Each triple encodes one ordered alternative. |

An indexed section starts with a record count N, followed by N+1 byte offsets relative to the start of that section's payload, then the payload itself. Offsets begin at zero and end at payload size. All IDs use zero-based array indexing. Fixed-width sections carry no count. Derive it by dividing the section length by the record width. Lexical keys, slot labels and suffix records are sorted by the unsigned UTF-8 bytes of their text. Comparison uses the catalogue's exact bytes.

## Execution

1. Look up the complete key in the lexicon. An unknown key yields missing on the catalogue path.
2. Split a terminal underscore and decimal homonym index off the key, if present. For `ressortir_2` the base is `ressortir` and the index is `2`. For `manger` the index is empty.
3. Construct the marked spelling from a caret, the index, a vertical bar and the base. Match the longest suffix at scalar boundaries in this marked spelling. Its decision gives the template ID.
4. For a zero-based slot S select block number floor(S / 16) of that template, then program number S modulo 16 **within the selected block**. Program ID zero returns missing.
5. Read every triple of the selected program as (prefix string ID, trim count, suffix string ID). Remove that many Unicode scalars from the end of the base. Concatenate the prefix, retained base and suffix. With trim 0xffffffff, use an empty retained base. Join alternatives with a literal ASCII semicolon, with no added space. Return the exact UTF-8 result.

## Text rules

The UTF-8 source has one JSON array per line. The first element is a directive, and the second is its value. Each record adds one definition to a table. References are integer IDs in definition order within their table. Recompiling needs only this file.

| Directive | Value |
|---|---|
| format | Integer 1 |
| slot | Slot label |
| verb | Array of key, integer flags and optional variant string |
| suffix | Array of suffix string and template ID |
| template | Ordered block IDs |
| block | 16 program IDs |
| program | Array of alternatives, each an array of prefix string, trim integer or null, and suffix string. Program zero is empty. |

The compiler interns each string once and encodes references by ID. See [compile.py](compile.py) for the writer and [RuleFile.swift](../swift/Sources/FRConjugation/RuleFile.swift) for the reader.
