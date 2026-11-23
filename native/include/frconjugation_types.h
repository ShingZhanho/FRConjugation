#ifndef FRCONJUGATION_TYPES_H
#define FRCONJUGATION_TYPES_H
#ifdef __cplusplus
extern "C" {
#endif
/** Typed voice selector. ANY is used only for bulk queries. */
typedef enum {
    FRC_VOICE_ANY = -1,     /**< No filter. */
    FRC_VOICE_ACTIVE_AVOIR, /**< voix_active_avoir. */
    FRC_VOICE_ACTIVE_ETRE,  /**< voix_active_etre. */
    FRC_VOICE_ACTIVE,       /**< voix_active. */
    FRC_VOICE_PASSIVE,      /**< voix_passive. */
    FRC_VOICE_PRONOMINAL,   /**< voix_prono. */
} frc_voice;
/** Borrowed catalogue label; NULL for ANY or an invalid selector. */
const char *frc_voice_label(frc_voice value);
/** Typed mode selector. ANY is used only for bulk queries. */
typedef enum {
    FRC_MOOD_ANY = -1,     /**< No filter. */
    FRC_MOOD_INDICATIF,    /**< indicatif. */
    FRC_MOOD_SUBJONCTIF,   /**< subjonctif. */
    FRC_MOOD_CONDITIONNEL, /**< conditionnel. */
    FRC_MOOD_IMPERATIF,    /**< imperatif. */
    FRC_MOOD_PARTICIPE,    /**< participe. */
} frc_mood;
/** Borrowed catalogue label; NULL for ANY or an invalid selector. */
const char *frc_mood_label(frc_mood value);
/** Typed tense selector. ANY is used only for bulk queries. */
typedef enum {
    FRC_TENSE_ANY = -1,                          /**< No filter. */
    FRC_TENSE_PRESENT,                           /**< present. */
    FRC_TENSE_IMPARFAIT,                         /**< imparfait. */
    FRC_TENSE_PASSE_SIMPLE,                      /**< passe_simple. */
    FRC_TENSE_FUTUR_SIMPLE,                      /**< futur_simple. */
    FRC_TENSE_PASSE_COMPOSE,                     /**< passe_compose. */
    FRC_TENSE_PLUS_QUE_PARFAIT,                  /**< plus_que_parfait. */
    FRC_TENSE_PASSE_ANTERIEUR,                   /**< passe_anterieur. */
    FRC_TENSE_FUTUR_ANTERIEUR,                   /**< futur_anterieur. */
    FRC_TENSE_PASSE,                             /**< passe. */
    FRC_TENSE_PASSE_MASCULIN_SINGULIER,          /**< passe_sm. */
    FRC_TENSE_PASSE_FEMININ_SINGULIER,           /**< passe_sf. */
    FRC_TENSE_PASSE_MASCULIN_PLURIEL,            /**< passe_pm. */
    FRC_TENSE_PASSE_FEMININ_PLURIEL,             /**< passe_pf. */
    FRC_TENSE_PASSE_COMPOUND_MASCULIN_SINGULIER, /**< passe_compound_sm. */
    FRC_TENSE_PASSE_COMPOUND_FEMININ_SINGULIER,  /**< passe_compound_sf. */
    FRC_TENSE_PASSE_COMPOUND_MASCULIN_PLURIEL,   /**< passe_compound_pm. */
    FRC_TENSE_PASSE_COMPOUND_FEMININ_PLURIEL,    /**< passe_compound_pf. */
    FRC_TENSE_PRESENT_MASCULIN_SINGULIER,        /**< present_sm. */
    FRC_TENSE_PRESENT_FEMININ_SINGULIER,         /**< present_sf. */
    FRC_TENSE_PRESENT_MASCULIN_PLURIEL,          /**< present_pm. */
    FRC_TENSE_PRESENT_FEMININ_PLURIEL,           /**< present_pf. */
    FRC_TENSE_GERONDIF_PRESENT,                  /**< gerondif_present. */
    FRC_TENSE_GERONDIF_PASSE_MASCULIN_SINGULIER, /**< gerondif_passe_sm. */
    FRC_TENSE_GERONDIF_PASSE_FEMININ_SINGULIER,  /**< gerondif_passe_sf. */
    FRC_TENSE_GERONDIF_PASSE_MASCULIN_PLURIEL,   /**< gerondif_passe_pm. */
    FRC_TENSE_GERONDIF_PASSE_FEMININ_PLURIEL,    /**< gerondif_passe_pf. */
} frc_tense;
/** Borrowed catalogue label; NULL for ANY or an invalid selector. */
const char *frc_tense_label(frc_tense value);
/** Typed person selector. ANY is used only for bulk queries. */
typedef enum {
    FRC_PERSON_ANY = -1,                  /**< No filter. */
    FRC_PERSON_FIRST_SINGULAR_MASCULINE,  /**< 1sm. */
    FRC_PERSON_FIRST_SINGULAR_FEMININE,   /**< 1sf. */
    FRC_PERSON_SECOND_SINGULAR_MASCULINE, /**< 2sm. */
    FRC_PERSON_SECOND_SINGULAR_FEMININE,  /**< 2sf. */
    FRC_PERSON_THIRD_SINGULAR_MASCULINE,  /**< 3sm. */
    FRC_PERSON_THIRD_SINGULAR_FEMININE,   /**< 3sf. */
    FRC_PERSON_THIRD_SINGULAR_NEUTRAL,    /**< 3sn. */
    FRC_PERSON_FIRST_PLURAL_MASCULINE,    /**< 1pm. */
    FRC_PERSON_FIRST_PLURAL_FEMININE,     /**< 1pf. */
    FRC_PERSON_SECOND_PLURAL_MASCULINE,   /**< 2pm. */
    FRC_PERSON_SECOND_PLURAL_FEMININE,    /**< 2pf. */
    FRC_PERSON_THIRD_PLURAL_MASCULINE,    /**< 3pm. */
    FRC_PERSON_THIRD_PLURAL_FEMININE,     /**< 3pf. */
} frc_person;
/** Borrowed catalogue label; NULL for ANY or an invalid selector. */
const char *frc_person_label(frc_person value);
/** Borrowed unelided subject pronoun; NULL for invalid person. */
const char *frc_person_pronoun(frc_person person);
/** Parse a catalogue label into out. Returns 1 on success, 0 for null/unknown input. */
int frc_voice_from_label(const char *label, frc_voice *out);
/** Parse a catalogue label into out. Returns 1 on success, 0 for null/unknown input. */
int frc_mood_from_label(const char *label, frc_mood *out);
/** Parse a catalogue label into out. Returns 1 on success, 0 for null/unknown input. */
int frc_tense_from_label(const char *label, frc_tense *out);
/** Parse a catalogue label into out. Returns 1 on success, 0 for null/unknown input. */
int frc_person_from_label(const char *label, frc_person *out);
#ifdef __cplusplus
}
#endif
#endif
