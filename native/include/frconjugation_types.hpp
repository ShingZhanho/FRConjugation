#ifndef FRCONJUGATION_TYPES_HPP
#define FRCONJUGATION_TYPES_HPP
#include "frconjugation_types.h"
#include <optional>
namespace frconjugation {
/** French grammatical voice. */
enum class Voice {
    ActiveAvoir = FRC_VOICE_ACTIVE_AVOIR, /**< voix_active_avoir. */
    ActiveEtre = FRC_VOICE_ACTIVE_ETRE,   /**< voix_active_etre. */
    Active = FRC_VOICE_ACTIVE,            /**< voix_active. */
    Passive = FRC_VOICE_PASSIVE,          /**< voix_passive. */
    Pronominal = FRC_VOICE_PRONOMINAL,    /**< voix_prono. */
};
/** French grammatical mode. */
enum class Mode {
    Indicatif = FRC_MOOD_INDICATIF,       /**< indicatif. */
    Subjonctif = FRC_MOOD_SUBJONCTIF,     /**< subjonctif. */
    Conditionnel = FRC_MOOD_CONDITIONNEL, /**< conditionnel. */
    Imperatif = FRC_MOOD_IMPERATIF,       /**< imperatif. */
    Participe = FRC_MOOD_PARTICIPE,       /**< participe. */
};
/** French grammatical tense. */
enum class Tense {
    Present = FRC_TENSE_PRESENT,                                 /**< present. */
    Imparfait = FRC_TENSE_IMPARFAIT,                             /**< imparfait. */
    PasseSimple = FRC_TENSE_PASSE_SIMPLE,                        /**< passe_simple. */
    FuturSimple = FRC_TENSE_FUTUR_SIMPLE,                        /**< futur_simple. */
    PasseCompose = FRC_TENSE_PASSE_COMPOSE,                      /**< passe_compose. */
    PlusQueParfait = FRC_TENSE_PLUS_QUE_PARFAIT,                 /**< plus_que_parfait. */
    PasseAnterieur = FRC_TENSE_PASSE_ANTERIEUR,                  /**< passe_anterieur. */
    FuturAnterieur = FRC_TENSE_FUTUR_ANTERIEUR,                  /**< futur_anterieur. */
    Passe = FRC_TENSE_PASSE,                                     /**< passe. */
    PasseMasculinSingulier = FRC_TENSE_PASSE_MASCULIN_SINGULIER, /**< passe_sm. */
    PasseFemininSingulier = FRC_TENSE_PASSE_FEMININ_SINGULIER,   /**< passe_sf. */
    PasseMasculinPluriel = FRC_TENSE_PASSE_MASCULIN_PLURIEL,     /**< passe_pm. */
    PasseFemininPluriel = FRC_TENSE_PASSE_FEMININ_PLURIEL,       /**< passe_pf. */
    PasseCompoundMasculinSingulier =
        FRC_TENSE_PASSE_COMPOUND_MASCULIN_SINGULIER, /**< passe_compound_sm. */
    PasseCompoundFemininSingulier =
        FRC_TENSE_PASSE_COMPOUND_FEMININ_SINGULIER, /**< passe_compound_sf. */
    PasseCompoundMasculinPluriel =
        FRC_TENSE_PASSE_COMPOUND_MASCULIN_PLURIEL, /**< passe_compound_pm. */
    PasseCompoundFemininPluriel =
        FRC_TENSE_PASSE_COMPOUND_FEMININ_PLURIEL,                    /**< passe_compound_pf. */
    PresentMasculinSingulier = FRC_TENSE_PRESENT_MASCULIN_SINGULIER, /**< present_sm. */
    PresentFemininSingulier = FRC_TENSE_PRESENT_FEMININ_SINGULIER,   /**< present_sf. */
    PresentMasculinPluriel = FRC_TENSE_PRESENT_MASCULIN_PLURIEL,     /**< present_pm. */
    PresentFemininPluriel = FRC_TENSE_PRESENT_FEMININ_PLURIEL,       /**< present_pf. */
    GerondifPresent = FRC_TENSE_GERONDIF_PRESENT,                    /**< gerondif_present. */
    GerondifPasseMasculinSingulier =
        FRC_TENSE_GERONDIF_PASSE_MASCULIN_SINGULIER, /**< gerondif_passe_sm. */
    GerondifPasseFemininSingulier =
        FRC_TENSE_GERONDIF_PASSE_FEMININ_SINGULIER, /**< gerondif_passe_sf. */
    GerondifPasseMasculinPluriel =
        FRC_TENSE_GERONDIF_PASSE_MASCULIN_PLURIEL, /**< gerondif_passe_pm. */
    GerondifPasseFemininPluriel =
        FRC_TENSE_GERONDIF_PASSE_FEMININ_PLURIEL, /**< gerondif_passe_pf. */
};
/** French grammatical person. */
enum class Person {
    FirstSingularMasculine = FRC_PERSON_FIRST_SINGULAR_MASCULINE,   /**< 1sm. */
    FirstSingularFeminine = FRC_PERSON_FIRST_SINGULAR_FEMININE,     /**< 1sf. */
    SecondSingularMasculine = FRC_PERSON_SECOND_SINGULAR_MASCULINE, /**< 2sm. */
    SecondSingularFeminine = FRC_PERSON_SECOND_SINGULAR_FEMININE,   /**< 2sf. */
    ThirdSingularMasculine = FRC_PERSON_THIRD_SINGULAR_MASCULINE,   /**< 3sm. */
    ThirdSingularFeminine = FRC_PERSON_THIRD_SINGULAR_FEMININE,     /**< 3sf. */
    ThirdSingularNeutral = FRC_PERSON_THIRD_SINGULAR_NEUTRAL,       /**< 3sn. */
    FirstPluralMasculine = FRC_PERSON_FIRST_PLURAL_MASCULINE,       /**< 1pm. */
    FirstPluralFeminine = FRC_PERSON_FIRST_PLURAL_FEMININE,         /**< 1pf. */
    SecondPluralMasculine = FRC_PERSON_SECOND_PLURAL_MASCULINE,     /**< 2pm. */
    SecondPluralFeminine = FRC_PERSON_SECOND_PLURAL_FEMININE,       /**< 2pf. */
    ThirdPluralMasculine = FRC_PERSON_THIRD_PLURAL_MASCULINE,       /**< 3pm. */
    ThirdPluralFeminine = FRC_PERSON_THIRD_PLURAL_FEMININE,         /**< 3pf. */
};
/** Borrowed catalogue label. */
inline const char *label(Voice value) {
    return frc_voice_label(static_cast<frc_voice>(value));
}
/** Borrowed catalogue label. */
inline const char *label(Mode value) {
    return frc_mood_label(static_cast<frc_mood>(value));
}
/** Borrowed catalogue label. */
inline const char *label(Tense value) {
    return frc_tense_label(static_cast<frc_tense>(value));
}
/** Borrowed catalogue label. */
inline const char *label(Person value) {
    return frc_person_label(static_cast<frc_person>(value));
}
/** Borrowed subject pronoun without elision. */
inline const char *pronoun(Person value) {
    return frc_person_pronoun(static_cast<frc_person>(value));
}
/** Borrowed compact person label. */
inline const char *short_label(Person value) {
    return label(value);
}
/** Parse a catalogue label, or return nullopt if unknown. */
inline std::optional<Voice> voice_from_label(const char *text) {
    frc_voice value;
    return frc_voice_from_label(text, &value) ? std::optional<Voice>(static_cast<Voice>(value))
                                              : std::nullopt;
}

/** Parse a catalogue label, or return nullopt if unknown. */
inline std::optional<Mode> mode_from_label(const char *text) {
    frc_mood value;
    return frc_mood_from_label(text, &value) ? std::optional<Mode>(static_cast<Mode>(value))
                                             : std::nullopt;
}

/** Parse a catalogue label, or return nullopt if unknown. */
inline std::optional<Tense> tense_from_label(const char *text) {
    frc_tense value;
    return frc_tense_from_label(text, &value) ? std::optional<Tense>(static_cast<Tense>(value))
                                              : std::nullopt;
}

/** Parse a catalogue label, or return nullopt if unknown. */
inline std::optional<Person> person_from_label(const char *text) {
    frc_person value;
    return frc_person_from_label(text, &value) ? std::optional<Person>(static_cast<Person>(value))
                                               : std::nullopt;
}

} // namespace frconjugation
#endif
