import { catalogue, lemmaIndex, nfc } from "./catalogue.js";
import {
    Mode,
    Person,
    Prediction,
    Spelling,
    Tense,
    Voice,
    personPronoun,
    type VerbEntry,
    type VoiceForms,
    type ModeForms,
    type TenseForms,
    type PersonForms,
    type ParticipleForms,
} from "./types.js";

/** Failure to decode the bundled rules, retaining the original cause. */
export class ConjugationError extends Error {
    /** Construct a loading failure. */
    constructor(cause: unknown) {
        super("Failed to load bundled conjugation model", { cause });
        this.name = "ConjugationError";
    }
}
function validate(verb: string, homonym?: number): void {
    if (typeof verb !== "string") throw new TypeError("verb must be a string");
    if (homonym !== undefined && (!Number.isSafeInteger(homonym) || homonym <= 0)) {
        throw new RangeError("homonymIndex must be a positive integer");
    }
}
const compare = (a: string, b: string): number => (a < b ? -1 : a > b ? 1 : 0);
const fold = (value: string): string =>
    value.replaceAll("œ", "oe").replaceAll("æ", "ae").normalize("NFKD").replace(/\p{M}/gu, "");
type Nested = { [key: string]: Nested | string };

/** Synchronous bundled-rule reader. Calls run on the current thread; use AsyncConjugator for workers.
 * Exact NFC lookup preserves catalogue availability. Inference trims Unicode whitespace and
 * lowercases supported strings. Exact homonym keys take precedence over a positive homonymIndex.
 * Missing single/all-voice results are null; missing scoped collections are empty objects.
 */
