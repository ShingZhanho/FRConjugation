import Foundation

extension Conjugator {
    // MARK: - Pronoun

    /// French vowels used for elision checks.
    private static let frenchVowels: Set<Character> = [
        "a", "e", "i", "o", "u",
        "\u{00E0}", "\u{00E2}", "\u{00E9}", "\u{00E8}", "\u{00EA}", "\u{00EB}",
        "\u{00EE}", "\u{00EF}", "\u{00F4}", "\u{00F9}", "\u{00FB}", "\u{00FC}",
        "\u{0153}", "\u{00E6}", "y",
    ]

    /// Whether a conjugated form starts with a sound that triggers elision.
    private func formStartsWithVowelSound(
        _ form: String, infinitive: String, voice: Voice, tense: Tense
    ) -> Bool {
        guard let first = form.first else { return false }
        let lower = Character(first.lowercased())
        // In passive or compound tenses the first word can be an auxiliary:
        // lexical blocking must not turn j'étais / j'ai into je étais / je ai.
        let simpleTense =
            tense == .present || tense == .imparfait
            || tense == .passeSimple || tense == .futurSimple
        if voice != .passive && simpleTense && blocksElisionAndLiaison(infinitive) {
            return false
        }
        if lower == "h" {
            return !isHAspire(infinitive)
        }
        return Self.frenchVowels.contains(lower)
    }

