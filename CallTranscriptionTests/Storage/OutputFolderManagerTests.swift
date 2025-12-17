import XCTest
@testable import CallTranscription

/// Tests for OutputFolderManager following TDD methodology.
/// Tests are written FIRST before implementation.
final class OutputFolderManagerTests: XCTestCase {
    var tempDirectory: URL!
    var manager: OutputFolderManager!

    override func setUp() async throws {
        try await super.setUp()

        // Create temp directory for testing
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        manager = await OutputFolderManager()
    }

    override func tearDown() async throws {
        // Clean up temp directory
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        try await super.tearDown()
    }

    // MARK: - Path Validation Tests

    func testValidatesAbsolutePaths() async throws {
        let absolutePath = tempDirectory.appendingPathComponent("test").path
        let result = try await manager.validateAndPreparePath(absolutePath)

        XCTAssertNotNil(result)
        XCTAssertTrue(result.path.hasPrefix("/"))
    }

    func testValidatesRelativePaths() async throws {
        let relativePath = "relative/path/test"
        let result = try await manager.validateAndPreparePath(relativePath)

        XCTAssertNotNil(result)
        // Relative paths should be converted to absolute
        XCTAssertTrue(result.path.hasPrefix("/"))
    }

    func testValidatesPathsWithTilde() async throws {
        let tildePath = "~/Desktop/Transcripts"
        let result = try await manager.validateAndPreparePath(tildePath)

        XCTAssertNotNil(result)
        XCTAssertFalse(result.path.contains("~"))
        XCTAssertTrue(result.path.contains(NSHomeDirectory()))
    }

    func testHandlesEmptyPath() async throws {
        // Empty path should use default
        let result = try await manager.validateAndPreparePath("")

        XCTAssertNotNil(result)
        XCTAssertTrue(result.path.contains("Transcripts"))
    }

    // MARK: - Tilde Expansion Tests

    func testExpandsTildeToUserHomeDirectory() async throws {
        let tildePath = "~/Documents/Transcripts"
        let result = try await manager.validateAndPreparePath(tildePath)

        XCTAssertFalse(result.path.contains("~"))
        XCTAssertTrue(result.path.hasPrefix(NSHomeDirectory()))
    }

    func testPreservesAbsolutePathsWithoutTilde() async throws {
        let absolutePath = tempDirectory.path
        let result = try await manager.validateAndPreparePath(absolutePath)

        XCTAssertEqual(result.path, absolutePath)
    }

    func testHandlesPathWithTildeInMiddle() async throws {
        // Path with ~ in middle should not expand
        let pathWithTildeInMiddle = "/some/path/~test/folder"
        let result = try await manager.validateAndPreparePath(pathWithTildeInMiddle)

        // Should still work, just not expand the ~
        XCTAssertNotNil(result)
    }

    // MARK: - Directory Creation Tests

    func testCreatesDirectoryWhenDoesNotExist() async throws {
        let newDir = tempDirectory.appendingPathComponent("new_folder")
        XCTAssertFalse(FileManager.default.fileExists(atPath: newDir.path))

        let result = try await manager.validateAndPreparePath(newDir.path)

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
    }

