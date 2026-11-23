import Foundation

struct InvalidFormat: Error, CustomStringConvertible {
    let description: String
    init(_ detail: String) { description = detail }
}

// Only byte positions and counts are retained. The NSData owns the backing storage.
final class RuleFile {
    private let owner: NSData
    private let bytes: UnsafeRawBufferPointer
    private let sections: [Int]
    private let none = Int(UInt32.max)
    let slotCount: Int
    let verbCount: Int
    private let suffixCount: Int
    private let width: Int

    init(_ url: URL) throws {
        let file = try NSData(contentsOf: url, options: .mappedIfSafe)
        let buffer = UnsafeRawBufferPointer(start: file.bytes, count: file.length)
        func word(_ p: Int) -> Int {
            RuleFile.word(buffer, p)
        }
        guard file.length >= 40, Array(buffer[0..<4]) == Array("FCR1".utf8),
            word(4) == 1
        else { throw InvalidFormat("Unrecognized header") }
        let s = (0..<8).map { word(8 + 4 * $0) }
        guard s.first == 40, s.last == file.length, zip(s, s.dropFirst()).allSatisfy(<=)
        else { throw InvalidFormat("Invalid section directory") }
        owner = file
        bytes = buffer
        sections = s
        slotCount = (s[2] - s[1]) / 4
        verbCount = (s[3] - s[2]) / 12
        suffixCount = (s[4] - s[3]) / 8
        width = (slotCount + 15) / 16
        try validate()
    }

    private static func word(_ bytes: UnsafeRawBufferPointer, _ p: Int) -> Int {
        var value: UInt32 = 0
        withUnsafeMutableBytes(of: &value) {
            $0.copyMemory(from: UnsafeRawBufferPointer(rebasing: bytes[p..<p + 4]))
        }
        return Int(UInt32(littleEndian: value))
    }

    private func word(_ p: Int) -> Int {
        RuleFile.word(bytes, p)
    }
    private func record(_ section: Int, _ index: Int) -> Range<Int> {
        let base = sections[section]
        let payload = base + 8 + 4 * word(base)
        let offset = base + 4 + 4 * index
        return payload + word(offset)..<payload + word(offset + 4)
    }
    private func validate() throws {
        func check(_ ok: Bool) throws {
            if !ok { throw InvalidFormat("Invalid table or reference") }
        }
        for section in [0, 6] {
            let start = sections[section], end = sections[section + 1]
            try check(end - start >= 8)
            let count = word(start)
            let payload = start + 8 + count * 4
            try check(payload <= end && word(start + 4) == 0)
            var previous = 0
            for i in 0...count {
                let offset = word(start + 4 + 4 * i)
                try check(offset >= previous && offset <= end - payload)
                if section == 6 { try check(offset % 12 == 0) }
                previous = offset
            }
            try check(payload + previous == end)
        }
        try check(slotCount > 0 && verbCount > 0 && suffixCount > 0)
        let strides = [4, 12, 8, 4 * width, 64]
        for (i, stride) in strides.enumerated() {
            try check((sections[i + 2] - sections[i + 1]) % stride == 0)
        }
        let strings = word(sections[0]), programs = word(sections[6])
        let templates = (sections[5] - sections[4]) / (width * 4)
        let blocks = (sections[6] - sections[5]) / 64
        func checkWords(_ section: Int, _ stride: Int, _ limit: Int) throws {
            for p in Swift.stride(from: sections[section], to: sections[section + 1], by: stride) {
                try check(word(p) < limit)
            }
        }
        try checkWords(1, 4, strings)
        try checkWords(2, 12, strings)
        try checkWords(3, 8, strings)
        try checkWords(4, 4, blocks)
        try checkWords(5, 4, programs)
        for p in stride(from: sections[2] + 8, to: sections[3], by: 12) {
            try check(word(p) == none || word(p) < strings)
        }
        for p in stride(from: sections[3] + 4, to: sections[4], by: 8) {
            try check(word(p) < templates)
        }
        try check(programs > 0 && record(6, 0).isEmpty)
        for i in 0..<programs {
            let r = record(6, i)
            for p in stride(from: r.lowerBound, to: r.upperBound, by: 12) {
                try check(word(p) < strings && word(p + 8) < strings)
            }
        }
    }
    private func string(_ id: Int) -> String {
        String(decoding: bytes[record(0, id)], as: UTF8.self)
    }
    private func find(_ text: Substring, section: Int, count: Int, stride: Int) -> Int? {
        let needle = text.utf8
        var low = 0, high = count
        while low < high {
            let mid = (low + high) / 2
            let p = sections[section] + stride * mid
            let candidate = bytes[record(0, word(p))]
            if candidate.elementsEqual(needle) { return p }
            if candidate.lexicographicallyPrecedes(needle) { low = mid + 1 } else { high = mid }
        }
        return nil
    }
    func slotName(_ i: Int) -> String { string(word(sections[1] + 4 * i)) }
    func metadata(at i: Int) -> (String, Int, String?) {
        let p = sections[2] + 12 * i
        let variant = word(p + 8)
        return (string(word(p)), word(p + 4), variant == none ? nil : string(variant))
    }
    struct Selection { let lemma: Substring; let template: Int }
    func select(_ key: String) -> Selection? {
        guard find(key[...], section: 2, count: verbCount, stride: 12) != nil else { return nil }
        return inferredSelection(key)
    }
    func inferredSelection(_ key: String) -> Selection? {
        firstSuffixResult(key) { $0 }
    }

