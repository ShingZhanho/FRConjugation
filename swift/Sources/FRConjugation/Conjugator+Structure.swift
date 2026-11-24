import Foundation

extension Conjugator {
    /// Return catalogue voices with at least one form, sorted by raw label.
    /// Unknown verbs and unavailable combinations return an empty array; no inference is performed.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func voices(_ infinitive: String, homonymIndex: Int? = nil) -> [Voice] {
        guard let entry = catalogue.entries[resolveKey(infinitive, homonymIndex: homonymIndex)]
        else { return [] }
        return catalogue.groups.compactMap { voice, modes in
            modes.values.contains { tenses in
                tenses.values.contains { catalogue.hasForm(entry, ids: $0) }
            }
                ? voice : nil
        }.sorted { $0.rawValue < $1.rawValue }
    }

    /// Return catalogue moods with at least one form in this voice, sorted by raw label.
    /// Unknown verbs and unavailable combinations return an empty array; no inference is performed.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func modes(_ infinitive: String, voice: Voice, homonymIndex: Int? = nil) -> [Mode] {
        guard let entry = catalogue.entries[resolveKey(infinitive, homonymIndex: homonymIndex)],
            let modes = catalogue.groups[voice]
        else { return [] }
        return modes.compactMap { mode, tenses in
            tenses.values.contains { catalogue.hasForm(entry, ids: $0) } ? mode : nil
        }.sorted { $0.rawValue < $1.rawValue }
    }

    /// Return catalogue tenses with at least one form in this voice and mood, sorted by raw label.
    /// Unknown verbs and unavailable combinations return an empty array; no inference is performed.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter mode: The grammatical mood.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func tenses(_ infinitive: String, voice: Voice, mode: Mode, homonymIndex: Int? = nil)
        -> [Tense]
    {
        guard let entry = catalogue.entries[resolveKey(infinitive, homonymIndex: homonymIndex)],
            let tenses = catalogue.groups[voice]?[mode]
        else { return [] }
        return tenses.compactMap { catalogue.hasForm(entry, ids: $0.value) ? $0.key : nil }
            .sorted { $0.rawValue < $1.rawValue }
    }

    /// Return available persons grouped by identical full spellings in source order; participles
    /// return an empty array.
    /// Unknown verbs and unavailable combinations return an empty array; no inference is performed.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter voice: The grammatical voice.
    /// - Parameter mode: The grammatical mood.
    /// - Parameter tense: The tense or gendered participle/gérondif form appropriate to this
    ///   operation.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func persons(
        _ infinitive: String, voice: Voice, mode: Mode, tense: Tense,
        homonymIndex: Int? = nil
    ) -> [Person] {
        let key = resolveKey(infinitive, homonymIndex: homonymIndex)
        guard let entry = catalogue.entries[key], let ids = catalogue.groups[voice]?[mode]?[tense],
            mode != .participe
        else { return [] }

        // The source lists persons with identical full spellings together, in
        // order of the first person in each group. Alternative spellings count.
        var forms = [Person: String]()
        for id in ids {
            if let person = catalogue.slots[id].person {
                forms[person] = catalogue.file.render(entry.selection, id)
            }
        }
        var order = [String]()
        var groups = [String: [Person]]()
        for person in Person.allCases {
            guard let form = forms[person] else { continue }
            if groups[form] == nil { order.append(form) }
            groups[form, default: []].append(person)
        }
        return order.flatMap { groups[$0] ?? [] }
    }
}
