import Foundation

/// Cache for shortcuts list in SettingsView to avoid reloading on every appearance
@MainActor
final class SettingsViewCache {
    private var cachedShortcuts: [String] = []
    private var cacheExpiry: Date = .distantPast
    let cacheTimeout: TimeInterval

    init(cacheTimeout: TimeInterval = 60.0) {
        self.cacheTimeout = cacheTimeout
    }

    /// Check if the cache has expired
    func isCacheExpired() -> Bool {
        return Date() > cacheExpiry
    }

    /// Update the cache with new shortcuts and reset expiry
    func updateCache(shortcuts: [String]) {
        cachedShortcuts = shortcuts
        cacheExpiry = Date().addingTimeInterval(cacheTimeout)
    }

    /// Get cached shortcuts (returns empty array if no data)
    func getCachedShortcuts() -> [String] {
        return cachedShortcuts
    }

    /// Invalidate the cache (mark as expired but preserve data)
    func invalidateCache() {
        cacheExpiry = .distantPast
    }
}
