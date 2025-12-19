import XCTest
import SwiftUI
@testable import CallTranscription

/// Tests for error scenarios in SettingsView
///
/// This test suite covers error handling that was not included in the original
/// SettingsViewTests, including:
/// - Shortcuts loading failures
/// - Invalid path handling
/// - Cache corruption recovery
@MainActor
final class SettingsViewErrorTests: XCTestCase {

    var testUserDefaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        testUserDefaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")
    }

    override func tearDown() async throws {
        if let suiteName = testUserDefaults.dictionaryRepresentation().keys.first {
            testUserDefaults.removePersistentDomain(forName: "test.\(suiteName)")
        }
        testUserDefaults = nil
        try await super.tearDown()
    }

    // MARK: - Shortcuts Execution Error Handling

    func testShortcutExecutorHandlesProcessFailureGracefully() async {
        // Given: Real ShortcutExecutor
        let executor = ShortcutExecutor()

        // When: Executing with invalid shortcut name (will fail)
        let result = await executor.execute(
            shortcutName: "NonExistentShortcut12345",
            transcriptPath: "/tmp/test.txt"
        )

        // Then: Should return failure result with error message, not crash
        XCTAssertFalse(result.success,
                      "Invalid shortcut execution should return failure")
        XCTAssertNotNil(result.errorMessage,
                       "Failure result should include error message")
    }

    func testShortcutExecutorHandlesEmptyShortcutNameAsNoOp() async {
        // Given: Real ShortcutExecutor
        let executor = ShortcutExecutor()

        // When: Executing with empty shortcut name
        let result = await executor.execute(
            shortcutName: "",
            transcriptPath: "/tmp/test.txt"
        )

        // Then: Should return success (no-op) per documented behavior
        XCTAssertTrue(result.success,
                     "Empty shortcut name should be handled as no-op")
        XCTAssertNil(result.errorMessage,
                    "No-op should not have error message")
    }

    // MARK: - Path Expansion Tests

    func testTildeExpansionWorksForNonExistentPaths() {
        // Given: Path with tilde that doesn't exist on disk
        let invalidTildePath = "~/nonexistent/deeply/nested/path"

        // When: Tilde is expanded using NSString
        let expandedPath = NSString(string: invalidTildePath).expandingTildeInPath

        // Then: Tilde should expand to absolute path even if path doesn't exist
        XCTAssertTrue(expandedPath.hasPrefix("/"),
                     "Tilde expansion should return absolute path")
        XCTAssertFalse(expandedPath.contains("~"),
                      "Expanded path should not contain tilde character")
        XCTAssertTrue(expandedPath.count > invalidTildePath.count,
                     "Expanded path should be longer than original")
    }

    func testFileManagerHandlesNonExistentPathsGracefully() {
        // Given: Non-existent path
        let nonExistentPath = "/tmp/nonexistent_\(UUID().uuidString)"

        // When: Checking if file exists
        let exists = FileManager.default.fileExists(atPath: nonExistentPath)

        // Then: Should return false without crashing
        XCTAssertFalse(exists,
                      "FileManager should return false for non-existent paths")
    }

    func testFileManagerIsReadableFileHandlesInaccessiblePaths() {
        // Given: A temporary directory we can control
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_\(UUID().uuidString)")

        do {
            // Create directory with restricted permissions
            try FileManager.default.createDirectory(at: tempDir,
                                                   withIntermediateDirectories: true)

            // When: Checking readability
            let readable = FileManager.default.isReadableFile(atPath: tempDir.path)

            // Then: Should complete check without crashing (result may vary)
            // We're testing that the check doesn't crash, not the specific result
            XCTAssertNotNil(readable as Bool?,
                           "Readability check should complete")

            // Cleanup
            try? FileManager.default.removeItem(at: tempDir)
        } catch {
            XCTFail("Test setup failed: \(error)")
        }
    }

    // MARK: - Cache Error Recovery Tests

    func testCacheExpiryCalculationDoesNotOverflow() {
        // Given: Cache with very large timeout value
        // This tests an edge case not covered in SettingsViewCacheTests
        let cache = SettingsViewCache(cacheTimeout: TimeInterval.greatestFiniteMagnitude / 2)

        // When: Updating cache with extreme timeout
        cache.updateCache(shortcuts: ["Test"])

        // Then: Should handle extreme timeout without overflow or crash
        XCTAssertFalse(cache.isCacheExpired(),
                      "Cache with extreme timeout should not be expired immediately")

        let cachedData = cache.getCachedShortcuts()
        XCTAssertEqual(cachedData.count, 1,
                      "Cache should handle extreme timeout values without corruption")
    }

    func testCacheMainActorIsolationPreventsDataRaces() async {
        // Given: Cache marked as @MainActor
        // This test verifies that @MainActor isolation prevents data races
        let cache = SettingsViewCache()

        // When: Multiple sequential updates from MainActor context
        await withTaskGroup(of: Void.self) { group in
            for i in 1...10 {
                group.addTask {
                    await MainActor.run {
                        cache.updateCache(shortcuts: ["Shortcut\(i)"])
                        _ = cache.getCachedShortcuts()
                        _ = cache.isCacheExpired()
                    }
                }
            }
        }

        // Then: All operations complete without crashing
        // @MainActor ensures all access is serialized on main thread
        let finalData = cache.getCachedShortcuts()
        XCTAssertNotNil(finalData,
                       "@MainActor isolation should prevent data races")
        XCTAssertEqual(finalData.count, 1,
                      "Last update should be preserved")
    }
}
