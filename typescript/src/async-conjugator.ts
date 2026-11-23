import { Transport } from "./transport.js";
import {
    Mode,
    Person,
    Prediction,
    Spelling,
    Tense,
    Voice,
    type VerbEntry,
    type VoiceForms,
    type ModeForms,
    type TenseForms,
    type PersonForms,
    type ParticipleForms,
} from "./types.js";

/** Worker-backed reader for browsers and Node.js. Methods mirror Conjugator but return Promises.
 * Each instance owns a worker; call close() when finished. No custom binary is accepted.
 * Closing rejects pending requests and terminates the worker. Results are detached snapshots.
 */
export class AsyncConjugator {
    private constructor(private readonly transport: Transport) {}
    /** Load the bundled rules in a dedicated worker, keeping decoding off the caller thread. */
    static async load(): Promise<AsyncConjugator> {
        return new AsyncConjugator(await Transport.create());
    }
    /** Reject pending operations and terminate this instance's worker. Idempotent. */
    close(): void {
        this.transport.close();
    }
    /** Worker-backed hasVerb; see Conjugator for arguments and semantics. */
    hasVerb(verb: string): Promise<boolean> {
        return this.transport.call("hasVerb", [verb]) as Promise<boolean>;
    }
    /** Worker-backed homonymIndices; see Conjugator for arguments and semantics. */
    homonymIndices(verb: string): Promise<readonly number[]> {
        return this.transport.call("homonymIndices", [verb]) as Promise<readonly number[]>;
    }
    /** Worker-backed hasHomonyms; see Conjugator for arguments and semantics. */
    hasHomonyms(verb: string): Promise<boolean> {
        return this.transport.call("hasHomonyms", [verb]) as Promise<boolean>;
    }
    /** Worker-backed homonymCount; see Conjugator for arguments and semantics. */
    homonymCount(verb: string): Promise<number> {
        return this.transport.call("homonymCount", [verb]) as Promise<number>;
    }
    /** Worker-backed isHAspire; see Conjugator for arguments and semantics. */
    isHAspire(verb: string): Promise<boolean> {
        return this.transport.call("isHAspire", [verb]) as Promise<boolean>;
    }
    /** Worker-backed blocksElisionAndLiaison; see Conjugator for arguments and semantics. */
    blocksElisionAndLiaison(verb: string, homonymIndex?: number): Promise<boolean> {
        return this.transport.call("blocksElisionAndLiaison", [
            verb,
            homonymIndex,
        ]) as Promise<boolean>;
    }
    /** Worker-backed is1990Reform; see Conjugator for arguments and semantics. */
    is1990Reform(verb: string): Promise<boolean> {
        return this.transport.call("is1990Reform", [verb]) as Promise<boolean>;
    }
    /** Worker-backed reformVariant; see Conjugator for arguments and semantics. */
    reformVariant(verb: string): Promise<string | null> {
        return this.transport.call("reformVariant", [verb]) as Promise<string | null>;
    }
    /** Worker-backed form; see Conjugator for arguments and semantics. */
    form(
        verb: string,
        slot: string,
        prediction: Prediction = Prediction.Catalogue,
        homonymIndex?: number,
        spelling: Spelling = Spelling.Primary,
    ): Promise<string | null> {
        return this.transport.call("form", [
            verb,
            slot,
            prediction,
            homonymIndex,
            spelling,
        ]) as Promise<string | null>;
    }
    /** Worker-backed forms; see Conjugator for arguments and semantics. */
    forms(
        verb: string,
        prediction: Prediction = Prediction.Catalogue,
        homonymIndex?: number,
    ): Promise<Record<string, string>> {
        return this.transport.call("forms", [verb, prediction, homonymIndex]) as Promise<
            Record<string, string>
        >;
    }
    /** Worker-backed voices; see Conjugator for arguments and semantics. */
    voices(verb: string, homonymIndex?: number): Promise<readonly Voice[]> {
        return this.transport.call("voices", [verb, homonymIndex]) as Promise<readonly Voice[]>;
    }
    /** Worker-backed modes; see Conjugator for arguments and semantics. */
    modes(verb: string, voice: Voice, homonymIndex?: number): Promise<readonly Mode[]> {
        return this.transport.call("modes", [verb, voice, homonymIndex]) as Promise<
            readonly Mode[]
        >;
    }
    /** Worker-backed tenses; see Conjugator for arguments and semantics. */
    tenses(
        verb: string,
        voice: Voice,
        mode: Mode,
        homonymIndex?: number,
    ): Promise<readonly Tense[]> {
        return this.transport.call("tenses", [verb, voice, mode, homonymIndex]) as Promise<
            readonly Tense[]
        >;
    }
    /** Worker-backed persons; see Conjugator for arguments and semantics. */
    persons(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        homonymIndex?: number,
    ): Promise<readonly Person[]> {
        return this.transport.call("persons", [verb, voice, mode, tense, homonymIndex]) as Promise<
            readonly Person[]
        >;
    }
    /** Worker-backed pronoun; see Conjugator for arguments and semantics. */
    pronoun(
        verb: string,
        slot: string,
        homonymIndex?: number,
        spelling: Spelling = Spelling.Primary,
    ): Promise<string | null> {
        return this.transport.call("pronoun", [verb, slot, homonymIndex, spelling]) as Promise<
            string | null
        >;
    }
    /** Worker-backed withPronoun; see Conjugator for arguments and semantics. */
    withPronoun(
        verb: string,
        slot: string,
        homonymIndex?: number,
        spelling: Spelling = Spelling.Primary,
    ): Promise<string | null> {
        return this.transport.call("withPronoun", [verb, slot, homonymIndex, spelling]) as Promise<
            string | null
        >;
    }
    /** Worker-backed conjugate; same scope and result semantics as Conjugator. */
    conjugate(verb: string): Promise<VoiceForms | null>;
    /** Worker-backed conjugate; same scope and result semantics as Conjugator. */
    conjugate(
        verb: string,
        voice: undefined,
        mode: undefined,
        tense: undefined,
        person: undefined,
        homonymIndex?: number,
    ): Promise<VoiceForms | null>;
    /** Worker-backed conjugate; same scope and result semantics as Conjugator. */
    conjugate(verb: string, voice: Voice): Promise<ModeForms>;
    /** Worker-backed conjugate; same scope and result semantics as Conjugator. */
    conjugate(
        verb: string,
        voice: Voice,
        mode: undefined,
        tense: undefined,
        person: undefined,
        homonymIndex?: number,
    ): Promise<ModeForms>;
    /** Worker-backed conjugate; same scope and result semantics as Conjugator. */
    conjugate(verb: string, voice: Voice, mode: Mode): Promise<TenseForms>;
    /** Worker-backed conjugate; same scope and result semantics as Conjugator. */
    conjugate(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: undefined,
        person: undefined,
        homonymIndex?: number,
    ): Promise<TenseForms>;
    /** Worker-backed conjugate; same scope and result semantics as Conjugator. */
    conjugate(verb: string, voice: Voice, mode: Mode, tense: Tense): Promise<PersonForms>;
    /** Worker-backed conjugate; same scope and result semantics as Conjugator. */
    conjugate(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: undefined,
        homonymIndex?: number,
    ): Promise<PersonForms>;
    /** Worker-backed conjugate; same scope and result semantics as Conjugator. */
    conjugate(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
    ): Promise<string | null>;
    /** Worker-backed conjugate; same scope and result semantics as Conjugator. */
    conjugate(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex?: number,
    ): Promise<string | null>;
    conjugate(
        verb: string,
        voice?: Voice,
        mode?: Mode,
        tense?: Tense,
        person?: Person,
        homonymIndex?: number,
    ): Promise<VoiceForms | ModeForms | TenseForms | PersonForms | string | null> {
        return this.transport.call("conjugate", [
            verb,
            voice,
            mode,
            tense,
            person,
            homonymIndex,
        ]) as Promise<VoiceForms | ModeForms | TenseForms | PersonForms | string | null>;
    }
    /** Worker-backed rawInferredConjugation; same scope and result semantics as Conjugator. */
    rawInferredConjugation(verb: string): Promise<VoiceForms | null>;
    /** Worker-backed rawInferredConjugation; same scope and result semantics as Conjugator. */
    rawInferredConjugation(
        verb: string,
        voice: undefined,
        mode: undefined,
        tense: undefined,
        person: undefined,
        homonymIndex?: number,
    ): Promise<VoiceForms | null>;
    /** Worker-backed rawInferredConjugation; same scope and result semantics as Conjugator. */
    rawInferredConjugation(verb: string, voice: Voice): Promise<ModeForms>;
    /** Worker-backed rawInferredConjugation; same scope and result semantics as Conjugator. */
    rawInferredConjugation(
        verb: string,
        voice: Voice,
        mode: undefined,
        tense: undefined,
        person: undefined,
        homonymIndex?: number,
    ): Promise<ModeForms>;
    /** Worker-backed rawInferredConjugation; same scope and result semantics as Conjugator. */
    rawInferredConjugation(verb: string, voice: Voice, mode: Mode): Promise<TenseForms>;
    /** Worker-backed rawInferredConjugation; same scope and result semantics as Conjugator. */
    rawInferredConjugation(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: undefined,
        person: undefined,
        homonymIndex?: number,
    ): Promise<TenseForms>;
    /** Worker-backed rawInferredConjugation; same scope and result semantics as Conjugator. */
    rawInferredConjugation(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
    ): Promise<PersonForms>;
    /** Worker-backed rawInferredConjugation; same scope and result semantics as Conjugator. */
    rawInferredConjugation(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: undefined,
        homonymIndex?: number,
    ): Promise<PersonForms>;
    /** Worker-backed rawInferredConjugation; same scope and result semantics as Conjugator. */
    rawInferredConjugation(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
    ): Promise<string | null>;
    /** Worker-backed rawInferredConjugation; same scope and result semantics as Conjugator. */
    rawInferredConjugation(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex?: number,
    ): Promise<string | null>;
    rawInferredConjugation(
        verb: string,
        voice?: Voice,
        mode?: Mode,
        tense?: Tense,
        person?: Person,
        homonymIndex?: number,
    ): Promise<VoiceForms | ModeForms | TenseForms | PersonForms | string | null> {
        return this.transport.call("rawInferredConjugation", [
            verb,
            voice,
            mode,
            tense,
            person,
            homonymIndex,
        ]) as Promise<VoiceForms | ModeForms | TenseForms | PersonForms | string | null>;
    }
    /** Worker-backed guessConjugation; same scope and result semantics as Conjugator. */
    guessConjugation(verb: string): Promise<VoiceForms | null>;
    /** Worker-backed guessConjugation; same scope and result semantics as Conjugator. */
    guessConjugation(
        verb: string,
        voice: undefined,
        mode: undefined,
        tense: undefined,
        person: undefined,
        homonymIndex?: number,
    ): Promise<VoiceForms | null>;
    /** Worker-backed guessConjugation; same scope and result semantics as Conjugator. */
    guessConjugation(verb: string, voice: Voice): Promise<ModeForms>;
    /** Worker-backed guessConjugation; same scope and result semantics as Conjugator. */
    guessConjugation(
        verb: string,
        voice: Voice,
        mode: undefined,
        tense: undefined,
        person: undefined,
        homonymIndex?: number,
    ): Promise<ModeForms>;
    /** Worker-backed guessConjugation; same scope and result semantics as Conjugator. */
    guessConjugation(verb: string, voice: Voice, mode: Mode): Promise<TenseForms>;
    /** Worker-backed guessConjugation; same scope and result semantics as Conjugator. */
    guessConjugation(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: undefined,
        person: undefined,
        homonymIndex?: number,
    ): Promise<TenseForms>;
    /** Worker-backed guessConjugation; same scope and result semantics as Conjugator. */
    guessConjugation(verb: string, voice: Voice, mode: Mode, tense: Tense): Promise<PersonForms>;
    /** Worker-backed guessConjugation; same scope and result semantics as Conjugator. */
    guessConjugation(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: undefined,
        homonymIndex?: number,
    ): Promise<PersonForms>;
    /** Worker-backed guessConjugation; same scope and result semantics as Conjugator. */
    guessConjugation(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
    ): Promise<string | null>;
    /** Worker-backed guessConjugation; same scope and result semantics as Conjugator. */
    guessConjugation(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex?: number,
    ): Promise<string | null>;
    guessConjugation(
        verb: string,
        voice?: Voice,
        mode?: Mode,
        tense?: Tense,
        person?: Person,
        homonymIndex?: number,
    ): Promise<VoiceForms | ModeForms | TenseForms | PersonForms | string | null> {
        return this.transport.call("guessConjugation", [
            verb,
            voice,
            mode,
            tense,
            person,
            homonymIndex,
        ]) as Promise<VoiceForms | ModeForms | TenseForms | PersonForms | string | null>;
    }
    /** Worker-backed commonPrefix; see Conjugator for arguments and semantics. */
    commonPrefix(verb: string, homonymIndex?: number): Promise<string | null> {
        return this.transport.call("commonPrefix", [verb, homonymIndex]) as Promise<string | null>;
    }
    /** Worker-backed participle; see Conjugator for arguments and semantics. */
    participle(
        verb: string,
        voice: Voice,
        tense: Tense,
        homonymIndex?: number,
    ): Promise<string | null> {
        return this.transport.call("participle", [verb, voice, tense, homonymIndex]) as Promise<
            string | null
        >;
    }
    /** Worker-backed participles; see Conjugator for arguments and semantics. */
    participles(verb: string, voice: Voice, homonymIndex?: number): Promise<ParticipleForms> {
        return this.transport.call("participles", [
            verb,
            voice,
            homonymIndex,
        ]) as Promise<ParticipleForms>;
    }
    /** Worker-backed gerondif; see Conjugator for arguments and semantics. */
    gerondif(
        verb: string,
        voice: Voice,
        tense: Tense,
        homonymIndex?: number,
    ): Promise<string | null> {
        return this.transport.call("gerondif", [verb, voice, tense, homonymIndex]) as Promise<
            string | null
        >;
    }
    /** Worker-backed rawInferredCommonPrefix; see Conjugator for arguments and semantics. */
    rawInferredCommonPrefix(verb: string, homonymIndex?: number): Promise<string | null> {
        return this.transport.call("rawInferredCommonPrefix", [verb, homonymIndex]) as Promise<
            string | null
        >;
    }
    /** Worker-backed rawInferredParticiple; see Conjugator for arguments and semantics. */
    rawInferredParticiple(
        verb: string,
        voice: Voice,
        tense: Tense,
        homonymIndex?: number,
    ): Promise<string | null> {
        return this.transport.call("rawInferredParticiple", [
            verb,
            voice,
            tense,
            homonymIndex,
        ]) as Promise<string | null>;
    }
    /** Worker-backed rawInferredParticiples; see Conjugator for arguments and semantics. */
    rawInferredParticiples(
        verb: string,
        voice: Voice,
        homonymIndex?: number,
    ): Promise<ParticipleForms> {
        return this.transport.call("rawInferredParticiples", [
            verb,
            voice,
            homonymIndex,
        ]) as Promise<ParticipleForms>;
    }
    /** Worker-backed rawInferredGerondif; see Conjugator for arguments and semantics. */
    rawInferredGerondif(
        verb: string,
        voice: Voice,
        tense: Tense,
        homonymIndex?: number,
    ): Promise<string | null> {
        return this.transport.call("rawInferredGerondif", [
            verb,
            voice,
            tense,
            homonymIndex,
        ]) as Promise<string | null>;
    }
    /** Worker-backed guessCommonPrefix; see Conjugator for arguments and semantics. */
    guessCommonPrefix(verb: string, homonymIndex?: number): Promise<string | null> {
        return this.transport.call("guessCommonPrefix", [verb, homonymIndex]) as Promise<
            string | null
        >;
    }
    /** Worker-backed guessParticiple; see Conjugator for arguments and semantics. */
    guessParticiple(
        verb: string,
        voice: Voice,
        tense: Tense,
        homonymIndex?: number,
    ): Promise<string | null> {
        return this.transport.call("guessParticiple", [
            verb,
            voice,
            tense,
            homonymIndex,
        ]) as Promise<string | null>;
    }
    /** Worker-backed guessParticiples; see Conjugator for arguments and semantics. */
    guessParticiples(verb: string, voice: Voice, homonymIndex?: number): Promise<ParticipleForms> {
        return this.transport.call("guessParticiples", [
            verb,
            voice,
            homonymIndex,
        ]) as Promise<ParticipleForms>;
    }
    /** Worker-backed guessGerondif; see Conjugator for arguments and semantics. */
    guessGerondif(
        verb: string,
        voice: Voice,
        tense: Tense,
        homonymIndex?: number,
    ): Promise<string | null> {
        return this.transport.call("guessGerondif", [verb, voice, tense, homonymIndex]) as Promise<
            string | null
        >;
    }
    /** Worker-backed conjugateAlternative; see Conjugator for arguments and semantics. */
    conjugateAlternative(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex?: number,
    ): Promise<string | null> {
        return this.transport.call("conjugateAlternative", [
            verb,
            voice,
            mode,
            tense,
            person,
            homonymIndex,
        ]) as Promise<string | null>;
    }
    /** Worker-backed hasAlternativeForm; see Conjugator for arguments and semantics. */
    hasAlternativeForm(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex?: number,
    ): Promise<boolean> {
        return this.transport.call("hasAlternativeForm", [
            verb,
            voice,
            mode,
            tense,
            person,
            homonymIndex,
        ]) as Promise<boolean>;
    }
    /** Worker-backed getPronoun; see Conjugator for arguments and semantics. */
    getPronoun(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex?: number,
    ): Promise<string | null> {
        return this.transport.call("getPronoun", [
            verb,
            voice,
            mode,
            tense,
            person,
            homonymIndex,
        ]) as Promise<string | null>;
    }
    /** Worker-backed conjugateWithPronoun; see Conjugator for arguments and semantics. */
    conjugateWithPronoun(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex?: number,
    ): Promise<string | null> {
        return this.transport.call("conjugateWithPronoun", [
            verb,
            voice,
            mode,
            tense,
            person,
            homonymIndex,
        ]) as Promise<string | null>;
    }
    /** Worker-backed conjugateAlternativeWithPronoun; see Conjugator for arguments and semantics. */
    conjugateAlternativeWithPronoun(
        verb: string,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex?: number,
    ): Promise<string | null> {
        return this.transport.call("conjugateAlternativeWithPronoun", [
            verb,
            voice,
            mode,
            tense,
            person,
            homonymIndex,
        ]) as Promise<string | null>;
    }
    /** Worker-backed participleAlternative; see Conjugator for arguments and semantics. */
    participleAlternative(
        verb: string,
        voice: Voice,
        tense: Tense,
        homonymIndex?: number,
    ): Promise<string | null> {
        return this.transport.call("participleAlternative", [
            verb,
            voice,
            tense,
            homonymIndex,
        ]) as Promise<string | null>;
    }
    /** Worker-backed hasAlternativeParticiple; see Conjugator for arguments and semantics. */
    hasAlternativeParticiple(
        verb: string,
        voice: Voice,
        tense: Tense,
        homonymIndex?: number,
    ): Promise<boolean> {
        return this.transport.call("hasAlternativeParticiple", [
            verb,
            voice,
            tense,
            homonymIndex,
        ]) as Promise<boolean>;
    }
    /** Read a detached slots snapshot from the worker. */
    getSlots(): Promise<readonly string[]> {
        return this.transport.call("getSlots", []) as Promise<readonly string[]>;
    }
    /** Read a detached entries snapshot from the worker. */
    getEntries(): Promise<readonly VerbEntry[]> {
        return this.transport.call("getEntries", []) as Promise<readonly VerbEntry[]>;
    }
    /** Read a detached allVerbs snapshot from the worker. */
    getAllVerbs(): Promise<readonly string[]> {
        return this.transport.call("getAllVerbs", []) as Promise<readonly string[]>;
    }
    /** Read a detached verbCount snapshot from the worker. */
    getVerbCount(): Promise<number> {
        return this.transport.call("getVerbCount", []) as Promise<number>;
    }
}
