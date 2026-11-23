package com.jacobs.frconjugation

/** The bundled catalogue could not be loaded; [cause] preserves the resource/decoder failure. */
class ConjugationException internal constructor(
    cause: Exception,
) : IllegalStateException("Failed to load bundled conjugation catalogue", cause)
