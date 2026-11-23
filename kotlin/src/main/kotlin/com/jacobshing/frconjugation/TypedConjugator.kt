package com.jacobshing.frconjugation

import java.text.Normalizer

private val sharedReader by lazy { Conjugator() }

/** Return the lazily initialized shared reader; resource errors propagate. */
fun Conjugator.Companion.getShared(): Conjugator = sharedReader

/** Distinct base-infinitive count, collapsing homonyms. */
val Conjugator.verbCount: Int get() = allVerbs.size

/** Whether the base name has indexed homonyms. */
fun Conjugator.hasHomonyms(verb: String): Boolean = homonymIndices(verb).isNotEmpty()

/** Homonym count, or one when no group exists, even for unknown verbs. */
fun Conjugator.homonymCount(verb: String): Int = homonymIndices(verb).size.coerceAtLeast(1)

private fun Conjugator.metadata(
    verb: String,
    homonym: Int? = null,
    resolve: Boolean = false,
): VerbEntry? {
    val key = if (resolve) catalogue.resolve(nfc(verb), homonym) else nfc(verb)
    return catalogue.entries[key]?.metadata
}

/** Whether this exact catalogue key has an aspirated initial h. */
fun Conjugator.isHAspire(verb: String): Boolean = metadata(verb)?.isHAspire ?: false

/** Lexical blocking for the resolved entry; auxiliaries may still elide. */
fun Conjugator.blocksElisionAndLiaison(
    verb: String,
    homonymIndex: Int? = null,
): Boolean = metadata(verb, homonymIndex, true)?.blocksElisionAndLiaison ?: false

/** Whether this exact key is marked as a reform variant. */
fun Conjugator.is1990Reform(verb: String): Boolean = metadata(verb)?.is1990Reform ?: false

/** Reform variant for the exact key, or null if absent. */
fun Conjugator.reformVariant(verb: String): String? = metadata(verb)?.variant

internal fun frenchSortKey(value: String): String =
    Normalizer.normalize(value.replace("œ", "oe").replace("æ", "ae"), Normalizer.Form.NFKD).filter {
        Character.getType(it) !=
            Character.NON_SPACING_MARK.toInt()
    }

private fun slot(
    voice: Voice,
    mode: Mode,
    tense: Tense,
    person: Person,
): String = "${voice.label}|${mode.label}|${tense.label}|${person.label}"

private fun Conjugator.typedForm(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    person: Person,
    homonym: Int?,
    prediction: Prediction,
): String? = form(verb, slot(voice, mode, tense, person), prediction, homonym)

private fun Conjugator.typedPersons(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    homonym: Int?,
    prediction: Prediction,
): Map<Person, String> =
    Person.entries
        .mapNotNull { person ->
            typedForm(verb, voice, mode, tense, person, homonym, prediction)?.let {
                person to
                    it
            }
        }.toMap()

private fun Conjugator.typedTenses(
    verb: String,
    voice: Voice,
    mode: Mode,
    homonym: Int?,
    prediction: Prediction,
): Map<Tense, Map<Person, String>> =
    Tense.entries
        .mapNotNull { tense ->
            typedPersons(
                verb,
                voice,
                mode,
                tense,
                homonym,
                prediction,
            ).takeIf { it.isNotEmpty() }?.let {
                tense to
                    it
            }
        }.toMap()

private fun Conjugator.typedModes(
    verb: String,
    voice: Voice,
    homonym: Int?,
    prediction: Prediction,
): Map<Mode, Map<Tense, Map<Person, String>>> =
    Mode.entries
        .filter {
            it !=
                Mode.PARTICIPE
        }.mapNotNull { mode ->
            typedTenses(
                verb,
                voice,
                mode,
                homonym,
                prediction,
            ).takeIf { it.isNotEmpty() }?.let {
                mode to
                    it
            }
        }.toMap()

