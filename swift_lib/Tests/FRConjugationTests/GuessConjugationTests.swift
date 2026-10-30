import Foundation
import XCTest
@testable import FRConjugation

final class GuessConjugationTests: XCTestCase {
    func testUnknownAndArbitraryStringsKeepCatalogueLookupsUnchanged() throws {
        let c = try Conjugator()
        for input in ["blorper", "bonjour", "télétravailler"] {
            XCTAssertFalse(c.hasVerb(input))
            let raw = try XCTUnwrap(c.rawInferredConjugation(input, voice: .activeAvoir,
                mode: .indicatif, tense: .present, person: .firstSingularMasculine))
            XCTAssertEqual(c.guessConjugation(input, voice: .activeAvoir, mode: .indicatif,
                tense: .present, person: .firstSingularMasculine), raw)
            XCTAssertNil(c.conjugate(input, voice: .activeAvoir, mode: .indicatif,
                tense: .present, person: .firstSingularMasculine))
            XCTAssertFalse(c.hasVerb(input))
        }
        XCTAssertEqual(c.rawInferredConjugation("  BLORPER\n", voice: .activeAvoir,
            mode: .indicatif, tense: .present, person: .firstSingularMasculine),
            c.rawInferredConjugation("blorper", voice: .activeAvoir,
                mode: .indicatif, tense: .present, person: .firstSingularMasculine))
        for input in ["", " \n", "blorp🙂er", "动词"] {
            XCTAssertNil(c.rawInferredConjugation(input))
            XCTAssertNil(c.guessConjugation(input))
        }
        XCTAssertTrue(c.rawInferredConjugation("blorper", voice: .activeAvoir,
            mode: .conditionnel, tense: .imparfait).isEmpty)
        XCTAssertTrue(c.guessConjugation("blorper", voice: .activeAvoir,
            mode: .conditionnel, tense: .imparfait).isEmpty)
    }

    func testCollectionOverloadsAndFiniteScope() throws {
        let c = try Conjugator()
        let allRaw = try XCTUnwrap(c.rawInferredConjugation("blorper"))
        XCTAssertEqual(allRaw.count, Voice.allCases.count)
        XCTAssertEqual(c.guessConjugation("blorper"), allRaw)
        for voice in Voice.allCases {
            XCTAssertEqual(c.rawInferredConjugation("blorper", voice: voice), allRaw[voice])
            XCTAssertEqual(c.guessConjugation("blorper", voice: voice), allRaw[voice])
        }
        let tenses = c.rawInferredConjugation("blorper", voice: .activeAvoir, mode: .indicatif)
        XCTAssertEqual(tenses, allRaw[.activeAvoir]?[.indicatif])
        XCTAssertEqual(c.guessConjugation("blorper", voice: .activeAvoir, mode: .indicatif), tenses)
        let persons = c.rawInferredConjugation("blorper", voice: .activeAvoir,
                                               mode: .indicatif, tense: .present)
        XCTAssertEqual(persons, tenses[.present])
        XCTAssertEqual(c.guessConjugation("blorper", voice: .activeAvoir,
            mode: .indicatif, tense: .present), persons)
        XCTAssertEqual(persons[.firstSingularMasculine], c.rawInferredConjugation("blorper",
            voice: .activeAvoir, mode: .indicatif, tense: .present, person: .firstSingularMasculine))

        XCTAssertNil(allRaw[.activeAvoir]?[.participe])
        XCTAssertNil(c.rawInferredConjugation("blorper", voice: .activeAvoir,
            mode: .participe, tense: .present, person: .firstSingularMasculine))
        XCTAssertTrue(c.guessConjugation("blorper", voice: .activeAvoir,
            mode: .participe, tense: .present).isEmpty)
    }

