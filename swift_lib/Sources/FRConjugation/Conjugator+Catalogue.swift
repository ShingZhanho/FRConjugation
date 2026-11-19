import Foundation

extension Conjugator {
    // MARK: - Form Splitting

    /// Extract the primary (first) form from a raw prediction that may
    /// contain semicolon-separated alternatives (e.g. "abrégerai;abrègerai").
    static func primaryForm(_ raw: String) -> String {
        if let idx = raw.firstIndex(of: ";") {
            return String(raw[raw.startIndex..<idx])
        }
        return raw
    }

    /// Extract the alternative (second) form from a raw prediction,
    /// falling back to the primary form when no alternative exists.
    static func alternativeForm(_ raw: String) -> String {
        if let idx = raw.firstIndex(of: ";") {
            return String(raw[raw.index(after: idx)...])
        }
        return raw
    }

    // MARK: - Conjugation (Single Form)

    /// Conjugate a single form.
    ///
    /// When the catalogue supplies multiple spelling variants (e.g.
    /// *abrégerai* / *abrègerai*), this method returns the **primary**
    /// (first) variant.  Use ``conjugateAlternative(_:voice:mode:tense:person:)``
    /// to obtain the alternative spelling.
    ///
    ///     conjugator.conjugate("aller", voice: .activeEtre,
    ///         mode: .indicatif, tense: .present,
    ///         person: .firstSingularMasculine)
    ///     // -> "vais"
    ///
    /// - Returns: The conjugated form, or `nil` if the combination is
    ///   invalid or the verb is unknown.
    public func conjugate(
        _ infinitive: String,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex: Int? = nil
    ) -> String? {
        let key = resolveKey(infinitive, homonymIndex: homonymIndex)

        guard let raw = catalogue.form(key, slot: .init(voice: voice, mode: mode, tense: tense, person: person)) else { return nil }
        return Self.primaryForm(raw)
    }

    /// Return the alternative spelling for a single conjugated form.
    ///
    /// If the form has two spelling variants (e.g. *abrégerai* /
    /// *abrègerai*), this returns the **second** variant.  When only
    /// one spelling exists, it behaves identically to
    /// ``conjugate(_:voice:mode:tense:person:)``.
    ///
    ///     conjugator.conjugateAlternative("abréger",
    ///         voice: .activeAvoir, mode: .indicatif,
    ///         tense: .futurSimple, person: .firstSingularMasculine)
    ///     // -> "abrègerai"
    ///
    /// - Returns: The alternative (or only) conjugated form, or `nil`
    ///   if the combination is invalid.
    public func conjugateAlternative(
        _ infinitive: String,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex: Int? = nil
    ) -> String? {
        let key = resolveKey(infinitive, homonymIndex: homonymIndex)

        guard let raw = catalogue.form(key, slot: .init(voice: voice, mode: mode, tense: tense, person: person)) else { return nil }
        return Self.alternativeForm(raw)
    }

    /// Whether the given conjugation has an alternative spelling variant.
    ///
    ///     conjugator.hasAlternativeForm("abréger",
    ///         voice: .activeAvoir, mode: .indicatif,
    ///         tense: .futurSimple, person: .firstSingularMasculine)
    ///     // -> true
    ///
    /// - Returns: `true` if there are two spelling variants, `false` otherwise.
    public func hasAlternativeForm(
        _ infinitive: String,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex: Int? = nil
    ) -> Bool {
        let key = resolveKey(infinitive, homonymIndex: homonymIndex)

        guard let raw = catalogue.form(key, slot: .init(voice: voice, mode: mode, tense: tense, person: person)) else { return false }
        return raw.contains(";")
    }

    /// Conjugate all persons for a given voice, mode and tense.
    ///
    /// - Returns: A dictionary mapping each valid person to its form.
    public func conjugate(
        _ infinitive: String,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        homonymIndex: Int? = nil
    ) -> [Person: String] {
        guard let entry = catalogue.entries[resolveKey(infinitive, homonymIndex: homonymIndex)],
              let ids = catalogue.groups[voice]?[mode]?[tense] else { return [:] }
        var result = [Person: String]()
        for id in ids {
            if let person = catalogue.slots[id].person, let raw = catalogue.file.render(entry.selection, id) {
                result[person] = Self.primaryForm(raw)
            }
        }
        return result
    }

