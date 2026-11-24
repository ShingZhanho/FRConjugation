# Shared behavioral conformance cases

`conformance.tsv` is the language-independent test specification. Its expected
answers are fixed data, never computed by the implementation under test. The
initial 72 prefix expectations were captured from the validated Swift public
APIs; known-verb guess expectations now match the existing catalogue expectations
under the 5.2.0 contract; other cases consolidate the existing per-language assertions and explicit
catalogue forms. These are regression/parity cases, not an independent linguistic
audit or a replacement for the full-catalogue comparison.

Each implementation reads the file with its own standard library. Kotlin/JUnit
creates one parameterized test per row; Swift/XCTest and the C++/C# test programs and Python unittest subtests
iterate rows and report the case ID on failure. Adding a row automatically adds
coverage in every language. This provides data-driven test generation without
writing source files or introducing a shared generator toolchain. Language-specific
ownership, error, concurrency and asynchronous API checks remain in their native
suites. The shared fixture is a test resource only, not shipped with the libraries.

## Format

UTF-8, LF line endings, one header and eight tab-separated columns per row:

| Column | Meaning |
| --- | --- |
| `id` | Unique stable case identifier; do not renumber existing cases. |
| `operation` | `form`, `prefix`, `pronoun`, `with_pronoun`, or `gerondif`. |
| `mode` | `catalogue`, `inferred`, or `guess`. Pronoun operations require `catalogue`. |
| `verb` | Input string, preserving whitespace and Unicode normalization. |
| `selector` | `voice\|mode\|tense\|person` for forms/pronouns, `voice\|tense` for gérondifs, empty for prefixes. Participles use `-` as person. Unknown selectors may test missing results. |
| `homonym` | `0` for the default, otherwise a positive index. |
| `spelling` | `primary` or `alternative`; only catalogue form/with-pronoun selection uses it. Use primary otherwise. |
| `expected` | Expected string, empty for a valid empty result, or `\N` for missing/null. |

String columns support `\\`, `\t`, `\n`, and `\r` escapes. An entire field equal
to `\N` represents null and is permitted only for `expected`. Literal backslash-N
is written `\\N`. Leading/trailing spaces are significant. No trimming, Unicode
normalization, comments, blank rows, or quoted fields are allowed in the fixture.
The format deliberately distinguishes empty prefixes from absent forms.

Use raw catalogue labels rather than language enum names. A new operation needs
an adapter in all language readers; a new case using existing operations needs only a
fixture row. Invalid API arguments, exceptions, C status codes and ownership
should be tested in language-specific suites because their contracts differ.

## Running

See [the main README](../README.md) for complete commands and requirements.
Swift's shared cases alone can be run with:

```sh
swift test -c release --filter SharedConformanceTests
```

No other language is required to execute a target's shared tests. Keep expected
results under review: do not regenerate them from the code being changed merely
to make a failing test pass.

## Typed API parity

`typed-api.tsv` contains Swift-authored expectations and normalized-input counterparts with columns
`id`, `operation`, `verb`, `voice`, `mode`, `tense`, `person`, `homonym`,
`prediction`, `expected`. `-` denotes an omitted grammatical selector. Expected
values use the same escaping and null rules as the original fixture. Bulk finite
results are canonicalized to sorted `voice|mode|tense|person=value` lines;
participle maps use sorted `tense=value` lines. Ordered lists use commas. An empty
map/list serializes as an empty string, distinct from missing `\N`.

The Swift test invokes the actual public overload for each requested scope. Each
port's reader also invokes its typed APIs, rather than comparing only the raw
slot renderer. Normal tests never rewrite expected data. If an intentional Swift
contract change requires regenerating the oracle, review the resulting diff:

```sh
FRCONJUGATION_WRITE_TYPED_FIXTURE="$PWD/tests/typed-api.tsv" \
  swift test -c release --filter TypedAPIParityTests
```

This optional authoring command requires Swift. Running the resulting fixture in
any other language requires only that language's own toolchain. Async scheduling,
result ownership, loading and argument errors are additionally checked in the
language-specific suites.

TypeScript reads both fixtures with Node.js and, optionally, Chrome. See
[TypeScript verification](../typescript/README.md#verification). Its asynchronous
reader runs the same cases in real workers, rather than wrapping synchronous
calls in already-resolved Promises.

Normalization cases reuse fixed lowercase catalogue expectations with uppercase and
surrounding Unicode whitespace. Shared slot cases also cover tabs/newlines and
known defective-verb gaps; typed cases cover metadata, homonyms and structure.
