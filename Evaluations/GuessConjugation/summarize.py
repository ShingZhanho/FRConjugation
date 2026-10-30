"""Summarize the opt-in Swift evaluation without running inference again."""
from collections import defaultdict
import hashlib
import json
from pathlib import Path

folder = Path(__file__).resolve().parent
repository = folder.parent.parent
report = json.loads((folder / "results.json").read_text())
provenance = {}
for relative in (
    "swift_lib/Sources/FRConjugation/Resources/model.json",
    "swift_lib/Sources/FRConjugation/Resources/weights.bin",
    "swift_lib/Sources/FRConjugation/Conjugator.swift",
    "swift_lib/Sources/FRConjugation/Conjugator+Inference.swift",
    "swift_lib/Sources/FRConjugation/Conjugator+NonpersonalInference.swift",
    "swift_lib/Sources/FRConjugation/InferenceEngine.swift",
    "Evaluations/GuessConjugation/cases.json",
):
    provenance[relative] = hashlib.sha256((repository / relative).read_bytes()).hexdigest()
report["sha256"] = provenance
(folder / "results.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
groups = defaultdict(list)
for row in report["cases"]:
    groups[row["category"]].append(row)
coverage = report["coverage"]
lines = [
    "# Raw and catalogue-first inference evaluation — 2026-10-30", "",
    "The bundled v4.3.0 neural weights were used unchanged. Raw inference bypasses the correction table; each guess family prefers its matching catalogue API (conjugate or participle) and falls back only for missing forms. "
    "References were fixed before observing predictions; unknown verbs were checked against the model's known-verbs set. "
    "The exact reference forms, publisher URLs and sampling method are in [cases.json](cases.json). "
    "Raw predictions for every scored case and every coverage slot, with artifact/source checksums, are in [results.json](results.json).", "",
    "| Sample | Cases | Raw exact full-string matches | Raw primary accepted | Hybrid primary accepted |",
    "|---|---:|---:|---:|---:|",
]
for category, rows in groups.items():
    lines.append(f"| {category} | {len(rows)} | {sum(x['exact'] for x in rows)} | {sum(x['primaryAccepted'] for x in rows)} | {sum(x['guessPrimaryAccepted'] for x in rows)} |")
lines += ["", f"All {len(coverage)} model-supported base form combinations returned nonempty raw predictions across the finite and participle families for the invented string `blorper`. "
          "This establishes API reachability, not grammatical accuracy.", "",
          "Exact means the full prediction equals the reference, including alternative order. Primary accepted means the first "
          "predicted alternative is among the reference's accepted alternatives. Neither metric assesses confidence or whether "
          "additional predicted alternatives are correct.", "",
          "## Unseen dictionary verbs", "", "| Input | Exact matches | Publisher reference |", "|---|---:|---|"]
by_input = defaultdict(list)
for row in groups["unseen_dictionary"]:
    by_input[row["input"]].append(row)
for word, rows in sorted(by_input.items()):
    lines.append(f"| {word} | {sum(x['exact'] for x in rows)}/{len(rows)} | [Reference]({rows[0]['source']}) |")
lines += ["", "## Limits", "",
          "- This is a small, curated sample: seven first-group verbs and one third-group `-re` verb (`survendre`). "
          "It does not establish accuracy for all unknown verbs, irregular patterns, misspellings, or arbitrary text.",
          "- These eight inputs are absent from the supplied model catalogue; no retraining or verb-level held-out split was performed. "
          "The seen controls are not evidence of unseen-verb generalization.",
          "- The ten correction-table cases deliberately target known neural errors. Their failures demonstrate why raw inference "
          "does not share the corrected catalogue API's accuracy guarantee; they are not a random sample of all known forms.",
          "- The matching guess families retain all ten catalogue answers in the correction stress set, including both participle corrections. "
          "Participle cases are evaluated through rawInferredParticiple / guessParticiple, without person placeholders. Gérondif derivation and catalogue fallback are covered by separate API regression checks.",
          "- The API does not infer which voices or slots are grammatically valid for a novel input. It validates only global model support. "
          "Output is bounded by the existing decoder's 50 steps and may be malformed or truncated.", "",
          "## Reproduce", "", "From the repository root:", "", "```bash",
          'FRCONJ_GUESS_REPORT="$PWD/Evaluations/GuessConjugation/results.json" \\',
          "  swift test -c release --filter GuessConjugationTests",
          "python3 Evaluations/GuessConjugation/summarize.py", "```", "",
          "The measurement test is skipped unless the report environment variable is set. API regression tests still run normally.", "",
          "## Every scored prediction", "",
          "| Category | Input | Voice/mode/tense/person | Expected | Raw prediction | Raw exact | Hybrid prediction | Hybrid source |", "|---|---|---|---|---|---|---|---|"]
def cell(text):
    return str(text).replace("|", "\\|").replace("\n", " ")
for row in report["cases"]:
    slot = "/".join([row["voice"], row["mode"], row["tense"], row["person"] or "-"])
    lines.append("| " + " | ".join(cell(x) for x in (row["category"], row["input"], slot,
                 row["expected"], row["prediction"], "yes" if row["exact"] else "no", row["guessPrediction"], row["guessSource"])) + " |")
(folder / "README.md").write_text("\n".join(lines) + "\n")
print("Updated evaluation summary and provenance.")