    func inferBySuffix(_ key: String, slot: Int) -> String? {
        firstSuffixResult(key) { selection in
            guard let form = render(selection, slot), !form.isEmpty else { return nil }
            return form
        }
    }

    static func lemmaAndIndex(_ key: String) -> (lemma: Substring, index: Substring) {
        if let separator = key.lastIndex(of: "_"), separator != key.startIndex {
            let index = key[key.index(after: separator)...]
            if !index.isEmpty && index.utf8.allSatisfy({ (48...57).contains($0) }) {
                return (key[..<separator], index)
            }
        }
        return (key[...], "")
    }

    private func firstSuffixResult<Result>(_ key: String, tryRule: (Selection) -> Result?)
        -> Result?
    {
        guard !key.isEmpty else { return nil }
        let (lemma, index) = Self.lemmaAndIndex(key)
        let marked = "^" + index + "|" + lemma
        var suffix = marked[...]
        while true {
            if let p = find(suffix, section: 3, count: suffixCount, stride: 8),
                let result = tryRule(Selection(lemma: lemma, template: word(p + 4)))
            {
                return result
            }
            if suffix.isEmpty { return nil }
            suffix = suffix[suffix.unicodeScalars.dropFirst().startIndex...]
        }
    }
    func program(template: Int, slot: Int) -> Int {
        let block = word(sections[4] + 4 * (template * width + slot / 16))
        return word(sections[5] + 4 * (16 * block + slot % 16))
    }

    func render(_ selection: Selection, _ slot: Int) -> String? {
        guard (0..<slotCount).contains(slot) else { return nil }
        let id = program(template: selection.template, slot: slot)
        guard id != 0 else { return nil }
        return apply(id, to: selection.lemma)
    }

    /// A short arbitrary input can be shorter than the donor's ending.
    /// In that case treat the input as a stem and apply the donor's affixes.
    func renderFallback(_ lemma: Substring, template: Int, slot: Int) -> String? {
        let id = program(template: template, slot: slot)
        return apply(id, to: lemma, allowShortStem: true)
    }

    private func apply(_ id: Int, to lemma: Substring, allowShortStem: Bool = false) -> String? {
        let ops = record(6, id)
        var out = ""
        for p in stride(from: ops.lowerBound, to: ops.upperBound, by: 12) {
            if p > ops.lowerBound { out += ";" }
            out += string(word(p))
            let trim = word(p + 4)
            if trim != none {
                let scalars = lemma.unicodeScalars
                if let end = scalars.index(
                    scalars.endIndex, offsetBy: -trim, limitedBy: scalars.startIndex)
                {
                    out += lemma[..<end]
                } else if allowShortStem {
                    out += lemma
                } else {
                    return nil
                }
            }
            out += string(word(p + 8))
        }
        return allowShortStem && out.isEmpty ? String(lemma) : out
    }
}
