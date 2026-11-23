import Foundation
import XCTest
@testable import FRConjugation

final class TypedAPIParityTests: XCTestCase {
    private func encode(_ value: String?) -> String {
        guard let value = value else { return "\\N" }
        return value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(
            of: "\t", with: "\\t"
        ).replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\r", with: "\\r")
    }
    func testTypedParity() throws {
        #if SWIFT_PACKAGE
            let bundle = Bundle.module
        #else
            let bundle = Bundle(for: TypedAPIParityTests.self)
        #endif
        let path = ProcessInfo.processInfo.environment["FRCONJUGATION_WRITE_TYPED_FIXTURE"]
        let url =
            try path.map { URL(fileURLWithPath: $0) }
            ?? XCTUnwrap(bundle.url(forResource: "typed-api", withExtension: "tsv"))
        let lines = try String(contentsOf: url, encoding: .utf8).split(separator: "\n").map(
            String.init)
        let c = try Conjugator()
        var output = [lines[0]]
        for line in lines.dropFirst() {
            var row = line.components(separatedBy: "\t")
            XCTAssertEqual(row.count, 10)
            let value = try evaluate(row, c)
            if path != nil {
                row[9] = encode(value)
            } else {
                XCTAssertEqual(encode(value), row[9], "typed case \(row[0])")
            }
            output.append(row.joined(separator: "\t"))
        }
        if path != nil {
            try (output.joined(separator: "\n") + "\n").write(
                to: url, atomically: true, encoding: .utf8)
        }
    }
    private func evaluate(_ r: [String], _ c: Conjugator) throws -> String? {
        let verb = r[2], v = Voice(rawValue: r[3]), m = Mode(rawValue: r[4]),
            t = Tense(rawValue: r[5]), p = Person(rawValue: r[6])
        let h = Int(r[7]) == 0 ? nil : Int(r[7])
        switch r[1] {
        case "all_verbs": return c.allVerbs.joined(separator: ",")
        case "verb_count": return String(c.verbCount)
        case "enum_voice": return Voice.allCases.map(\.rawValue).joined(separator: ",")
        case "enum_mode": return Mode.allCases.map(\.rawValue).joined(separator: ",")
        case "enum_tense": return Tense.allCases.map(\.rawValue).joined(separator: ",")
        case "enum_person": return Person.allCases.map(\.shortLabel).joined(separator: ",")
        case "person_pronouns": return Person.allCases.map(\.pronoun).joined(separator: ",")
        case "has_verb": return c.hasVerb(verb) ? "1" : "0"
        case "has_homonyms": return c.hasHomonyms(verb) ? "1" : "0"
        case "homonym_count": return String(c.homonymCount(verb))
        case "homonym_indices":
            return c.homonymIndices(verb).map(String.init).joined(separator: ",")
        case "h_aspire": return c.isHAspire(verb) ? "1" : "0"
        case "blocking": return c.blocksElisionAndLiaison(verb, homonymIndex: h) ? "1" : "0"
        case "reform": return c.is1990Reform(verb) ? "1" : "0"
        case "variant": return c.reformVariante(verb)
        case "voices": return c.voices(verb, homonymIndex: h).map(\.rawValue).joined(separator: ",")
        case "modes":
            return c.modes(verb, voice: v!, homonymIndex: h).map(\.rawValue).joined(separator: ",")
        case "tenses":
            return c.tenses(verb, voice: v!, mode: m!, homonymIndex: h).map(\.rawValue).joined(
                separator: ",")
        case "persons":
            return c.persons(verb, voice: v!, mode: m!, tense: t!, homonymIndex: h).map(\.rawValue)
                .joined(separator: ",")
        case "alternative":
            return c.conjugateAlternative(
                verb, voice: v!, mode: m!, tense: t!, person: p!, homonymIndex: h)
        case "has_alternative":
            return c.hasAlternativeForm(
                verb, voice: v!, mode: m!, tense: t!, person: p!, homonymIndex: h) ? "1" : "0"
        case "participle_alternative":
            return c.participleAlternative(verb, voice: v!, tense: t!, homonymIndex: h)
        case "has_alternative_participle":
            return c.hasAlternativeParticiple(verb, voice: v!, tense: t!, homonymIndex: h)
                ? "1" : "0"
        case "pronoun":
            return c.getPronoun(verb, voice: v!, mode: m!, tense: t!, person: p!, homonymIndex: h)
        case "with_pronoun":
            return c.conjugateWithPronoun(
                verb, voice: v!, mode: m!, tense: t!, person: p!, homonymIndex: h)
        case "alternative_with_pronoun":
            return c.conjugateAlternativeWithPronoun(
                verb, voice: v!, mode: m!, tense: t!, person: p!, homonymIndex: h)
        default: break
        }
        let raw = r[8] == "inferred", guess = r[8] == "guess"
        if r[1] == "participle" {
            return raw
                ? c.rawInferredParticiple(verb, voice: v!, tense: t!, homonymIndex: h)
                : guess
                    ? c.guessParticiple(verb, voice: v!, tense: t!, homonymIndex: h)
                    : c.participle(verb, voice: v!, tense: t!, homonymIndex: h)
        }
        if r[1] == "gerondif" {
            return raw
                ? c.rawInferredGerondif(verb, voice: v!, tense: t!, homonymIndex: h)
                : guess
                    ? c.guessGerondif(verb, voice: v!, tense: t!, homonymIndex: h)
                    : c.gerondif(verb, voice: v!, tense: t!, homonymIndex: h)
        }
        if r[1] == "participles" {
            let parts =
                raw
                ? c.rawInferredParticiples(verb, voice: v!, homonymIndex: h)
                : guess
                    ? c.guessParticiples(verb, voice: v!, homonymIndex: h)
                    : c.participles(verb, voice: v!, homonymIndex: h)
            return parts.map { "\($0.key.rawValue)=\($0.value)" }.sorted().joined(separator: "\n")
        }
        XCTAssertEqual(r[1], "finite")
        if let p = p {
            return raw
                ? c.rawInferredConjugation(
                    verb, voice: v!, mode: m!, tense: t!, person: p, homonymIndex: h)
                : guess
                    ? c.guessConjugation(
                        verb, voice: v!, mode: m!, tense: t!, person: p, homonymIndex: h)
                    : c.conjugate(verb, voice: v!, mode: m!, tense: t!, person: p, homonymIndex: h)
        }
        var all: [Voice: [Mode: [Tense: [Person: String]]]]?
        if let t = t {
            let x =
                raw
                ? c.rawInferredConjugation(verb, voice: v!, mode: m!, tense: t, homonymIndex: h)
                : guess
                    ? c.guessConjugation(verb, voice: v!, mode: m!, tense: t, homonymIndex: h)
                    : c.conjugate(verb, voice: v!, mode: m!, tense: t, homonymIndex: h)
            all = [v!: [m!: [t: x]]]
        } else if let m = m {
            let x =
                raw
                ? c.rawInferredConjugation(verb, voice: v!, mode: m, homonymIndex: h)
                : guess
                    ? c.guessConjugation(verb, voice: v!, mode: m, homonymIndex: h)
                    : c.conjugate(verb, voice: v!, mode: m, homonymIndex: h)
            all = [v!: [m: x]]
        } else if let v = v {
            let x =
                raw
                ? c.rawInferredConjugation(verb, voice: v, homonymIndex: h)
                : guess
                    ? c.guessConjugation(verb, voice: v, homonymIndex: h)
                    : c.conjugate(verb, voice: v, homonymIndex: h)
            all = [v: x]
        } else {
            all =
                raw
                ? c.rawInferredConjugation(verb, homonymIndex: h)
                : guess
                    ? c.guessConjugation(verb, homonymIndex: h) : c.conjugate(verb, homonymIndex: h)
        }
        guard let all = all else { return nil }
        var lines = [String]()
        for (voice, modes) in all {
            for (mode, tenses) in modes {
                for (tense, persons) in tenses {
                    for (person, value) in persons {
                        lines.append(
                            "\(voice.rawValue)|\(mode.rawValue)|\(tense.rawValue)|\(person.rawValue)=\(value)"
                        )
                    }
                }
            }
        }
        return lines.sorted().joined(separator: "\n")
    }
}
