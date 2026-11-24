import Foundation

extension Conjugator {
    /// Shared spelling across all available catalogue slots and alternatives.
    /// Includes participles and all voices. Auxiliaries and pronouns are excluded.
    /// Accents are significant. This is a display aid, not a grammatical stem.
    /// Returns nil for unavailable forms, or an empty string for no common prefix.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func commonPrefix(_ infinitive: String, homonymIndex: Int? = nil) -> String? {
        let key = resolveKey(infinitive, homonymIndex: homonymIndex)
        return sharedPrefix { catalogue.form(key, slot: $0) }
    }

    /// Shared spelling across all globally supported inferred slots and alternatives.
    /// Input normalization and validation match rawInferredConjugation.
    /// - Parameter infinitive: Any supported input string; surrounding whitespace is trimmed, then
    ///   case and Unicode are normalized.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func rawInferredCommonPrefix(_ infinitive: String, homonymIndex: Int? = nil) -> String? {
        sharedPrefix { slot in
            rawInferredForm(
                infinitive, voice: slot.voice, mode: slot.mode,
                tense: slot.tense, person: slot.person, homonymIndex: homonymIndex)
        }
    }

    /// Use the catalogue prefix for known infinitives, preserving missing slots.
    /// Infer a prefix only for infinitives absent from the catalogue.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func guessCommonPrefix(_ infinitive: String, homonymIndex: Int? = nil) -> String? {
        if hasVerb(infinitive) {
            return commonPrefix(infinitive, homonymIndex: homonymIndex)
        }
        return rawInferredCommonPrefix(infinitive, homonymIndex: homonymIndex)
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
        guard let last = normalized.split(whereSeparator: { $0.isWhitespace }).last else {
            return nil
        }
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
    /// Work runs off the calling executor. Cancellation does not interrupt the queued operation.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func commonPrefix(_ infinitive: String, homonymIndex: Int? = nil) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(
                    returning: self.commonPrefix(infinitive, homonymIndex: homonymIndex))
            }
        }
    }

    /// Compute the prefix off the calling executor.
    /// Work runs off the calling executor. Cancellation does not interrupt the queued operation.
    /// - Parameter infinitive: Any supported input string; surrounding whitespace is trimmed, then
    ///   case and Unicode are normalized.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func rawInferredCommonPrefix(_ infinitive: String, homonymIndex: Int? = nil) async
        -> String?
    {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(
                    returning: self.rawInferredCommonPrefix(infinitive, homonymIndex: homonymIndex))
            }
        }
    }

    /// Compute the prefix off the calling executor.
    /// Work runs off the calling executor. Cancellation does not interrupt the queued operation.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func guessCommonPrefix(_ infinitive: String, homonymIndex: Int? = nil) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(
                    returning: self.guessCommonPrefix(infinitive, homonymIndex: homonymIndex))
            }
        }
    }
}
