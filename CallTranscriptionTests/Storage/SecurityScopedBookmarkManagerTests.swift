import XCTest
@testable import CallTranscription

@MainActor
final class SecurityScopedBookmarkManagerTests: XCTestCase {
    var bookmarkManager: SecurityScopedBookmarkManager!
    var tempDirectory: URL!

    override func setUp() async throws {
        bookmarkManager = SecurityScopedBookmarkManager()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        bookmarkManager = nil
    }

    // MARK: - Bookmark Creation Tests

    func testCreatesBookmarkForDirectory() async throws {
        // Given a directory URL
        let testFolder = tempDirectory.appendingPathComponent("test-folder", isDirectory: true)
        try FileManager.default.createDirectory(at: testFolder, withIntermediateDirectories: true)

        // When creating a bookmark
        let bookmarkData = try bookmarkManager.createBookmark(for: testFolder)

        // Then bookmark data should not be empty
        XCTAssertFalse(bookmarkData.isEmpty, "Bookmark data should not be empty")
    }

    func testThrowsErrorForNonExistentDirectory() async throws {
        // Given a non-existent directory
        let nonExistent = tempDirectory.appendingPathComponent("does-not-exist", isDirectory: true)

        // When creating a bookmark
        // Then should throw error
        XCTAssertThrowsError(try bookmarkManager.createBookmark(for: nonExistent)) { error in
            guard case CallTranscriptionError.bookmarkCreationFailed = error else {
                XCTFail("Expected bookmarkCreationFailed error, got \(error)")
                return
            }
        }
    }

    // MARK: - Bookmark Resolution Tests

    func testResolvesBookmarkToOriginalURL() async throws {
        // Given a bookmark for a directory
        let testFolder = tempDirectory.appendingPathComponent("test-folder", isDirectory: true)
        try FileManager.default.createDirectory(at: testFolder, withIntermediateDirectories: true)
        let bookmarkData = try bookmarkManager.createBookmark(for: testFolder)

        // When resolving the bookmark
        let resolvedURL = try bookmarkManager.resolveBookmark(bookmarkData)

        // Then resolved URL should match original
        XCTAssertEqual(resolvedURL.path, testFolder.path)
    }

    func testThrowsErrorForInvalidBookmarkData() async throws {
        // Given invalid bookmark data
        let invalidData = "not a bookmark".data(using: .utf8)!

        // When resolving
        // Then should throw error
        XCTAssertThrowsError(try bookmarkManager.resolveBookmark(invalidData)) { error in
            guard case CallTranscriptionError.bookmarkResolutionFailed = error else {
                XCTFail("Expected bookmarkResolutionFailed error, got \(error)")
                return
            }
        }
    }

    func testThrowsErrorForStaleBookmark() async throws {
        // Given a bookmark for a deleted directory
        let testFolder = tempDirectory.appendingPathComponent("will-be-deleted", isDirectory: true)
        try FileManager.default.createDirectory(at: testFolder, withIntermediateDirectories: true)
        let bookmarkData = try bookmarkManager.createBookmark(for: testFolder)

        // Delete the directory
        try FileManager.default.removeItem(at: testFolder)

        // When resolving stale bookmark
        // Then should throw error
        XCTAssertThrowsError(try bookmarkManager.resolveBookmark(bookmarkData)) { error in
            guard case CallTranscriptionError.bookmarkResolutionFailed = error else {
                XCTFail("Expected bookmarkResolutionFailed error, got \(error)")
                return
            }
        }
    }

    // MARK: - Security-Scoped Access Tests

    func testStartsAndStopsSecurityScopedAccess() async throws {
        // Given a resolved bookmark
        let testFolder = tempDirectory.appendingPathComponent("test-folder", isDirectory: true)
        try FileManager.default.createDirectory(at: testFolder, withIntermediateDirectories: true)
        let bookmarkData = try bookmarkManager.createBookmark(for: testFolder)
        let resolvedURL = try bookmarkManager.resolveBookmark(bookmarkData)

        // When starting security-scoped access
        let didStart = resolvedURL.startAccessingSecurityScopedResource()

        // Then access should be granted
        XCTAssertTrue(didStart, "Should successfully start accessing security-scoped resource")

        // Cleanup
        resolvedURL.stopAccessingSecurityScopedResource()
    }

    func testAccessTokenTracksAccess() async throws {
        // Given a bookmark
        let testFolder = tempDirectory.appendingPathComponent("test-folder", isDirectory: true)
        try FileManager.default.createDirectory(at: testFolder, withIntermediateDirectories: true)
        let bookmarkData = try bookmarkManager.createBookmark(for: testFolder)

        // When accessing with a token
        let token = try await bookmarkManager.accessResource(bookmarkData: bookmarkData) { url in
            // Then should be able to access the folder
            XCTAssertTrue(FileManager.default.isReadableFile(atPath: url.path))
            return "success"
        }

        // Then operation should succeed
        XCTAssertEqual(token, "success")
    }

    func testAccessTokenReleasesResourceOnExit() async throws {
        // Given a bookmark
        let testFolder = tempDirectory.appendingPathComponent("test-folder", isDirectory: true)
        try FileManager.default.createDirectory(at: testFolder, withIntermediateDirectories: true)
        let bookmarkData = try bookmarkManager.createBookmark(for: testFolder)

        // When accessing resource in a scope
        let capturedURL: URL = try await bookmarkManager.accessResource(bookmarkData: bookmarkData) { url in
            return url
        }

        // Then URL should still be valid but scope should be released
        // (We can't directly test if stopAccessingSecurityScopedResource was called,
        // but we verify the function completes without errors)
        XCTAssertEqual(capturedURL.path, testFolder.path)
    }

    // MARK: - Bookmark Validation Tests

    func testValidatesBookmarkIsForDirectory() async throws {
        // Given a file (not directory) bookmark
        let testFile = tempDirectory.appendingPathComponent("test-file.txt")
        try "test".write(to: testFile, atomically: true, encoding: .utf8)

        // When creating bookmark for file
        // Then should throw error
        XCTAssertThrowsError(try bookmarkManager.createBookmark(for: testFile)) { error in
            guard case CallTranscriptionError.bookmarkCreationFailed = error else {
                XCTFail("Expected bookmarkCreationFailed error, got \(error)")
                return
            }
        }
    }

    func testBookmarkDataIsStableAcrossCreations() async throws {
        // Given a directory
        let testFolder = tempDirectory.appendingPathComponent("stable-folder", isDirectory: true)
        try FileManager.default.createDirectory(at: testFolder, withIntermediateDirectories: true)

        // When creating multiple bookmarks
        let bookmark1 = try bookmarkManager.createBookmark(for: testFolder)
        let bookmark2 = try bookmarkManager.createBookmark(for: testFolder)

        // Then both should resolve to same path
        let url1 = try bookmarkManager.resolveBookmark(bookmark1)
        let url2 = try bookmarkManager.resolveBookmark(bookmark2)
        XCTAssertEqual(url1.path, url2.path)
    }
}
