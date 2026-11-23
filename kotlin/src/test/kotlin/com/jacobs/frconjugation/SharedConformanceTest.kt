package com.jacobs.frconjugation

import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.test.Test
import kotlin.test.assertEquals

@RunWith(Parameterized::class)
class SharedConformanceTest(
    private val row: List<String>,
) {
    @Test fun sharedCase() {
        val c = Conjugator()
        val verb = requireNotNull(decode(row[3]))
        val selector = requireNotNull(decode(row[4]))
        val mode =
            when (row[2]) {
                "catalogue" -> Prediction.CATALOGUE
                "inferred" -> Prediction.INFERRED
                "guess" -> Prediction.GUESS
                else -> error("Invalid mode")
            }
        val homonym = row[5].toInt().takeUnless { it == 0 }
        val spelling =
            when (row[6]) {
                "primary" -> Spelling.PRIMARY
                "alternative" -> Spelling.ALTERNATIVE
                else -> error("Invalid spelling")
            }
        val actual =
            when (row[1]) {
                "form" -> {
                    c.form(verb, selector, mode, homonym, spelling)
                }

                "prefix" -> {
                    when (mode) {
                        Prediction.CATALOGUE -> c.commonPrefix(verb, homonym)
                        Prediction.INFERRED -> c.rawInferredCommonPrefix(verb, homonym)
                        Prediction.GUESS -> c.guessCommonPrefix(verb, homonym)
                    }
                }

                "pronoun" -> {
                    c.pronoun(verb, selector, homonym, spelling)
                }

                "with_pronoun" -> {
                    c.withPronoun(verb, selector, homonym, spelling)
                }

                "gerondif" -> {
                    selector.split('|').let { c.gerondif(verb, it[0], it[1], mode, homonym) }
                }

                else -> {
                    error("Unknown operation")
                }
            }
        assertEquals(decode(row[7]), actual, "Conformance case ${row[0]}")
    }

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{index}: {0}")
        fun cases(): List<Array<Any>> {
            val lines =
                requireNotNull(
                    SharedConformanceTest::class.java.getResourceAsStream("/conformance.tsv"),
                ).bufferedReader(Charsets.UTF_8)
                    .use { it.readLines() }
            require(
                lines.size > 1 &&
                    lines[0] == "id\toperation\tmode\tverb\tselector\thomonym\tspelling\texpected",
            )
            val ids = mutableSetOf<String>()
            return lines.drop(1).map { line ->
                val row = line.split('\t')
                require(row.size == 8 && ids.add(row[0])) { "Invalid or duplicate fixture row" }
                arrayOf<Any>(row)
            }
        }

        private fun decode(text: String): String? {
            if (text == "\\N") return null
            return buildString {
                var i = 0
                while (i < text.length) {
                    if (text[i] != '\\') {
                        append(text[i++])
                        continue
                    }
                    require(++i < text.length) { "Truncated escape" }
                    append(
                        when (text[i++]) {
                            'n' -> '\n'
                            'r' -> '\r'
                            't' -> '\t'
                            '\\' -> '\\'
                            else -> error("Invalid escape")
                        },
                    )
                }
            }
        }
    }
}
