package com.jacobshing.frconjugation

import java.text.Normalizer

/** Selects exact catalogue lookup, raw inference, or catalogue-first guessing. */
enum class Prediction {
    /** Trimmed, lowercase, NFC-normalized catalogue lookup. */
    CATALOGUE,

    /** Trim, lowercase and infer supported input, including unknown verbs. Predictions may be unattested. */
    INFERRED,

    /** Use catalogue data for known infinitives; infer only unknown infinitives. */
    GUESS,
}

/** Catalogue spelling selection; inference always preserves all alternatives. */
enum class Spelling {
    /** First semicolon-delimited spelling. */
    PRIMARY,

    /** Remainder after the first semicolon, or primary if no alternative exists. */
    ALTERNATIVE,

    /** All semicolon-delimited spellings. */
    ALL,
}

/** Immutable metadata for one catalogue entry.
 * @property key Exact infinitive key including a homonym suffix, if present.
 * @property flags Bits 0: h aspiré, 1: elision/liaison blocking, 2: 1990 reform.
 * @property variant Reform-variant key, or null when none is recorded.
 */
data class VerbEntry(
    val key: String,
    val flags: Int,
    val variant: String?,
) {
    /** Whether an initial h blocks elision and liaison. */
    val isHAspire: Boolean get() = flags and 1 != 0

    /** Whether the source blocks lexical elision/liaison, including non-h initials. Auxiliaries may still elide. */
    val blocksElisionAndLiaison: Boolean get() = flags and 2 != 0

    /** Whether the entry is marked as a 1990 spelling reform variant. */
    val is1990Reform: Boolean get() = flags and 4 != 0
}

/** Immutable, thread-safe bundled catalogue. Ordinary calls run on the caller.
 * Async-suffixed suspend extensions run on the shared worker pool without cancellation.
 * Slot labels use voice|mode|tense|person, with "-" for participles.
 * Null means missing. An empty prefix is a valid result.
 * All verb inputs are trimmed, lowercased and NFC-normalized. Inference permits space,
 * apostrophe, hyphen, 1, 2, semicolon, underscore, a-z and âçèéêîïôûœ.
 * No custom catalogue can be supplied. Resource-loading failures propagate.
 * @constructor Creates a reader sharing the lazily loaded bundled catalogue.
 */
class Conjugator {
    internal val catalogue = bundled

    /** All supported voice|mode|tense|person labels in catalogue order; participles use - as person. */
    val slots: List<String> get() = catalogue.slots.toList()

    /** A snapshot of all catalogue entries, including separately indexed homonyms. */
    val entries: List<VerbEntry> get() = catalogue.entries.values.map { it.metadata }

    /** Distinct base infinitives in French-oriented accent/ligature-insensitive order, collapsing homonym suffixes. */
    val allVerbs: List<String> get() =
        entries
            .map {
                lemmaIndex(it.key).first
            }.distinct()
            .sortedWith(compareBy<String> { frenchSortKey(it) }.thenBy { it })

    /** Tests normalized catalogue membership, accepting either base infinitives or indexed homonym keys.
     * @param verb Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.
     */
    fun hasVerb(verb: String): Boolean =
        catalogue.entries.containsKey(verbKey(verb)) ||
            catalogue.homonyms.containsKey(verbKey(verb))

    /** Returns ascending indices for a base infinitive, or an empty list when no indexed group exists.
     * @param verb Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.
     */
    fun homonymIndices(verb: String): List<Int> =
        catalogue.homonyms[verbKey(verb)]?.toList() ?: emptyList()

    /** Returns one form, or null for an unknown slot, unsupported input, or unavailable catalogue form.
     * @param verb Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.
     * @param slot Supported voice|mode|tense|person label from [slots], with - for participles.
     * @param prediction All modes trim, lowercase and NFC-normalize verb inputs; Guess infers only infinitives absent from the catalogue. Predictions can be unattested.
     * @param homonymIndex Positive homonym index, or null for the first available index. An exact entry key takes precedence.
     * @param spelling Catalogue spelling selection. Inferred output retains all semicolon-separated alternatives.
     * @throws IllegalArgumentException if a supplied homonym index is not positive.
     */
    fun form(
        verb: String,
        slot: String,
        prediction: Prediction = Prediction.CATALOGUE,
        homonymIndex: Int? = null,
        spelling: Spelling = Spelling.PRIMARY,
    ): String? {
        require(homonymIndex == null || homonymIndex > 0)
        val id = catalogue.slotIds[slot] ?: return null
        if (prediction != Prediction.INFERRED) {
            val known = catalogue.raw(verb, id, homonymIndex, Prediction.CATALOGUE)
            if (known != null) return selectSpelling(known, spelling)
            if (prediction == Prediction.CATALOGUE || hasVerb(verb)) return null
        }
        return catalogue.raw(verb, id, homonymIndex, Prediction.INFERRED)
    }

