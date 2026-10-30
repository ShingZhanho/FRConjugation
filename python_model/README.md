# python_model -- ML Training & Python API

This directory contains the PyTorch seq2seq model for French verb conjugation:
training scripts, evaluation tools, and a reusable Python module.

## Overview

| File | Purpose |
|:-----|:--------|
| `french_conjugation_model.py` | Reusable module -- `import` this |
| `train_model.py` | Training script (reads `verbs.db`) |
| `build_final_model.py` | Embeds exception table -> `conjugation_model_final.pt` |
| `test_model.py` | Unit tests |
| `full_test_model.py` | Full-DB validation |
| `export_weights.py` | Export to portable format for the Swift package |
| `USAGE.md` | Detailed Python API reference (voices, modes, tenses, persons, aliases) |
| `conjugation_model_final.pt` | Final checkpoint -- ML + 187 exceptions (100%) |
| `conjugation_model.pt` | ML-only checkpoint (~99.97%) |
| `verbs.db` | SQLite database (6,358 verbs incl. homonyms, 5 voices) |

## Data Source

`verbs.db` is a release artefact of
[**ShingZhanho/verbe-conjugaison-academie-francaise**](https://github.com/ShingZhanho/verbe-conjugaison-academie-francaise).
Download it and place it in this directory before training.

## Requirements

- Python 3.10+
- PyTorch 2.x (`pip install torch`)
- `tqdm` (optional, for progress bars during training)

## Training Pipeline

```bash
# 1. Train the neural model
python3 train_model.py
# -> conjugation_model.pt (~6 MB, ~99.97% accuracy)

# 2. Run full database test to identify remaining errors
python3 full_test_model.py "$PWD/conjugation_model.pt"
# -> full_test_errors.json (raw errors)

# 3. Build the final model with an exception table for 100% accuracy
python3 build_final_model.py
# -> conjugation_model_final.pt
```

## Quick Start

```python
from french_conjugation_model import ConjugationModel

model = ConjugationModel()  # loads conjugation_model_final.pt

# Single form (voice is required)
model.conjugate("parler", voice="active_avoir", mode="indicatif",
                tense="present", person="1sm")
# -> "parle"

# All forms for a voice
model.conjugate("aller", voice="active_etre")
# -> { "indicatif": { "present": { "1sm": "vais", ... }, ... }, ... }

# Full conjugation (all voices)
model.conjugate("finir")
# -> { "voix_active_avoir": { ... }, ... }

# Discover voices
model.voices("aller")
# -> ["voix_active_etre", "voix_prono"]

model.has_verb("parler")    # -> True
model.is_h_aspire("hair")  # -> True
```

See [USAGE.md](USAGE.md) for the complete API reference including all accepted
voice, mode, tense, and person values with aliases.

## Testing

```bash
# Unit tests
python3 test_model.py

# Full database validation (2,572,183 forms)
python3 full_test_model.py [path/to/model.pt]
```

## Architecture

| Component | Detail |
|:----------|:-------|
| Encoder | Bidirectional GRU, 256 hidden, 64-dim char embeddings |
| Attention | Bahdanau (additive) |
| Decoder | GRU conditioned on voice + mode + tense + person embeddings (32-dim each) |
| Bridge | Linear + tanh: encoder hidden + 4 conditioning embeddings -> decoder initial hidden |
| Parameters | ~1,540,000 |
| Exception table | 187 corrections in the imported model for 100% accuracy |
| Accuracy | **100%** on 6,358 verbs (5 voices) |
| Size | ~6 MB |

## Lexical blocking metadata

Training reads `bloque_elision_liaison` from dataset v0.5.0 and saves it in the
checkpoint. Legacy databases/checkpoints retain their h-only fallback.
`ConjugationModel.blocks_elision_and_liaison(infinitive)` reports the checkpoint's
list independently of `is_h_aspire`. A legacy checkpoint without the list cannot
report the non-h exceptions through that query.

Export a previously trained checkpoint with metadata from its matching database:

```bash
# From the repository root; requires the training/export Python environment.
python3 python_model/export_weights.py --database python_model/verbs.db
```

For an already exported Swift model, refresh just its blocking metadata without
PyTorch or another training run:

```bash
python3 python_model/lexical_metadata.py python_model/verbs.db \
  swift_lib/Sources/FRConjugation/Resources/model.json
```

This changes `model.json` only; it does not rewrite checkpoints or neural weights.
A mismatched verb catalogue is rejected. The optional list keeps export format 2
compatible with older Swift loaders; updated loaders fall back to `h_aspire` when
loading an older export without the list.

Run the lightweight metadata checks with:

```bash
python3 -m unittest discover -s python_model -p test_lexical_metadata.py -v
```
