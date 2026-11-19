import Foundation
import FRConjugation

func checkInitializers(path: String, url: URL) throws {
    _ = try Conjugator()
    _ = Conjugator.getShared()
    _ = try Conjugator(modelDirectory: path) // expected-error {{'init(modelDirectory:)' is unavailable}}
    _ = try Conjugator(modelDirectory: url) // expected-error {{'init(modelDirectory:)' is unavailable}}
    _ = try Conjugator(modelDirectory: path, cacheSize: 0) // expected-error {{'init(modelDirectory:cacheSize:)' is unavailable}}
    _ = try Conjugator(modelDirectory: url, cacheSize: 0) // expected-error {{'init(modelDirectory:cacheSize:)' is unavailable}}
}

func checkAsyncLoaders(path: String, url: URL) async throws {
    _ = try await Conjugator.load()
    _ = try await Conjugator.getShared()
    _ = try await Conjugator.load(modelDirectory: path) // expected-error {{'load(modelDirectory:)' is unavailable}}
    _ = try await Conjugator.load(modelDirectory: url) // expected-error {{'load(modelDirectory:)' is unavailable}}
    _ = try await Conjugator.load(modelDirectory: path, cacheSize: 0) // expected-error {{'load(modelDirectory:cacheSize:)' is unavailable}}
    _ = try await Conjugator.load(modelDirectory: url, cacheSize: 0) // expected-error {{'load(modelDirectory:cacheSize:)' is unavailable}}
}
