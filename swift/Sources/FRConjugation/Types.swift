// Types.swift -- Enums and value types for the FRConjugation library.

import Foundation
#if canImport(CoreVideo)
    // Preserve the Apple SDK extensions on the public RawRepresentable enums.
    import CoreVideo
#endif

// MARK: - Voice

/// French grammatical voice.
///
/// The database distinguishes five voices.  The vast majority of verbs
/// use ``activeAvoir`` (transitive / intransitive with *avoir*).
///
///     Voice.activeAvoir      // il a mangé
///     Voice.activeEtre       // il est allé
///     Voice.active           // (rare) impersonal active
///     Voice.passive          // il est mangé
///     Voice.pronominal       // il se lave
public enum Voice: String, CaseIterable, Sendable, Hashable {
    /// Active voice with avoir as auxiliary.
    case activeAvoir = "voix_active_avoir"
    /// Active voice with être as auxiliary.
    case activeEtre = "voix_active_etre"
    /// Source-defined active voice without a specified auxiliary.
    case active = "voix_active"
    /// Passive voice.
    case passive = "voix_passive"
    /// Pronominal voice, including reflexive forms.
    case pronominal = "voix_prono"
}

// MARK: - Mode

/// French grammatical mode (mood).
public enum Mode: String, CaseIterable, Sendable, Hashable {
    /// Indicative mood.
    case indicatif
    /// Subjunctive mood.
    case subjonctif
    /// Conditional mood.
    case conditionnel
    /// Imperative mood; no subject pronoun.
    case imperatif
    /// Participles; use the dedicated participle APIs.
    case participe
}

// MARK: - Tense

/// French verb tense.
///
/// Not every tense is valid in every mode or voice.  Invalid
/// combinations return `nil`.  Use ``Conjugator/tenses(_:voice:mode:homonymIndex:)``
/// to discover valid tenses for a given verb, voice and mode.
///
/// ## Simple tenses
/// `.present`, `.imparfait`, `.passeSimple`, `.futurSimple`
///
/// ## Compound tenses
/// `.passeCompose`, `.plusQueParfait`, `.passeAnterieur`,
/// `.futurAnterieur`, `.passe`
///
/// ## Participle sub-forms (mode: `.participe`)
/// `.passeMasculinSingulier`, `.passeFemininSingulier`,
/// `.passeMasculinPluriel`,   `.passeFemininPluriel`,
/// `.passeCompoundMasculinSingulier`, `.passeCompoundFemininSingulier`,
/// `.passeCompoundMasculinPluriel`, `.passeCompoundFemininPluriel`,
/// `.presentMasculinSingulier`, `.presentFemininSingulier`,
/// `.presentMasculinPluriel`, `.presentFemininPluriel`
///
/// ## Gérondif (dedicated -- use ``Conjugator/gerondif(_:voice:tense:homonymIndex:)-301m3``)
/// `.gerondifPresent`, `.gerondifPasseMasculinSingulier`,
/// `.gerondifPasseFemininSingulier`, `.gerondifPasseMasculinPluriel`,
/// `.gerondifPasseFemininPluriel`
public enum Tense: String, CaseIterable, Sendable, Hashable {
    // Simple
    /// Present tense, or generic present participle in participle mode.
    case present = "present"
    /// Imperfect tense.
    case imparfait = "imparfait"
    /// Simple past tense.
    case passeSimple = "passe_simple"
    /// Simple future tense.
    case futurSimple = "futur_simple"

    // Compound
    /// Compound past tense.
    case passeCompose = "passe_compose"
    /// Pluperfect tense.
    case plusQueParfait = "plus_que_parfait"
    /// Past anterior tense.
    case passeAnterieur = "passe_anterieur"
    /// Future anterior tense.
    case futurAnterieur = "futur_anterieur"

    // Generic passé (conditionnel, subjonctif, impératif)
    /// Compound past used by the conditional, subjunctive and imperative.
    case passe = "passe"

    // Participle sub-forms (simple)
    /// Past participle, masculine singular.
    case passeMasculinSingulier = "passe_sm"
    /// Past participle, feminine singular.
    case passeFemininSingulier = "passe_sf"
    /// Past participle, masculine plural.
    case passeMasculinPluriel = "passe_pm"
    /// Past participle, feminine plural.
    case passeFemininPluriel = "passe_pf"

