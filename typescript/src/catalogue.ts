import { bundled } from "./bundled.js";
import { Prediction } from "./types.js";

const missing = 0xffffffff;
export const nfc = (value: string): string => value.normalize("NFC");
export const verbKey = (value: string): string =>
    nfc(value.replace(/^\p{White_Space}+|\p{White_Space}+$/gu, "").toLowerCase());
export function lemmaIndex(value: string): [string, string] {
    const match = /^(.+)_([0-9]+)$/u.exec(value);
    return match ? [match[1], match[2]] : [value, ""];
}

export class Catalogue {
    readonly slots: string[];
    readonly slotIds: Map<string, number>;
    readonly entries = new Map<string, [number, string | null, number]>();
    readonly homonyms = new Map<string, number[]>();
    private readonly suffixes = new Map<string, number>();
    private readonly templates: number[][] = [];
    private readonly blocks: number[][] = [];
    private readonly programs: [string, number, string][][] = [];
    private readonly fallbacks: number[];

    constructor() {
        const data = Uint8Array.from(atob(bundled), (c) => c.charCodeAt(0));
        const view = new DataView(data.buffer);
        const word = (at: number): number => view.getUint32(at, true);
        if (
            data.length < 40 ||
            new TextDecoder().decode(data.slice(0, 4)) !== "FCR1" ||
            word(4) !== 1
        ) {
            throw new Error("Invalid catalogue header");
        }
        const sections = Array.from({ length: 8 }, (_, i) => word(8 + 4 * i));
        if (
            sections[0] !== 40 ||
            sections[7] !== data.length ||
            sections.some((n, i) => i > 0 && n < sections[i - 1])
        ) {
            throw new Error("Invalid catalogue directory");
        }
        const record = (section: number, index: number): [number, number] => {
            const base = sections[section];
            const payload = base + 8 + word(base) * 4;
            const start = payload + word(base + 4 + index * 4);
            const end = payload + word(base + 8 + index * 4);
            if (start < payload || end < start || end > sections[section + 1]) {
                throw new Error("Invalid catalogue record");
            }
            return [start, end];
        };
        const strings = Array.from({ length: word(sections[0]) }, (_, i) => {
            const [start, end] = record(0, i);
            return new TextDecoder("utf-8", { fatal: true }).decode(data.subarray(start, end));
        });
        this.slots = [];
        for (let at = sections[1]; at < sections[2]; at += 4) this.slots.push(strings[word(at)]);
        this.slotIds = new Map(this.slots.map((s, i) => [s, i]));
        for (let at = sections[3]; at < sections[4]; at += 8)
            this.suffixes.set(strings[word(at)], word(at + 4));
        const width = Math.ceil(this.slots.length / 16);
        for (let at = sections[4]; at < sections[5]; at += width * 4) {
            this.templates.push(Array.from({ length: width }, (_, i) => word(at + i * 4)));
        }
        for (let at = sections[5]; at < sections[6]; at += 64) {
            this.blocks.push(Array.from({ length: 16 }, (_, i) => word(at + i * 4)));
        }
        for (let i = 0; i < word(sections[6]); i++) {
            const [start, end] = record(6, i);
            const edits: [string, number, string][] = [];
            for (let at = start; at < end; at += 12)
                edits.push([strings[word(at)], word(at + 4), strings[word(at + 8)]]);
            this.programs.push(edits);
        }
        const frequencies = new Map<number, number>();
        for (let at = sections[2]; at < sections[3]; at += 12) {
            const key = strings[word(at)];
            const model = this.models(key).next().value;
            if (model === undefined) throw new Error("Entry has no template");
            const variant = word(at + 8);
            this.entries.set(key, [
                word(at + 4),
                variant === missing ? null : strings[variant],
                model,
            ]);
            frequencies.set(model, (frequencies.get(model) ?? 0) + 1);
            const [lemma, index] = lemmaIndex(key);
            if (index)
                this.homonyms.set(lemma, [...(this.homonyms.get(lemma) ?? []), Number(index)]);
        }
        for (const indices of this.homonyms.values()) indices.sort((a, b) => a - b);
        const ranked = [...frequencies.keys()].sort(
            (a, b) => frequencies.get(b)! - frequencies.get(a)! || a - b,
        );
        this.fallbacks = this.slots.map((_, slot) => {
            const model = ranked.find((m) => this.program(m, slot) !== 0);
            if (model === undefined) throw new Error("Slot has no fallback");
            return model;
        });
    }
    resolve(value: string, homonym?: number): string {
        const indices = this.homonyms.get(value);
        return this.entries.has(value) || !indices ? value : `${value}_${homonym ?? indices[0]}`;
    }
    *models(key: string): Generator<number> {
        const [lemma, index] = lemmaIndex(key);
        const marked = `^${index}|${lemma}`;
        for (let at = 0; at <= marked.length; at++) {
            const model = this.suffixes.get(marked.slice(at));
            if (model !== undefined) yield model;
        }
    }
    private program(model: number, slot: number): number {
        return this.blocks[this.templates[model][Math.floor(slot / 16)]][slot % 16];
    }
    private render(model: number, slot: number, lemma: string, fallback = false): string | null {
        const program = this.program(model, slot);
        if (program === 0) return null;
        const chars = [...lemma];
        const alternatives: string[] = [];
        for (const [prefix, trim, suffix] of this.programs[program]) {
            let retained: string;
            if (trim === missing) retained = "";
            else if (trim > chars.length) {
                if (!fallback) return null;
                retained = lemma;
            } else retained = chars.slice(0, chars.length - trim).join("");
            alternatives.push(prefix + retained + suffix);
        }
        const result = alternatives.join(";");
        return fallback && !result ? lemma : result;
    }
    raw(value: string, slot: number, homonym: number | undefined, mode: Prediction): string | null {
        if (mode !== Prediction.Inferred) {
            const key = this.resolve(verbKey(value), homonym);
            const entry = this.entries.get(key);
            if (entry) {
                const result = this.render(entry[2], slot, lemmaIndex(key)[0]);
                if (result !== null) return result;
            }
            if (
                mode === Prediction.Catalogue ||
                this.entries.has(this.resolve(verbKey(value), undefined))
            )
                return null;
        }
        value = verbKey(value);
        if (!value || /[^ '\-12;_abcdefghijklmnopqrstuvwxyzâçèéêîïôûœ]/u.test(value)) return null;
        const key = this.resolve(value, homonym);
        const lemma = lemmaIndex(key)[0];
        for (const model of this.models(key)) {
            const result = this.render(model, slot, lemma);
            if (result) return result;
        }
        return this.render(this.fallbacks[slot], slot, lemma, true);
    }
}
let shared: Catalogue | undefined;
export function catalogue(): Catalogue {
    return (shared ??= new Catalogue());
}
