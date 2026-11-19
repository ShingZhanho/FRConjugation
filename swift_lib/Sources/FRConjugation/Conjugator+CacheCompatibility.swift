import Foundation

extension Conjugator {
    /// Historical default accepted by the cache-size overloads.
    @available(*, deprecated, message: "Omit the cacheSize argument. The rule engine has no prediction cache.")
    public static let defaultCacheSize = 64

    @available(*, deprecated, message: "Use Conjugator() and omit the cache size.")
    public convenience init(cacheSize: Int = defaultCacheSize) throws {
        try self.init()
    }

    @available(*, deprecated, message: "Use getShared() and omit the cache size.")
    public static func getShared(cacheSize: Int = defaultCacheSize) -> Conjugator {
        getShared()
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @available(*, deprecated, message: "Use getShared() and omit the cache size.")
    public static func getShared(cacheSize: Int = defaultCacheSize) async throws -> Conjugator {
        try await getShared()
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @available(*, deprecated, message: "Use load() and omit the cache size.")
    public static func load(cacheSize: Int = defaultCacheSize) async throws -> Conjugator {
        try await load()
    }

    @available(*, deprecated, message: "The rule engine has no prediction cache. This value is always zero.")
    public var cacheCount: Int { 0 }

    @available(*, deprecated, message: "The rule engine has no prediction cache. This value is always zero.")
    public var cacheCapacity: Int { 0 }

    @available(*, deprecated, message: "Remove the clearCache() call. The rule engine has no prediction cache.")
    public func clearCache() {}
}
