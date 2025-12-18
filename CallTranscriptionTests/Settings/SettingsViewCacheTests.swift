import XCTest
@testable import CallTranscription

/// Tests for shortcut caching behavior in SettingsView
/// These tests verify that shortcuts are not reloaded on every Settings view appearance
@MainActor
final class SettingsViewCacheTests: XCTestCase {
    var sut: SettingsViewCache!

    override func setUp() {
        super.setUp()
        sut = SettingsViewCache()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Cache Expiry Tests

    func testCacheInitiallyExpired() {
        // Given: A fresh cache instance
        // When: Checking if cache is valid
        // Then: Cache should be expired (needs loading)
        XCTAssertTrue(sut.isCacheExpired(), "Fresh cache should be expired")
    }

    func testCacheNotExpiredWithinTimeout() {
        // Given: Cache was just updated
        sut.updateCache(shortcuts: ["Shortcut1", "Shortcut2"])

        // When: Checking immediately after update
        // Then: Cache should not be expired
        XCTAssertFalse(sut.isCacheExpired(), "Cache should not be expired immediately after update")
    }

    func testCacheExpiresAfterTimeout() {
        // Given: Cache with a very short timeout (1 second for testing)
        sut = SettingsViewCache(cacheTimeout: 1.0)
        sut.updateCache(shortcuts: ["Shortcut1"])

        // When: Waiting for cache to expire
        let expectation = self.expectation(description: "Cache expires")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            // Then: Cache should be expired
            XCTAssertTrue(self.sut.isCacheExpired(), "Cache should be expired after timeout")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Cache Data Tests

    func testUpdateCacheStoresShortcuts() {
        // Given: A list of shortcuts
        let shortcuts = ["Shortcut A", "Shortcut B", "Shortcut C"]

        // When: Updating the cache
        sut.updateCache(shortcuts: shortcuts)

        // Then: Cache should return the stored shortcuts
        XCTAssertEqual(sut.getCachedShortcuts(), shortcuts, "Cache should store and return shortcuts")
    }

    func testGetCachedShortcutsReturnsEmptyArrayWhenNoData() {
        // Given: A fresh cache with no data
        // When: Getting cached shortcuts
        let cached = sut.getCachedShortcuts()

        // Then: Should return empty array
        XCTAssertEqual(cached, [], "Cache should return empty array when no data stored")
    }

    func testUpdateCacheReplacesOldData() {
        // Given: Cache with initial shortcuts
        sut.updateCache(shortcuts: ["Old1", "Old2"])

        // When: Updating with new shortcuts
        let newShortcuts = ["New1", "New2", "New3"]
        sut.updateCache(shortcuts: newShortcuts)

        // Then: Cache should return new shortcuts, not old ones
        XCTAssertEqual(sut.getCachedShortcuts(), newShortcuts, "Cache should replace old data with new data")
    }

    // MARK: - Cache Invalidation Tests

    func testInvalidateCacheSetsExpiry() {
        // Given: Cache with valid data
        sut.updateCache(shortcuts: ["Shortcut1"])
        XCTAssertFalse(sut.isCacheExpired())

        // When: Invalidating the cache
        sut.invalidateCache()

        // Then: Cache should be expired
        XCTAssertTrue(sut.isCacheExpired(), "Invalidated cache should be expired")
    }

    func testInvalidateCachePreservesData() {
        // Given: Cache with shortcuts
        let shortcuts = ["Shortcut1", "Shortcut2"]
        sut.updateCache(shortcuts: shortcuts)

        // When: Invalidating the cache
        sut.invalidateCache()

        // Then: Data should still be accessible (though marked expired)
        XCTAssertEqual(sut.getCachedShortcuts(), shortcuts, "Invalidation should preserve data")
    }

    // MARK: - Default Timeout Tests

    func testDefaultTimeoutIs60Seconds() {
        // Given: A cache with default timeout
        let cache = SettingsViewCache()

        // When: Getting the timeout value
        // Then: Should be 60 seconds
        XCTAssertEqual(cache.cacheTimeout, 60.0, "Default cache timeout should be 60 seconds")
    }

    // MARK: - Thread Safety Tests

    func testConcurrentUpdatesCacheData() {
        // Given: Multiple concurrent updates
        let expectation1 = expectation(description: "Update 1")
        let expectation2 = expectation(description: "Update 2")

        // When: Updating cache from different threads
        DispatchQueue.global().async {
            self.sut.updateCache(shortcuts: ["A", "B"])
            expectation1.fulfill()
        }

        DispatchQueue.global().async {
            self.sut.updateCache(shortcuts: ["C", "D"])
            expectation2.fulfill()
        }

        wait(for: [expectation1, expectation2], timeout: 1.0)

        // Then: Cache should have one of the values (no crash)
        let cached = sut.getCachedShortcuts()
        XCTAssertTrue(cached == ["A", "B"] || cached == ["C", "D"],
                      "Cache should handle concurrent updates without crashing")
    }
}
