import XCTest
@testable import FRConjugation

final class CommonPrefixTests: XCTestCase {
    func testCataloguePrefixesAcrossAllTenses() {
        let conjugator = Conjugator.getShared()
        let examples = [
            "manger": "mang", "finir": "fin", "céder": "c", "payer": "pa",
            "venir": "v", "prendre": "pr", "battre": "bat",
            "écrire": "écri", "aller": "", "être": "", "avoir": ""
        ]
        for (verb, expected) in examples {
            XCTAssertEqual(conjugator.commonPrefix(verb), expected, verb)
        }
        XCTAssertNil(conjugator.commonPrefix("blorper"))
        XCTAssertNil(conjugator.commonPrefix(""))
        XCTAssertNil(conjugator.commonPrefix(" MANGER "))
    }

    func testMainVerbExtraction() {
        let examples = [
            "aurions été mangées": "mangées",
            "viens-t'en": "viens",
            "allons-nous-en": "allons",
            "s’habille": "habille",
            "entre-bâille": "entre-bâille",
            "s’entr’ouvre": "entr’ouvre",
            "entr'ouvre": "entr'ouvre",
            "cédé": "cédé"
        ]
        for (phrase, expected) in examples {
            XCTAssertEqual(Conjugator.mainVerbWord(phrase), expected)
        }
        XCTAssertNil(Conjugator.mainVerbWord("  "))
    }

    func testPredictionAndHybridAgainstPublicForms() {
        let conjugator = Conjugator.getShared()
        for verb in ["blorper", "x", " MANGER ", "pleuvoir", "ressortir"] {
            for hybrid in [false, true] {
                var words: [String] = []
                for voice in Voice.allCases {
                    for mode in Mode.allCases {
                        for tense in Tense.allCases {
                            let people: [Person?] = mode == .participe ? [nil] : Person.allCases.map { $0 }
                            for person in people {
                                var raw: String?
                                if hybrid {
                                    if let person = person {
                                        raw = conjugator.conjugate(verb, voice: voice, mode: mode,
                                            tense: tense, person: person)
                                        if let alternative = conjugator.conjugateAlternative(verb,
                                            voice: voice, mode: mode, tense: tense, person: person) {
                                            raw = raw.map { $0 + ";" + alternative }
                                        }
                                    } else {
                                        // Catalogue alternatives are tested by the catalogue fixtures above.
                                        raw = conjugator.participle(verb, voice: voice, tense: tense)
                                    }
                                }
                                if raw == nil {
                                    if let person = person {
                                        raw = conjugator.rawInferredConjugation(verb, voice: voice,
                                            mode: mode, tense: tense, person: person)
                                    } else {
                                        raw = conjugator.rawInferredParticiple(verb, voice: voice, tense: tense)
                                    }
                                }
                                words += (raw ?? "").split(separator: ";").compactMap {
                                    Conjugator.mainVerbWord(String($0))
                                }
                            }
                        }
                    }
                }
                let shortest = words.min { $0.count < $1.count }!
                var expected = shortest
                while !words.allSatisfy({ $0.hasPrefix(expected) }) {
                    expected.removeLast()
                }
                let actual = hybrid ? conjugator.guessCommonPrefix(verb)
                    : conjugator.rawInferredCommonPrefix(verb)
                XCTAssertEqual(actual, expected, "\(verb), hybrid \(hybrid)")
            }
        }
        for input in ["", "  ", "🙂"] {
            XCTAssertNil(conjugator.rawInferredCommonPrefix(input))
            XCTAssertNil(conjugator.guessCommonPrefix(input))
        }
        XCTAssertEqual(conjugator.commonPrefix("ressortir", homonymIndex: 2),
                       conjugator.commonPrefix("ressortir_2"))
        XCTAssertEqual(conjugator.rawInferredCommonPrefix(" BLORPER "),
                       conjugator.rawInferredCommonPrefix("blorper"))
    }

    func testAsyncPrefixes() async {
        let conjugator = try! Conjugator()
        let known = await conjugator.commonPrefix("manger")
        let raw = await conjugator.rawInferredCommonPrefix("blorper")
        let guess = await conjugator.guessCommonPrefix("blorper")
        XCTAssertEqual(known, "mang")
        XCTAssertNotNil(raw)
        XCTAssertEqual(raw, guess)
    }
}
