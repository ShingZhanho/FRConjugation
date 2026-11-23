import Foundation

extension Conjugator {
    /// Shared spelling across all available catalogue slots and alternatives.
    /// Includes participles and all voices. Auxiliaries and pronouns are excluded.
    /// Accents are significant. This is a display aid, not a grammatical stem.
    /// Returns nil for unavailable forms, or an empty string for no common prefix.
    public func commonPrefix(_ infinitive: String, homonymIndex: Int? = nil) -> String? {
        let key = resolveKey(infinitive, homonymIndex: homonymIndex)
        return sharedPrefix { catalogue.form(key, slot: $0) }
    }

    /// Shared spelling across all globally supported inferred slots and alternatives.
    /// Input normalization and validation match rawInferredConjugation.
    public func rawInferredCommonPrefix(_ infinitive: String, homonymIndex: Int? = nil) -> String? {
        sharedPrefix { slot in
            rawInferredForm(infinitive, voice: slot.voice, mode: slot.mode,
                            tense: slot.tense, person: slot.person, homonymIndex: homonymIndex)
        }
    }

    /// Shared spelling across catalogue forms, inferring each missing slot.
    /// Includes every catalogue spelling alternative. Missing slots on defective
    /// verbs can introduce hypothetical forms and shorten the resulting prefix.
    public func guessCommonPrefix(_ infinitive: String, homonymIndex: Int? = nil) -> String? {
        let key = resolveKey(infinitive, homonymIndex: homonymIndex)
        return sharedPrefix { slot in
            catalogue.form(key, slot: slot)
                ?? rawInferredForm(infinitive, voice: slot.voice, mode: slot.mode,
                                   tense: slot.tense, person: slot.person, homonymIndex: homonymIndex)
        }
    }

    private func sharedPrefix(form: (RuleCatalogue.Slot) -> String?) -> String? {
        var prefix: String?
        for slot in catalogue.slots {
            guard let raw = form(slot) else { continue }
            for alternative in raw.split(separator: ";") {
                guard let word = Self.mainVerbWord(String(alternative)) else { continue }
                if let current = prefix {
                    prefix = String(zip(current, word).prefix { $0 == $1 }.map { $0.0 })
                } else {
                    prefix = word
                }
                if prefix == "" { return "" }
            }
        }
        return prefix
    }

    // Catalogue phrases place the lexical verb last, optionally followed by
    // imperative clitics. Strip clitics before splitting elided leading pronouns.
    // Preserve lexical hyphens, such as entre-bâiller.
    static func mainVerbWord(_ form: String) -> String? {
        let normalized = form.precomposedStringWithCanonicalMapping
        guard let last = normalized.split(whereSeparator: { $0.isWhitespace }).last else { return nil }
        let uncliticized = String(last).replacingOccurrences(
            of: "-(?:(?:m|t)['’]en|moi|toi|nous|vous|le|la|les|lui|leur|en|y)(?:-(?:en|y))?$",
            with: "", options: .regularExpression
        )
        let word = uncliticized.replacingOccurrences(
            of: "^(?:(?:j|m|t|s|n|l|qu)['’])+", with: "", options: .regularExpression
        )
        return word.isEmpty ? nil : word
    }

    /// Compute the prefix off the calling executor.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func commonPrefix(_ infinitive: String, homonymIndex: Int? = nil) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: self.commonPrefix(infinitive, homonymIndex: homonymIndex))
            }
        }
    }

    /// Compute the prefix off the calling executor.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func rawInferredCommonPrefix(_ infinitive: String, homonymIndex: Int? = nil) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: self.rawInferredCommonPrefix(infinitive, homonymIndex: homonymIndex))
            }
        }
    }

    /// Compute the prefix off the calling executor.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func guessCommonPrefix(_ infinitive: String, homonymIndex: Int? = nil) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: self.guessCommonPrefix(infinitive, homonymIndex: homonymIndex))
            }
        }
    }
}
