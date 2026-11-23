/** Catalogue labels for voice. */
export enum Voice {
    /** Catalogue label `voix_active_avoir`. */
    ActiveAvoir = "voix_active_avoir",
    /** Catalogue label `voix_active_etre`. */
    ActiveEtre = "voix_active_etre",
    /** Catalogue label `voix_active`. */
    Active = "voix_active",
    /** Catalogue label `voix_passive`. */
    Passive = "voix_passive",
    /** Catalogue label `voix_prono`. */
    Pronominal = "voix_prono",
}

/** Catalogue labels for mode. */
export enum Mode {
    /** Catalogue label `indicatif`. */
    Indicatif = "indicatif",
    /** Catalogue label `subjonctif`. */
    Subjonctif = "subjonctif",
    /** Catalogue label `conditionnel`. */
    Conditionnel = "conditionnel",
    /** Catalogue label `imperatif`. */
    Imperatif = "imperatif",
    /** Catalogue label `participe`. */
    Participe = "participe",
}

/** Catalogue labels for tense. */
export enum Tense {
    /** Catalogue label `present`. */
    Present = "present",
    /** Catalogue label `imparfait`. */
    Imparfait = "imparfait",
    /** Catalogue label `passe_simple`. */
    PasseSimple = "passe_simple",
    /** Catalogue label `futur_simple`. */
    FuturSimple = "futur_simple",
    /** Catalogue label `passe_compose`. */
    PasseCompose = "passe_compose",
    /** Catalogue label `plus_que_parfait`. */
    PlusQueParfait = "plus_que_parfait",
    /** Catalogue label `passe_anterieur`. */
    PasseAnterieur = "passe_anterieur",
    /** Catalogue label `futur_anterieur`. */
    FuturAnterieur = "futur_anterieur",
    /** Catalogue label `passe`. */
    Passe = "passe",
    /** Catalogue label `passe_sm`. */
    PasseMasculinSingulier = "passe_sm",
    /** Catalogue label `passe_sf`. */
    PasseFemininSingulier = "passe_sf",
    /** Catalogue label `passe_pm`. */
    PasseMasculinPluriel = "passe_pm",
    /** Catalogue label `passe_pf`. */
    PasseFemininPluriel = "passe_pf",
    /** Catalogue label `passe_compound_sm`. */
    PasseCompoundMasculinSingulier = "passe_compound_sm",
    /** Catalogue label `passe_compound_sf`. */
    PasseCompoundFemininSingulier = "passe_compound_sf",
    /** Catalogue label `passe_compound_pm`. */
    PasseCompoundMasculinPluriel = "passe_compound_pm",
    /** Catalogue label `passe_compound_pf`. */
    PasseCompoundFemininPluriel = "passe_compound_pf",
    /** Catalogue label `present_sm`. */
    PresentMasculinSingulier = "present_sm",
    /** Catalogue label `present_sf`. */
    PresentFemininSingulier = "present_sf",
    /** Catalogue label `present_pm`. */
    PresentMasculinPluriel = "present_pm",
    /** Catalogue label `present_pf`. */
    PresentFemininPluriel = "present_pf",
    /** Catalogue label `gerondif_present`. */
    GerondifPresent = "gerondif_present",
    /** Catalogue label `gerondif_passe_sm`. */
    GerondifPasseMasculinSingulier = "gerondif_passe_sm",
    /** Catalogue label `gerondif_passe_sf`. */
    GerondifPasseFemininSingulier = "gerondif_passe_sf",
    /** Catalogue label `gerondif_passe_pm`. */
    GerondifPasseMasculinPluriel = "gerondif_passe_pm",
    /** Catalogue label `gerondif_passe_pf`. */
    GerondifPasseFemininPluriel = "gerondif_passe_pf",
}

/** Catalogue labels for person. */
export enum Person {
    /** Catalogue label `1sm`. */
    FirstSingularMasculine = "1sm",
    /** Catalogue label `1sf`. */
    FirstSingularFeminine = "1sf",
    /** Catalogue label `2sm`. */
    SecondSingularMasculine = "2sm",
    /** Catalogue label `2sf`. */
    SecondSingularFeminine = "2sf",
    /** Catalogue label `3sm`. */
    ThirdSingularMasculine = "3sm",
    /** Catalogue label `3sf`. */
    ThirdSingularFeminine = "3sf",
    /** Catalogue label `3sn`. */
    ThirdSingularNeutral = "3sn",
    /** Catalogue label `1pm`. */
    FirstPluralMasculine = "1pm",
    /** Catalogue label `1pf`. */
    FirstPluralFeminine = "1pf",
    /** Catalogue label `2pm`. */
    SecondPluralMasculine = "2pm",
    /** Catalogue label `2pf`. */
    SecondPluralFeminine = "2pf",
    /** Catalogue label `3pm`. */
    ThirdPluralMasculine = "3pm",
    /** Catalogue label `3pf`. */
    ThirdPluralFeminine = "3pf",
}

/** Select catalogue lookup, raw inference, or catalogue-first guessing. */
export enum Prediction {
    /** Preserve source availability. */
    Catalogue = "catalogue",
    /** Predict every supported slot. */
    Inferred = "inferred",
    /** Infer only missing catalogue slots. */
    Guess = "guess",
}
/** Which catalogue spelling to return; predictions retain all alternatives. */
export enum Spelling {
    /** First spelling. */
    Primary = "primary",
    /** Remaining spellings, or primary if no alternative exists. */
    Alternative = "alternative",
    /** All spellings separated by semicolons. */
    All = "all",
}
/** Finite forms keyed by person; missing forms are omitted. */
export type PersonForms = Partial<Record<Person, string>>;
/** Finite forms keyed by tense. */
export type TenseForms = Partial<Record<Tense, PersonForms>>;
/** Finite forms keyed by mood. */
export type ModeForms = Partial<Record<Mode, TenseForms>>;
/** Finite forms keyed by voice. */
export type VoiceForms = Partial<Record<Voice, ModeForms>>;
/** Personless participle spellings keyed by tense. */
export type ParticipleForms = Partial<Record<Tense, string>>;
/** Context-free subject pronoun. */
export function personPronoun(person: Person): string {
    return (
        (
            {
                "1s": "je",
                "2s": "tu",
                "3sm": "il",
                "3sf": "elle",
                "3sn": "on",
                "1p": "nous",
                "2p": "vous",
                "3pm": "ils",
                "3pf": "elles",
            } as Record<string, string>
        )[person] ??
        ({ "1s": "je", "2s": "tu", "1p": "nous", "2p": "vous" } as Record<string, string>)[
            person.slice(0, 2)
        ] ??
        ""
    );
}
/** Parse a raw catalogue label into an enum, returning null for unknown values. */
export function parseLabel<T extends string>(values: Record<string, T>, label: string): T | null {
    return Object.values(values).find((value) => value === label) ?? null;
}
/** Read-only snapshot of lexical metadata for an exact catalogue key. */
export interface VerbEntry {
    /** Exact key, including any homonym suffix. */
    readonly key: string;
    /** Source bits: h aspiré, lexical blocking, and reform respectively. */
    readonly flags: number;
    /** Reform variant key, if present. */
    readonly variant: string | null;
    /** Whether initial h blocks elision. */
    readonly isHAspire: boolean;
    /** Lexical blocking, distinct from auxiliary elision. */
    readonly blocksElisionAndLiaison: boolean;
    /** Whether marked as a reform entry. */
    readonly is1990Reform: boolean;
}
