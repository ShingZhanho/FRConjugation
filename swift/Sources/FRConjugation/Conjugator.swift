import Foundation

/// French conjugation using an immutable, bundled catalogue of spelling rules.
///
/// Instances support concurrent reads. Synchronous methods run on the caller;
/// async overloads dispatch work to a background queue without cancellation.
/// All verb inputs are trimmed, lowercased and NFC-normalized before lookup.
/// Its supported alphabet is space, apostrophe, hyphen, 1, 2, semicolon,
/// underscore, a-z and âçèéêîïôûœ. Predictions may be grammatically unattested.
/// Only the bundled catalogue is supported.
public final class Conjugator: @unchecked Sendable {
    private static let shared = Result { try Conjugator() }
    let catalogue: RuleCatalogue

    /// Returns the shared bundled catalogue.
    /// Traps if the bundled resource cannot load;
    /// use the throwing initializer to handle a resource failure.
    public static func getShared() -> Conjugator {
        try! shared.get()
    }

    /// Loads the shared bundled catalogue off the calling executor.
    /// Work runs off the calling executor. Cancellation does not interrupt the queued operation.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public static func getShared() async throws -> Conjugator {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(with: shared)
            }
        }
    }

    /// Load the catalogue bundled with this package.
    /// - Throws: `ConjugationError.modelLoadFailed` if the resource cannot be loaded.
    public init() throws {
        #if SWIFT_PACKAGE
            let bundle = Bundle.module
        #else
            let bundle = Bundle(for: Conjugator.self)
        #endif
        guard let url = bundle.url(forResource: "catalogue", withExtension: "fcr") else {
            throw ConjugationError.modelLoadFailed(path: "bundled resources")
        }
        do {
            catalogue = try RuleCatalogue(url: url)
        } catch {
            throw ConjugationError.modelLoadFailed(path: url.deletingLastPathComponent().path)
        }
    }

    // MARK: - Properties

    /// The number of verbs the model recognises.
    ///
    /// Homonym groups (e.g. `ressortir_1`, `ressortir_2`) count as a single verb.
    public var verbCount: Int {
        // Each homonym group contributes 1 base name instead of N suffixed entries.
        var count = catalogue.entries.count
        for (_, indices) in catalogue.homonymMap {
            count -= indices.count
            count += 1
        }
        return count
    }

    /// A sorted list of all verb infinitives known to the model.
    ///
    /// Homonym-suffixed entries (e.g. `ressortir_1`, `ressortir_2`) are
    /// collapsed into their base infinitive (`ressortir`).
    ///
    ///     conjugator.allVerbs
    ///     // ["abaisser", "abandonner", "abasourdir", ...]
    public var allVerbs: [String] {
        var verbs = Set(catalogue.entries.keys)
        for (base, indices) in catalogue.homonymMap {
            for idx in indices {
                verbs.remove("\(base)_\(idx)")
            }
            verbs.insert(base)
        }
        return verbs.sorted { a, b in
            let ak = Conjugator.sortKey(a)
            let bk = Conjugator.sortKey(b)
            return ak == bk ? a < b : ak < bk
        }
    }

    /// Produce a diacritics-insensitive, ligature-expanded sort key.
    private static func sortKey(_ s: String) -> String {
        s.replacingOccurrences(of: "œ", with: "oe")
            .replacingOccurrences(of: "Œ", with: "OE")
            .replacingOccurrences(of: "æ", with: "ae")
            .replacingOccurrences(of: "Æ", with: "AE")
            .folding(
                options: [.diacriticInsensitive, .widthInsensitive],
                locale: Locale(identifier: "fr"))
    }

    // MARK: - Queries

    /// Whether the model recognises this infinitive.
    ///
    /// For verbs with homonyms (e.g. *ressortir*), returns `true` for
    /// the base name even though the internal keys are suffixed
    /// (*ressortir_1*, *ressortir_2*).
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    public func hasVerb(_ infinitive: String) -> Bool {
        return catalogue.entries[Self.normalizedInfinitive(infinitive)] != nil
            || catalogue.homonymMap[Self.normalizedInfinitive(infinitive)] != nil
    }

    /// Whether a verb beginning with *h* is h-aspiré (no elision/liaison).
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    public func isHAspire(_ infinitive: String) -> Bool {
        return (catalogue.entries[Self.normalizedInfinitive(infinitive)]?.flags ?? 0) & 1 != 0
    }

    /// Whether the source marks this verb as blocking elision and liaison.
    ///
    /// This lexical property includes non-h initials such as ululer and yoyoter.
    /// Auxiliary forms can still trigger elision (for example, j'ai ululé).
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    /// - Parameter homonymIndex: An indexed homonym, or `nil` for the first available index. Exact
    ///   catalogue keys take precedence.
    public func blocksElisionAndLiaison(_ infinitive: String, homonymIndex: Int? = nil) -> Bool {
        return (catalogue.entries[resolveKey(infinitive, homonymIndex: homonymIndex)]?.flags ?? 0)
            & 2 != 0
    }

    /// Whether a verb has 1990 reform spelling changes.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    public func is1990Reform(_ infinitive: String) -> Bool {
        return (catalogue.entries[Self.normalizedInfinitive(infinitive)]?.flags ?? 0) & 4 != 0
    }

    /// Return the 1990 reform variant for a verb, or `nil`.
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    public func reformVariante(_ infinitive: String) -> String? {
        return catalogue.entries[Self.normalizedInfinitive(infinitive)]?.variant
    }

    // MARK: - Homonym Queries

    /// Whether the given base infinitive has multiple homonym entries.
    ///
    ///     conjugator.hasHomonyms("ressortir")  // true
    ///     conjugator.hasHomonyms("parler")     // false
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    public func hasHomonyms(_ infinitive: String) -> Bool {
        return catalogue.homonymMap[Self.normalizedInfinitive(infinitive)] != nil
    }

    /// The number of homonym entries for a verb, or 1 if it has no homonyms.
    ///
    ///     conjugator.homonymCount("ressortir")  // 2
    ///     conjugator.homonymCount("parler")     // 1
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    public func homonymCount(_ infinitive: String) -> Int {
        return catalogue.homonymMap[Self.normalizedInfinitive(infinitive)]?.count ?? 1
    }

    /// The available homonym indices for a verb, or an empty array if none.
    ///
    ///     conjugator.homonymIndices("ressortir")  // [1, 2]
    ///     conjugator.homonymIndices("parler")     // []
    /// - Parameter infinitive: The infinitive or exact homonym key. Verb inputs are trimmed, lowercased,
    ///   and NFC-normalized before lookup.
    public func homonymIndices(_ infinitive: String) -> [Int] {
        return catalogue.homonymMap[Self.normalizedInfinitive(infinitive)] ?? []
    }

    // MARK: - Homonym Key Resolution

    static func normalizedInfinitive(_ input: String) -> String {
        input.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased().precomposedStringWithCanonicalMapping
    }

    /// Resolve a user-facing infinitive + optional homonym index to the
    /// internal DB key used for lookups.
    ///
    /// - If the infinitive is directly known (e.g. "parler"), returns it as-is.
    /// - If the infinitive has homonyms and `homonymIndex` is nil, defaults to
    ///   the first index (1).
    /// - If `homonymIndex` is provided, returns "`infinitive`_`index`".
    func resolveKey(_ infinitive: String, homonymIndex: Int?) -> String {
        let infinitive = Self.normalizedInfinitive(infinitive)
        // Direct match — no homonyms
        if catalogue.entries[infinitive] != nil {
            return infinitive
        }
        // Homonym verb — resolve to suffixed key
        if let indices = catalogue.homonymMap[infinitive] {
            let idx = homonymIndex ?? indices.first ?? 1
            return "\(infinitive)_\(idx)"
        }
        // Unknown verb — return as-is (will fail downstream)
        return infinitive
    }
}
