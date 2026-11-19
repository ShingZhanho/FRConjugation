import Foundation
import XCTest
import FRConjugation

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

    func testCatalogueAnswersAndHomonymSelectionAfterRawInference() throws {
        let c = try Conjugator()
        _ = c.rawInferredConjugation("faire", voice: .pronominal, mode: .subjonctif,
            tense: .present, person: .thirdPluralFeminine)
        XCTAssertEqual(c.guessConjugation("faire", voice: .pronominal, mode: .subjonctif,
            tense: .present, person: .thirdPluralFeminine), "se fassent")
        XCTAssertEqual(c.conjugate("faire", voice: .pronominal, mode: .subjonctif,
            tense: .present, person: .thirdPluralFeminine), "se fassent")
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
}
