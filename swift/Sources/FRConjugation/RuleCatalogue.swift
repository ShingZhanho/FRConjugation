import Foundation

/// Immutable indexes over the compiled catalogue. Rendered answers are never retained.
struct RuleCatalogue {
    struct Entry {
        let selection: RuleFile.Selection
        let flags: Int
        let variant: String?
    }

    struct Slot: Hashable {
        let voice: Voice
        let mode: Mode
        let tense: Tense
        let person: Person?
    }

    let file: RuleFile
    let entries: [String: Entry]
    let homonymMap: [String: [Int]]
    let slotIDs: [Slot: Int]
    let groups: [Voice: [Mode: [Tense: [Int]]]]
    let slots: [Slot]
    private let fallbackTemplates: [Int]

    init(url: URL) throws {
        let file = try RuleFile(url)
        var slots = [Slot]()
        var ids = [Slot: Int]()
        var groups = [Voice: [Mode: [Tense: [Int]]]]()
        for i in 0..<file.slotCount {
            let parts = file.slotName(i).components(separatedBy: "|")
            guard parts.count == 4, let voice = Voice(rawValue: parts[0]),
                let mode = Mode(rawValue: parts[1]), let tense = Tense(rawValue: parts[2])
            else { throw InvalidFormat("Unrecognized grammatical slot") }
            let person = Person(rawValue: parts[3])
            guard mode == .participe ? parts[3] == "-" : person != nil else {
                throw InvalidFormat("Invalid person in grammatical slot")
            }
            let slot = Slot(voice: voice, mode: mode, tense: tense, person: person)
            guard ids.updateValue(i, forKey: slot) == nil else {
                throw InvalidFormat("Duplicate slot")
            }
            groups[voice, default: [:]][mode, default: [:]][tense, default: []].append(i)
            slots.append(slot)
        }

        var entries = [String: Entry](minimumCapacity: file.verbCount)
        var homonyms = [String: [Int]]()
        var frequencies = [Int: Int]()
        for i in 0..<file.verbCount {
            let (key, flags, variant) = file.metadata(at: i)
            guard let selection = file.inferredSelection(key), entries[key] == nil else {
                throw InvalidFormat("Invalid lexical entry")
            }
            entries[key] = Entry(selection: selection, flags: flags, variant: variant)
            frequencies[selection.template, default: 0] += 1
            if let separator = key.lastIndex(of: "_"),
                let index = Int(key[key.index(after: separator)...])
            {
                homonyms[String(key[..<separator]), default: []].append(index)
            }
        }

        // When suffix backoff exhausts a slot, transfer the most widely used
        // catalogue template that actually supplies it. Template ID breaks ties.
        let ranked = frequencies.keys.sorted {
            let lhs = frequencies[$0]!, rhs = frequencies[$1]!
            return lhs == rhs ? $0 < $1 : lhs > rhs
        }
        let defaults = try slots.indices.map { id -> Int in
            guard let template = ranked.first(where: { file.program(template: $0, slot: id) != 0 })
            else { throw InvalidFormat("Slot has no attested form") }
            return template
        }
        self.file = file
        self.entries = entries
        self.homonymMap = homonyms.mapValues { $0.sorted() }
        self.slotIDs = ids
        self.slots = slots
        self.groups = groups
        self.fallbackTemplates = defaults
    }

    func form(_ key: String, slot: Slot) -> String? {
        guard let entry = entries[key], let id = slotIDs[slot] else { return nil }
        return file.render(entry.selection, id)
    }

    func infer(_ key: String, slot: Slot) -> String? {
        guard let id = slotIDs[slot] else { return nil }
        if let result = file.inferBySuffix(key, slot: id) { return result }
        let base = RuleFile.lemmaAndIndex(key).lemma
        return file.renderFallback(base, template: fallbackTemplates[id], slot: id)
    }

    func hasForm(_ entry: Entry, ids: [Int]) -> Bool {
        ids.contains { file.program(template: entry.selection.template, slot: $0) != 0 }
    }
}