export class Conjugator {
    readonly #catalogue: ReturnType<typeof catalogue>;
    static #shared: Conjugator | undefined;
    /** Initialize a reader; no external/custom model can be supplied. */
    constructor() {
        try {
            this.#catalogue = catalogue();
        } catch (cause) {
            throw new ConjugationError(cause);
        }
    }
    /** Return the shared reader for this JavaScript realm. */
    static getShared(): Conjugator {
        return (this.#shared ??= new Conjugator());
    }
    /** All raw slot labels; participles use '-' as person. Returns a detached array. */
    get slots(): readonly string[] {
        return [...this.#catalogue.slots];
    }
    /** Detached lexical metadata snapshots, including indexed homonyms. */
    get entries(): readonly VerbEntry[] {
        return [...this.#catalogue.entries].map(([key, [flags, variant]]) => ({
            key,
            flags,
            variant,
            isHAspire: !!(flags & 1),
            blocksElisionAndLiaison: !!(flags & 2),
            is1990Reform: !!(flags & 4),
        }));
    }
    /** Distinct infinitives in accent/ligature-insensitive French-oriented order. */
    get allVerbs(): readonly string[] {
        return [...new Set([...this.#catalogue.entries.keys()].map((k) => lemmaIndex(k)[0]))].sort(
            (a, b) => compare(fold(a), fold(b)) || compare(a, b),
        );
    }
    /** Count distinct base infinitives, collapsing homonyms. */
    get verbCount(): number {
        return this.allVerbs.length;
    }
    /** Exact NFC catalogue membership, including base homonym names. */
    hasVerb(verb: string): boolean {
        validate(verb);
        const key = nfc(verb);
        return this.#catalogue.entries.has(key) || this.#catalogue.homonyms.has(key);
    }
    /** Ascending homonym indices, or an empty array. */
    homonymIndices(verb: string): readonly number[] {
        validate(verb);
        return [...(this.#catalogue.homonyms.get(nfc(verb)) ?? [])];
    }
    /** Whether a base infinitive has indexed homonyms. */
    hasHomonyms(verb: string): boolean {
        return this.homonymIndices(verb).length > 0;
    }
    /** Indexed count, or one without a group, including unknown verbs. */
    homonymCount(verb: string): number {
        return this.homonymIndices(verb).length || 1;
    }
    private metadata(
        verb: string,
        homonym?: number,
        resolve = false,
    ): [number, string | null, number] {
        validate(verb, homonym);
        const key = nfc(verb);
        return (
            this.#catalogue.entries.get(resolve ? this.#catalogue.resolve(key, homonym) : key) ?? [
                0,
                null,
                0,
            ]
        );
    }
    /** Initial-h blocking flag for an exact entry key. */
    isHAspire(verb: string): boolean {
        return !!(this.metadata(verb)[0] & 1);
    }
    /** Resolved lexical blocking flag; compound auxiliaries may still elide. */
    blocksElisionAndLiaison(verb: string, homonymIndex?: number): boolean {
        return !!(this.metadata(verb, homonymIndex, true)[0] & 2);
    }
    /** Whether an exact entry is marked as a reform variant. */
    is1990Reform(verb: string): boolean {
        return !!(this.metadata(verb)[0] & 4);
    }
    /** Reform variant for an exact entry key, or null. */
    reformVariant(verb: string): string | null {
        return this.metadata(verb)[1];
    }
    /** Query a raw slot. Catalogue spelling selection never discards inferred alternatives. */
    form(
        verb: string,
        slot: string,
        prediction = Prediction.Catalogue,
        homonymIndex?: number,
        spelling = Spelling.Primary,
    ): string | null {
        validate(verb, homonymIndex);
        if (
            !Object.values(Prediction).includes(prediction) ||
            !Object.values(Spelling).includes(spelling)
        )
            throw new RangeError("Invalid prediction or spelling");
        const id = this.#catalogue.slotIds.get(slot);
        if (id === undefined) return null;
        if (prediction !== Prediction.Inferred) {
            const known = this.#catalogue.raw(verb, id, homonymIndex, Prediction.Catalogue);
            if (known !== null) {
                const index = known.indexOf(";");
                return spelling === Spelling.All
                    ? known
                    : spelling === Spelling.Alternative && index >= 0
                      ? known.slice(index + 1)
                      : known.split(";")[0];
            }
            if (prediction === Prediction.Catalogue) return null;
        }
        return this.#catalogue.raw(verb, id, homonymIndex, Prediction.Inferred);
    }
    /** Flat slot-to-form map, including participles; missing values are omitted. */
    forms(
        verb: string,
        prediction = Prediction.Catalogue,
        homonymIndex?: number,
    ): Record<string, string> {
        const result: Record<string, string> = {};
        for (const slot of this.#catalogue.slots) {
            const value = this.form(verb, slot, prediction, homonymIndex);
            if (value !== null) result[slot] = value;
        }
        return result;
    }
    private finite(
        verb: string,
        voice: Voice | undefined,
        mode: Mode | undefined,
        tense: Tense | undefined,
        person: Person | undefined,
        homonym: number | undefined,
        prediction: Prediction,
    ): Nested | string | null {
        const values = [voice, mode, tense, person];
        const types = [Voice, Mode, Tense, Person];
        const selected: string[] = [];
        let omitted = false;
        values.forEach((value, index) => {
            if (value === undefined) {
                omitted = true;
                return;
            }
            if (omitted || !(Object.values(types[index]) as string[]).includes(value))
                throw new RangeError("Invalid or noncontiguous selectors");
            selected.push(value);
        });
        if (selected.length === 4) return this.form(verb, selected.join("|"), prediction, homonym);
        const result: Nested = {};
        for (const [slot, value] of Object.entries(this.forms(verb, prediction, homonym))) {
            const parts = slot.split("|");
            if (parts[1] === "participe" || selected.some((s, i) => s !== parts[i])) continue;
            const keys = parts.slice(selected.length);
            let level = result;
            for (const key of keys.slice(0, -1)) level = (level[key] ??= {}) as Nested;
            level[keys[keys.length - 1]] = value;
        }
        return !selected.length && !Object.keys(result).length ? null : result;
    }
    private structure(verb: string, selectors: string[], homonym?: number): string[] {
        return [
            ...new Set(
                Object.keys(this.forms(verb, Prediction.Catalogue, homonym))
                    .map((slot) => slot.split("|"))
                    .filter((parts) => selectors.every((s, i) => parts[i] === s))
                    .map((parts) => parts[selectors.length]),
            ),
        ].sort(compare);
    }
    /** Available voices, ordered by raw catalogue label. */
    voices(verb: string, homonymIndex?: number): readonly Voice[] {
        return this.structure(verb, [], homonymIndex) as Voice[];
    }
    /** Available moods, including participles. */
    modes(verb: string, voice: Voice, homonymIndex?: number): readonly Mode[] {
        return this.structure(verb, [voice], homonymIndex) as Mode[];
    }
    /** Available tenses in a voice/mood, ordered by raw label. */
    tenses(verb: string, voice: Voice, mode: Mode, homonymIndex?: number): readonly Tense[] {
        return this.structure(verb, [voice, mode], homonymIndex) as Tense[];
    }
    /** Persons grouped by identical full spelling, in declaration order; excludes participles. */
    persons(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        homonymIndex?: number,
    ): readonly Person[] {
        if (mode === Mode.Participe) return [];
        const groups = new Map<string, Person[]>();
        for (const person of Object.values(Person)) {
            const raw = this.form(
                verb,
                [voice, mode, tense, person].join("|"),
                Prediction.Catalogue,
                homonymIndex,
                Spelling.All,
            );
            if (raw !== null) groups.set(raw, [...(groups.get(raw) ?? []), person]);
        }
        return [...groups.values()].flat();
    }
    private prefix(verb: string, homonym: number | undefined, mode: Prediction): string | null {
        validate(verb, homonym);
        let result: string | null = null;
        for (let slot = 0; slot < this.#catalogue.slots.length; slot++) {
            const raw = this.#catalogue.raw(verb, slot, homonym, mode);
            if (raw === null) continue;
            for (const alternative of raw.split(";")) {
                const words = nfc(alternative)
                    .split(/\p{White_Space}+/u)
                    .filter(Boolean);
                const word = (words.at(-1) ?? "")
                    .replace(
                        /-(?:(?:m|t)['’]en|moi|toi|nous|vous|le|la|les|lui|leur|en|y)(?:-(?:en|y))?$/u,
                        "",
                    )
                    .replace(/^(?:(?:j|m|t|s|n|l|qu)['’])+/u, "");
                if (!word) continue;
                if (result === null) result = word;
                else {
                    const a: string[] = [...result];
                    const b: string[] = [...word];
                    let length = 0;
                    while (length < Math.min(a.length, b.length) && a[length] === b[length])
                        length++;
                    result = a.slice(0, length).join("");
                }
                if (!result) return "";
            }
        }
        return result;
    }
    private subject(
        verb: string,
        slot: string,
        homonym: number | undefined,
        form: string,
    ): string | null {
        const parts = slot.split("|");
        if (parts.length !== 4 || ["imperatif", "participe"].includes(parts[1])) return null;
        const subject = personPronoun(parts[3] as Person);
        if (!subject) return null;
        const flags = this.metadata(verb, homonym, true)[0];
        const first = form.slice(0, 1).toLowerCase();
        let vowel = !!first && "aeiouàâéèêëîïôùûüœæy".includes(first);
        if (first === "h") vowel = !(flags & 1);
        if (
            parts[0] !== "voix_passive" &&
            ["present", "imparfait", "passe_simple", "futur_simple"].includes(parts[2]) &&
            flags & 2
        )
            vowel = false;
        const result = subject === "je" && vowel ? "j'" : subject + " ";
        return parts[1] === "subjonctif"
            ? (parts[3].startsWith("3") ? "qu'" : "que ") + result
            : result;
    }
    /** Raw-slot contextual subject prefix, including trailing space/apostrophe. */
    pronoun(
        verb: string,
        slot: string,
        homonymIndex?: number,
        spelling = Spelling.Primary,
    ): string | null {
        if (spelling === Spelling.All) throw new RangeError("Select primary or alternative");
        const form = this.form(verb, slot, Prediction.Catalogue, homonymIndex, spelling);
        return form === null ? null : this.subject(verb, slot, homonymIndex, form);
    }
    /** Raw-slot catalogue form with its subject; imperatives/participles are bare. */
    withPronoun(
        verb: string,
        slot: string,
        homonymIndex?: number,
        spelling = Spelling.Primary,
    ): string | null {
        if (spelling === Spelling.All) throw new RangeError("Select primary or alternative");
        const form = this.form(verb, slot, Prediction.Catalogue, homonymIndex, spelling);
        return form === null ? null : (this.subject(verb, slot, homonymIndex, form) ?? "") + form;
    }
    /** Catalogue finite forms at this grammatical scope. */
    conjugate(verb: string): VoiceForms | null;
    /** Catalogue finite forms with an explicit homonym index in the final position. */
    conjugate(
        verb: string,
        voice: undefined,
        mode: undefined,
        tense: undefined,
        person: undefined,
        homonymIndex?: number,
    ): VoiceForms | null;
    /** Catalogue finite forms at this grammatical scope. */
    conjugate(verb: string, voice: Voice): ModeForms;
    /** Catalogue finite forms with an explicit homonym index in the final position. */
    conjugate(
        verb: string,
        voice: Voice,
        mode: undefined,
        tense: undefined,
        person: undefined,
        homonymIndex?: number,
    ): ModeForms;
    /** Catalogue finite forms at this grammatical scope. */
    conjugate(verb: string, voice: Voice, mode: Mode): TenseForms;
    /** Catalogue finite forms with an explicit homonym index in the final position. */
    conjugate(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: undefined,
        person: undefined,
        homonymIndex?: number,
    ): TenseForms;
    /** Catalogue finite forms at this grammatical scope. */
    conjugate(verb: string, voice: Voice, mode: Mode, tense: Tense): PersonForms;
    /** Catalogue finite forms with an explicit homonym index in the final position. */
    conjugate(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: undefined,
        homonymIndex?: number,
    ): PersonForms;
    /** Catalogue finite forms at this grammatical scope. */
    conjugate(verb: string, voice: Voice, mode: Mode, tense: Tense, person: Person): string | null;
    /** Catalogue finite forms with an explicit homonym index in the final position. */
    conjugate(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex?: number,
    ): string | null;
    conjugate(
        verb: string,
        voice?: Voice,
        mode?: Mode,
        tense?: Tense,
        person?: Person,
        homonymIndex?: number,
    ): VoiceForms | ModeForms | TenseForms | PersonForms | string | null {
        return this.finite(verb, voice, mode, tense, person, homonymIndex, Prediction.Catalogue);
    }
    /** Inferred finite forms at this grammatical scope. */
    rawInferredConjugation(verb: string): VoiceForms | null;
    /** Inferred finite forms with an explicit homonym index in the final position. */
    rawInferredConjugation(
        verb: string,
        voice: undefined,
        mode: undefined,
        tense: undefined,
        person: undefined,
        homonymIndex?: number,
    ): VoiceForms | null;
    /** Inferred finite forms at this grammatical scope. */
    rawInferredConjugation(verb: string, voice: Voice): ModeForms;
    /** Inferred finite forms with an explicit homonym index in the final position. */
    rawInferredConjugation(
        verb: string,
        voice: Voice,
        mode: undefined,
        tense: undefined,
        person: undefined,
        homonymIndex?: number,
    ): ModeForms;
    /** Inferred finite forms at this grammatical scope. */
    rawInferredConjugation(verb: string, voice: Voice, mode: Mode): TenseForms;
    /** Inferred finite forms with an explicit homonym index in the final position. */
    rawInferredConjugation(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: undefined,
        person: undefined,
        homonymIndex?: number,
    ): TenseForms;
    /** Inferred finite forms at this grammatical scope. */
    rawInferredConjugation(verb: string, voice: Voice, mode: Mode, tense: Tense): PersonForms;
    /** Inferred finite forms with an explicit homonym index in the final position. */
    rawInferredConjugation(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: undefined,
        homonymIndex?: number,
    ): PersonForms;
    /** Inferred finite forms at this grammatical scope. */
    rawInferredConjugation(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
    ): string | null;
    /** Inferred finite forms with an explicit homonym index in the final position. */
    rawInferredConjugation(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex?: number,
    ): string | null;
    rawInferredConjugation(
        verb: string,
        voice?: Voice,
        mode?: Mode,
        tense?: Tense,
        person?: Person,
        homonymIndex?: number,
    ): VoiceForms | ModeForms | TenseForms | PersonForms | string | null {
        return this.finite(verb, voice, mode, tense, person, homonymIndex, Prediction.Inferred);
    }
    /** Guess finite forms at this grammatical scope. */
    guessConjugation(verb: string): VoiceForms | null;
    /** Guess finite forms with an explicit homonym index in the final position. */
    guessConjugation(
        verb: string,
        voice: undefined,
        mode: undefined,
        tense: undefined,
        person: undefined,
        homonymIndex?: number,
    ): VoiceForms | null;
    /** Guess finite forms at this grammatical scope. */
    guessConjugation(verb: string, voice: Voice): ModeForms;
    /** Guess finite forms with an explicit homonym index in the final position. */
    guessConjugation(
        verb: string,
        voice: Voice,
        mode: undefined,
        tense: undefined,
        person: undefined,
        homonymIndex?: number,
    ): ModeForms;
    /** Guess finite forms at this grammatical scope. */
    guessConjugation(verb: string, voice: Voice, mode: Mode): TenseForms;
    /** Guess finite forms with an explicit homonym index in the final position. */
    guessConjugation(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: undefined,
        person: undefined,
        homonymIndex?: number,
    ): TenseForms;
    /** Guess finite forms at this grammatical scope. */
    guessConjugation(verb: string, voice: Voice, mode: Mode, tense: Tense): PersonForms;
    /** Guess finite forms with an explicit homonym index in the final position. */
    guessConjugation(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: undefined,
        homonymIndex?: number,
    ): PersonForms;
    /** Guess finite forms at this grammatical scope. */
    guessConjugation(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
    ): string | null;
    /** Guess finite forms with an explicit homonym index in the final position. */
    guessConjugation(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex?: number,
    ): string | null;
    guessConjugation(
        verb: string,
        voice?: Voice,
        mode?: Mode,
        tense?: Tense,
        person?: Person,
        homonymIndex?: number,
    ): VoiceForms | ModeForms | TenseForms | PersonForms | string | null {
        return this.finite(verb, voice, mode, tense, person, homonymIndex, Prediction.Guess);
    }
    /** Catalogue shared lexical spelling; null means absent, empty string is valid. Not a grammatical stem. */
    commonPrefix(verb: string, homonymIndex?: number): string | null {
        return this.prefix(verb, homonymIndex, Prediction.Catalogue);
    }
    /** Catalogue personless participle selected by a gendered tense. */
    participle(verb: string, voice: Voice, tense: Tense, homonymIndex?: number): string | null {
        return this.form(
            verb,
            [voice, Mode.Participe, tense, "-"].join("|"),
            Prediction.Catalogue,
            homonymIndex,
        );
    }
    /** All available catalogue participles keyed by tense; absent forms are omitted. */
    participles(verb: string, voice: Voice, homonymIndex?: number): ParticipleForms {
        const result: ParticipleForms = {};
        for (const tense of Object.values(Tense)) {
            const value = this.participle(verb, voice, tense, homonymIndex);
            if (value !== null) result[tense] = value;
        }
        return result;
    }
    /** Catalogue gerondif; prefixes each underlying participle alternative with en. */
    gerondif(verb: string, voice: Voice, tense: Tense, homonymIndex?: number): string | null {
        const source =
            tense === Tense.GerondifPresent
                ? Tense.Present
                : tense.startsWith("gerondif_passe_")
                  ? (tense.replace("gerondif_passe_", "passe_compound_") as Tense)
                  : null;
        if (source === null) return null;
        const value = this.participle(verb, voice, source, homonymIndex);
        return value === null
            ? null
            : value
                  .split(";")
                  .map((x) => "en " + x.trim())
                  .join(";");
    }
    /** Inferred shared lexical spelling; null means absent, empty string is valid. Not a grammatical stem. */
    rawInferredCommonPrefix(verb: string, homonymIndex?: number): string | null {
        return this.prefix(verb, homonymIndex, Prediction.Inferred);
    }
    /** Inferred personless participle selected by a gendered tense. */
    rawInferredParticiple(
        verb: string,
        voice: Voice,
        tense: Tense,
        homonymIndex?: number,
    ): string | null {
        return this.form(
            verb,
            [voice, Mode.Participe, tense, "-"].join("|"),
            Prediction.Inferred,
            homonymIndex,
        );
    }
    /** All available inferred participles keyed by tense; absent forms are omitted. */
    rawInferredParticiples(verb: string, voice: Voice, homonymIndex?: number): ParticipleForms {
        const result: ParticipleForms = {};
        for (const tense of Object.values(Tense)) {
            const value = this.rawInferredParticiple(verb, voice, tense, homonymIndex);
            if (value !== null) result[tense] = value;
        }
        return result;
    }
    /** Inferred gerondif; prefixes each underlying participle alternative with en. */
    rawInferredGerondif(
        verb: string,
        voice: Voice,
        tense: Tense,
        homonymIndex?: number,
    ): string | null {
        const source =
            tense === Tense.GerondifPresent
                ? Tense.Present
                : tense.startsWith("gerondif_passe_")
                  ? (tense.replace("gerondif_passe_", "passe_compound_") as Tense)
                  : null;
        if (source === null) return null;
        const value = this.rawInferredParticiple(verb, voice, source, homonymIndex);
        return value === null
            ? null
            : value
                  .split(";")
                  .map((x) => "en " + x.trim())
                  .join(";");
    }
    /** Guess shared lexical spelling; null means absent, empty string is valid. Not a grammatical stem. */
    guessCommonPrefix(verb: string, homonymIndex?: number): string | null {
        return this.prefix(verb, homonymIndex, Prediction.Guess);
    }
    /** Guess personless participle selected by a gendered tense. */
    guessParticiple(
        verb: string,
        voice: Voice,
        tense: Tense,
        homonymIndex?: number,
    ): string | null {
        return this.form(
            verb,
            [voice, Mode.Participe, tense, "-"].join("|"),
            Prediction.Guess,
            homonymIndex,
        );
    }
    /** All available guess participles keyed by tense; absent forms are omitted. */
    guessParticiples(verb: string, voice: Voice, homonymIndex?: number): ParticipleForms {
        const result: ParticipleForms = {};
        for (const tense of Object.values(Tense)) {
            const value = this.guessParticiple(verb, voice, tense, homonymIndex);
            if (value !== null) result[tense] = value;
        }
        return result;
    }
    /** Guess gerondif; prefixes each underlying participle alternative with en. */
    guessGerondif(verb: string, voice: Voice, tense: Tense, homonymIndex?: number): string | null {
        const source =
            tense === Tense.GerondifPresent
                ? Tense.Present
                : tense.startsWith("gerondif_passe_")
                  ? (tense.replace("gerondif_passe_", "passe_compound_") as Tense)
                  : null;
        if (source === null) return null;
        const value = this.guessParticiple(verb, voice, source, homonymIndex);
        return value === null
            ? null
            : value
                  .split(";")
                  .map((x) => "en " + x.trim())
                  .join(";");
    }
    /** Alternative catalogue form, falling back to primary. */
    conjugateAlternative(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex?: number,
    ): string | null {
        return this.form(
            verb,
            [voice, mode, tense, person].join("|"),
            Prediction.Catalogue,
            homonymIndex,
            Spelling.Alternative,
        );
    }
    /** Whether a catalogue finite form has alternatives. */
    hasAlternativeForm(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex?: number,
    ): boolean {
        return (
            this.form(
                verb,
                [voice, mode, tense, person].join("|"),
                Prediction.Catalogue,
                homonymIndex,
                Spelling.All,
            ) ?? ""
        ).includes(";");
    }
    /** Contextual primary subject prefix. */
    getPronoun(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex?: number,
    ): string | null {
        return this.pronoun(verb, [voice, mode, tense, person].join("|"), homonymIndex);
    }
    /** Primary catalogue finite form with subject. */
    conjugateWithPronoun(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex?: number,
    ): string | null {
        return this.withPronoun(verb, [voice, mode, tense, person].join("|"), homonymIndex);
    }
    /** Alternative catalogue finite form with subject. */
    conjugateAlternativeWithPronoun(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex?: number,
    ): string | null {
        return this.withPronoun(
            verb,
            [voice, mode, tense, person].join("|"),
            homonymIndex,
            Spelling.Alternative,
        );
    }
    /** Alternative catalogue participle, falling back to primary. */
    participleAlternative(
        verb: string,
        voice: Voice,
        tense: Tense,
        homonymIndex?: number,
    ): string | null {
        return this.form(
            verb,
            [voice, Mode.Participe, tense, "-"].join("|"),
            Prediction.Catalogue,
            homonymIndex,
            Spelling.Alternative,
        );
    }
    /** Whether a catalogue participle has alternatives. */
    hasAlternativeParticiple(
        verb: string,
        voice: Voice,
        tense: Tense,
        homonymIndex?: number,
    ): boolean {
        return (
            this.form(
                verb,
                [voice, Mode.Participe, tense, "-"].join("|"),
                Prediction.Catalogue,
                homonymIndex,
                Spelling.All,
            ) ?? ""
        ).includes(";");
    }
}
