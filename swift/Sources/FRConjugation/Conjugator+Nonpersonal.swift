import Foundation

extension Conjugator {
    // MARK: - Gérondif

    /// The gérondif tense → source participle tense mapping.
    static let gerondifSourceTense: [Tense: Tense] = [
        .gerondifPresent: .present,
        .gerondifPasseMasculinSingulier: .passeCompoundMasculinSingulier,
        .gerondifPasseFemininSingulier: .passeCompoundFemininSingulier,
        .gerondifPasseMasculinPluriel: .passeCompoundMasculinPluriel,
        .gerondifPasseFemininPluriel: .passeCompoundFemininPluriel,
    ]

    /// Get a gérondif form.
    ///
    /// The gérondif is derived from the corresponding participle by
    /// prepending *en*:
    ///
    /// - **Gérondif présent** = "en " + present participle
    /// - **Gérondif passé**   = "en " + compound past participle
    ///   (4 gendered forms)
    ///
    ///     conjugator.gerondif("parler", voice: .activeAvoir,
    ///                         tense: .gerondifPresent)
    ///     // -> "en parlant"
    ///
    ///     conjugator.gerondif("partir", voice: .activeEtre,
    ///                         tense: .gerondifPasseFemininPluriel)
    ///     // -> "en étant parties"
    ///
    /// - Parameters:
    ///   - infinitive: The verb infinitive.
    ///   - voice: The grammatical voice.
    ///   - tense: Which gérondif form (one of the five `.gerondif...` tenses).
    ///   - homonymIndex: Optional homonym index for verbs with multiple entries.
    /// - Returns: The gérondif string, or `nil` if the underlying
    ///   participle is unavailable or `tense` is not a gérondif tense.
    public func gerondif(
        _ infinitive: String,
        voice: Voice,
        tense: Tense,
        homonymIndex: Int? = nil
    ) -> String? {
        guard let sourceTense = Self.gerondifSourceTense[tense] else {
            return nil
        }
        guard
            let part = participle(
                infinitive, voice: voice, tense: sourceTense,
                homonymIndex: homonymIndex)
        else {
            return nil
        }
        return "en " + part
    }

    /// All available primary participles in this voice.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func participles(_ infinitive: String, voice: Voice, homonymIndex: Int? = nil) -> [Tense:
        String]
    {
        var result = [Tense: String]()
        for tense in tenses(infinitive, voice: voice, mode: .participe, homonymIndex: homonymIndex)
        {
            result[tense] = participle(
                infinitive, voice: voice, tense: tense, homonymIndex: homonymIndex)
        }
        return result
    }
}
