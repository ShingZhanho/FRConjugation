import Foundation

extension Conjugator {
    /// Async variant of ``participle(_:voice:tense:homonymIndex:)-6sqv2``.
    /// Work runs off the calling executor. Cancellation does not interrupt the queued operation.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func participle(
        _ infinitive: String,
        voice: Voice,
        tense: Tense,
        homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.participle(
                    infinitive, voice: voice, tense: tense,
                    homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    /// Async variant of ``gerondif(_:voice:tense:homonymIndex:)-301m3``.
    /// Work runs off the calling executor. Cancellation does not interrupt the queued operation.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func gerondif(
        _ infinitive: String,
        voice: Voice,
        tense: Tense,
        homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.gerondif(
                    infinitive, voice: voice, tense: tense,
                    homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    /// Async variant of ``participleAlternative(_:voice:tense:homonymIndex:)-yz3f``.
    /// Work runs off the calling executor. Cancellation does not interrupt the queued operation.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func participleAlternative(
        _ infinitive: String,
        voice: Voice,
        tense: Tense,
        homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.participleAlternative(
                    infinitive, voice: voice, tense: tense,
                    homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    /// Async variant of ``getPronoun(_:voice:mode:tense:person:homonymIndex:)-acv8``.
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
    public func getPronoun(
        _ infinitive: String,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.getPronoun(
                    infinitive, voice: voice, mode: mode,
                    tense: tense, person: person,
                    homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    /// Async variant of ``conjugateWithPronoun(_:voice:mode:tense:person:homonymIndex:)``.
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
    public func conjugateWithPronoun(
        _ infinitive: String,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.conjugateWithPronoun(
                    infinitive, voice: voice, mode: mode,
                    tense: tense, person: person,
                    homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    /// Async variant of
    /// ``conjugateAlternativeWithPronoun(_:voice:mode:tense:person:homonymIndex:)``.
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
    public func conjugateAlternativeWithPronoun(
        _ infinitive: String,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.conjugateAlternativeWithPronoun(
                    infinitive, voice: voice, mode: mode,
                    tense: tense, person: person,
                    homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    // MARK: - Async Initialization

    /// Asynchronously load the conjugation model from bundled resources.
    /// Work runs off the calling executor. Cancellation does not interrupt the queued operation.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public static func load() async throws -> Conjugator {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let conjugator = try Conjugator()
                    continuation.resume(returning: conjugator)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Async Conjugation

    /// Conjugate a single form asynchronously.
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
    public func conjugate(
        _ infinitive: String,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.conjugate(
                    infinitive, voice: voice, mode: mode,
                    tense: tense, person: person,
                    homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    /// Conjugate all persons for a given voice, mode and tense asynchronously.
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
    public func conjugate(
        _ infinitive: String,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        homonymIndex: Int? = nil
    ) async -> [Person: String] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.conjugate(
                    infinitive, voice: voice, mode: mode, tense: tense,
                    homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }

    /// Return the alternative spelling for a single form asynchronously.
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
    public func conjugateAlternative(
        _ infinitive: String,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex: Int? = nil
    ) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.conjugateAlternative(
                    infinitive, voice: voice, mode: mode,
                    tense: tense, person: person,
                    homonymIndex: homonymIndex)
                continuation.resume(returning: result)
            }
        }
    }
}
