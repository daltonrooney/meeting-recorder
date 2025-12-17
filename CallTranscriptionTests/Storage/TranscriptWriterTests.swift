import XCTest
@testable import CallTranscription

/// Tests for TranscriptWriter following TDD methodology.
/// Tests are written FIRST before implementation.
final class TranscriptWriterTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()

        // Create temp directory for testing
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        // Clean up temp directory
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        try await super.tearDown()
    }

    // MARK: - File Creation Tests

    func testCreatesFileAtSpecifiedURL() async throws {
        let fileURL = tempDirectory.appendingPathComponent("test_transcript.txt")

        let writer = try await TranscriptWriter(outputFolder: tempDirectory, filename: "test_transcript.txt")
        try await writer.finalize()

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testGeneratesFilenameWhenNotProvided() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        let fileURL = try await writer.finalize()

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertTrue(fileURL.lastPathComponent.hasSuffix(".txt"))
    }

    func testFilenameIncludesISO8601Timestamp() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        let fileURL = try await writer.finalize()

        let filename = fileURL.lastPathComponent
        // Should contain date in format like "2025-12-17"
        XCTAssertTrue(filename.contains("-"))

        // Should contain time components
        let components = filename.components(separatedBy: CharacterSet(charactersIn: "T_-."))
        XCTAssertGreaterThan(components.count, 3)
    }

    func testCreatesFileWithProperHeader() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory, title: "Test Call")
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("Olive - Call Transcription Transcript"))
    }

    func testHeaderIncludesDateAndTitle() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory, title: "Test Call")
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("Test Call"))

        // Should contain a date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let today = dateFormatter.string(from: Date())
        XCTAssertTrue(content.contains(today))
    }

    func testThrowsWhenFolderNotWritable() async throws {
        let readOnlyFolder = tempDirectory.appendingPathComponent("readonly")
        try FileManager.default.createDirectory(at: readOnlyFolder, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o444], ofItemAtPath: readOnlyFolder.path)

        do {
            _ = try await TranscriptWriter(outputFolder: readOnlyFolder)
            XCTFail("Expected error for read-only folder")
        } catch CallTranscriptionError.outputFolderNotWritable {
            // Expected
        } catch {
            XCTFail("Expected outputFolderNotWritable error, got \(error)")
        }

        // Restore permissions for cleanup
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: readOnlyFolder.path)
    }

    // MARK: - Header Formatting Tests

    func testHeaderContainsBrandingText() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("Olive - Call Transcription Transcript"))
    }

    func testHeaderContainsFormattedDate() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        let expectedDate = dateFormatter.string(from: Date())

        XCTAssertTrue(content.contains(expectedDate))
    }

    func testHeaderIncludesSeparatorLine() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("---") || content.contains("===") || content.contains("___"))
    }

    func testHeaderIsWrittenBeforeContent() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory, title: "Test")
        try await writer.append("First line", timestamp: 0.0)
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let headerRange = content.range(of: "Olive - Call Transcription Transcript")
        let contentRange = content.range(of: "First line")

        XCTAssertNotNil(headerRange)
        XCTAssertNotNil(contentRange)
        XCTAssertLessThan(headerRange!.lowerBound, contentRange!.lowerBound)
    }

    // MARK: - Text Appending Tests

    func testAppendAddsTextWithTimestamp() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        try await writer.append("Test text", timestamp: 65.0)
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("[01:05]"))
        XCTAssertTrue(content.contains("Test text"))
    }

    func testTimestampFormatIsMMSS() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        try await writer.append("Text", timestamp: 125.0) // 2:05
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("[02:05]"))
    }

    func testTimestampFormatIsHHMMSS() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        try await writer.append("Text", timestamp: 3665.0) // 1:01:05
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("[1:01:05]"))
    }

    func testTextIsAppendedWithNewline() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        try await writer.append("Line 1", timestamp: 0.0)
        try await writer.append("Line 2", timestamp: 1.0)
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        let line1Index = lines.firstIndex { $0.contains("Line 1") }
        let line2Index = lines.firstIndex { $0.contains("Line 2") }

        XCTAssertNotNil(line1Index)
        XCTAssertNotNil(line2Index)
        XCTAssertNotEqual(line1Index, line2Index)
    }

    func testMultipleAppendsAreSequential() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        try await writer.append("First", timestamp: 0.0)
        try await writer.append("Second", timestamp: 1.0)
        try await writer.append("Third", timestamp: 2.0)
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)

        let firstIndex = content.range(of: "First")?.lowerBound
        let secondIndex = content.range(of: "Second")?.lowerBound
        let thirdIndex = content.range(of: "Third")?.lowerBound

        XCTAssertNotNil(firstIndex)
        XCTAssertNotNil(secondIndex)
        XCTAssertNotNil(thirdIndex)
        XCTAssertLessThan(firstIndex!, secondIndex!)
        XCTAssertLessThan(secondIndex!, thirdIndex!)
    }

    func testHandlesEmptyTextGracefully() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        try await writer.append("", timestamp: 0.0)
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("[00:00]"))
    }

    func testHandlesSpecialCharactersInText() async throws {
        let specialText = "Test with émoji 🎉 and quotes \"hello\" and <tags>"

        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        try await writer.append(specialText, timestamp: 0.0)
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains(specialText))
    }

    // MARK: - Timestamp Formatting Tests

    func testFormatsSecondsLessThan60AsMMSS() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        try await writer.append("Text", timestamp: 45.0)
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("[00:45]"))
    }

    func testFormatsSeconds3600OrMoreAsHHMMSS() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        try await writer.append("Text", timestamp: 3661.0) // 1:01:01
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("[1:01:01]"))
    }

    func testZeroPadsMinutesAndSeconds() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        try await writer.append("Text", timestamp: 65.0) // 01:05
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("[01:05]"))
    }

    func testHandlesNegativeTimestampsAsZero() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        try await writer.append("Text", timestamp: -5.0)
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("[00:00]"))
    }

    func testHandlesVeryLargeTimestamps() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        try await writer.append("Text", timestamp: 359999.0) // 99:59:59
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        // Should handle very large timestamps without crashing
        XCTAssertTrue(content.contains("Text"))
    }

    // MARK: - File Finalization Tests

    func testFinalizeClosesFileHandle() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        try await writer.append("Text", timestamp: 0.0)
        let fileURL = try await writer.finalize()

        // File should be readable after finalization (handle closed)
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("Text"))
    }

    func testFinalizeReturnsCorrectOutputURL() async throws {
        let filename = "test_output.txt"
        let writer = try await TranscriptWriter(outputFolder: tempDirectory, filename: filename)
        let fileURL = try await writer.finalize()

        XCTAssertEqual(fileURL.lastPathComponent, filename)
        XCTAssertTrue(fileURL.path.hasPrefix(tempDirectory.path))
    }

    func testFileIsReadableAfterFinalization() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        try await writer.append("Test content", timestamp: 0.0)
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("Test content"))
        XCTAssertTrue(content.contains("Olive - Call Transcription Transcript"))
    }

    func testCannotAppendAfterFinalization() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        _ = try await writer.finalize()

        do {
            try await writer.append("Should fail", timestamp: 0.0)
            XCTFail("Expected error when appending after finalization")
        } catch {
            // Expected to throw
        }
    }

    // MARK: - File Integrity Tests

    func testUsesUTF8Encoding() async throws {
        let unicodeText = "Test with Unicode: 日本語, émojis 🎉, and symbols ∑∫"

        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        try await writer.append(unicodeText, timestamp: 0.0)
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertEqual(content.contains(unicodeText), true)
    }

    func testFileIsValidTextFormat() async throws {
        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        try await writer.append("Line 1", timestamp: 0.0)
        try await writer.append("Line 2", timestamp: 1.0)
        let fileURL = try await writer.finalize()

        // Should be readable as text
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertFalse(content.isEmpty)

        // Should contain newlines
        XCTAssertTrue(content.contains("\n"))
    }

    func testNoDataCorruption() async throws {
        let testText = String(repeating: "A", count: 1000)

        let writer = try await TranscriptWriter(outputFolder: tempDirectory)
        try await writer.append(testText, timestamp: 0.0)
        let fileURL = try await writer.finalize()

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains(testText))

        // Verify exact length was preserved
        let textRange = content.range(of: testText)
        XCTAssertNotNil(textRange)
        XCTAssertEqual(content.distance(from: textRange!.lowerBound, to: textRange!.upperBound), 1000)
    }

    func testFileHandleIsProperlyManaged() async throws {
        // Create and finalize multiple writers to test handle management
        for i in 0..<5 {
            let writer = try await TranscriptWriter(outputFolder: tempDirectory, filename: "test_\(i).txt")
            try await writer.append("Test \(i)", timestamp: 0.0)
            _ = try await writer.finalize()
        }

        // Verify all files were created properly
        let contents = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
        XCTAssertGreaterThanOrEqual(contents.count, 5)
    }

    // MARK: - Error Scenario Tests

    func testThrowsOutputFolderNotWritableWhenAppropriate() async throws {
        let readOnlyFolder = tempDirectory.appendingPathComponent("readonly")
        try FileManager.default.createDirectory(at: readOnlyFolder, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o444], ofItemAtPath: readOnlyFolder.path)

        do {
            _ = try await TranscriptWriter(outputFolder: readOnlyFolder)
            XCTFail("Expected outputFolderNotWritable error")
        } catch CallTranscriptionError.outputFolderNotWritable {
            // Expected
        } catch {
            XCTFail("Expected outputFolderNotWritable, got \(error)")
        }

        // Cleanup
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: readOnlyFolder.path)
    }

    func testCleansUpOnInitializationFailure() async throws {
        let readOnlyFolder = tempDirectory.appendingPathComponent("readonly2")
        try FileManager.default.createDirectory(at: readOnlyFolder, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o444], ofItemAtPath: readOnlyFolder.path)

        do {
            _ = try await TranscriptWriter(outputFolder: readOnlyFolder, filename: "test.txt")
            XCTFail("Expected initialization to fail")
        } catch {
            // Check that no partial files were left behind
            let testFile = readOnlyFolder.appendingPathComponent("test.txt")
            XCTAssertFalse(FileManager.default.fileExists(atPath: testFile.path))
        }

        // Cleanup
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: readOnlyFolder.path)
    }
}
