import Foundation

extension Conjugator {
    /// Infer a participle without catalogue validation or correction exceptions.
    /// Gender/number is selected by tense; no grammatical person is required.
    /// Invalid or unsupported participle tenses return nil. Alternatives are
    /// returned as a semicolon-separated string, as in raw finite inference.
    public func rawInferredParticiple(
        _ infinitive: String, voice: Voice, tense: Tense, homonymIndex: Int? = nil
    ) -> String? {
        rawInferredForm(infinitive, voice: voice, mode: .participe, tense: tense,
                        person: nil, homonymIndex: homonymIndex)
    }

    /// Prefer participle's corrected primary answer; infer only when it is nil.
    public func guessParticiple(
        _ infinitive: String, voice: Voice, tense: Tense, homonymIndex: Int? = nil
    ) -> String? {
        participle(infinitive, voice: voice, tense: tense, homonymIndex: homonymIndex)
            ?? rawInferredParticiple(infinitive, voice: voice, tense: tense,
                                     homonymIndex: homonymIndex)
    }

    /// Infer every globally supported participle tense for the selected voice.
    public func rawInferredParticiples(
        _ infinitive: String, voice: Voice, homonymIndex: Int? = nil
    ) -> [Tense: String] {
        fillInferredParticiples(infinitive, voice: voice, homonymIndex: homonymIndex, existing: [:])
    }

    /// Preserve catalogue participles, inferring only missing tenses.
    public func guessParticiples(
        _ infinitive: String, voice: Voice, homonymIndex: Int? = nil
    ) -> [Tense: String] {
        let existing = participles(infinitive, voice: voice, homonymIndex: homonymIndex)
        return fillInferredParticiples(infinitive, voice: voice,
                                       homonymIndex: homonymIndex, existing: existing)
    }

    private func fillInferredParticiples(
        _ input: String, voice: Voice, homonymIndex: Int?, existing: [Tense: String]
    ) -> [Tense: String] {
        var result = existing
        for tense in Tense.allCases where result[tense] == nil {
            if let form = rawInferredParticiple(input, voice: voice, tense: tense,
                                                homonymIndex: homonymIndex) {
                result[tense] = form
            }
        }
        return result
    }

    /// Derive a gérondif from a raw participle, repeating "en " for each alternative.
    /// Accepts only the existing gerondifPresent / gerondifPasse... tense cases.
    public func rawInferredGerondif(
        _ infinitive: String, voice: Voice, tense: Tense, homonymIndex: Int? = nil
    ) -> String? {
        guard let source = Self.gerondifSourceTense[tense],
              let form = rawInferredParticiple(infinitive, voice: voice, tense: source,
                                               homonymIndex: homonymIndex) else { return nil }
        return form.components(separatedBy: ";").map {
            "en " + $0.trimmingCharacters(in: .whitespaces)
        }.joined(separator: ";")
    }

    /// Prefer gerondif's corrected answer; derive a raw guess only when it is nil.
    public func guessGerondif(
        _ infinitive: String, voice: Voice, tense: Tense, homonymIndex: Int? = nil
    ) -> String? {
        gerondif(infinitive, voice: voice, tense: tense, homonymIndex: homonymIndex)
            ?? rawInferredGerondif(infinitive, voice: voice, tense: tense,
                                   homonymIndex: homonymIndex)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func rawInferredParticiple(
        _ infinitive: String, voice: Voice, tense: Tense, homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.rawInferredParticiple(infinitive, voice: voice, tense: tense,
                                         homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func guessParticiple(
        _ infinitive: String, voice: Voice, tense: Tense, homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.guessParticiple(infinitive, voice: voice, tense: tense,
                                         homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func rawInferredGerondif(
        _ infinitive: String, voice: Voice, tense: Tense, homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.rawInferredGerondif(infinitive, voice: voice, tense: tense,
                                         homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func guessGerondif(
        _ infinitive: String, voice: Voice, tense: Tense, homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.guessGerondif(infinitive, voice: voice, tense: tense,
                                         homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }
}
