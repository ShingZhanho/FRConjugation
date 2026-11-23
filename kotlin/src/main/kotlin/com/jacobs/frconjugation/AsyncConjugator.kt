package com.jacobs.frconjugation

import java.util.concurrent.Executors
import kotlin.coroutines.suspendCoroutine

private val workerPool =
    Executors.newFixedThreadPool(
        Runtime.getRuntime().availableProcessors().coerceAtLeast(2),
    ) { task -> Thread(task, "FRConjugation-worker").apply { isDaemon = true } }

private suspend fun <T> background(block: () -> T): T =
    suspendCoroutine { continuation ->
        workerPool.execute { continuation.resumeWith(runCatching(block)) }
    }

/** Run conjugate on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.conjugateAsync(
    verb: String,
    homonymIndex: Int? = null,
): Map<Voice, Map<Mode, Map<Tense, Map<Person, String>>>>? =
    background {
        conjugate(verb, homonymIndex)
    }

/** Run conjugate on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.conjugateAsync(
    verb: String,
    voice: Voice,
    homonymIndex: Int? = null,
): Map<Mode, Map<Tense, Map<Person, String>>> = background { conjugate(verb, voice, homonymIndex) }

/** Run conjugate on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.conjugateAsync(
    verb: String,
    voice: Voice,
    mode: Mode,
    homonymIndex: Int? = null,
): Map<Tense, Map<Person, String>> = background { conjugate(verb, voice, mode, homonymIndex) }

/** Run conjugate on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.conjugateAsync(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    homonymIndex: Int? = null,
): Map<Person, String> = background { conjugate(verb, voice, mode, tense, homonymIndex) }

/** Run conjugate on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.conjugateAsync(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    person: Person,
    homonymIndex: Int? = null,
): String? = background { conjugate(verb, voice, mode, tense, person, homonymIndex) }

/** Run rawInferredConjugation on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.rawInferredConjugationAsync(
    verb: String,
    homonymIndex: Int? = null,
): Map<Voice, Map<Mode, Map<Tense, Map<Person, String>>>>? =
    background {
        rawInferredConjugation(verb, homonymIndex)
    }

/** Run rawInferredConjugation on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.rawInferredConjugationAsync(
    verb: String,
    voice: Voice,
    homonymIndex: Int? = null,
): Map<Mode, Map<Tense, Map<Person, String>>> =
    background {
        rawInferredConjugation(verb, voice, homonymIndex)
    }

/** Run rawInferredConjugation on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.rawInferredConjugationAsync(
    verb: String,
    voice: Voice,
    mode: Mode,
    homonymIndex: Int? = null,
): Map<Tense, Map<Person, String>> =
    background {
        rawInferredConjugation(verb, voice, mode, homonymIndex)
    }

/** Run rawInferredConjugation on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.rawInferredConjugationAsync(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    homonymIndex: Int? = null,
): Map<Person, String> =
    background {
        rawInferredConjugation(verb, voice, mode, tense, homonymIndex)
    }

/** Run rawInferredConjugation on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.rawInferredConjugationAsync(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    person: Person,
    homonymIndex: Int? = null,
): String? = background { rawInferredConjugation(verb, voice, mode, tense, person, homonymIndex) }

/** Run guessConjugation on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.guessConjugationAsync(
    verb: String,
    homonymIndex: Int? = null,
): Map<Voice, Map<Mode, Map<Tense, Map<Person, String>>>>? =
    background {
        guessConjugation(verb, homonymIndex)
    }

/** Run guessConjugation on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.guessConjugationAsync(
    verb: String,
    voice: Voice,
    homonymIndex: Int? = null,
): Map<Mode, Map<Tense, Map<Person, String>>> =
    background {
        guessConjugation(verb, voice, homonymIndex)
    }

/** Run guessConjugation on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.guessConjugationAsync(
    verb: String,
    voice: Voice,
    mode: Mode,
    homonymIndex: Int? = null,
): Map<Tense, Map<Person, String>> =
    background {
        guessConjugation(verb, voice, mode, homonymIndex)
    }

/** Run guessConjugation on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.guessConjugationAsync(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    homonymIndex: Int? = null,
): Map<Person, String> = background { guessConjugation(verb, voice, mode, tense, homonymIndex) }

/** Run guessConjugation on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.guessConjugationAsync(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    person: Person,
    homonymIndex: Int? = null,
): String? = background { guessConjugation(verb, voice, mode, tense, person, homonymIndex) }

/** Run participle on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.participleAsync(
    verb: String,
    voice: Voice,
    tense: Tense,
    homonymIndex: Int? = null,
): String? = background { participle(verb, voice, tense, homonymIndex) }

/** Run gerondif on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.gerondifAsync(
    verb: String,
    voice: Voice,
    tense: Tense,
    homonymIndex: Int? = null,
): String? = background { gerondif(verb, voice, tense, homonymIndex) }

/** Run rawInferredParticiple on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.rawInferredParticipleAsync(
    verb: String,
    voice: Voice,
    tense: Tense,
    homonymIndex: Int? = null,
): String? = background { rawInferredParticiple(verb, voice, tense, homonymIndex) }

/** Run rawInferredGerondif on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.rawInferredGerondifAsync(
    verb: String,
    voice: Voice,
    tense: Tense,
    homonymIndex: Int? = null,
): String? = background { rawInferredGerondif(verb, voice, tense, homonymIndex) }

/** Run guessParticiple on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.guessParticipleAsync(
    verb: String,
    voice: Voice,
    tense: Tense,
    homonymIndex: Int? = null,
): String? = background { guessParticiple(verb, voice, tense, homonymIndex) }

/** Run guessGerondif on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.guessGerondifAsync(
    verb: String,
    voice: Voice,
    tense: Tense,
    homonymIndex: Int? = null,
): String? = background { guessGerondif(verb, voice, tense, homonymIndex) }

/** Run conjugateAlternative on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.conjugateAlternativeAsync(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    person: Person,
    homonymIndex: Int? = null,
): String? = background { conjugateAlternative(verb, voice, mode, tense, person, homonymIndex) }

/** Run getPronoun on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.getPronounAsync(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    person: Person,
    homonymIndex: Int? = null,
): String? = background { getPronoun(verb, voice, mode, tense, person, homonymIndex) }

/** Run conjugateWithPronoun on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.conjugateWithPronounAsync(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    person: Person,
    homonymIndex: Int? = null,
): String? = background { conjugateWithPronoun(verb, voice, mode, tense, person, homonymIndex) }

/** Run conjugateAlternativeWithPronoun on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.conjugateAlternativeWithPronounAsync(
    verb: String,
    voice: Voice,
    mode: Mode,
    tense: Tense,
    person: Person,
    homonymIndex: Int? = null,
): String? =
    background {
        conjugateAlternativeWithPronoun(verb, voice, mode, tense, person, homonymIndex)
    }

/** Run participleAlternative on the shared worker pool; cancellation does not interrupt work. */
suspend fun Conjugator.participleAlternativeAsync(
    verb: String,
    voice: Voice,
    tense: Tense,
    homonymIndex: Int? = null,
): String? = background { participleAlternative(verb, voice, tense, homonymIndex) }

/** Run commonPrefix off the calling thread; work is not cancellable. */
suspend fun Conjugator.commonPrefixAsync(
    verb: String,
    homonymIndex: Int? = null,
): String? = background { commonPrefix(verb, homonymIndex) }

/** Run rawInferredCommonPrefix off the calling thread; work is not cancellable. */
suspend fun Conjugator.rawInferredCommonPrefixAsync(
    verb: String,
    homonymIndex: Int? = null,
): String? = background { rawInferredCommonPrefix(verb, homonymIndex) }

/** Run guessCommonPrefix off the calling thread; work is not cancellable. */
suspend fun Conjugator.guessCommonPrefixAsync(
    verb: String,
    homonymIndex: Int? = null,
): String? = background { guessCommonPrefix(verb, homonymIndex) }

/** Load a new bundled reader off the calling thread. */
suspend fun Conjugator.Companion.load(): Conjugator = background { Conjugator() }

/** Obtain the shared reader off the calling thread. */
suspend fun Conjugator.Companion.getSharedAsync(): Conjugator = background { getShared() }
