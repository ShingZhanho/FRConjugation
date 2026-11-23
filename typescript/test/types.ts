import {
    Conjugator,
    AsyncConjugator,
    Voice,
    Mode,
    Tense,
    Person,
    type VoiceForms,
    type ModeForms,
    type TenseForms,
    type PersonForms,
} from "../dist/index.js";
const c = new Conjugator();
const all: VoiceForms | null = c.conjugate("manger");
const modes: ModeForms = c.conjugate("manger", Voice.ActiveAvoir);
const tenses: TenseForms = c.conjugate("manger", Voice.ActiveAvoir, Mode.Indicatif);
const persons: PersonForms = c.conjugate(
    "manger",
    Voice.ActiveAvoir,
    Mode.Indicatif,
    Tense.Present,
);
const form: string | null = c.conjugate(
    "manger",
    Voice.ActiveAvoir,
    Mode.Indicatif,
    Tense.Present,
    Person.FirstPluralMasculine,
);
const homonym: VoiceForms | null = c.guessConjugation(
    "ressortir",
    undefined,
    undefined,
    undefined,
    undefined,
    2,
);
// @ts-expect-error Custom binaries are not public API.
new Conjugator(new Uint8Array());
// @ts-expect-error Invalid enum spelling is not an accepted typed selector.
c.conjugate("manger", "active");
// @ts-expect-error Missing leading selector is invalid.
c.conjugate("manger", undefined, Mode.Indicatif);
async function workerTypes() {
    const worker = await AsyncConjugator.load();
    const all: VoiceForms | null = await worker.conjugate("manger");
    const form: string | null = await worker.conjugate(
        "manger",
        Voice.ActiveAvoir,
        Mode.Indicatif,
        Tense.Present,
        Person.FirstPluralMasculine,
    );
    worker.close();
}
