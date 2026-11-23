// Optional exhaustive model-output comparison; no Swift/Python runtime needed.
import { createHash } from "node:crypto";
import assert from "node:assert/strict";
import { Conjugator, Prediction, Spelling } from "../dist/index.js";
const c = new Conjugator();
const hash = createHash("sha256");
let bytes = 0;
function emit(value) {
    const data = value === null ? null : Buffer.from(value, "utf8");
    const size = Buffer.allocUnsafe(4);
    size.writeUInt32LE(data === null ? 0xffffffff : data.length);
    hash.update(size);
    bytes += 4;
    if (data !== null) {
        hash.update(data);
        bytes += data.length;
    }
}
const slots = c.slots;
for (const slot of slots) emit(slot);
for (const entry of [...c.entries].sort((a, b) => (a.key < b.key ? -1 : a.key > b.key ? 1 : 0))) {
    emit(entry.key);
    emit(String(entry.flags));
    emit(entry.variant);
    for (const slot of slots)
        emit(c.form(entry.key, slot, Prediction.Catalogue, undefined, Spelling.All));
}
for (const verb of [
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
]) {
    for (const slot of slots) emit(c.form(verb, slot, Prediction.Inferred));
}
const digest = hash.digest("hex");
assert.equal(bytes, 61908621);
assert.equal(digest, "e7e38425d7df37be2a458dc9615c62c4fd9dbda2d02de6e4d37bd7a000ed2026");
console.log(`Full catalogue + inference stream matches: ${bytes} bytes, SHA-256 ${digest}`);