    /** Returns supported slots mapped to forms; missing results are omitted. Catalogue spellings are primary.
     * @param verb Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.
     * @param prediction All modes trim, lowercase and NFC-normalize verb inputs; Guess infers only infinitives absent from the catalogue. Predictions can be unattested.
     * @param homonymIndex Positive homonym index, or null for the first available index. An exact entry key takes precedence.
     * @throws IllegalArgumentException if a supplied homonym index is not positive.
     */
    fun forms(
        verb: String,
        prediction: Prediction = Prediction.CATALOGUE,
        homonymIndex: Int? = null,
    ): Map<String, String> =
        slots
            .mapNotNull { slot ->
                form(verb, slot, prediction, homonymIndex)?.let { slot to it }
            }.toMap()

    /** Returns shared spelling across all catalogue forms and alternatives, excluding auxiliaries and attached pronouns.
     * @param verb Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.
     * @param homonymIndex Positive homonym index, or null for the first available index. An exact entry key takes precedence.
     * @return null for no usable forms; empty is valid. Shared spelling is not a grammatical stem.
     * @throws IllegalArgumentException if a supplied homonym index is not positive.
     */
    fun commonPrefix(
        verb: String,
        homonymIndex: Int? = null,
    ): String? = prefix(verb, homonymIndex, Prediction.CATALOGUE)

    /** Returns shared spelling across raw inferred forms and alternatives, excluding auxiliaries and attached pronouns.
     * @param verb Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.
     * @param homonymIndex Positive homonym index, or null for the first available index. An exact entry key takes precedence.
     * @return null for no usable forms; empty is valid. Shared spelling is not a grammatical stem.
     * @throws IllegalArgumentException if a supplied homonym index is not positive.
     */
    fun rawInferredCommonPrefix(
        verb: String,
        homonymIndex: Int? = null,
    ): String? = prefix(verb, homonymIndex, Prediction.INFERRED)

    /** Returns the catalogue prefix for known infinitives, otherwise an inferred prefix.
     * @param verb Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.
     * @param homonymIndex Positive homonym index, or null for the first available index. An exact entry key takes precedence.
     * @return null for no usable forms; empty is valid. Shared spelling is not a grammatical stem.
     * @throws IllegalArgumentException if a supplied homonym index is not positive.
     */
    fun guessCommonPrefix(
        verb: String,
        homonymIndex: Int? = null,
    ): String? = prefix(verb, homonymIndex, Prediction.GUESS)

    private fun prefix(
        verb: String,
        homonym: Int?,
        prediction: Prediction,
    ): String? {
        require(homonym == null || homonym > 0)
        var result: String? = null
        for (slot in catalogue.slots.indices) {
            val raw = catalogue.raw(verb, slot, homonym, prediction) ?: continue
            for (alternative in raw.split(';')) {
                val word = mainWord(alternative)
                if (word.isEmpty()) continue
                result = if (result == null) word else sharedPrefix(result, word)
                if (result.isEmpty()) return result
            }
        }
        return result
    }

    /** Prefixes the underlying participle with en; predictions repeat en for each alternative. Missing forms return null.
     * @param verb Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.
     * @param prediction All modes trim, lowercase and NFC-normalize verb inputs; Guess infers only infinitives absent from the catalogue. Predictions can be unattested.
     * @param homonymIndex Positive homonym index, or null for the first available index. An exact entry key takes precedence.
     * @param voice Catalogue voice label, such as voix_active_avoir or voix_prono.
     * @param tense gerondif_present or gerondif_passe_sm, gerondif_passe_sf, gerondif_passe_pm, gerondif_passe_pf.
     * @throws IllegalArgumentException if a supplied homonym index is not positive.
     */
    fun gerondif(
        verb: String,
        voice: String,
        tense: String,
        prediction: Prediction = Prediction.CATALOGUE,
        homonymIndex: Int? = null,
    ): String? {
        val source = gerondifSources[tense] ?: return null
        val value =
            form(verb, "$voice|participe|$source|-", prediction, homonymIndex) ?: return null
        return value.split(';').joinToString(";") { "en " + it.trim() }
    }

    /** Returns a catalogue subject prefix with its trailing space or apostrophe, including subjunctive que/qu’. Imperatives, participles and unavailable forms return null.
     * @param verb Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.
     * @param slot Supported voice|mode|tense|person label from [slots], with - for participles.
     * @param homonymIndex Positive homonym index, or null for the first available index. An exact entry key takes precedence.
     * @param spelling PRIMARY or ALTERNATIVE. ALL is invalid.
     * @throws IllegalArgumentException if a supplied homonym index is not positive.
     */
    fun pronoun(
        verb: String,
        slot: String,
        homonymIndex: Int? = null,
        spelling: Spelling = Spelling.PRIMARY,
    ): String? {
        require(spelling != Spelling.ALL)
        val value =
            form(verb, slot, homonymIndex = homonymIndex, spelling = spelling) ?: return null
        return subject(verb, slot, homonymIndex, value)
    }