    func testCatalogueAnswersAndMissingSlotsAreMergedPerForm() throws {
        let c = try Conjugator()
        let existing = c.conjugate("falloir", voice: .activeAvoir, mode: .indicatif, tense: .present)
        let merged = c.guessConjugation("falloir", voice: .activeAvoir, mode: .indicatif, tense: .present)
        XCTAssertFalse(existing.isEmpty)
        for (person, form) in existing { XCTAssertEqual(merged[person], form) }
        XCTAssertNil(existing[.firstSingularMasculine])
        XCTAssertNotNil(merged[.firstSingularMasculine])
        XCTAssertEqual(merged[.firstSingularMasculine], c.rawInferredConjugation("falloir",
            voice: .activeAvoir, mode: .indicatif, tense: .present, person: .firstSingularMasculine))
        let all = try XCTUnwrap(c.conjugate("falloir"))
        let guessed = try XCTUnwrap(c.guessConjugation("falloir"))
        for (voice, modes) in all {
            for (mode, tenses) in modes {
                for (tense, persons) in tenses {
                    for (person, form) in persons {
                        XCTAssertEqual(guessed[voice]?[mode]?[tense]?[person], form)
                    }
                }
            }
        }
    }

    func testCorrectionCacheAndHomonymSelectionStaySeparateFromRawPredictions() throws {
        let c = try Conjugator()
        for _ in 0..<2 {
            _ = c.rawInferredConjugation("faire", voice: .pronominal, mode: .subjonctif,
                tense: .present, person: .thirdPluralFeminine)
            XCTAssertEqual(c.guessConjugation("faire", voice: .pronominal, mode: .subjonctif,
                tense: .present, person: .thirdPluralFeminine), "se fassent")
            XCTAssertEqual(c.conjugate("faire", voice: .pronominal, mode: .subjonctif,
                tense: .present, person: .thirdPluralFeminine), "se fassent")
            c.clearCache()
        }
        for index in [1, 2] {
            XCTAssertEqual(c.guessConjugation("ressortir", voice: .activeAvoir,
                mode: .indicatif, tense: .present, person: .firstSingularMasculine, homonymIndex: index),
                c.conjugate("ressortir", voice: .activeAvoir, mode: .indicatif,
                    tense: .present, person: .firstSingularMasculine, homonymIndex: index))
            XCTAssertEqual(c.rawInferredConjugation("ressortir", voice: .activeAvoir,
                mode: .indicatif, tense: .present, person: .firstSingularMasculine, homonymIndex: index),
                c.rawInferredConjugation("ressortir_\(index)", voice: .activeAvoir,
                    mode: .indicatif, tense: .present, person: .firstSingularMasculine))
        }
    }

    func testAsyncOverloadsMatchSingleAndCollectionLookups() async throws {
        let c = try Conjugator()
        let raw = await c.rawInferredConjugation("blorper", voice: .activeAvoir,
            mode: .indicatif, tense: .present, person: .firstSingularMasculine)
        let raws = await c.rawInferredConjugation("blorper", voice: .activeAvoir,
            mode: .indicatif, tense: .present)
        let guess = await c.guessConjugation("blorper", voice: .activeAvoir,
            mode: .indicatif, tense: .present, person: .firstSingularMasculine)
        let guesses = await c.guessConjugation("blorper", voice: .activeAvoir,
            mode: .indicatif, tense: .present)
        XCTAssertNotNil(raw)
        XCTAssertEqual(raw, raws[.firstSingularMasculine])
        XCTAssertEqual(guess, raw)
        XCTAssertEqual(guesses, raws)
        let known = await c.guessConjugation("ressortir", voice: .activeAvoir,
            mode: .indicatif, tense: .present, person: .firstSingularMasculine, homonymIndex: 2)
        XCTAssertEqual(known, "ressortis")
    }

