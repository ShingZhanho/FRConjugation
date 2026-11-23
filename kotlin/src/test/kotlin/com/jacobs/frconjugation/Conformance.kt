package com.jacobs.frconjugation

import java.io.BufferedOutputStream
import java.io.DataOutputStream
import java.io.File

object Conformance {
    @JvmStatic fun main(args: Array<String>) {
        val c = Conjugator()
        val slots = c.slots
        DataOutputStream(BufferedOutputStream(File(args[0]).outputStream())).use { output ->
            fun emit(value: String?) {
                val bytes = value?.toByteArray(Charsets.UTF_8)
                output.writeInt(Integer.reverseBytes(bytes?.size ?: -1))
                if (bytes != null) output.write(bytes)
            }
            slots.forEach { emit(it) }
            for (entry in c.entries.sortedBy { it.key }) {
                emit(entry.key)
                emit(entry.flags.toString())
                emit(entry.variant)
                slots.forEach { emit(c.form(entry.key, it, spelling = Spelling.ALL)) }
            }
            for (verb in listOf(
                "blorper",
                "x",
                "er",
                "_",
                "manger",
                "finir",
                "pleuvoir",
                "aller",
                "ressortir_2",
                "réinventer",
                "télétravailler",
            )) {
                slots.forEach { emit(c.form(verb, it, Prediction.INFERRED)) }
            }
        }
    }
}