    /** Returns a catalogue form with its subject prefix; imperatives and participles remain bare. Missing forms return null.
     * @param verb Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.
     * @param slot Supported voice|mode|tense|person label from [slots], with - for participles.
     * @param homonymIndex Positive homonym index, or null for the first available index. An exact entry key takes precedence.
     * @param spelling PRIMARY or ALTERNATIVE. ALL is invalid.
     * @throws IllegalArgumentException if a supplied homonym index is not positive.
     */
    fun withPronoun(
        verb: String,
        slot: String,
        homonymIndex: Int? = null,
        spelling: Spelling = Spelling.PRIMARY,
    ): String? {
        require(spelling != Spelling.ALL)
        val value =
            form(verb, slot, homonymIndex = homonymIndex, spelling = spelling) ?: return null
        return (subject(verb, slot, homonymIndex, value) ?: "") + value
    }

    private fun subject(
        verb: String,
        slot: String,
        homonym: Int?,
        form: String,
    ): String? {
        val parts = slot.split('|')
        if (parts.size != 4 || parts[1] in listOf("imperatif", "participe")) return null
        val base = subjects[parts[3]] ?: return null
        val entry = catalogue.entries[catalogue.resolve(verbKey(verb), homonym)]?.metadata
        val first = form.firstOrNull()?.lowercaseChar()
        var vowel = first != null && first in "aeiouàâéèêëîïôùûüœæy"
        if (first == 'h') vowel = entry?.isHAspire != true
        if (parts[0] != "voix_passive" && parts[2] in simpleTenses &&
            entry?.blocksElisionAndLiaison == true
        ) {
            vowel = false
        }
        val result = if (base == "je" && vowel) "j'" else "$base "
        return if (parts[1] ==
            "subjonctif"
        ) {
            (if (parts[3].startsWith("3")) "qu'" else "que ") + result
        } else {
            result
        }
    }

    /** Shared bundled-resource initialization; no configurable model state is exposed. */
    companion object {
        private val bundled by lazy {
            try {
                Catalogue()
            } catch (
                error: Exception,
            ) {
                throw ConjugationException(error)
            }
        }
        private val gerondifSources =
            mapOf(
                "gerondif_present" to "present",
                "gerondif_passe_sm" to "passe_compound_sm",
                "gerondif_passe_sf" to "passe_compound_sf",
                "gerondif_passe_pm" to "passe_compound_pm",
                "gerondif_passe_pf" to "passe_compound_pf",
            )
        private val subjects =
            mapOf(
                "1sm" to "je",
                "1sf" to "je",
                "2sm" to "tu",
                "2sf" to "tu",
                "3sm" to "il",
                "3sf" to "elle",
                "3sn" to "on",
                "1pm" to "nous",
                "1pf" to "nous",
                "2pm" to "vous",
                "2pf" to "vous",
                "3pm" to "ils",
                "3pf" to "elles",
            )
        private val simpleTenses = setOf("present", "imparfait", "passe_simple", "futur_simple")
        private val trailing =
            Regex("-(?:(?:m|t)['’]en|moi|toi|nous|vous|le|la|les|lui|leur|en|y)(?:-(?:en|y))?$")
        private val leading = Regex("^(?:(?:j|m|t|s|n|l|qu)['’])+")

        private fun mainWord(form: String): String {
            val last = nfc(form).trim().split(Regex("[\\s\\p{Z}]+")).last()
            return leading.replace(trailing.replace(last, ""), "")
        }

        // Valid inference alphabet and NFC catalogue use BMP characters with
        // precomposed accents. Comparing these characters preserves accent changes.
        private fun sharedPrefix(
            a: String,
            b: String,
        ): String {
            var index = 0
            while (index < a.length && index < b.length && a[index] == b[index]) index++
            if (index > 0 && Character.isHighSurrogate(a[index - 1])) index--
            return a.substring(0, index)
        }

        private fun selectSpelling(
            raw: String,
            spelling: Spelling,
        ): String =
            when (spelling) {
                Spelling.ALL -> raw
                Spelling.PRIMARY -> raw.substringBefore(';')
                Spelling.ALTERNATIVE -> if (';' in raw) raw.substringAfter(';') else raw
            }
    }
}

internal fun nfc(value: String): String = Normalizer.normalize(value, Normalizer.Form.NFC)

internal fun lemmaIndex(value: String): Pair<String, String> {
    val position = value.lastIndexOf('_')
    val index = value.substring(position + 1)
    return if (position > 0 && index.isNotEmpty() && index.all { it in '0'..'9' }) {
        value.substring(0, position) to index
    } else {
        value to ""
    }
}

internal fun verbKey(value: String): String =
    nfc(
        value
            .trim {
                it.isWhitespace() ||
                    Character.isSpaceChar(
                        it,
                    )
            }.lowercase(java.util.Locale.ROOT),
    )