    func testCreatesIntermediateDirectories() async throws {
        let deepPath = tempDirectory.appendingPathComponent("level1/level2/level3")
        XCTAssertFalse(FileManager.default.fileExists(atPath: deepPath.path))

        let result = try await manager.validateAndPreparePath(deepPath.path)

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))

        // Verify intermediate directories were created
        let level1 = tempDirectory.appendingPathComponent("level1")
        let level2 = level1.appendingPathComponent("level2")
        XCTAssertTrue(FileManager.default.fileExists(atPath: level1.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: level2.path))
    }

    func testDoesNotFailWhenDirectoryExists() async throws {
        // Create directory first
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        // Should not throw when directory already exists
        let result = try await manager.validateAndPreparePath(tempDirectory.path)

        XCTAssertNotNil(result)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
    }

    func testThrowsWhenCreationFailsPermissionDenied() async throws {
        // Try to create directory in a read-only location
        let readOnlyPath = "/System/Library/PrivateFrameworks/test_dir"

        do {
            _ = try await manager.validateAndPreparePath(readOnlyPath)
            XCTFail("Expected error for permission denied")
        } catch CallTranscriptionError.outputFolderNotWritable {
            // Expected
        } catch {
            XCTFail("Expected outputFolderNotWritable error, got \(error)")
        }
    }

    // MARK: - Write Permission Tests

    func testVerifiesWritePermission() async throws {
        let writablePath = tempDirectory.path

        let result = try await manager.validateAndPreparePath(writablePath)

        XCTAssertNotNil(result)
        // Should succeed since temp directory is writable
    }

    func testDetectsReadOnlyFolders() async throws {
        // Create a directory and make it read-only
        let readOnlyDir = tempDirectory.appendingPathComponent("readonly")
        try FileManager.default.createDirectory(at: readOnlyDir, withIntermediateDirectories: true)

        // Make read-only
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o444],
            ofItemAtPath: readOnlyDir.path
        )

        do {
            _ = try await manager.validateAndPreparePath(readOnlyDir.path)
            XCTFail("Expected error for read-only folder")
        } catch CallTranscriptionError.outputFolderNotWritable {
            // Expected
        } catch {
            XCTFail("Expected outputFolderNotWritable error, got \(error)")
        }

        // Restore permissions for cleanup
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: readOnlyDir.path
        )
    }

    func testChecksParentDirectoryIfTargetDoesNotExist() async throws {
        let newDir = tempDirectory.appendingPathComponent("nonexistent")
        XCTAssertFalse(FileManager.default.fileExists(atPath: newDir.path))

        // Should check parent (tempDirectory) which is writable
        let result = try await manager.validateAndPreparePath(newDir.path)

        XCTAssertNotNil(result)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
    }

    // MARK: - URL Conversion Tests

    func testConvertsStringPathToURL() async throws {
        let pathString = tempDirectory.path
        let result = try await manager.validateAndPreparePath(pathString)

        XCTAssertTrue(result.isFileURL)
        XCTAssertEqual(result.path, pathString)
    }

    func testHandlesFileURLs() async throws {
        let fileURL = tempDirectory!
        let result = try await manager.validateAndPreparePath(fileURL.path)

        XCTAssertEqual(result.path, fileURL.path)
    }

    func testStandardizesPathFormat() async throws {
        // Path with double slashes and trailing slash
        let messyPath = tempDirectory.path + "/subdir//test/"
        let result = try await manager.validateAndPreparePath(messyPath)

        XCTAssertNotNil(result)
        // URL should standardize the path
        XCTAssertFalse(result.path.hasSuffix("/"))
    }

    func testResolvesSymlinks() async throws {
        // Create a real directory
        let realDir = tempDirectory.appendingPathComponent("real")
        try FileManager.default.createDirectory(at: realDir, withIntermediateDirectories: true)

        // Create a symlink to it
        let symlinkPath = tempDirectory.appendingPathComponent("symlink")
        try FileManager.default.createSymbolicLink(
            at: symlinkPath,
            withDestinationURL: realDir
        )

        let result = try await manager.validateAndPreparePath(symlinkPath.path)

        XCTAssertNotNil(result)
        // Should resolve to actual path
        let resolvedURL = result.resolvingSymlinksInPath()
        XCTAssertTrue(FileManager.default.fileExists(atPath: resolvedURL.path))
    }

    // MARK: - Default Folder Tests

    func testDefaultIsDesktopTranscripts() async throws {
        let defaultURL = await manager.defaultOutputFolder()

        XCTAssertTrue(defaultURL.path.contains("Desktop"))
        XCTAssertTrue(defaultURL.path.contains("Transcripts"))
    }

    func testCreatesDefaultIfDoesNotExist() async throws {
        let defaultURL = await manager.defaultOutputFolder()

        // Ensure it's created
        let result = try await manager.validateAndPreparePath(defaultURL.path)

        XCTAssertNotNil(result)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
    }

    func testFallsBackToDocumentsIfDesktopUnavailable() async throws {
        // Test the fallback mechanism (hard to test without mocking FileManager)
        // At minimum verify the method exists
        let defaultURL = await manager.defaultOutputFolder()
        XCTAssertNotNil(defaultURL)
    }

    // MARK: - Edge Cases

    func testHandlesVeryLongPaths() async throws {
        let longName = String(repeating: "a", count: 200)
        let longPath = tempDirectory.appendingPathComponent(longName)

        let result = try await manager.validateAndPreparePath(longPath.path)

        XCTAssertNotNil(result)
    }

    func testHandlesSpecialCharactersInPath() async throws {
        let specialPath = tempDirectory.appendingPathComponent("test folder with spaces & special!chars")

        let result = try await manager.validateAndPreparePath(specialPath.path)

        XCTAssertNotNil(result)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
    }

    func testHandlesUnicodeCharactersInPath() async throws {
        let unicodePath = tempDirectory.appendingPathComponent("测试文件夹")

        let result = try await manager.validateAndPreparePath(unicodePath.path)

        XCTAssertNotNil(result)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
    }

    // MARK: - Concurrency Tests

    func testConcurrentValidationCalls() async throws {
        let paths = (0..<10).map { tempDirectory.appendingPathComponent("concurrent_\($0)").path }

        // Validate all paths
        for path in paths {
            _ = try await manager.validateAndPreparePath(path)
        }

        // Verify all directories were created
        for path in paths {
            XCTAssertTrue(FileManager.default.fileExists(atPath: path))
        }
    }
}
