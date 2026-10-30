import Foundation

extension Conjugator {
    // MARK: - Raw Neural Inference

    /// Infer a form without catalogue validation or correction-table exceptions.
    ///
    /// Accepts any nonempty model-supported string, lowercasing and trimming it.
    /// Known homonyms follow the same homonymIndex resolution as conjugate.
    /// Unsupported input or global form combinations return nil. Output can
    /// contain semicolon alternatives, mistakes, or truncated predictions.
    /// Finite forms only; use rawInferredParticiple or rawInferredGerondif otherwise.
    public func rawInferredConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, tense: Tense,
        person: Person, homonymIndex: Int? = nil
    ) -> String? {
        guard mode != .participe else { return nil }
        return rawInferredForm(infinitive, voice: voice, mode: mode, tense: tense,
                               person: person, homonymIndex: homonymIndex)
    }

    /// Infer every globally supported person in a finite tense.
    public func rawInferredConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, tense: Tense,
        homonymIndex: Int? = nil
    ) -> [Person: String] {
        fillInferredPersons(infinitive, voice: voice, mode: mode, tense: tense,
                            homonymIndex: homonymIndex, existing: [:])
    }

    /// Infer every globally supported tense/person combination in a mode.
    public func rawInferredConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, homonymIndex: Int? = nil
    ) -> [Tense: [Person: String]] {
        fillInferredTenses(infinitive, voice: voice, mode: mode,
                          homonymIndex: homonymIndex, existing: [:])
    }

    /// Infer every globally supported mode/tense/person combination in a voice.
    public func rawInferredConjugation(
        _ infinitive: String, voice: Voice, homonymIndex: Int? = nil
    ) -> [Mode: [Tense: [Person: String]]] {
        fillInferredModes(infinitive, voice: voice, homonymIndex: homonymIndex, existing: [:])
    }

    /// Infer all voices and forms, or nil when no predictions can be produced.
    public func rawInferredConjugation(
        _ infinitive: String, homonymIndex: Int? = nil
    ) -> [Voice: [Mode: [Tense: [Person: String]]]]? {
        let result = fillInferredVoices(infinitive, homonymIndex: homonymIndex, existing: [:])
        return result.isEmpty ? nil : result
    }

    // MARK: - Catalogue With Inference Fallback

    /// Return conjugate's primary/corrected answer unchanged when available;
    /// otherwise return a raw neural prediction for the requested form.
    ///
    /// Catalogue lookup uses conjugate's exact input semantics. Only the raw
    /// fallback normalizes input. Inferred answers can include alternatives and
    /// are not guaranteed to be grammatical; known defective verbs can gain
    /// inferred slots absent from their catalogue entries.
    public func guessConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, tense: Tense,
        person: Person, homonymIndex: Int? = nil
    ) -> String? {
        guard mode != .participe else { return nil }
        return conjugate(infinitive, voice: voice, mode: mode, tense: tense,
                         person: person, homonymIndex: homonymIndex)
            ?? rawInferredConjugation(infinitive, voice: voice, mode: mode, tense: tense,
                                      person: person, homonymIndex: homonymIndex)
    }

    /// Preserve catalogue persons, inferring only missing person entries.
    public func guessConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, tense: Tense,
        homonymIndex: Int? = nil
    ) -> [Person: String] {
        let existing = conjugate(infinitive, voice: voice, mode: mode, tense: tense,
                                 homonymIndex: homonymIndex)
        return fillInferredPersons(infinitive, voice: voice, mode: mode, tense: tense,
                                   homonymIndex: homonymIndex, existing: existing)
    }

    /// Preserve catalogue tenses/persons and infer their missing entries.
    public func guessConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, homonymIndex: Int? = nil
    ) -> [Tense: [Person: String]] {
        let existing = conjugate(infinitive, voice: voice, mode: mode, homonymIndex: homonymIndex)
        return fillInferredTenses(infinitive, voice: voice, mode: mode,
                                  homonymIndex: homonymIndex, existing: existing)
    }

    /// Preserve catalogue modes/tenses/persons and infer their missing entries.
    public func guessConjugation(
        _ infinitive: String, voice: Voice, homonymIndex: Int? = nil
    ) -> [Mode: [Tense: [Person: String]]] {
        let existing = conjugate(infinitive, voice: voice, homonymIndex: homonymIndex)
        return fillInferredModes(infinitive, voice: voice,
                                 homonymIndex: homonymIndex, existing: existing)
    }

    /// Preserve all catalogue answers and fill missing globally supported forms.
    public func guessConjugation(
        _ infinitive: String, homonymIndex: Int? = nil
    ) -> [Voice: [Mode: [Tense: [Person: String]]]]? {
        let existing = conjugate(infinitive, homonymIndex: homonymIndex) ?? [:]
        let result = fillInferredVoices(infinitive, homonymIndex: homonymIndex, existing: existing)
        return result.isEmpty ? nil : result
    }

    // MARK: - Collection Assembly

    private func fillInferredPersons(
        _ input: String, voice: Voice, mode: Mode, tense: Tense,
        homonymIndex: Int?, existing: [Person: String]
    ) -> [Person: String] {
        guard mode != .participe else { return [:] }
        var result = existing
        for person in Person.allCases where result[person] == nil {
            if let form = rawInferredConjugation(input, voice: voice, mode: mode, tense: tense,
                                                 person: person, homonymIndex: homonymIndex) {
                result[person] = form
            }
        }
        return result
    }

    private func fillInferredTenses(
        _ input: String, voice: Voice, mode: Mode, homonymIndex: Int?,
        existing: [Tense: [Person: String]]
    ) -> [Tense: [Person: String]] {
        var result = existing
        for tense in Tense.allCases {
            let forms = fillInferredPersons(input, voice: voice, mode: mode, tense: tense,
                                             homonymIndex: homonymIndex, existing: result[tense] ?? [:])
            if !forms.isEmpty { result[tense] = forms }
        }
        return result
    }

    private func fillInferredModes(
        _ input: String, voice: Voice, homonymIndex: Int?,
        existing: [Mode: [Tense: [Person: String]]]
    ) -> [Mode: [Tense: [Person: String]]] {
        var result = existing
        for mode in Mode.allCases where mode != .participe {
            let forms = fillInferredTenses(input, voice: voice, mode: mode,
                                           homonymIndex: homonymIndex, existing: result[mode] ?? [:])
            if !forms.isEmpty { result[mode] = forms }
        }
        return result
    }

    private func fillInferredVoices(
        _ input: String, homonymIndex: Int?,
        existing: [Voice: [Mode: [Tense: [Person: String]]]]
    ) -> [Voice: [Mode: [Tense: [Person: String]]]] {
        var result = existing
        for voice in Voice.allCases {
            let forms = fillInferredModes(input, voice: voice, homonymIndex: homonymIndex,
                                          existing: result[voice] ?? [:])
            if !forms.isEmpty { result[voice] = forms }
        }
        return result
    }

    // MARK: - Async Overloads (matching conjugate)

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func rawInferredConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, tense: Tense,
        person: Person, homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.rawInferredConjugation(infinitive, voice: voice, mode: mode,
                    tense: tense, person: person, homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func rawInferredConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, tense: Tense,
        homonymIndex: Int? = nil
    ) async -> [Person: String] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.rawInferredConjugation(infinitive, voice: voice, mode: mode,
                    tense: tense, homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func guessConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, tense: Tense,
        person: Person, homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.guessConjugation(infinitive, voice: voice, mode: mode,
                    tense: tense, person: person, homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func guessConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, tense: Tense,
        homonymIndex: Int? = nil
    ) async -> [Person: String] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.guessConjugation(infinitive, voice: voice, mode: mode,
                    tense: tense, homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }
}
