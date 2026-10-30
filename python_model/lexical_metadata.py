"""Read lexical blocking metadata without loading neural weights or PyTorch."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import sqlite3


def read_elision_liaison_blocks(connection: sqlite3.Connection) -> list[str]:
    """Support v0.5.0's explicit flag and the h-only legacy schema."""
    columns = {row[1] for row in connection.execute("PRAGMA table_info(verbes)")}
    field = "bloque_elision_liaison" if "bloque_elision_liaison" in columns else "h_aspire"
    return sorted(row[0] for row in connection.execute(
        f"SELECT infinitif FROM verbes WHERE {field} = 1"))


def export_elision_liaison_blocks(model: dict, database_path: str | None = None) -> list[str]:
    """Refresh from an explicitly selected database, or preserve checkpoint metadata.

    Legacy checkpoints retain their h-only behavior when no database is supplied.
    A database must describe the same verb catalogue as the exported model.
    """
    if database_path is not None:
        uri = Path(database_path).resolve().as_uri() + "?mode=ro"
        connection = sqlite3.connect(uri, uri=True)
        try:
            verbs = {row[0] for row in connection.execute("SELECT infinitif FROM verbes")}
            if verbs != set(model.get("known_verbs", [])):
                raise ValueError("Database and model verb catalogues differ")
            return read_elision_liaison_blocks(connection)
        finally:
            connection.close()
    return sorted(set(model.get("bloque_elision_liaison", model.get("h_aspire", []))))


def refresh_exported_metadata(database_path: str, model_path: str) -> None:
    """Update just the blocking list in an existing export; leave weights intact."""
    path = Path(model_path)
    model = json.loads(path.read_text(encoding="utf-8"))
    model["bloque_elision_liaison"] = export_elision_liaison_blocks(model, database_path)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(model, ensure_ascii=False, separators=(",", ":")),
                         encoding="utf-8")
    os.replace(temporary, path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Refresh exported lexical metadata without retraining")
    parser.add_argument("database", help="Matching verbs.db")
    parser.add_argument("model_json", help="Existing exported model.json")
    arguments = parser.parse_args()
    refresh_exported_metadata(arguments.database, arguments.model_json)
