import Foundation
import FRConjugation

func checkInitializers(path: String, url: URL) throws {
    let instance = try Conjugator()
    _ = Conjugator.defaultCacheSize  // expected-error {{type 'Conjugator' has no member 'defaultCacheSize'}}
    _ = instance.cacheCount  // expected-error {{value of type 'Conjugator' has no member 'cacheCount'}}
    _ = instance.cacheCapacity  // expected-error {{value of type 'Conjugator' has no member 'cacheCapacity'}}
    instance.clearCache()  // expected-error {{value of type 'Conjugator' has no member 'clearCache'}}
    _ = try Conjugator(cacheSize: 0)  // expected-error {{takes no arguments}}
    _ = Conjugator.getShared(cacheSize: 0)  // expected-error {{takes no arguments}}
    _ = Conjugator.getShared()
    _ = try Conjugator(modelDirectory: path)  // expected-error {{takes no arguments}}
    _ = try Conjugator(modelDirectory: url)  // expected-error {{takes no arguments}}
    _ = try Conjugator(modelDirectory: path, cacheSize: 0)  // expected-error {{takes no arguments}}
    _ = try Conjugator(modelDirectory: url, cacheSize: 0)  // expected-error {{takes no arguments}}
}

func checkAsyncLoaders(path: String, url: URL) async throws {
    _ = try await Conjugator.load()
    _ = try await Conjugator.load(cacheSize: 0)  // expected-error {{takes no arguments}}
    _ = try await Conjugator.getShared(cacheSize: 0)  // expected-error {{takes no arguments}}
    _ = try await Conjugator.getShared()
    _ = try await Conjugator.load(modelDirectory: path)  // expected-error {{takes no arguments}}
    _ = try await Conjugator.load(modelDirectory: url)  // expected-error {{takes no arguments}}
    _ = try await Conjugator.load(modelDirectory: path, cacheSize: 0)  // expected-error {{takes no arguments}}
    _ = try await Conjugator.load(modelDirectory: url, cacheSize: 0)  // expected-error {{takes no arguments}}
}
