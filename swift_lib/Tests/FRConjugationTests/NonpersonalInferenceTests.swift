import XCTest
import FRConjugation

final class NonpersonalInferenceTests: XCTestCase {
    func testUnknownParticiplesAndGerondifsNeedNoPerson() throws {
        let c = try Conjugator()
        let raw = c.rawInferredParticiples("blorper", voice: .activeAvoir)
        XCTAssertFalse(raw.isEmpty)
        XCTAssertEqual(c.guessParticiples("blorper", voice: .activeAvoir), raw)
        for tense in [Tense.present, .passeFemininPluriel, .passeCompoundFemininSingulier] {
            XCTAssertNotNil(raw[tense])
            XCTAssertEqual(c.rawInferredParticiple("blorper", voice: .activeAvoir, tense: tense), raw[tense])
            XCTAssertEqual(c.guessParticiple("blorper", voice: .activeAvoir, tense: tense), raw[tense])
        }
        let compound = try XCTUnwrap(raw[.passeCompoundFemininPluriel])
        XCTAssertEqual(c.rawInferredGerondif("blorper", voice: .activeAvoir,
            tense: .gerondifPasseFemininPluriel), "en " + compound)
        XCTAssertEqual(c.guessGerondif("blorper", voice: .activeAvoir, tense: .gerondifPresent),
            c.rawInferredGerondif("blorper", voice: .activeAvoir, tense: .gerondifPresent))
        XCTAssertFalse(c.hasVerb("blorper"))
    }

    func testCatalogueCorrectionsAndMissingFormsAreHandledSeparately() throws {
        let c = try Conjugator()
        for tense in [Tense.passeFemininSingulier, .passeMasculinPluriel] {
            _ = c.rawInferredParticiple("enquêter", voice: .activeAvoir, tense: tense)
            XCTAssertEqual(c.guessParticiple("enquêter", voice: .activeAvoir, tense: tense),
                c.participle("enquêter", voice: .activeAvoir, tense: tense))
        }
        let existing = c.participles("entre-nuire", voice: .pronominal)
        let guessed = c.guessParticiples("entre-nuire", voice: .pronominal)
        XCTAssertFalse(existing.isEmpty)
        for (tense, form) in existing { XCTAssertEqual(guessed[tense], form) }
        XCTAssertNil(c.participle("entre-nuire", voice: .pronominal, tense: .present))
        XCTAssertNotNil(guessed[.present])
        XCTAssertEqual(guessed[.present], c.rawInferredParticiple("entre-nuire", voice: .pronominal,
                                                              tense: .present))
        XCTAssertNil(c.gerondif("entre-nuire", voice: .pronominal, tense: .gerondifPresent))
        XCTAssertEqual(c.guessGerondif("entre-nuire", voice: .pronominal, tense: .gerondifPresent),
            c.rawInferredGerondif("entre-nuire", voice: .pronominal, tense: .gerondifPresent))
        XCTAssertEqual(c.guessGerondif("absoudre", voice: .activeAvoir,
            tense: .gerondifPasseMasculinSingulier), c.gerondif("absoudre", voice: .activeAvoir,
                                                            tense: .gerondifPasseMasculinSingulier))
        let variants = try XCTUnwrap(c.rawInferredParticiple("absoudre", voice: .activeAvoir,
                                                           tense: .passeCompoundMasculinSingulier))
        XCTAssertTrue(variants.contains(";"))
        XCTAssertEqual(c.rawInferredGerondif("absoudre", voice: .activeAvoir,
            tense: .gerondifPasseMasculinSingulier), "en " + variants.replacingOccurrences(of: ";", with: ";en "))
        XCTAssertEqual(c.guessParticiple("partir", voice: .activeEtre, tense: .passeFemininPluriel,
            homonymIndex: 2), c.participle("partir", voice: .activeEtre, tense: .passeFemininPluriel,
                                          homonymIndex: 2))
    }

    func testWrongFamiliesAndUnsupportedInputReturnNil() throws {
        let c = try Conjugator()
        for tense in [Tense.imparfait, .gerondifPresent] {
            XCTAssertNil(c.rawInferredParticiple("blorper", voice: .activeAvoir, tense: tense))
            XCTAssertNil(c.guessParticiple("blorper", voice: .activeAvoir, tense: tense))
        }
        XCTAssertNil(c.rawInferredGerondif("blorper", voice: .activeAvoir, tense: .passeMasculinSingulier))
        XCTAssertNil(c.guessGerondif("blorper", voice: .activeAvoir, tense: .present))
        XCTAssertNil(c.rawInferredParticiple("🙂", voice: .activeAvoir, tense: .present))
        XCTAssertNil(c.guessGerondif("", voice: .activeAvoir, tense: .gerondifPresent))
    }

    func testAsyncSingleFormAPIsMatchTheirFamilies() async throws {
        let c = try Conjugator()
        let rawPart = await c.rawInferredParticiple("blorper", voice: .activeAvoir, tense: .present)
        let guessPart = await c.guessParticiple("blorper", voice: .activeAvoir, tense: .present)
        let rawGerondif = await c.rawInferredGerondif("blorper", voice: .activeAvoir, tense: .gerondifPresent)
        let guessGerondif = await c.guessGerondif("blorper", voice: .activeAvoir, tense: .gerondifPresent)
        XCTAssertNotNil(rawPart)
        XCTAssertEqual(rawPart, guessPart)
        XCTAssertEqual(rawGerondif, "en " + (try XCTUnwrap(rawPart)))
        XCTAssertEqual(rawGerondif, guessGerondif)
    }
}
