package com.jacobs.frconjugation

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class ConjugatorTest {
    @Test fun publicBehaviour() {
        val c = Conjugator()
        val slot = "voix_active_avoir|indicatif|present|1pm"
        assertEquals(6358, c.entries.size)
        assertEquals(820, c.slots.size)
        assertEquals(listOf(1, 2), c.homonymIndices("ressortir"))
        assertFailsWith<IllegalArgumentException> { c.form("manger", slot, homonymIndex = -1) }
        val executor =
            java.util.concurrent.Executors
                .newFixedThreadPool(8)
        try {
            val futures =
                (0..7).map {
                    executor.submit {
                        repeat(
                            100,
                        ) { assertEquals("mangeons", c.form("manger", slot)) }
                    }
                }
            futures.forEach { it.get() }
        } finally {
            executor.shutdown()
        }
    }
}
