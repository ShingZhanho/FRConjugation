package com.jacobshing.frconjugation

/** French grammatical voice.
 * @property label Stable catalogue spelling, corresponding to Swift rawValue.
 */
enum class Voice(
    val label: String,
) {
    /** voix_active_avoir. */
    ACTIVE_AVOIR("voix_active_avoir"),

    /** voix_active_etre. */
    ACTIVE_ETRE("voix_active_etre"),

    /** voix_active. */
    ACTIVE("voix_active"),

    /** voix_passive. */
    PASSIVE("voix_passive"),

    /** voix_prono. */
    PRONOMINAL("voix_prono"),
    ;

    /** Conversion from the stable catalogue label. */
    companion object {
        /** Return the matching value, or null for an unknown label. */
        fun fromLabel(label: String): Voice? = entries.firstOrNull { it.label == label }
    }
}

/** French grammatical mode.
 * @property label Stable catalogue spelling, corresponding to Swift rawValue.
 */
enum class Mode(
    val label: String,
) {
    /** indicatif. */
    INDICATIF("indicatif"),

    /** subjonctif. */
    SUBJONCTIF("subjonctif"),

    /** conditionnel. */
    CONDITIONNEL("conditionnel"),

    /** imperatif. */
    IMPERATIF("imperatif"),

    /** participe. */
    PARTICIPE("participe"),
    ;

    /** Conversion from the stable catalogue label. */
    companion object {
        /** Return the matching value, or null for an unknown label. */
        fun fromLabel(label: String): Mode? = entries.firstOrNull { it.label == label }
    }
}

/** French grammatical tense.
 * @property label Stable catalogue spelling, corresponding to Swift rawValue.
 */
enum class Tense(
    val label: String,
) {
    /** present. */
    PRESENT("present"),

    /** imparfait. */
    IMPARFAIT("imparfait"),

    /** passe_simple. */
    PASSE_SIMPLE("passe_simple"),

    /** futur_simple. */
    FUTUR_SIMPLE("futur_simple"),

    /** passe_compose. */
    PASSE_COMPOSE("passe_compose"),

    /** plus_que_parfait. */
    PLUS_QUE_PARFAIT("plus_que_parfait"),

    /** passe_anterieur. */
    PASSE_ANTERIEUR("passe_anterieur"),

    /** futur_anterieur. */
    FUTUR_ANTERIEUR("futur_anterieur"),

    /** passe. */
    PASSE("passe"),

    /** passe_sm. */
    PASSE_MASCULIN_SINGULIER("passe_sm"),

    /** passe_sf. */
    PASSE_FEMININ_SINGULIER("passe_sf"),

    /** passe_pm. */
    PASSE_MASCULIN_PLURIEL("passe_pm"),

    /** passe_pf. */
    PASSE_FEMININ_PLURIEL("passe_pf"),

    /** passe_compound_sm. */
    PASSE_COMPOUND_MASCULIN_SINGULIER("passe_compound_sm"),

    /** passe_compound_sf. */
    PASSE_COMPOUND_FEMININ_SINGULIER("passe_compound_sf"),

    /** passe_compound_pm. */
    PASSE_COMPOUND_MASCULIN_PLURIEL("passe_compound_pm"),

    /** passe_compound_pf. */
    PASSE_COMPOUND_FEMININ_PLURIEL("passe_compound_pf"),

    /** present_sm. */
    PRESENT_MASCULIN_SINGULIER("present_sm"),

    /** present_sf. */
    PRESENT_FEMININ_SINGULIER("present_sf"),

    /** present_pm. */
    PRESENT_MASCULIN_PLURIEL("present_pm"),

    /** present_pf. */
    PRESENT_FEMININ_PLURIEL("present_pf"),

    /** gerondif_present. */
    GERONDIF_PRESENT("gerondif_present"),

    /** gerondif_passe_sm. */
    GERONDIF_PASSE_MASCULIN_SINGULIER("gerondif_passe_sm"),

    /** gerondif_passe_sf. */
    GERONDIF_PASSE_FEMININ_SINGULIER("gerondif_passe_sf"),

    /** gerondif_passe_pm. */
    GERONDIF_PASSE_MASCULIN_PLURIEL("gerondif_passe_pm"),

    /** gerondif_passe_pf. */
    GERONDIF_PASSE_FEMININ_PLURIEL("gerondif_passe_pf"),
    ;

    /** Conversion from the stable catalogue label. */
    companion object {
        /** Return the matching value, or null for an unknown label. */
        fun fromLabel(label: String): Tense? = entries.firstOrNull { it.label == label }
    }
}

/** French grammatical person.
 * @property label Stable catalogue spelling, corresponding to Swift rawValue.
 */
enum class Person(
    val label: String,
) {
    /** 1sm. */
    FIRST_SINGULAR_MASCULINE("1sm"),

    /** 1sf. */
    FIRST_SINGULAR_FEMININE("1sf"),

    /** 2sm. */
    SECOND_SINGULAR_MASCULINE("2sm"),

    /** 2sf. */
    SECOND_SINGULAR_FEMININE("2sf"),

    /** 3sm. */
    THIRD_SINGULAR_MASCULINE("3sm"),

    /** 3sf. */
    THIRD_SINGULAR_FEMININE("3sf"),

    /** 3sn. */
    THIRD_SINGULAR_NEUTRAL("3sn"),

    /** 1pm. */
    FIRST_PLURAL_MASCULINE("1pm"),

    /** 1pf. */
    FIRST_PLURAL_FEMININE("1pf"),

    /** 2pm. */
    SECOND_PLURAL_MASCULINE("2pm"),

    /** 2pf. */
    SECOND_PLURAL_FEMININE("2pf"),

    /** 3pm. */
    THIRD_PLURAL_MASCULINE("3pm"),

    /** 3pf. */
    THIRD_PLURAL_FEMININE("3pf"),
    ;

    /** Conversion from the stable catalogue label. */
    companion object {
        /** Return the matching value, or null for an unknown label. */
        fun fromLabel(label: String): Person? = entries.firstOrNull { it.label == label }
    }
}

/** French subject pronoun without contextual elision. */
val Person.pronoun: String get() =
    when (label) {
        "1sm", "1sf" -> "je"
        "2sm", "2sf" -> "tu"
        "3sm" -> "il"
        "3sf" -> "elle"
        "3sn" -> "on"
        "1pm", "1pf" -> "nous"
        "2pm", "2pf" -> "vous"
        "3pm" -> "ils"
        else -> "elles"
    }

/** Compact catalogue person label. */
val Person.shortLabel: String get() = label