    /// Conjugate all tenses and persons for a voice and mode.
    ///
    /// - Returns: A nested dictionary: tense -> person -> form.
    public func conjugate(
        _ infinitive: String,
        voice: Voice,
        mode: Mode,
        homonymIndex: Int? = nil
    ) -> [Tense: [Person: String]] {
        var result = [Tense: [Person: String]]()
        for tense in tenses(infinitive, voice: voice, mode: mode, homonymIndex: homonymIndex) {
            let forms = conjugate(infinitive, voice: voice, mode: mode, tense: tense, homonymIndex: homonymIndex)
            if !forms.isEmpty { result[tense] = forms }
        }
        return result
    }

    /// Conjugate all modes, tenses and persons for a voice.
    ///
    /// - Returns: A nested dictionary: mode -> tense -> person -> form.
    public func conjugate(
        _ infinitive: String,
        voice: Voice,
        homonymIndex: Int? = nil
    ) -> [Mode: [Tense: [Person: String]]] {
        var result = [Mode: [Tense: [Person: String]]]()
        for mode in modes(infinitive, voice: voice, homonymIndex: homonymIndex) where mode != .participe {
            let forms = conjugate(infinitive, voice: voice, mode: mode, homonymIndex: homonymIndex)
            if !forms.isEmpty { result[mode] = forms }
        }
        return result
    }

    /// Conjugate all voices, modes, tenses and persons for a verb.
    ///
    /// - Returns: A nested dictionary: voice -> mode -> tense -> person -> form,
    ///   or `nil` if the verb is unknown.
    public func conjugate(
        _ infinitive: String,
        homonymIndex: Int? = nil
    ) -> [Voice: [Mode: [Tense: [Person: String]]]]? {
        var result = [Voice: [Mode: [Tense: [Person: String]]]]()
        for voice in voices(infinitive, homonymIndex: homonymIndex) {
            let forms = conjugate(infinitive, voice: voice, homonymIndex: homonymIndex)
            if !forms.isEmpty { result[voice] = forms }
        }
        return result.isEmpty ? nil : result
    }

    // MARK: - Participles

    /// Get a single participle form.
    ///
    ///     conjugator.participle("partir", voice: .activeEtre,
    ///                           tense: .passeFemininPluriel)
    ///     // -> "parties"
    ///
    ///     conjugator.participle("parler", voice: .activeAvoir,
    ///                           tense: .present)
    ///     // -> "parlant"
    ///
    /// - Parameters:
    ///   - infinitive: The verb infinitive.
    ///   - voice: The grammatical voice.
    ///   - tense: Which participle form to retrieve (e.g. `.present`,
    ///     `.passeMasculinSingulier`, `.passeFemininPluriel`).
    /// - Returns: The participle string, or `nil` if unavailable.
    /// Get a single participle form.
    ///
    /// When variants exist, returns the **primary** form.
    /// Use ``participleAlternative(_:voice:tense:)`` for the alternative.
    public func participle(
        _ infinitive: String,
        voice: Voice,
        tense: Tense,
        homonymIndex: Int? = nil
    ) -> String? {
        let key = resolveKey(infinitive, homonymIndex: homonymIndex)
        guard let raw = catalogue.form(key, slot: .init(voice: voice, mode: .participe, tense: tense, person: nil)) else { return nil }
        return Self.primaryForm(raw)
    }

    /// Return the alternative spelling for a single participle form.
    ///
    /// If only one spelling exists, behaves identically to
    /// ``participle(_:voice:tense:)``.
    public func participleAlternative(
        _ infinitive: String,
        voice: Voice,
        tense: Tense,
        homonymIndex: Int? = nil
    ) -> String? {
        let key = resolveKey(infinitive, homonymIndex: homonymIndex)
        guard let raw = catalogue.form(key, slot: .init(voice: voice, mode: .participe, tense: tense, person: nil)) else { return nil }
        return Self.alternativeForm(raw)
    }

    /// Whether the given participle has an alternative spelling variant.
    public func hasAlternativeParticiple(
        _ infinitive: String,
        voice: Voice,
        tense: Tense,
        homonymIndex: Int? = nil
    ) -> Bool {
        let key = resolveKey(infinitive, homonymIndex: homonymIndex)
        guard let raw = catalogue.form(key, slot: .init(voice: voice, mode: .participe, tense: tense, person: nil)) else { return false }
        return raw.contains(";")
    }
}