    /// Measurement is opt-in: raw neural accuracy is evidence, not a 100% contract.
    func testGuessEvaluation() throws {
        guard let output = ProcessInfo.processInfo.environment["FRCONJ_GUESS_REPORT"] else {
            throw XCTSkip("Set FRCONJ_GUESS_REPORT to record the fixed evaluation.")
        }
        let repository = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let fixture = repository.appendingPathComponent("Evaluations/GuessConjugation/cases.json")
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: fixture)) as? [String: Any])
        let cases = try XCTUnwrap(root["cases"] as? [[String: Any]])
        let c = try Conjugator(cacheSize: 0)
        var results = [[String: Any]]()
        let start = Date()
        for item in cases {
            let input = try XCTUnwrap(item["input"] as? String)
            let voice = try XCTUnwrap(Voice(rawValue: try XCTUnwrap(item["voice"] as? String)))
            let mode = try XCTUnwrap(Mode(rawValue: try XCTUnwrap(item["mode"] as? String)))
            let tense = try XCTUnwrap(Tense(rawValue: try XCTUnwrap(item["tense"] as? String)))
            let person = (item["person"] as? String).flatMap(Person.init(rawValue:)) ?? .firstSingularMasculine
            let expected = try XCTUnwrap(item["expected"] as? String)
            let known = c.hasVerb(input)
            if item["category"] as? String == "unseen_dictionary" { XCTAssertFalse(known, input) }
            let raw: String?
            let catalogue: String?
            let guess: String?
            if mode == .participe {
                raw = c.rawInferredParticiple(input, voice: voice, tense: tense)
                catalogue = c.participle(input, voice: voice, tense: tense)
                guess = c.guessParticiple(input, voice: voice, tense: tense)
            } else {
                raw = c.rawInferredConjugation(input, voice: voice, mode: mode,
                                               tense: tense, person: person)
                catalogue = c.conjugate(input, voice: voice, mode: mode, tense: tense, person: person)
                guess = c.guessConjugation(input, voice: voice, mode: mode, tense: tense, person: person)
            }
            XCTAssertEqual(guess, catalogue ?? raw)
            var result = item
            result["known"] = known
            result["prediction"] = raw as Any? ?? NSNull()
            result["cataloguePrediction"] = catalogue as Any? ?? NSNull()
            result["guessPrediction"] = guess as Any? ?? NSNull()
            result["guessSource"] = catalogue == nil ? "raw_fallback" : "catalogue"
            result["exact"] = raw == expected
            let accepted = expected.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }
            let first = raw?.components(separatedBy: ";").first?.trimmingCharacters(in: .whitespaces)
            result["primaryAccepted"] = first.map { accepted.contains($0) } ?? false
            result["guessPrimaryAccepted"] = guess?.components(separatedBy: ";").first.map {
                accepted.contains($0.trimmingCharacters(in: .whitespaces))
            } ?? false
            results.append(result)
        }
        let engine = try InferenceEngine(modelDirectory: URL(fileURLWithPath:
            try XCTUnwrap(ConjugationTests.modelDir)))
        var coverage = [[String: Any]]()
        for slot in engine.supportedGuessForms.sorted() {
            let keys = slot.components(separatedBy: "|")
            let voice = try XCTUnwrap(Voice(rawValue: keys[0]))
            let mode = try XCTUnwrap(Mode(rawValue: keys[1]))
            let tense = try XCTUnwrap(Tense(rawValue: keys[2]))
            let person = Person(rawValue: keys[3]) ?? .firstSingularMasculine
            let prediction = mode == .participe
                ? c.rawInferredParticiple("blorper", voice: voice, tense: tense)
                : c.rawInferredConjugation("blorper", voice: voice, mode: mode,
                                            tense: tense, person: person)
            coverage.append(["slot": slot, "prediction": prediction as Any? ?? NSNull()])
        }
        let report: [String: Any] = ["measuredAt": ISO8601DateFormatter().string(from: Date()),
            "referenceDate": root["date"] ?? "", "elapsedSeconds": Date().timeIntervalSince(start),
            "cases": results, "coverageInput": "blorper", "coverage": coverage,
            "method": root["method"] ?? ""]
        try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
            .write(to: URL(fileURLWithPath: output), options: .atomic)
        XCTAssertEqual(results.count, cases.count)
    }
}
