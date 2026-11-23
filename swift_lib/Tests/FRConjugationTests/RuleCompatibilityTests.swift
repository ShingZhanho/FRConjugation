import XCTest
import FRConjugation

final class RuleCompatibilityTests: XCTestCase {
    func testGlobalSlotCoverageIncludingOneCharacterInputs() throws {
        let c = Conjugator.getShared()
        for input in ["x", "er", "_", "blorper"] {
            let all = try XCTUnwrap(c.rawInferredConjugation(input))
            let finite = all.values.flatMap { $0.values }.flatMap { $0.values }.flatMap { $0.values }
            let participles = Voice.allCases.flatMap { c.rawInferredParticiples(input, voice: $0).values }
            XCTAssertEqual(finite.count + participles.count, 820, input)
            XCTAssertTrue((finite + participles).allSatisfy { !$0.isEmpty }, input)
            XCTAssertNil(c.conjugate(input))
        }
    }

    func testBundledLoadersAndSharedIdentity() async throws {
        let getSharedSync: () -> Conjugator = Conjugator.getShared
        let shared = try await Conjugator.getShared()
        XCTAssertTrue(shared === getSharedSync())

        let first = try Conjugator()
        let second = try await Conjugator.load()
        XCTAssertFalse(first === shared)
        XCTAssertFalse(second === shared)
        XCTAssertFalse(first === second)
        for conjugator in [first, second, shared] {
            let form = await conjugator.conjugate("manger", voice: .activeAvoir, mode: .indicatif,
                                                  tense: .present, person: .firstPluralMasculine)
            XCTAssertEqual(form, "mangeons")
        }
    }
}
