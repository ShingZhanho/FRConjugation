package com.jacobs.frconjugation

import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.coroutines.Continuation
import kotlin.coroutines.EmptyCoroutineContext
import kotlin.coroutines.intrinsics.COROUTINE_SUSPENDED
import kotlin.coroutines.resume
import kotlin.coroutines.startCoroutine
import kotlin.coroutines.suspendCoroutine
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertSame

class TypedParityTest {
    private fun label(value: Any): String =
        when (value) {
            is Voice -> value.label
            is Mode -> value.label
            is Tense -> value.label
            is Person -> value.label
            else -> value.toString()
        }

    private fun call(
        c: Conjugator,
        name: String,
        args: List<Any?>,
    ): Any? {
        val extension =
            Class
                .forName("com.jacobs.frconjugation.TypedConjugatorKt")
                .methods
                .firstOrNull { method ->
                    method.name == name && method.parameterCount == args.size + 1 &&
                        matches(method.parameterTypes.drop(1), args)
                }
        if (extension != null) return extension.invoke(null, c, *args.toTypedArray())
        val member =
            c.javaClass.methods.single {
                it.name == name && it.parameterCount == args.size &&
                    matches(it.parameterTypes.toList(), args)
            }
        return member.invoke(c, *args.toTypedArray())
    }

    private fun matches(
        types: List<Class<*>>,
        args: List<Any?>,
    ): Boolean =
        types.zip(args).all { (t, a) ->
            a ==
                null ||
                t.isInstance(a)
        }

    private fun flatten(
        value: Any?,
        prefix: List<String> = emptyList(),
    ): String? {
        if (value == null || value is String) return value as String?
        val lines = mutableListOf<String>()

        fun walk(
            node: Map<*, *>,
            path: List<String>,
        ) {
            for ((key, child) in node) {
                val keys = path + label(requireNotNull(key))
                if (child is Map<*, *>) {
                    walk(child, keys)
                } else {
                    lines.add(keys.joinToString("|") + "=" + child)
                }
            }
        }
        walk(value as Map<*, *>, prefix)
        return lines.sorted().joinToString("\n")
    }

    private fun decode(text: String): String? {
        if (text == "\\N") return null
        val out = StringBuilder()
        var i = 0
        while (i <
            text.length
        ) {
            if (text[i] !=
                '\\'
            ) {
                out.append(text[i++])
            } else {
                i++
                out.append(
                    when (text[i++]) {
                        'n' -> '\n'
                        'r' -> '\r'
                        't' -> '\t'
                        '\\' -> '\\'
                        else -> error("Bad escape")
                    },
                )
            }
        }
        return out.toString()
    }

    @Test fun swiftVectors() {
        val lines =
            requireNotNull(
                javaClass.getResourceAsStream("/typed-api.tsv"),
            ).bufferedReader().use {
                it.readLines()
            }
        val c = Conjugator()
        for (line in lines.drop(1)) {
            val r = line.split('\t')
            assertEquals(decode(r[9]), evaluate(c, r), "Typed case ${r[0]} (${r[1]})")
        }
    }