private fun Conjugator.typedVoices(
    verb: String,
    homonym: Int?,
    prediction: Prediction,
): Map<Voice, Map<Mode, Map<Tense, Map<Person, String>>>>? =
    Voice.entries
        .mapNotNull { voice ->
            typedModes(verb, voice, homonym, prediction).takeIf { it.isNotEmpty() }?.let {
                voice to
                    it
            }
        }.toMap()
        .takeIf { it.isNotEmpty() }

/** Catalogue finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested. */
fun Conjugator.conjugate(
    verb: String,
    homonymIndex: Int? = null,
): Map<Voice, Map<Mode, Map<Tense, Map<Person, String>>>>? =
    typedVoices(verb, homonymIndex, Prediction.CATALOGUE)

/** Catalogue finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested. */
fun Conjugator.conjugate(
    verb: String,
    voice: Voice,
    homonymIndex: Int? = null,
): Map<Mode, Map<Tense, Map<Person, String>>> =
    typedModes(verb, voice, homonymIndex, Prediction.CATALOGUE)

/** Catalogue finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested. */
fun Conjugator.conjugate(
    verb: String,
    voice: Voice,
    mode: Mode,
    homonymIndex: Int? = null,
): Map<Tense, Map<Person, String>> =
    typedTenses(verb, voice, mode, homonymIndex, Prediction.CATALOGUE)

/** Catalogue finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested. */
fun Conjugator.conjugate(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    homonymIndex: Int? = null,
): Map<Person, String> = typedPersons(verb, voice, mode, tense, homonymIndex, Prediction.CATALOGUE)

/** Catalogue finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested. */
fun Conjugator.conjugate(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    person: Person,
    homonymIndex: Int? = null,
): String? = typedForm(verb, voice, mode, tense, person, homonymIndex, Prediction.CATALOGUE)

/** Inferred finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested. */
fun Conjugator.rawInferredConjugation(
    verb: String,
    homonymIndex: Int? = null,
): Map<Voice, Map<Mode, Map<Tense, Map<Person, String>>>>? =
    typedVoices(verb, homonymIndex, Prediction.INFERRED)

/** Inferred finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested. */
fun Conjugator.rawInferredConjugation(
    verb: String,
    voice: Voice,
    homonymIndex: Int? = null,
): Map<Mode, Map<Tense, Map<Person, String>>> =
    typedModes(verb, voice, homonymIndex, Prediction.INFERRED)

/** Inferred finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested. */
fun Conjugator.rawInferredConjugation(
    verb: String,
    voice: Voice,
    mode: Mode,
    homonymIndex: Int? = null,
): Map<Tense, Map<Person, String>> =
    typedTenses(verb, voice, mode, homonymIndex, Prediction.INFERRED)

/** Inferred finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested. */
fun Conjugator.rawInferredConjugation(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    homonymIndex: Int? = null,
): Map<Person, String> = typedPersons(verb, voice, mode, tense, homonymIndex, Prediction.INFERRED)

/** Inferred finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested. */
fun Conjugator.rawInferredConjugation(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    person: Person,
    homonymIndex: Int? = null,
): String? = typedForm(verb, voice, mode, tense, person, homonymIndex, Prediction.INFERRED)

/** Guess finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested. */
fun Conjugator.guessConjugation(
    verb: String,
    homonymIndex: Int? = null,
): Map<Voice, Map<Mode, Map<Tense, Map<Person, String>>>>? =
    typedVoices(verb, homonymIndex, Prediction.GUESS)

/** Guess finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested. */
fun Conjugator.guessConjugation(
    verb: String,
    voice: Voice,
    homonymIndex: Int? = null,
): Map<Mode, Map<Tense, Map<Person, String>>> =
    typedModes(verb, voice, homonymIndex, Prediction.GUESS)

/** Guess finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested. */
fun Conjugator.guessConjugation(
    verb: String,
    voice: Voice,
    mode: Mode,
    homonymIndex: Int? = null,
): Map<Tense, Map<Person, String>> = typedTenses(verb, voice, mode, homonymIndex, Prediction.GUESS)

/** Guess finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested. */
fun Conjugator.guessConjugation(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    homonymIndex: Int? = null,
): Map<Person, String> = typedPersons(verb, voice, mode, tense, homonymIndex, Prediction.GUESS)

