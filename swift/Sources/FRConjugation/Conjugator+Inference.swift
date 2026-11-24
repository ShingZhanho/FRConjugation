import Foundation

extension Conjugator {
    // The input vocabulary matches the original Swift inference API.
    private static let inferenceAlphabet = Set(" '-12;_abcdefghijklmnopqrstuvwxyzâçèéêîïôûœ")

    func rawInferredForm(
        _ input: String, voice: Voice, mode: Mode, tense: Tense, person: Person?, homonymIndex: Int?
    ) -> String? {
        let slot = RuleCatalogue.Slot(voice: voice, mode: mode, tense: tense, person: person)
        guard catalogue.slotIDs[slot] != nil else { return nil }
        let normalized = Self.normalizedInfinitive(input)
        guard !normalized.isEmpty else { return nil }
        let key = resolveKey(normalized, homonymIndex: homonymIndex)
        guard key.allSatisfy(Self.inferenceAlphabet.contains) else { return nil }
        return catalogue.infer(key, slot: slot)
    }

    // MARK: - Raw Rule Inference

    /// Apply the learned spelling rules to a supported input and form.
    ///
    /// Accepts any nonempty model-supported string, lowercasing and trimming it.
    /// Known homonyms follow the same homonymIndex resolution as conjugate.
    /// Unsupported input or global form combinations return nil. Output can
    /// contain semicolon alternatives or grammatically unattested predictions.
    /// Finite forms only; use rawInferredParticiple or rawInferredGerondif otherwise.
    /// - Parameter infinitive: Any supported input string; surrounding whitespace is trimmed, then
    ///   case and Unicode are normalized.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter mode: The grammatical mood.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter person: The grammatical person and gender.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func rawInferredConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, tense: Tense,
        person: Person, homonymIndex: Int? = nil
    ) -> String? {
        guard mode != .participe else { return nil }
        return rawInferredForm(
            infinitive, voice: voice, mode: mode, tense: tense,
            person: person, homonymIndex: homonymIndex)
    }

    /// Infer every globally supported person in a finite tense.
    /// - Parameter infinitive: Any supported input string; surrounding whitespace is trimmed, then
    ///   case and Unicode are normalized.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter mode: The grammatical mood.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func rawInferredConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, tense: Tense,
        homonymIndex: Int? = nil
    ) -> [Person: String] {
        fillInferredPersons(
            infinitive, voice: voice, mode: mode, tense: tense,
            homonymIndex: homonymIndex, existing: [:])
    }

    /// Infer every globally supported tense/person combination in a mode.
    /// - Parameter infinitive: Any supported input string; surrounding whitespace is trimmed, then
    ///   case and Unicode are normalized.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter mode: The grammatical mood.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func rawInferredConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, homonymIndex: Int? = nil
    ) -> [Tense: [Person: String]] {
        fillInferredTenses(
            infinitive, voice: voice, mode: mode,
            homonymIndex: homonymIndex, existing: [:])
    }

    /// Infer every globally supported mode/tense/person combination in a voice.
    /// - Parameter infinitive: Any supported input string; surrounding whitespace is trimmed, then
    ///   case and Unicode are normalized.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func rawInferredConjugation(
        _ infinitive: String, voice: Voice, homonymIndex: Int? = nil
    ) -> [Mode: [Tense: [Person: String]]] {
        fillInferredModes(infinitive, voice: voice, homonymIndex: homonymIndex, existing: [:])
    }

    /// Infer all voices and forms, or nil when no predictions can be produced.
    /// - Parameter infinitive: Any supported input string; surrounding whitespace is trimmed, then
    ///   case and Unicode are normalized.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func rawInferredConjugation(
        _ infinitive: String, homonymIndex: Int? = nil
    ) -> [Voice: [Mode: [Tense: [Person: String]]]]? {
        let result = fillInferredVoices(infinitive, homonymIndex: homonymIndex, existing: [:])
        return result.isEmpty ? nil : result
    }

    // MARK: - Catalogue With Inference Fallback

    /// Return catalogue data for known infinitives, including missing answers;
    /// otherwise return a raw rule prediction for the requested form.
    ///
    /// All verb inputs are trimmed, lowercased and NFC-normalized before
    /// catalogue membership is checked. Inferred answers can include alternatives and
    /// are not guaranteed to be grammatical. Known infinitives retain their
    /// catalogue gaps; only unknown infinitives are inferred.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter mode: The grammatical mood.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter person: The grammatical person and gender.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func guessConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, tense: Tense,
        person: Person, homonymIndex: Int? = nil
    ) -> String? {
        if hasVerb(infinitive) {
            return conjugate(
                infinitive, voice: voice, mode: mode, tense: tense, person: person,
                homonymIndex: homonymIndex)
        }
        return rawInferredConjugation(
            infinitive, voice: voice, mode: mode, tense: tense, person: person,
            homonymIndex: homonymIndex)
    }

    /// Return catalogue persons for known infinitives; infer unknown infinitives.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter mode: The grammatical mood.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func guessConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, tense: Tense,
        homonymIndex: Int? = nil
    ) -> [Person: String] {
        if hasVerb(infinitive) {
            return conjugate(
                infinitive, voice: voice, mode: mode, tense: tense, homonymIndex: homonymIndex)
        }
        return rawInferredConjugation(
            infinitive, voice: voice, mode: mode, tense: tense, homonymIndex: homonymIndex)
    }

    /// Return catalogue tenses/persons for known infinitives; infer unknown infinitives.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter mode: The grammatical mood.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func guessConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, homonymIndex: Int? = nil
    ) -> [Tense: [Person: String]] {
        if hasVerb(infinitive) {
            return conjugate(infinitive, voice: voice, mode: mode, homonymIndex: homonymIndex)
        }
        return rawInferredConjugation(
            infinitive, voice: voice, mode: mode, homonymIndex: homonymIndex)
    }

    /// Return catalogue modes for known infinitives; infer unknown infinitives.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func guessConjugation(
        _ infinitive: String, voice: Voice, homonymIndex: Int? = nil
    ) -> [Mode: [Tense: [Person: String]]] {
        if hasVerb(infinitive) {
            return conjugate(infinitive, voice: voice, homonymIndex: homonymIndex)
        }
        return rawInferredConjugation(infinitive, voice: voice, homonymIndex: homonymIndex)
    }

    /// Return catalogue data for known infinitives; infer unknown infinitives.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func guessConjugation(
        _ infinitive: String, homonymIndex: Int? = nil
    ) -> [Voice: [Mode: [Tense: [Person: String]]]]? {
        if hasVerb(infinitive) {
            return conjugate(infinitive, homonymIndex: homonymIndex)
        }
        return rawInferredConjugation(infinitive, homonymIndex: homonymIndex)
    }

    // MARK: - Collection Assembly

    private func fillInferredPersons(
        _ input: String, voice: Voice, mode: Mode, tense: Tense,
        homonymIndex: Int?, existing: [Person: String]
    ) -> [Person: String] {
        guard mode != .participe, let ids = catalogue.groups[voice]?[mode]?[tense] else {
            return existing
        }
        var result = existing
        for id in ids {
            guard let person = catalogue.slots[id].person, result[person] == nil else { continue }
            if let form = rawInferredConjugation(
                input, voice: voice, mode: mode, tense: tense,
                person: person, homonymIndex: homonymIndex)
            {
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
        guard let tenses = catalogue.groups[voice]?[mode] else { return result }
        for tense in tenses.keys {
            let forms = fillInferredPersons(
                input, voice: voice, mode: mode, tense: tense,
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
            let forms = fillInferredTenses(
                input, voice: voice, mode: mode,
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
            let forms = fillInferredModes(
                input, voice: voice, homonymIndex: homonymIndex,
                existing: result[voice] ?? [:])
            if !forms.isEmpty { result[voice] = forms }
        }
        return result
    }

    // MARK: - Async Overloads (matching conjugate)

    /// Infer a single form on a background queue using the bundled rules.
    /// Predictions may be unattested; unsupported input returns `nil` or an empty collection.
    /// Work runs off the calling executor. Cancellation does not interrupt the queued operation.
    /// - Parameter infinitive: Any supported input string; surrounding whitespace is trimmed, then
    ///   case and Unicode are normalized.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter mode: The grammatical mood.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter person: The grammatical person and gender.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func rawInferredConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, tense: Tense,
        person: Person, homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.rawInferredConjugation(
                    infinitive, voice: voice, mode: mode,
                    tense: tense, person: person, homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    /// Infer available forms on a background queue using the bundled rules.
    /// Predictions may be unattested; unsupported input returns `nil` or an empty collection.
    /// Work runs off the calling executor. Cancellation does not interrupt the queued operation.
    /// - Parameter infinitive: Any supported input string; surrounding whitespace is trimmed, then
    ///   case and Unicode are normalized.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter mode: The grammatical mood.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func rawInferredConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, tense: Tense,
        homonymIndex: Int? = nil
    ) async -> [Person: String] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.rawInferredConjugation(
                    infinitive, voice: voice, mode: mode,
                    tense: tense, homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    /// Use catalogue data for known infinitives; infer unknown infinitives off the calling executor.
    /// Predictions may be unattested; unsupported input returns `nil` or an empty collection.
    /// Work runs off the calling executor. Cancellation does not interrupt the queued operation.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter mode: The grammatical mood.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter person: The grammatical person and gender.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func guessConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, tense: Tense,
        person: Person, homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.guessConjugation(
                    infinitive, voice: voice, mode: mode,
                    tense: tense, person: person, homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    /// Use catalogue data for known infinitives; infer unknown infinitives off the calling executor.
    /// Predictions may be unattested; unsupported input returns `nil` or an empty collection.
    /// Work runs off the calling executor. Cancellation does not interrupt the queued operation.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter mode: The grammatical mood.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func guessConjugation(
        _ infinitive: String, voice: Voice, mode: Mode, tense: Tense,
        homonymIndex: Int? = nil
    ) async -> [Person: String] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.guessConjugation(
                    infinitive, voice: voice, mode: mode,
                    tense: tense, homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }
}