    private fun evaluate(
        c: Conjugator,
        r: List<String>,
    ): String? {
        val op = r[1]
        val verb = r[2]
        val enums = listOf(Voice.entries, Mode.entries, Tense.entries, Person.entries)
        val selectors =
            (0..3).map { i ->
                if (r[i + 3] ==
                    "-"
                ) {
                    null
                } else {
                    enums[i].first { label(it) == r[i + 3] }
                }
            }
        val h = r[7].toInt().takeUnless { it == 0 }
        if (op.startsWith(
                "enum_",
            )
        ) {
            return enums[
                listOf(
                    "enum_voice",
                    "enum_mode",
                    "enum_tense",
                    "enum_person",
                ).indexOf(op),
            ].joinToString(",") {
                label(it)
            }
        }
        if (op == "person_pronouns") return Person.entries.joinToString(",") { it.pronoun }
        if (op == "all_verbs") return c.allVerbs.joinToString(",")
        if (op == "verb_count") return c.verbCount.toString()
        val names =
            mapOf(
                "has_verb" to "hasVerb",
                "has_homonyms" to "hasHomonyms",
                "homonym_count" to "homonymCount",
                "homonym_indices" to "homonymIndices",
                "h_aspire" to "isHAspire",
                "blocking" to "blocksElisionAndLiaison",
                "reform" to "is1990Reform",
                "variant" to "reformVariant",
            )
        names[op]?.let { name ->
            val value = call(c, name, if (op == "blocking") listOf(verb, h) else listOf(verb))
            return when (value) {
                is Boolean -> if (value) "1" else "0"
                is List<*> -> value.joinToString(",")
                else -> value?.toString()
            }
        }
        val structure = listOf("voices", "modes", "tenses", "persons").indexOf(op)
        if (structure >=
            0
        ) {
            return (
                call(
                    c,
                    op,
                    listOf(verb) + selectors.take(structure) + listOf(h),
                ) as List<*>
            ).joinToString(",") {
                label(requireNotNull(it))
            }
        }
        val methods =
            mapOf(
                "alternative" to "conjugateAlternative",
                "has_alternative" to "hasAlternativeForm",
                "participle_alternative" to "participleAlternative",
                "has_alternative_participle" to "hasAlternativeParticiple",
                "pronoun" to "getPronoun",
                "with_pronoun" to "conjugateWithPronoun",
                "alternative_with_pronoun" to "conjugateAlternativeWithPronoun",
            )
        methods[op]?.let { name ->
            val args =
                if (op.contains(
                        "participle",
                    )
                ) {
                    listOf(selectors[0], selectors[2])
                } else {
                    selectors
                }
            val value = call(c, name, listOf(verb) + args + listOf(h))
            return if (value is Boolean) {
                if (value) "1" else "0"
            } else {
                value as String?
            }
        }
        val prefix =
            when (r[8]) {
                "inferred" -> "rawInferred"
                "guess" -> "guess"
                else -> ""
            }
        if (op == "finite") {
            val chosen = selectors.takeWhile { it != null }
            val name = if (prefix.isEmpty()) "conjugate" else prefix + "Conjugation"
            return flatten(
                call(c, name, listOf(verb) + chosen + listOf(h)),
                chosen.map {
                    label(requireNotNull(it))
                },
            )
        }
        val name = if (prefix.isEmpty()) op else prefix + op.replaceFirstChar { it.uppercaseChar() }
        val args =
            if (op == "participles") {
                listOf(
                    selectors[0],
                )
            } else {
                listOf(selectors[0], selectors[2])
            }
        return flatten(call(c, name, listOf(verb) + args + listOf(h)))
    }

    private fun <T> runSuspend(block: suspend () -> T): T {
        val latch = CountDownLatch(1)
        var outcome: Result<T>? = null
        block.startCoroutine(
            object : Continuation<T> {
                override val context = EmptyCoroutineContext

                override fun resumeWith(result: Result<T>) {
                    outcome = result
                    latch.countDown()
                }
            },
        )
        check(latch.await(30, TimeUnit.SECONDS)) { "Async operation timed out" }
        return requireNotNull(outcome).getOrThrow()
    }

    @Test fun asyncParity() =
        runSuspend {
            assertSame(Conjugator.getShared(), Conjugator.getSharedAsync())
            val c = Conjugator.load()
            for (method in Class
                .forName(
                    "com.jacobs.frconjugation.AsyncConjugatorKt",
                ).methods
                .filter {
                    it.name.endsWith("Async") &&
                        it.parameterTypes.firstOrNull() == Conjugator::class.java
                }) {
                val args: List<Any?> =
                    method.parameterTypes.drop(1).dropLast(1).map { type ->
                        when (type) {
                            String::class.java -> {
                                "manger"
                            }

                            Voice::class.java -> {
                                Voice.ACTIVE_AVOIR
                            }

                            Mode::class.java -> {
                                Mode.INDICATIF
                            }

                            Tense::class.java -> {
                                if (method.name.contains("Gerondif", true)) {
                                    Tense.GERONDIF_PRESENT
                                } else if (method.name.contains("Participle", true)) {
                                    Tense.PASSE_FEMININ_PLURIEL
                                } else {
                                    Tense.PRESENT
                                }
                            }

                            Person::class.java -> {
                                Person.FIRST_PLURAL_MASCULINE
                            }

                            else -> {
                                null
                            }
                        }
                    }
                val actual =
                    suspendCoroutine<Any?> { continuation ->
                        val result = method.invoke(null, c, *args.toTypedArray(), continuation)
                        if (result !== COROUTINE_SUSPENDED) continuation.resume(result)
                    }
                assertEquals(
                    flatten(call(c, method.name.removeSuffix("Async"), args)),
                    flatten(actual),
                    method.name,
                )
            }
        }
}
