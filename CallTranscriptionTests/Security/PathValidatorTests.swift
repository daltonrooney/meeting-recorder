import XCTest
import Foundation
@testable import CallTranscription

@MainActor
final class PathValidatorTests: XCTestCase {
    var pathValidator: PathValidator!
    var testBaseDirectory: URL!
    var tempDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()

        // Create temporary test directory
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PathValidatorTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        testBaseDirectory = tempDirectory.appendingPathComponent("base")
        try FileManager.default.createDirectory(at: testBaseDirectory, withIntermediateDirectories: true)

        pathValidator = PathValidator()
    }

    override func tearDown() async throws {
        // Clean up temporary directory
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        pathValidator = nil
        testBaseDirectory = nil
        tempDirectory = nil
        try await super.tearDown()
    }

    // MARK: - Basic Path Validation Tests

    func testValidatesAbsolutePathWithinBaseDirectory() throws {
        let validPath = testBaseDirectory.appendingPathComponent("file.txt").path

        let validatedURL = try pathValidator.validate(path: validPath, againstBaseDirectories: [testBaseDirectory])

        XCTAssertEqual(validatedURL.path, testBaseDirectory.appendingPathComponent("file.txt").path)
    }

    func testValidatesRelativePathConvertedToAbsolute() throws {
        let relativePath = "file.txt"

        let validatedURL = try pathValidator.validate(path: relativePath, againstBaseDirectories: [testBaseDirectory])

        XCTAssertTrue(validatedURL.path.hasPrefix(testBaseDirectory.path))
    }

    func testRejectsPathOutsideBaseDirectory() throws {
        let outsidePath = tempDirectory.appendingPathComponent("outside/file.txt").path

        XCTAssertThrowsError(try pathValidator.validate(path: outsidePath, againstBaseDirectories: [testBaseDirectory])) { error in
            guard let ctError = error as? CallTranscriptionError,
                  case .pathOutsideAllowedDirectories = ctError else {
                XCTFail("Expected pathOutsideAllowedDirectories error, got \(error)")
                return
            }
        }
    }

    func testValidatesPathWithSpaces() throws {
        let pathWithSpaces = testBaseDirectory.appendingPathComponent("my document.txt").path

        let validatedURL = try pathValidator.validate(path: pathWithSpaces, againstBaseDirectories: [testBaseDirectory])

        XCTAssertTrue(validatedURL.path.contains("my document.txt"))
    }

    func testHandlesTrailingSlashCorrectly() throws {
        let pathWithSlash = testBaseDirectory.appendingPathComponent("folder/").path

        let validatedURL = try pathValidator.validate(path: pathWithSlash, againstBaseDirectories: [testBaseDirectory])

        XCTAssertTrue(validatedURL.path.hasPrefix(testBaseDirectory.path))
    }

    // MARK: - Path Traversal Attack Prevention Tests

    func testDetectsSimplePathTraversal() throws {
        let traversalPath = testBaseDirectory.appendingPathComponent("../../../etc/passwd").path

        XCTAssertThrowsError(try pathValidator.validate(path: traversalPath, againstBaseDirectories: [testBaseDirectory])) { error in
            guard let ctError = error as? CallTranscriptionError,
                  case .pathTraversalDetected = ctError else {
                XCTFail("Expected pathTraversalDetected error, got \(error)")
                return
            }
        }
    }

    func testDetectsMultipleTraversalSequences() throws {
        let traversalPath = testBaseDirectory.appendingPathComponent("../../subdir/../../etc/passwd").path

        XCTAssertThrowsError(try pathValidator.validate(path: traversalPath, againstBaseDirectories: [testBaseDirectory])) { error in
            guard let ctError = error as? CallTranscriptionError,
                  case .pathTraversalDetected = ctError else {
                XCTFail("Expected pathTraversalDetected error, got \(error)")
                return
            }
        }
    }

    func testAllowsLegitimateDoubleDotWithinBoundaries() throws {
        // Create subdir/file structure
        let subdir = testBaseDirectory.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)

        let sibling = testBaseDirectory.appendingPathComponent("sibling")
        try FileManager.default.createDirectory(at: sibling, withIntermediateDirectories: true)

        // Path like /base/subdir/../sibling should be allowed (stays within base)
        let validPath = subdir.appendingPathComponent("../sibling/file.txt").path

        let validatedURL = try pathValidator.validate(path: validPath, againstBaseDirectories: [testBaseDirectory])

        XCTAssertTrue(validatedURL.path.hasPrefix(testBaseDirectory.path))
    }

    func testDetectsAbsolutePathOutsideBase() throws {
        let maliciousPath = "/etc/passwd"

        XCTAssertThrowsError(try pathValidator.validate(path: maliciousPath, againstBaseDirectories: [testBaseDirectory])) { error in
            guard let ctError = error as? CallTranscriptionError,
                  case .pathOutsideAllowedDirectories = ctError else {
                XCTFail("Expected pathOutsideAllowedDirectories error, got \(error)")
                return
            }
        }
    }

    func testDetectsComplexTraversal() throws {
        let complexPath = testBaseDirectory.appendingPathComponent("a/b/c/../../../../../../../../etc/passwd").path

        XCTAssertThrowsError(try pathValidator.validate(path: complexPath, againstBaseDirectories: [testBaseDirectory])) { error in
            guard let ctError = error as? CallTranscriptionError,
                  case .pathTraversalDetected = ctError else {
                XCTFail("Expected pathTraversalDetected error, got \(error)")
                return
            }
        }
    }

    // MARK: - Symlink Attack Prevention Tests

    func testDetectsSymlinkPointingOutsideBase() throws {
        let symlinkPath = testBaseDirectory.appendingPathComponent("evil-link")
        let targetPath = tempDirectory.appendingPathComponent("outside/target.txt")

        // Create target outside base
        try FileManager.default.createDirectory(at: targetPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: targetPath.path, contents: nil)

        // Create symlink inside base pointing outside
        try FileManager.default.createSymbolicLink(at: symlinkPath, withDestinationURL: targetPath)

        XCTAssertThrowsError(try pathValidator.validate(path: symlinkPath.path, againstBaseDirectories: [testBaseDirectory])) { error in
            guard let ctError = error as? CallTranscriptionError,
                  case .symlinkAttackDetected = ctError else {
                XCTFail("Expected symlinkAttackDetected error, got \(error)")
                return
            }
        }
    }

    func testAllowsSymlinkWithinSafeBoundaries() throws {
        let targetPath = testBaseDirectory.appendingPathComponent("target.txt")
        FileManager.default.createFile(atPath: targetPath.path, contents: nil)

        let symlinkPath = testBaseDirectory.appendingPathComponent("safe-link")
        try FileManager.default.createSymbolicLink(at: symlinkPath, withDestinationURL: targetPath)

        let validatedURL = try pathValidator.validate(path: symlinkPath.path, againstBaseDirectories: [testBaseDirectory])

        // Should resolve to actual target within base
        XCTAssertTrue(validatedURL.path.hasPrefix(testBaseDirectory.path))
    }

    func testDetectsSymlinkChain() throws {
        let firstTarget = testBaseDirectory.appendingPathComponent("first")
        let secondTarget = tempDirectory.appendingPathComponent("outside/second")

        try FileManager.default.createDirectory(at: secondTarget.deletingLastPathComponent(), withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: secondTarget.path, contents: nil)

        // Create chain: symlink1 -> symlink2 -> outside
        let symlink2 = testBaseDirectory.appendingPathComponent("link2")
        try FileManager.default.createSymbolicLink(at: symlink2, withDestinationURL: secondTarget)

        let symlink1 = testBaseDirectory.appendingPathComponent("link1")
        try FileManager.default.createSymbolicLink(at: symlink1, withDestinationURL: symlink2)

        XCTAssertThrowsError(try pathValidator.validate(path: symlink1.path, againstBaseDirectories: [testBaseDirectory])) { error in
            guard let ctError = error as? CallTranscriptionError,
                  case .symlinkAttackDetected = ctError else {
                XCTFail("Expected symlinkAttackDetected error, got \(error)")
                return
            }
        }
    }

    // MARK: - Normalization Tests

    func testNormalizesDoubleSlashes() throws {
        let pathWithDoubleSlash = testBaseDirectory.path + "//subdir//file.txt"

        let validatedURL = try pathValidator.validate(path: pathWithDoubleSlash, againstBaseDirectories: [testBaseDirectory])

        XCTAssertFalse(validatedURL.path.contains("//"))
    }

    func testResolvesDotToCurrentDirectory() throws {
        let pathWithDot = testBaseDirectory.appendingPathComponent("./file.txt").path

        let validatedURL = try pathValidator.validate(path: pathWithDot, againstBaseDirectories: [testBaseDirectory])

        XCTAssertTrue(validatedURL.path.hasPrefix(testBaseDirectory.path))
    }

    // MARK: - Multiple Base Directories Tests

    func testValidatesAgainstMultipleBaseDirectories() throws {
        let secondBase = tempDirectory.appendingPathComponent("base2")
        try FileManager.default.createDirectory(at: secondBase, withIntermediateDirectories: true)

        let pathInSecondBase = secondBase.appendingPathComponent("file.txt").path

        let validatedURL = try pathValidator.validate(path: pathInSecondBase, againstBaseDirectories: [testBaseDirectory, secondBase])

        XCTAssertTrue(validatedURL.path.hasPrefix(secondBase.path))
    }

    func testRejectsPathNotInAnyBaseDirectory() throws {
        let secondBase = tempDirectory.appendingPathComponent("base2")
        try FileManager.default.createDirectory(at: secondBase, withIntermediateDirectories: true)

        let outsidePath = tempDirectory.appendingPathComponent("outside/file.txt").path

        XCTAssertThrowsError(try pathValidator.validate(path: outsidePath, againstBaseDirectories: [testBaseDirectory, secondBase])) { error in
            guard let ctError = error as? CallTranscriptionError,
                  case .pathOutsideAllowedDirectories = ctError else {
                XCTFail("Expected pathOutsideAllowedDirectories error, got \(error)")
                return
            }
        }
    }

    // MARK: - Convenience Method Tests

    func testValidateForFileOutputUsesDefaultDirectories() throws {
        // This test will verify default directories (home, temp) are used
        // Create path in temp directory
        let tempPath = FileManager.default.temporaryDirectory.appendingPathComponent("test.txt").path

        // Should allow temp directory by default
        let validatedURL = try pathValidator.validateForFileOutput(path: tempPath)

        XCTAssertEqual(validatedURL.path, FileManager.default.temporaryDirectory.appendingPathComponent("test.txt").path)
    }

    func testValidateForFileOutputRejectsSystemDirectories() throws {
        let systemPath = "/etc/passwd"

        XCTAssertThrowsError(try pathValidator.validateForFileOutput(path: systemPath)) { error in
            guard let ctError = error as? CallTranscriptionError,
                  case .pathOutsideAllowedDirectories = ctError else {
                XCTFail("Expected pathOutsideAllowedDirectories error, got \(error)")
                return
            }
        }
    }

    // MARK: - Error Message Quality Tests

    func testPathTraversalErrorIncludesHelpfulMessage() throws {
        let traversalPath = testBaseDirectory.appendingPathComponent("../../../etc/passwd").path

        do {
            _ = try pathValidator.validate(path: traversalPath, againstBaseDirectories: [testBaseDirectory])
            XCTFail("Should have thrown error")
        } catch let error as CallTranscriptionError {
            let description = error.errorDescription ?? ""
            let reason = error.failureReason ?? ""

            // Should mention the path and the issue
            XCTAssertFalse(description.isEmpty)
            XCTAssertFalse(reason.isEmpty)
        }
    }

    func testSymlinkAttackErrorIncludesResolvedPath() throws {
        let symlinkPath = testBaseDirectory.appendingPathComponent("evil-link")
        let targetPath = tempDirectory.appendingPathComponent("outside/target.txt")

        try FileManager.default.createDirectory(at: targetPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: targetPath.path, contents: nil)
        try FileManager.default.createSymbolicLink(at: symlinkPath, withDestinationURL: targetPath)

        do {
            _ = try pathValidator.validate(path: symlinkPath.path, againstBaseDirectories: [testBaseDirectory])
            XCTFail("Should have thrown error")
        } catch let error as CallTranscriptionError {
            let description = error.errorDescription ?? ""

            // Should mention it's a symlink attack
            XCTAssertFalse(description.isEmpty)
        }
    }

    // MARK: - Edge Case Tests

    func testHandlesEmptyPath() throws {
        let emptyPath = ""

        XCTAssertThrowsError(try pathValidator.validate(path: emptyPath, againstBaseDirectories: [testBaseDirectory])) { error in
            guard let ctError = error as? CallTranscriptionError,
                  case .invalidPath = ctError else {
                XCTFail("Expected invalidPath error, got \(error)")
                return
            }
        }
    }

    func testHandlesPathsWithUnicode() throws {
        let unicodePath = testBaseDirectory.appendingPathComponent("文件.txt").path

        let validatedURL = try pathValidator.validate(path: unicodePath, againstBaseDirectories: [testBaseDirectory])

        XCTAssertTrue(validatedURL.path.hasPrefix(testBaseDirectory.path))
    }

    func testHandlesVeryLongPath() throws {
        // Create a very long but valid path
        let longComponent = String(repeating: "a", count: 200)
        let longPath = testBaseDirectory.appendingPathComponent(longComponent).path

        let validatedURL = try pathValidator.validate(path: longPath, againstBaseDirectories: [testBaseDirectory])

        XCTAssertTrue(validatedURL.path.hasPrefix(testBaseDirectory.path))
    }
}
