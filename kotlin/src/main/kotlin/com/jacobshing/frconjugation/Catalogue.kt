package com.jacobshing.frconjugation

import java.util.Locale

internal class Catalogue {
    data class Entry(
        val metadata: VerbEntry,
        val model: Int,
    )

    data class Operation(
        val prefix: String,
        val trim: Int,
        val suffix: String,
    )

    val slots: List<String>
    val slotIds: Map<String, Int>
    val entries = linkedMapOf<String, Entry>()
    val homonyms = mutableMapOf<String, List<Int>>()
    private val suffixes: Map<String, Int>
    private val templates: List<List<Int>>
    private val blocks: List<List<Int>>
    private val programs: List<List<Operation>>
    private val fallbacks: List<Int>

    init {
        val bytes =
            requireNotNull(
                javaClass.getResourceAsStream("/com/jacobshing/frconjugation/catalogue.fcr"),
            ) {
                "Bundled catalogue is missing"
            }.use { it.readBytes() }

        fun word(at: Int): Int {
            require(at >= 0 && at <= bytes.size - 4)
            return (bytes[at].toInt() and 255) or ((bytes[at + 1].toInt() and 255) shl 8) or
                ((bytes[at + 2].toInt() and 255) shl 16) or ((bytes[at + 3].toInt() and 255) shl 24)
        }
        require(
            bytes.size >= 40 && String(bytes, 0, 4, Charsets.US_ASCII) == "FCR1" && word(4) == 1,
        )
        val sections = (0..7).map { word(8 + it * 4) }
        require(
            sections.first() == 40 && sections.last() == bytes.size &&
                sections.zipWithNext().all { it.first <= it.second },
        )

        fun record(
            section: Int,
            index: Int,
        ): IntRange {
            val base = sections[section]
            val payload = base + 8 + word(base) * 4
            val start = payload + word(base + 4 + index * 4)
            val end = payload + word(base + 8 + index * 4)
            require(start >= payload && end >= start && end <= sections[section + 1])
            return start until end
        }
        val strings =
            (0 until word(sections[0])).map {
                val range = record(0, it)
                String(bytes, range.first, range.count(), Charsets.UTF_8)
            }
        slots = (sections[1] until sections[2] step 4).map { strings[word(it)] }
        require(slots.isNotEmpty())
        slotIds = slots.withIndex().associate { it.value to it.index }
        suffixes =
            (sections[3] until sections[4] step 8).associate { strings[word(it)] to word(it + 4) }
        val width = (slots.size + 15) / 16
        templates =
            (sections[4] until sections[5] step width * 4).map { at ->
                (0 until width).map { word(at + it * 4) }
            }
        blocks =
            (sections[5] until sections[6] step 64).map { at -> (0..15).map { word(at + it * 4) } }
        programs =
            (0 until word(sections[6])).map { id ->
                record(
                    6,
                    id,
                ).step(12).map { Operation(strings[word(it)], word(it + 4), strings[word(it + 8)]) }
            }
        val frequencies = mutableMapOf<Int, Int>()
        for (at in sections[2] until sections[3] step 12) {
            val key = strings[word(at)]
            val model = models(key).first()
            val variant = word(at + 8).let { if (it == -1) null else strings[it] }
            entries[key] = Entry(VerbEntry(key, word(at + 4), variant), model)
            frequencies[model] = (frequencies[model] ?: 0) + 1
            val (lemma, index) = lemmaIndex(key)
            if (index.isNotEmpty()) {
                homonyms[lemma] =
                    ((homonyms[lemma] ?: emptyList()) + index.toInt()).sorted()
            }
        }
        val ranked =
            frequencies.keys.sortedWith(
                compareByDescending<Int> { frequencies[it] }.thenBy { it },
            )
        fallbacks = slots.indices.map { slot -> ranked.first { program(it, slot) != 0 } }
    }

    fun resolve(
        input: String,
        homonym: Int?,
    ): String {
        if (entries.containsKey(input)) return input
        val indices = homonyms[input] ?: return input
        return input + "_" + (homonym ?: indices.first())
    }

    private fun models(key: String): List<Int> {
        val (lemma, index) = lemmaIndex(key)
        val marked = "^$index|$lemma"
        val result = mutableListOf<Int>()
        var at = 0
        while (true) {
            suffixes[marked.substring(at)]?.let { result.add(it) }
            if (at == marked.length) break
            at = marked.offsetByCodePoints(at, 1)
        }
        return result
    }

    private fun program(
        model: Int,
        slot: Int,
    ): Int = blocks[templates[model][slot / 16]][slot % 16]

    private fun render(
        model: Int,
        slot: Int,
        lemma: String,
        fallback: Boolean = false,
    ): String? {
        val id = program(model, slot)
        if (id == 0) return null
        val length = lemma.codePointCount(0, lemma.length)
        val alternatives = mutableListOf<String>()
        for (operation in programs[id]) {
            val retained =
                when {
                    operation.trim == -1 -> ""
                    operation.trim > length -> if (fallback) lemma else return null
                    else -> lemma.substring(0, lemma.offsetByCodePoints(0, length - operation.trim))
                }
            alternatives.add(operation.prefix + retained + operation.suffix)
        }
        val result = alternatives.joinToString(";")
        return if (fallback && result.isEmpty()) lemma else result
    }

    fun raw(
        input: String,
        slot: Int,
        homonym: Int?,
        prediction: Prediction,
    ): String? {
        if (prediction != Prediction.INFERRED) {
            val key = resolve(nfc(input), homonym)
            entries[key]?.let { render(it.model, slot, lemmaIndex(key).first) }?.let { return it }
            if (prediction == Prediction.CATALOGUE) return null
        }
        val normalized =
            nfc(
                input
                    .trim {
                        it.isWhitespace() ||
                            Character.isSpaceChar(
                                it,
                            )
                    }.lowercase(Locale.ROOT),
            )
        if (normalized.isEmpty() ||
            normalized.any { it !in " '-12;_abcdefghijklmnopqrstuvwxyzâçèéêîïôûœ" }
        ) {
            return null
        }
        val key = resolve(normalized, homonym)
        val lemma = lemmaIndex(key).first
        for (model in models(key)) {
            render(model, slot, lemma)?.takeIf { it.isNotEmpty() }?.let { return it }
        }
        return render(fallbacks[slot], slot, lemma, true)
    }
}