/** Guess finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested. */
fun Conjugator.guessConjugation(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    person: Person,
    homonymIndex: Int? = null,
): String? = typedForm(verb, voice, mode, tense, person, homonymIndex, Prediction.GUESS)

/** Catalogue participle selected by gendered tense, or null if unsupported. */
fun Conjugator.participle(
    verb: String,
    voice: Voice,
    tense: Tense,
    homonymIndex: Int? = null,
): String? =
    form(verb, "${voice.label}|participe|${tense.label}|-", Prediction.CATALOGUE, homonymIndex)

/** All catalogue participles keyed by typed tense; missing values omitted. */
fun Conjugator.participles(
    verb: String,
    voice: Voice,
    homonymIndex: Int? = null,
): Map<Tense, String> =
    Tense.entries
        .mapNotNull { t ->
            participle(verb, voice, t, homonymIndex)?.let {
                t to
                    it
            }
        }.toMap()

/** Catalogue gérondif. Each inferred alternative receives en; unsupported tenses return null. */
fun Conjugator.gerondif(
    verb: String,
    voice: Voice,
    tense: Tense,
    homonymIndex: Int? = null,
): String? = gerondif(verb, voice.label, tense.label, Prediction.CATALOGUE, homonymIndex)

/** Inferred participle selected by gendered tense, or null if unsupported. */
fun Conjugator.rawInferredParticiple(
    verb: String,
    voice: Voice,
    tense: Tense,
    homonymIndex: Int? = null,
): String? =
    form(verb, "${voice.label}|participe|${tense.label}|-", Prediction.INFERRED, homonymIndex)

/** All inferred participles keyed by typed tense; missing values omitted. */
fun Conjugator.rawInferredParticiples(
    verb: String,
    voice: Voice,
    homonymIndex: Int? = null,
): Map<Tense, String> =
    Tense.entries
        .mapNotNull { t ->
            rawInferredParticiple(verb, voice, t, homonymIndex)?.let {
                t to
                    it
            }
        }.toMap()

/** Inferred gérondif. Each inferred alternative receives en; unsupported tenses return null. */
fun Conjugator.rawInferredGerondif(
    verb: String,
    voice: Voice,
    tense: Tense,
    homonymIndex: Int? = null,
): String? = gerondif(verb, voice.label, tense.label, Prediction.INFERRED, homonymIndex)

/** Guess participle selected by gendered tense, or null if unsupported. */
fun Conjugator.guessParticiple(
    verb: String,
    voice: Voice,
    tense: Tense,
    homonymIndex: Int? = null,
): String? = form(verb, "${voice.label}|participe|${tense.label}|-", Prediction.GUESS, homonymIndex)

/** All guess participles keyed by typed tense; missing values omitted. */
fun Conjugator.guessParticiples(
    verb: String,
    voice: Voice,
    homonymIndex: Int? = null,
): Map<Tense, String> =
    Tense.entries
        .mapNotNull { t ->
            guessParticiple(verb, voice, t, homonymIndex)?.let {
                t to
                    it
            }
        }.toMap()

/** Guess gérondif. Each inferred alternative receives en; unsupported tenses return null. */
fun Conjugator.guessGerondif(
    verb: String,
    voice: Voice,
    tense: Tense,
    homonymIndex: Int? = null,
): String? = gerondif(verb, voice.label, tense.label, Prediction.GUESS, homonymIndex)

/** Typed catalogue query. Alternatives fall back to primary; absent forms return null (false for availability). */
fun Conjugator.conjugateAlternative(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    person: Person,
    homonymIndex: Int? = null,
): String? =
    form(
        verb,
        slot(voice, mode, tense, person),
        homonymIndex = homonymIndex,
        spelling = Spelling.ALTERNATIVE,
    )

/** Typed catalogue query. Alternatives fall back to primary; absent forms return null (false for availability). */
fun Conjugator.hasAlternativeForm(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    person: Person,
    homonymIndex: Int? = null,
): Boolean =
    form(
        verb,
        slot(voice, mode, tense, person),
        homonymIndex = homonymIndex,
        spelling = Spelling.ALL,
    )?.contains(";")
        ?: false

