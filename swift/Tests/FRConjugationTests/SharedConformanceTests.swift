import Foundation
import XCTest
@testable import FRConjugation

final class SharedConformanceTests: XCTestCase {
    private func decode(_ text: String) throws -> String? {
        if text == "\\N" { return nil }
        var result = ""
        var chars = text.makeIterator()
        while let char = chars.next() {
            if char != "\\" { result.append(char); continue }
            switch chars.next() {
            case "n": result.append("\n")
            case "r": result.append("\r")
            case "t": result.append("\t")
            case "\\": result.append("\\")
            default: throw FixtureError.invalid("Invalid escape")
            }
        }
        return result
    }
    private enum FixtureError: Error { case invalid(String) }

    func testSharedCases() throws {
        #if SWIFT_PACKAGE
            let bundle = Bundle.module
        #else
            let bundle = Bundle(for: SharedConformanceTests.self)
        #endif
        let url = try XCTUnwrap(bundle.url(forResource: "conformance", withExtension: "tsv"))
        let text = try String(contentsOf: url, encoding: .utf8)
        var lines = text.components(separatedBy: "\n")
        if lines.last == "" { lines.removeLast() }
        XCTAssertEqual(
            lines.first, "id\toperation\tmode\tverb\tselector\thomonym\tspelling\texpected")
        XCTAssertGreaterThan(lines.count, 1)
        let c = try Conjugator()
        var ids = Set<String>()
        for line in lines.dropFirst() {
            let row = line.components(separatedBy: "\t")
            guard row.count == 8, ids.insert(row[0]).inserted else {
                throw FixtureError.invalid("Invalid or duplicate fixture row")
            }
            let actual = try evaluate(row, c)
            XCTAssertEqual(actual, try decode(row[7]), "Conformance case \(row[0])")
        }
    }
    private func evaluate(_ row: [String], _ c: Conjugator) throws -> String? {
        guard ["form", "prefix", "pronoun", "with_pronoun", "gerondif"].contains(row[1]) else {
            throw FixtureError.invalid("Unknown operation")
        }
        let verb = try XCTUnwrap(decode(row[3]))
        let selector = try XCTUnwrap(decode(row[4])).components(separatedBy: "|")
        let index = try XCTUnwrap(Int(row[5]))
        let homonym = index == 0 ? nil : index
        guard ["catalogue", "inferred", "guess"].contains(row[2]),
            ["primary", "alternative"].contains(row[6])
        else {
            throw FixtureError.invalid("Invalid prediction or spelling")
        }
        if row[1] == "prefix" {
            switch row[2] {
            case "catalogue": return c.commonPrefix(verb, homonymIndex: homonym)
            case "inferred": return c.rawInferredCommonPrefix(verb, homonymIndex: homonym)
            default: return c.guessCommonPrefix(verb, homonymIndex: homonym)
            }
        }
        // Unknown slot labels intentionally produce missing results in all APIs.
        guard selector.count == 2 || selector.count == 4,
            let voice = Voice(rawValue: selector[0])
        else { return nil }
        if row[1] == "gerondif" {
            guard let tense = Tense(rawValue: selector[1]) else { return nil }
            switch row[2] {
            case "catalogue":
                return c.gerondif(verb, voice: voice, tense: tense, homonymIndex: homonym)
            case "inferred":
                return c.rawInferredGerondif(
                    verb, voice: voice, tense: tense, homonymIndex: homonym)
            default: return c.guessGerondif(verb, voice: voice, tense: tense, homonymIndex: homonym)
            }
        }
        guard selector.count == 4, let mode = Mode(rawValue: selector[1]),
            let tense = Tense(rawValue: selector[2])
        else { return nil }
        if row[1] == "form" && mode == .participe {
            switch row[2] {
            case "inferred":
                return c.rawInferredParticiple(
                    verb, voice: voice, tense: tense, homonymIndex: homonym)
            case "guess":
                return c.guessParticiple(verb, voice: voice, tense: tense, homonymIndex: homonym)
            default:
                return row[6] == "primary"
                    ? c.participle(verb, voice: voice, tense: tense, homonymIndex: homonym)
                    : c.participleAlternative(
                        verb, voice: voice, tense: tense, homonymIndex: homonym)
            }
        }
        guard let person = Person(rawValue: selector[3]) else { return nil }
        switch row[1] {
        case "form":
            switch row[2] {
            case "inferred":
                return c.rawInferredConjugation(
                    verb, voice: voice, mode: mode, tense: tense, person: person,
                    homonymIndex: homonym)
            case "guess":
                return c.guessConjugation(
                    verb, voice: voice, mode: mode, tense: tense, person: person,
                    homonymIndex: homonym)
            default:
                return row[6] == "primary"
                    ? c.conjugate(
                        verb, voice: voice, mode: mode, tense: tense, person: person,
                        homonymIndex: homonym)
                    : c.conjugateAlternative(
                        verb, voice: voice, mode: mode, tense: tense, person: person,
                        homonymIndex: homonym)
            }
        case "pronoun":
            guard row[6] == "primary" else {
                throw FixtureError.invalid("Swift pronoun selection requires primary spelling")
            }
            return c.getPronoun(
                verb, voice: voice, mode: mode, tense: tense, person: person, homonymIndex: homonym)
        case "with_pronoun":
            return row[6] == "primary"
                ? c.conjugateWithPronoun(
                    verb, voice: voice, mode: mode, tense: tense, person: person,
                    homonymIndex: homonym)
                : c.conjugateAlternativeWithPronoun(
                    verb, voice: voice, mode: mode, tense: tense, person: person,
                    homonymIndex: homonym)
        default: throw FixtureError.invalid("Unknown operation")
        }
    }
}