    // Participle sub-forms (compound)
    /// Compound past participle, masculine singular.
    case passeCompoundMasculinSingulier = "passe_compound_sm"
    /// Compound past participle, feminine singular.
    case passeCompoundFemininSingulier = "passe_compound_sf"
    /// Compound past participle, masculine plural.
    case passeCompoundMasculinPluriel = "passe_compound_pm"
    /// Compound past participle, feminine plural.
    case passeCompoundFemininPluriel = "passe_compound_pf"

    // Participle sub-forms (gendered present -- passive voice)
    /// Present participle, masculine singular.
    case presentMasculinSingulier = "present_sm"
    /// Present participle, feminine singular.
    case presentFemininSingulier = "present_sf"
    /// Present participle, masculine plural.
    case presentMasculinPluriel = "present_pm"
    /// Present participle, feminine plural.
    case presentFemininPluriel = "present_pf"

    // Gérondif (derived -- not stored in the model)
    /// Present gérondif, derived from the generic present participle.
    case gerondifPresent = "gerondif_present"
    /// Past gérondif, masculine singular.
    case gerondifPasseMasculinSingulier = "gerondif_passe_sm"
    /// Past gérondif, feminine singular.
    case gerondifPasseFemininSingulier = "gerondif_passe_sf"
    /// Past gérondif, masculine plural.
    case gerondifPasseMasculinPluriel = "gerondif_passe_pm"
    /// Past gérondif, feminine plural.
    case gerondifPasseFemininPluriel = "gerondif_passe_pf"
}

// MARK: - Person

/// Grammatical person with gender.
///
/// French conjugation distinguishes masculine and feminine forms for all
/// persons (due to participle agreement in compound tenses).
///
/// The person keys follow the pattern `{number}{plurality}{gender}`:
/// - Number: `1`, `2`, `3`
/// - Plurality: `s` (singular), `p` (plural)
/// - Gender: `m` (masculine), `f` (feminine), `n` (neutral)
public enum Person: String, CaseIterable, Sendable, Hashable {
    /// First singular masculine.
    case firstSingularMasculine = "1sm"
    /// First singular feminine.
    case firstSingularFeminine = "1sf"
    /// Second singular masculine.
    case secondSingularMasculine = "2sm"
    /// Second singular feminine.
    case secondSingularFeminine = "2sf"
    /// Third singular masculine.
    case thirdSingularMasculine = "3sm"
    /// Third singular feminine.
    case thirdSingularFeminine = "3sf"
    /// Third singular neutral (on).
    case thirdSingularNeutral = "3sn"
    /// First plural masculine.
    case firstPluralMasculine = "1pm"
    /// First plural feminine.
    case firstPluralFeminine = "1pf"
    /// Second plural masculine.
    case secondPluralMasculine = "2pm"
    /// Second plural feminine.
    case secondPluralFeminine = "2pf"
    /// Third plural masculine.
    case thirdPluralMasculine = "3pm"
    /// Third plural feminine.
    case thirdPluralFeminine = "3pf"

    /// The French subject pronoun for this person.
    ///
    ///     Person.firstSingularMasculine.pronoun  // "je"
    ///     Person.thirdPluralFeminine.pronoun      // "elles"
    public var pronoun: String {
        switch self {
        case .firstSingularMasculine, .firstSingularFeminine: return "je"
        case .secondSingularMasculine, .secondSingularFeminine: return "tu"
        case .thirdSingularMasculine: return "il"
        case .thirdSingularFeminine: return "elle"
        case .thirdSingularNeutral: return "on"
        case .firstPluralMasculine, .firstPluralFeminine: return "nous"
        case .secondPluralMasculine, .secondPluralFeminine: return "vous"
        case .thirdPluralMasculine: return "ils"
        case .thirdPluralFeminine: return "elles"
        }
    }

    /// Short label (e.g. "1sm", "3pf").
    public var shortLabel: String { rawValue }
}

// MARK: - Errors

/// Errors thrown by ``Conjugator``.
public enum ConjugationError: Error, LocalizedError {
    /// The bundled conjugation catalogue could not be loaded.
    case modelLoadFailed(path: String)

    /// A localized description identifying the bundled resource that failed to load.
    public var errorDescription: String? {
        switch self {
        case .modelLoadFailed(let path):
            return "Failed to load conjugation model from: \(path)"
        }
    }
}
