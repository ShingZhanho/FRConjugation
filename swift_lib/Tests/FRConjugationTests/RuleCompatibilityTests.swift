import XCTest
import FRConjugation

final class RuleCompatibilityTests: XCTestCase {
    @available(*, deprecated, message: "Exercises the legacy cache API.")
    func testCacheCompatibilityAndSharedIdentity() throws {
        XCTAssertEqual(Conjugator.defaultCacheSize, 64)
        XCTAssertTrue(Conjugator.getShared(cacheSize: 32) === Conjugator.getShared(cacheSize: 0))
        for size in [-1, 0, 256] {
            let c = try Conjugator(cacheSize: size)
            XCTAssertEqual(c.cacheCapacity, 0)
            let first = c.gerondif("manger", voice: .activeAvoir, tense: .gerondifPresent)
            XCTAssertEqual(first, "en mangeant")
            XCTAssertNotNil(c.guessParticiple("blorper", voice: .activeAvoir, tense: .present))
            XCTAssertEqual(c.cacheCount, 0)
            c.clearCache()
            XCTAssertEqual(c.cacheCount, 0)
            XCTAssertEqual(c.gerondif("manger", voice: .activeAvoir, tense: .gerondifPresent), first)
        }
    }

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

    @available(*, deprecated, message: "Exercises the legacy cache API.")
    func testAsyncBundledLoadersAndSharedIdentity() async throws {
        let shared = try await Conjugator.getShared(cacheSize: 100)
        let independent = try await Conjugator.load(cacheSize: 42)
        let bundled = try await Conjugator.load()
        let singleton = try await Conjugator.getShared()
        XCTAssertTrue(shared === singleton)
        XCTAssertFalse(bundled === singleton)
        for c in [bundled, independent, shared] {
            XCTAssertEqual(c.cacheCapacity, 0)
            let form = await c.conjugate("manger", voice: .activeAvoir, mode: .indicatif,
                                         tense: .present, person: .firstPluralMasculine)
            XCTAssertEqual(form, "mangeons")
        }
        let again = try await Conjugator.getShared(cacheSize: 0)
        XCTAssertTrue(shared === again)
    }
}
