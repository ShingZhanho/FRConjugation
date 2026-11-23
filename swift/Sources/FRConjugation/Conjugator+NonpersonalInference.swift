import Foundation

extension Conjugator {
    /// Infer a participle using the learned spelling rules.
    /// Gender/number is selected by tense; no grammatical person is required.
    /// Invalid or unsupported participle tenses return nil. Alternatives are
    /// returned as a semicolon-separated string, as in raw finite inference.
    /// - Parameter infinitive: Any supported input string; surrounding whitespace is trimmed, then
    ///   case and Unicode are normalized.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func rawInferredParticiple(
        _ infinitive: String, voice: Voice, tense: Tense, homonymIndex: Int? = nil
    ) -> String? {
        rawInferredForm(
            infinitive, voice: voice, mode: .participe, tense: tense,
            person: nil, homonymIndex: homonymIndex)
    }

    /// Prefer the catalogue’s primary participle; infer only when it is nil.
    /// - Parameter infinitive: The infinitive or exact homonym key. Catalogue lookup preserves case
    ///   and surrounding whitespace.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func guessParticiple(
        _ infinitive: String, voice: Voice, tense: Tense, homonymIndex: Int? = nil
    ) -> String? {
        participle(infinitive, voice: voice, tense: tense, homonymIndex: homonymIndex)
            ?? rawInferredParticiple(
                infinitive, voice: voice, tense: tense,
                homonymIndex: homonymIndex)
    }

    /// Infer every globally supported participle tense for the selected voice.
    /// - Parameter infinitive: Any supported input string; surrounding whitespace is trimmed, then
    ///   case and Unicode are normalized.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func rawInferredParticiples(
        _ infinitive: String, voice: Voice, homonymIndex: Int? = nil
    ) -> [Tense: String] {
        fillInferredParticiples(infinitive, voice: voice, homonymIndex: homonymIndex, existing: [:])
    }

    /// Preserve catalogue participles, inferring only missing tenses.
    /// - Parameter infinitive: The infinitive or exact homonym key. Catalogue lookup preserves case
    ///   and surrounding whitespace.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func guessParticiples(
        _ infinitive: String, voice: Voice, homonymIndex: Int? = nil
    ) -> [Tense: String] {
        let existing = participles(infinitive, voice: voice, homonymIndex: homonymIndex)
        return fillInferredParticiples(
            infinitive, voice: voice,
            homonymIndex: homonymIndex, existing: existing)
    }

    private func fillInferredParticiples(
        _ input: String, voice: Voice, homonymIndex: Int?, existing: [Tense: String]
    ) -> [Tense: String] {
        var result = existing
        for tense in Tense.allCases where result[tense] == nil {
            if let form = rawInferredParticiple(
                input, voice: voice, tense: tense,
                homonymIndex: homonymIndex)
            {
                result[tense] = form
            }
        }
        return result
    }

    /// Derive a gérondif from a raw participle, repeating "en " for each alternative.
    /// Accepts only the existing gerondifPresent / gerondifPasse... tense cases.
    /// - Parameter infinitive: Any supported input string; surrounding whitespace is trimmed, then
    ///   case and Unicode are normalized.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func rawInferredGerondif(
        _ infinitive: String, voice: Voice, tense: Tense, homonymIndex: Int? = nil
    ) -> String? {
        guard let source = Self.gerondifSourceTense[tense],
            let form = rawInferredParticiple(
                infinitive, voice: voice, tense: source,
                homonymIndex: homonymIndex)
        else { return nil }
        return form.components(separatedBy: ";").map {
            "en " + $0.trimmingCharacters(in: .whitespaces)
        }.joined(separator: ";")
    }

    /// Prefer the catalogue’s gérondif; derive a raw guess only when it is nil.
    /// - Parameter infinitive: The infinitive or exact homonym key. Catalogue lookup preserves case
    ///   and surrounding whitespace.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func guessGerondif(
        _ infinitive: String, voice: Voice, tense: Tense, homonymIndex: Int? = nil
    ) -> String? {
        gerondif(infinitive, voice: voice, tense: tense, homonymIndex: homonymIndex)
            ?? rawInferredGerondif(
                infinitive, voice: voice, tense: tense,
                homonymIndex: homonymIndex)
    }

    /// Infer a single form on a background queue using the bundled rules.
    /// Predictions may be unattested; unsupported input returns `nil` or an empty collection.
    /// Work runs off the calling executor. Cancellation does not interrupt the queued operation.
    /// - Parameter infinitive: Any supported input string; surrounding whitespace is trimmed, then
    ///   case and Unicode are normalized.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func rawInferredParticiple(
        _ infinitive: String, voice: Voice, tense: Tense, homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.rawInferredParticiple(
                    infinitive, voice: voice, tense: tense,
                    homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    /// Use catalogue answers first, predicting missing forms on a background queue.
    /// Predictions may be unattested; unsupported input returns `nil` or an empty collection.
    /// Work runs off the calling executor. Cancellation does not interrupt the queued operation.
    /// - Parameter infinitive: The infinitive or exact homonym key. Catalogue lookup preserves case
    ///   and surrounding whitespace.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func guessParticiple(
        _ infinitive: String, voice: Voice, tense: Tense, homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.guessParticiple(
                    infinitive, voice: voice, tense: tense,
                    homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    /// Infer a single form on a background queue using the bundled rules.
    /// Predictions may be unattested; unsupported input returns `nil` or an empty collection.
    /// Work runs off the calling executor. Cancellation does not interrupt the queued operation.
    /// - Parameter infinitive: Any supported input string; surrounding whitespace is trimmed, then
    ///   case and Unicode are normalized.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func rawInferredGerondif(
        _ infinitive: String, voice: Voice, tense: Tense, homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.rawInferredGerondif(
                    infinitive, voice: voice, tense: tense,
                    homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    /// Use catalogue answers first, predicting missing forms on a background queue.
    /// Predictions may be unattested; unsupported input returns `nil` or an empty collection.
    /// Work runs off the calling executor. Cancellation does not interrupt the queued operation.
    /// - Parameter infinitive: The infinitive or exact homonym key. Catalogue lookup preserves case
    ///   and surrounding whitespace.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func guessGerondif(
        _ infinitive: String, voice: Voice, tense: Tense, homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.guessGerondif(
                    infinitive, voice: voice, tense: tense,
                    homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }
}
