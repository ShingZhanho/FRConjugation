import Foundation

// Keep the former signatures so migrating callers get a compiler diagnostic at the call site.
extension Conjugator {
    @available(*, unavailable, message: "Use Conjugator() to load the bundled catalogue.")
    public convenience init(modelDirectory path: String) throws {
        throw ConjugationError.modelLoadFailed(path: path)
    }

    @available(*, unavailable, message: "Use Conjugator() to load the bundled catalogue.")
    public convenience init(modelDirectory url: URL) throws {
        throw ConjugationError.modelLoadFailed(path: url.path)
    }

    @available(*, unavailable, message: "Use Conjugator() to load the bundled catalogue.")
    public convenience init(modelDirectory path: String, cacheSize: Int) throws {
        throw ConjugationError.modelLoadFailed(path: path)
    }

    @available(*, unavailable, message: "Use Conjugator() to load the bundled catalogue.")
    public convenience init(modelDirectory url: URL, cacheSize: Int) throws {
        throw ConjugationError.modelLoadFailed(path: url.path)
    }

    @available(*, unavailable, message: "Use Conjugator.load() to load the bundled catalogue.")
    public static func load(modelDirectory path: String) async throws -> Conjugator {
        throw ConjugationError.modelLoadFailed(path: path)
    }

    @available(*, unavailable, message: "Use Conjugator.load() to load the bundled catalogue.")
    public static func load(modelDirectory url: URL) async throws -> Conjugator {
        throw ConjugationError.modelLoadFailed(path: url.path)
    }

    @available(*, unavailable, message: "Use Conjugator.load() to load the bundled catalogue.")
    public static func load(modelDirectory path: String, cacheSize: Int) async throws -> Conjugator {
        throw ConjugationError.modelLoadFailed(path: path)
    }

    @available(*, unavailable, message: "Use Conjugator.load() to load the bundled catalogue.")
    public static func load(modelDirectory url: URL, cacheSize: Int) async throws -> Conjugator {
        throw ConjugationError.modelLoadFailed(path: url.path)
    }
}