    /// Return the contextual subject pronoun for a conjugated form.
    ///
    /// The pronoun accounts for elision ("je" becomes "j'" before a
    /// vowel sound or h-muet) and prepends *que* / *qu'* for the
    /// subjonctif mood.
    ///
    ///     conjugator.getPronoun("aimer", voice: .activeAvoir,
    ///         mode: .indicatif, tense: .present,
    ///         person: .firstSingularMasculine)
    ///     // -> "j'"
    ///
    ///     conjugator.getPronoun("parler", voice: .activeAvoir,
    ///         mode: .subjonctif, tense: .present,
    ///         person: .thirdSingularMasculine)
    ///     // -> "qu'il "
    ///
    /// - Returns: The pronoun string (with trailing space or apostrophe),
    ///   or `nil` for imperatif, participe, unknown verbs, or invalid
    ///   combinations.
    /// - Parameter infinitive: The infinitive or exact homonym key. Catalogue lookup preserves case
    ///   and surrounding whitespace.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter mode: The grammatical mood.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter person: The grammatical person and gender.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func getPronoun(
        _ infinitive: String,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex: Int? = nil
    ) -> String? {
        // No subject pronoun for imperatif or participe
        guard mode != .imperatif, mode != .participe else { return nil }

        let key = resolveKey(infinitive, homonymIndex: homonymIndex)

        guard
            let raw = catalogue.form(
                key, slot: .init(voice: voice, mode: mode, tense: tense, person: person))
        else { return nil }

        let form = Self.primaryForm(raw)
        return pronounString(
            person: person, mode: mode, form: form,
            infinitive: key, voice: voice, tense: tense)
    }

    /// Build the pronoun string for a given person, mode, and conjugated form.
    private func pronounString(
        person: Person, mode: Mode, form: String, infinitive: String, voice: Voice, tense: Tense
    ) -> String {
        let base = person.pronoun
        let vowelSound = formStartsWithVowelSound(
            form, infinitive: infinitive,
            voice: voice, tense: tense)

        // Determine the subject pronoun (with possible elision)
        let subject: String
        if (person == .firstSingularMasculine || person == .firstSingularFeminine) && vowelSound {
            subject = "j'"
        } else {
            subject = base + " "
        }

        // Subjonctif: prepend "que" / "qu'"
        if mode == .subjonctif {
            let pronounStartsWithVowel: Bool
            switch person {
            case .thirdSingularMasculine, .thirdSingularFeminine,
                .thirdSingularNeutral,
                .thirdPluralMasculine, .thirdPluralFeminine:
                pronounStartsWithVowel = true  // il, elle, on, ils, elles
            default:
                pronounStartsWithVowel = false
            }

            if pronounStartsWithVowel {
                return "qu'" + subject
            }
            return "que " + subject
        }

        return subject
    }

    /// Return the conjugated form prefixed with its contextual subject pronoun.
    ///
    /// Combines ``getPronoun(_:voice:mode:tense:person:homonymIndex:)-acv8`` and
    /// ``conjugate(_:voice:mode:tense:person:homonymIndex:)-48gqq`` into a single call.
    /// Imperatives are returned without a subject. This finite-form signature
    /// cannot address personless participle slots; use `participle` for those.
    ///
    ///     conjugator.conjugateWithPronoun("aimer", voice: .activeAvoir,
    ///         mode: .indicatif, tense: .present,
    ///         person: .firstSingularMasculine)
    ///     // -> "j'aime"
    ///
    ///     conjugator.conjugateWithPronoun("parler", voice: .activeAvoir,
    ///         mode: .imperatif, tense: .present,
    ///         person: .secondSingularMasculine)
    ///     // -> "parle"
    ///
    /// - Returns: The pronoun + form string, or `nil` if the verb is
    ///   unknown or the combination is invalid.
    /// - Parameter infinitive: The infinitive or exact homonym key. Catalogue lookup preserves case
    ///   and surrounding whitespace.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter mode: The grammatical mood.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter person: The grammatical person and gender.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func conjugateWithPronoun(
        _ infinitive: String,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex: Int? = nil
    ) -> String? {
        // Modes with no subject pronoun -- return bare form
        if mode == .imperatif || mode == .participe {
            return conjugate(
                infinitive, voice: voice, mode: mode,
                tense: tense, person: person, homonymIndex: homonymIndex)
        }

        let key = resolveKey(infinitive, homonymIndex: homonymIndex)

        guard
            let raw = catalogue.form(
                key, slot: .init(voice: voice, mode: mode, tense: tense, person: person))
        else { return nil }

        let form = Self.primaryForm(raw)
        let pronoun = pronounString(
            person: person, mode: mode, form: form,
            infinitive: key, voice: voice, tense: tense)
        return pronoun + form
    }

    /// Return the alternative conjugated form prefixed with its contextual
    /// subject pronoun.
    ///
    /// Combines ``getPronoun(_:voice:mode:tense:person:homonymIndex:)-acv8`` and
    /// ``conjugateAlternative(_:voice:mode:tense:person:homonymIndex:)-5ki9r`` into a single call.
    /// Imperatives are returned without a subject. This finite-form signature
    /// cannot address personless participle slots; use `participleAlternative` for those.
    ///
    ///     conjugator.conjugateAlternativeWithPronoun("abr\u{00E9}ger",
    ///         voice: .activeAvoir, mode: .indicatif,
    ///         tense: .futurSimple, person: .firstSingularMasculine)
    ///     // -> "j'abr\u{00E8}gerai"
    ///
    /// - Returns: The pronoun + alternative form string, or `nil` if the
    ///   verb is unknown or the combination is invalid.
    /// - Parameter infinitive: The infinitive or exact homonym key. Catalogue lookup preserves case
    ///   and surrounding whitespace.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter mode: The grammatical mood.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter person: The grammatical person and gender.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func conjugateAlternativeWithPronoun(
        _ infinitive: String,
        voice: Voice,
        mode: Mode,
        tense: Tense,
        person: Person,
        homonymIndex: Int? = nil
    ) -> String? {
        if mode == .imperatif || mode == .participe {
            return conjugateAlternative(
                infinitive, voice: voice, mode: mode,
                tense: tense, person: person, homonymIndex: homonymIndex)
        }

        let key = resolveKey(infinitive, homonymIndex: homonymIndex)

        guard
            let raw = catalogue.form(
                key, slot: .init(voice: voice, mode: mode, tense: tense, person: person))
        else { return nil }

        let form = Self.alternativeForm(raw)
        let pronoun = pronounString(
            person: person, mode: mode, form: form,
            infinitive: key, voice: voice, tense: tense)
        return pronoun + form
    }
}
