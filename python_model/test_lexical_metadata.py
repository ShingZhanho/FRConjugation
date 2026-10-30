"""Lexical metadata checks require only Python's standard library."""
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest

from lexical_metadata import export_elision_liaison_blocks, refresh_exported_metadata


class LexicalMetadataTests(unittest.TestCase):
    def test_database_refresh_preserves_non_h_blocks_and_existing_export(self):
        with tempfile.TemporaryDirectory() as directory:
            db = Path(directory) / "verbs.db"
            connection = sqlite3.connect(db)
            connection.execute("CREATE TABLE verbes (infinitif TEXT, h_aspire INTEGER, bloque_elision_liaison INTEGER)")
            connection.executemany("INSERT INTO verbes VALUES (?, ?, ?)",
                                   [("hacher", 1, 1), ("ululer", 0, 1), ("yoyoter", 0, 1), ("aimer", 0, 0)])
            connection.commit()
            connection.close()
            original = {"known_verbs": ["hacher", "ululer", "yoyoter", "aimer"],
                        "h_aspire": ["hacher"], "exceptions": {"some-slot": "some form"},
                        "weight_manifest": {"tensor": {"offset": 0, "count": 12}}}
            path = Path(directory) / "model.json"
            path.write_text(json.dumps(original))
            refresh_exported_metadata(str(db), str(path))
            result = json.loads(path.read_text())
            self.assertEqual(result.pop("bloque_elision_liaison"), ["hacher", "ululer", "yoyoter"])
            self.assertEqual(result, original)
            with self.assertRaisesRegex(ValueError, "catalogues differ"):
                export_elision_liaison_blocks({"known_verbs": ["aimer"]}, str(db))

    def test_checkpoint_metadata_and_legacy_h_only_exports(self):
        self.assertEqual(export_elision_liaison_blocks({"h_aspire": ["hacher"]}), ["hacher"])
        self.assertEqual(export_elision_liaison_blocks({"h_aspire": ["hacher"],
                         "bloque_elision_liaison": ["yoyoter", "ululer", "hacher"]}),
                         ["hacher", "ululer", "yoyoter"])


if __name__ == "__main__":
    unittest.main()