/** Typed catalogue query. Alternatives fall back to primary; absent forms return null (false for availability). */
fun Conjugator.getPronoun(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    person: Person,
    homonymIndex: Int? = null,
): String? = pronoun(verb, slot(voice, mode, tense, person), homonymIndex, Spelling.PRIMARY)

/** Typed catalogue query. Alternatives fall back to primary; absent forms return null (false for availability). */
fun Conjugator.conjugateWithPronoun(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    person: Person,
    homonymIndex: Int? = null,
): String? = withPronoun(verb, slot(voice, mode, tense, person), homonymIndex, Spelling.PRIMARY)

/** Typed catalogue query. Alternatives fall back to primary; absent forms return null (false for availability). */
fun Conjugator.conjugateAlternativeWithPronoun(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    person: Person,
    homonymIndex: Int? = null,
): String? = withPronoun(verb, slot(voice, mode, tense, person), homonymIndex, Spelling.ALTERNATIVE)

/** Catalogue participle alternative or alternative availability; unsupported tenses are missing. */
fun Conjugator.participleAlternative(
    verb: String,
    voice: Voice,
    tense: Tense,
    homonymIndex: Int? = null,
): String? =
    form(
        verb,
        "${voice.label}|participe|${tense.label}|-",
        homonymIndex = homonymIndex,
        spelling = Spelling.ALTERNATIVE,
    )

/** Catalogue participle alternative or alternative availability; unsupported tenses are missing. */
fun Conjugator.hasAlternativeParticiple(
    verb: String,
    voice: Voice,
    tense: Tense,
    homonymIndex: Int? = null,
): Boolean =
    form(
        verb,
        "${voice.label}|participe|${tense.label}|-",
        homonymIndex = homonymIndex,
        spelling = Spelling.ALL,
    )?.contains(";")
        ?: false

/** Catalogue structure with at least one available form, ordered by raw label. */
fun Conjugator.voices(
    verb: String,
    homonymIndex: Int? = null,
): List<Voice> =
    forms(verb, homonymIndex = homonymIndex)
        .keys
        .map { it.split("|") }
        .filter { p ->
            true
        }.map { p ->
            Voice.entries.first {
                it.label ==
                    p[0]
            }
        }.distinct()
        .sortedBy { it.label }

/** Catalogue structure with at least one available form, ordered by raw label. */
fun Conjugator.modes(
    verb: String,
    voice: Voice,
    homonymIndex: Int? = null,
): List<Mode> =
    forms(verb, homonymIndex = homonymIndex)
        .keys
        .map { it.split("|") }
        .filter { p ->
            p[0] ==
                voice.label
        }.map { p -> Mode.entries.first { it.label == p[1] } }
        .distinct()
        .sortedBy { it.label }

/** Catalogue structure with at least one available form, ordered by raw label. */
fun Conjugator.tenses(
    verb: String,
    voice: Voice,
    mode: Mode,
    homonymIndex: Int? = null,
): List<Tense> =
    forms(verb, homonymIndex = homonymIndex)
        .keys
        .map { it.split("|") }
        .filter { p ->
            p[0] ==
                voice.label &&
                p[1] == mode.label
        }.map { p -> Tense.entries.first { it.label == p[2] } }
        .distinct()
        .sortedBy { it.label }

/** Persons grouped by identical full spellings in declaration order; no participles. */
fun Conjugator.persons(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    homonymIndex: Int? = null,
): List<Person> {
    if (mode == Mode.PARTICIPE) return emptyList()
    val groups = linkedMapOf<String, MutableList<Person>>()
    for (person in Person.entries) {
        val raw =
            form(
                verb,
                slot(voice, mode, tense, person),
                homonymIndex = homonymIndex,
                spelling = Spelling.ALL,
            )
                ?: continue
        groups.getOrPut(raw) { mutableListOf() }.add(person)
    }
    return groups.values.flatten()
}
