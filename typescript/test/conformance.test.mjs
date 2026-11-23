import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { Conjugator, AsyncConjugator, Mode, Prediction, Spelling } from "../dist/index.js";

const root = new URL("../../tests/", import.meta.url);
import { decode, typed, shared } from "./evaluate.mjs";
const rows = async (name) =>
    (await readFile(new URL(name, root), "utf8"))
        .trimEnd()
        .split("\n")
        .slice(1)
        .map((line) => line.split("\t"));
test("Swift-authored fixtures through sync and real worker APIs", async () => {
    const sync = new Conjugator();
    const worker = await AsyncConjugator.load();
    try {
        for (const c of [sync, worker]) {
            for (const r of await rows("conformance.tsv"))
                assert.equal(await shared(c, r), decode(r[7]), `shared ${r[0]}`);
            for (const r of await rows("typed-api.tsv"))
                assert.equal(await typed(c, r), decode(r[9]), `typed ${r[0]} ${r[1]}`);
        }
    } finally {
        worker.close();
    }
});
test("worker lifecycle and detached state", async () => {
    const c = await AsyncConjugator.load();
    const pending = c.guessCommonPrefix("blorper");
    const rejection = assert.rejects(pending, /closed/);
    c.close();
    c.close();
    await rejection;
    await assert.rejects(c.commonPrefix("manger"), /closed/);
    const next = await AsyncConjugator.load();
    try {
        await assert.rejects(next.form("manger", "bad", Prediction.Catalogue, -1), /positive/);
        assert.equal(await next.commonPrefix("manger"), "mang");
        const verbs = await next.getAllVerbs();
        verbs.length = 0;
        assert.equal(await next.getVerbCount(), 6298);
    } finally {
        next.close();
    }
    const sync = Conjugator.getShared();
    assert.equal(sync, Conjugator.getShared());
    const slots = sync.slots;
    slots.length = 0;
    assert.equal(sync.slots.length, 820);
    assert.throws(() => sync.conjugate("manger", undefined, Mode.Indicatif), /selectors/);
    assert.equal(
        sync.form(
            "manger",
            "voix_active_avoir|indicatif|present|1pm",
            Prediction.Catalogue,
            undefined,
            Spelling.Primary,
        ),
        "mangeons",
    );
});
