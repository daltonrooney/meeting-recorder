import XCTest
import AVFoundation
@testable import CallTranscription

/// End-to-End Integration Tests for Complete Recording Workflows
///
/// Following TDD methodology: These tests are written FIRST before implementation.
///
/// This test suite validates complete recording workflows from start to finish:
/// - Complete recording flow with all subsystems
/// - Microphone-only recording workflow
/// - System-audio-only recording workflow
/// - Dual-source recording workflow
/// - Error scenarios and recovery
/// - State transitions and edge cases
/// - Output file validation (format, headers, timestamps, encoding)
///
/// Each test verifies the entire pipeline: audio capture → mixing → transcription → file output → post-processing
@MainActor
final class EndToEndIntegrationTests: XCTestCase {

    var coordinator: RecordingSessionCoordinator!
    var testOutputFolder: URL!

    override func setUp() async throws {
        try await super.setUp()

        // Create unique temp output folder for each test
        testOutputFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent("E2ETests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testOutputFolder, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        // Stop any active recording
        if let coordinator = coordinator {
            let isRecording = await coordinator.isRecording
            if isRecording {
                try? await coordinator.stopRecording()
            }
        }
        coordinator = nil

        // Clean up temp folder
        if let testOutputFolder = testOutputFolder {
            try? FileManager.default.removeItem(at: testOutputFolder)
        }
        testOutputFolder = nil

        try await super.tearDown()
    }

    // MARK: - Complete Recording Flow Tests

    /// Test 1: Complete recording flow from start to transcript file
    ///
    /// Validates:
    /// - Can start recording
    /// - Captures audio (microphone in test environment)
    /// - Produces transcription results (if audio detected)
    /// - Writes transcript file
    /// - File contains expected content and format
    func testCompleteRecordingFlowProducesValidTranscript() async throws {
        // GIVEN: A valid recording configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true,
            systemAudioEnabled: false
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // Track transcription results
        var transcriptionResults: [(text: String, isFinal: Bool)] = []
        await coordinator.onTranscriptionResult { text, isFinal in
            transcriptionResults.append((text, isFinal))
        }

        // WHEN: Starting and stopping a recording
        try await coordinator.startRecording(title: "Complete Flow Test")

        // Verify recording state
        let isRecording = await coordinator.isRecording
        XCTAssertTrue(isRecording, "Recording should be active")

        // Let recording run for a reasonable duration
        try await Task.sleep(for: .seconds(2))

        let transcriptURL = try await coordinator.stopRecording()

        // THEN: Verify output
        XCTAssertNotNil(transcriptURL, "Should return transcript URL")
        XCTAssertTrue(FileManager.default.fileExists(atPath: transcriptURL.path), "Transcript file should exist")

        // Verify file is readable and valid UTF-8
        let content = try String(contentsOf: transcriptURL, encoding: .utf8)
        XCTAssertFalse(content.isEmpty, "Transcript should not be empty")

        // Verify header format
        XCTAssertTrue(content.contains("Olive - Call Transcription Transcript"), "Should contain app header")
        XCTAssertTrue(content.contains("Date:"), "Should contain date header")
        XCTAssertTrue(content.contains("Title: Complete Flow Test"), "Should contain title")
        XCTAssertTrue(content.contains("================================================================================"), "Should contain separator")
    }

    /// Test 2: Complete flow with post-recording script execution
    ///
    /// Validates:
    /// - Recording completes successfully
    /// - Post-recording script is executed
    /// - Script receives transcript path as argument
    func testCompleteFlowExecutesPostRecordingScript() async throws {
        // GIVEN: A test script that logs execution
        let scriptPath = testOutputFolder.appendingPathComponent("post-recording-test.sh")
        let logPath = testOutputFolder.appendingPathComponent("script-log.txt")

        let scriptContent = """
        #!/bin/bash
        echo "Script executed with: $1" > "\(logPath.path)"
        """
        try scriptContent.write(to: scriptPath, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath.path)

        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true,
            systemAudioEnabled: false,
            postRecordingScriptPath: scriptPath.path
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Completing a recording
        try await coordinator.startRecording(title: "Script Test")
        try await Task.sleep(for: .seconds(1))
        let transcriptURL = try await coordinator.stopRecording()

        // Give script time to execute
        try await Task.sleep(for: .milliseconds(500))

        // THEN: Verify script executed
        XCTAssertTrue(FileManager.default.fileExists(atPath: logPath.path), "Script log should exist")

        let logContent = try String(contentsOf: logPath, encoding: .utf8)
        XCTAssertTrue(logContent.contains("Script executed with:"), "Script should have logged execution")
        XCTAssertTrue(logContent.contains(transcriptURL.path), "Script should receive transcript path")
    }

    // MARK: - Microphone-Only Recording Tests

    /// Test 3: Microphone-only recording produces valid transcript
    ///
    /// Validates:
    /// - Records with only microphone enabled
    /// - Transcription works with single source
    /// - Transcript file created correctly
    func testMicrophoneOnlyRecordingProducesValidOutput() async throws {
        // GIVEN: Microphone-only configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true,
            systemAudioEnabled: false
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Recording with microphone only
        try await coordinator.startRecording(title: "Microphone Only Test")

        let isRecording = await coordinator.isRecording
        XCTAssertTrue(isRecording, "Should be recording")

        try await Task.sleep(for: .seconds(1))
        let transcriptURL = try await coordinator.stopRecording()

        // THEN: Verify output
        XCTAssertTrue(FileManager.default.fileExists(atPath: transcriptURL.path), "Transcript should exist")

        let content = try String(contentsOf: transcriptURL, encoding: .utf8)
        XCTAssertTrue(content.contains("Olive - Call Transcription Transcript"), "Should have valid header")
        XCTAssertTrue(content.contains("Title: Microphone Only Test"), "Should contain correct title")

        // Verify state is clean
        let isRecordingAfter = await coordinator.isRecording
        XCTAssertFalse(isRecordingAfter, "Should not be recording after stop")
    }

    // MARK: - System Audio-Only Recording Tests

    /// Test 4: System audio-only recording handles gracefully
    ///
    /// Validates:
    /// - Attempts to record with only system audio enabled
    /// - Handles success or failure appropriately
    /// - If successful, produces valid transcript
    /// - If failed, provides meaningful error
    func testSystemAudioOnlyRecordingHandlesGracefully() async throws {
        // GIVEN: System audio-only configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: false,
            systemAudioEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Attempting to record with system audio only
        do {
            try await coordinator.startRecording(title: "System Audio Test")

            // If successful in test environment
            let isRecording = await coordinator.isRecording
            XCTAssertTrue(isRecording, "Should be recording if system audio available")

            try await Task.sleep(for: .seconds(1))
            let transcriptURL = try await coordinator.stopRecording()

            // THEN: Verify output if recording succeeded
            XCTAssertTrue(FileManager.default.fileExists(atPath: transcriptURL.path), "Transcript should exist")

            let content = try String(contentsOf: transcriptURL, encoding: .utf8)
            XCTAssertTrue(content.contains("Olive - Call Transcription Transcript"), "Should have valid header")

        } catch let error as CallTranscriptionError {
            // If system audio not available in test environment, verify error is meaningful
            XCTAssertNotNil(error.errorDescription, "Error should have description")
            XCTAssertNotNil(error.failureReason, "Error should have failure reason")
            XCTAssertNotNil(error.recoverySuggestion, "Error should have recovery suggestion")
        }
    }

    // MARK: - Dual-Source Recording Tests

    /// Test 5: Dual-source recording mixes both audio streams
    ///
    /// Validates:
    /// - Records with both sources enabled
    /// - Both audio streams are processed
    /// - Single transcript produced from mixed audio
    func testDualSourceRecordingProcessesBothStreams() async throws {
        // GIVEN: Both sources enabled
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true,
            systemAudioEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        var transcriptionCount = 0
        await coordinator.onTranscriptionResult { _, _ in
            transcriptionCount += 1
        }

        // WHEN: Recording with both sources (system audio may fail in test environment)
        do {
            try await coordinator.startRecording(title: "Dual Source Test")

            let isRecording = await coordinator.isRecording
            XCTAssertTrue(isRecording, "Should be recording")

            try await Task.sleep(for: .seconds(2))
            let transcriptURL = try await coordinator.stopRecording()

            // THEN: Verify single unified output
            XCTAssertTrue(FileManager.default.fileExists(atPath: transcriptURL.path), "Transcript should exist")

            let content = try String(contentsOf: transcriptURL, encoding: .utf8)
            XCTAssertTrue(content.contains("Olive - Call Transcription Transcript"), "Should have valid header")

            // Verify it's a single transcript (not two separate ones)
            let lines = content.components(separatedBy: .newlines)
            let headerCount = lines.filter { $0.contains("Olive - Call Transcription Transcript") }.count
            XCTAssertEqual(headerCount, 1, "Should have exactly one header (single unified transcript)")

        } catch {
            // System audio may not be available in test environment - that's okay for this test
            // The important part is that we tried to set up both sources
            XCTAssert(error is CallTranscriptionError, "Should throw CallTranscriptionError if audio unavailable")
        }
    }

    // MARK: - Error Scenario Tests

    /// Test 6: Handles permission denied gracefully
    ///
    /// Validates:
    /// - Detects missing permissions
    /// - Provides meaningful error messages
    /// - Cleans up state after error
    func testHandlesPermissionDeniedGracefully() async throws {
        // GIVEN: Configuration that requires permissions
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Attempting to start recording
        // Note: In test environment, permissions are typically granted
        // This test validates the error handling structure exists
        do {
            try await coordinator.startRecording(title: "Permission Test")

            // If permissions granted (typical in tests), verify recording works
            let isRecording = await coordinator.isRecording
            XCTAssertTrue(isRecording)

            try await coordinator.stopRecording()

        } catch let error as CallTranscriptionError {
            // If permission denied, verify error is well-formed
            XCTAssertNotNil(error.errorDescription)
            XCTAssertNotNil(error.failureReason)
            XCTAssertNotNil(error.recoverySuggestion)

            // Verify state is clean after error
            let isRecording = await coordinator.isRecording
            XCTAssertFalse(isRecording, "Should not be recording after error")
        }
    }

    /// Test 7: Handles transcription unavailable
    ///
    /// Validates:
    /// - Detects unsupported locale
    /// - Handles transcription model unavailability
    /// - Provides meaningful error or fallback
    func testHandlesTranscriptionUnavailable() async throws {
        // GIVEN: Invalid/unsupported locale
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "xx-XX"), // Invalid locale
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Attempting to start recording
        do {
            try await coordinator.startRecording(title: "Unsupported Locale Test")

            // May succeed with fallback behavior
            let isRecording = await coordinator.isRecording
            if isRecording {
                try await coordinator.stopRecording()
            }

        } catch let error as CallTranscriptionError {
            // Should provide meaningful error for unsupported locale
            XCTAssertNotNil(error.errorDescription)

            // Verify clean state
            let isRecording = await coordinator.isRecording
            XCTAssertFalse(isRecording)
        }
    }

    /// Test 8: Handles write failures
    ///
    /// Validates:
    /// - Detects non-writable output folder
    /// - Provides meaningful error
    /// - Cleans up after error
    func testHandlesWriteFailures() async throws {
        // GIVEN: Read-only output folder
        let readOnlyFolder = testOutputFolder.appendingPathComponent("readonly")
        try FileManager.default.createDirectory(at: readOnlyFolder, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o444], ofItemAtPath: readOnlyFolder.path)

        defer {
            // Cleanup
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: readOnlyFolder.path)
        }

        let config = RecordingConfiguration(
            outputFolder: readOnlyFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Attempting to start recording
        do {
            try await coordinator.startRecording(title: "Write Failure Test")
            XCTFail("Should throw error for read-only folder")

        } catch let error as CallTranscriptionError {
            // THEN: Verify error is meaningful
            XCTAssertNotNil(error.errorDescription)
            XCTAssertNotNil(error.failureReason)

            // Verify state is clean
            let isRecording = await coordinator.isRecording
            XCTAssertFalse(isRecording, "Should not be recording after write error")
        }
    }

    /// Test 9: Cleans up after errors
    ///
    /// Validates:
    /// - Error during startup triggers cleanup
    /// - State is reset to initial condition
    /// - Can start new recording after error
    func testCleansUpAfterErrors() async throws {
        // GIVEN: Invalid configuration
        let config = RecordingConfiguration(
            outputFolder: "/nonexistent/invalid/path",
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Attempting to start with invalid config
        do {
            try await coordinator.startRecording(title: "Cleanup Test")
            XCTFail("Should throw error")

        } catch {
            // THEN: Verify state is clean
            let isRecording = await coordinator.isRecording
            XCTAssertFalse(isRecording, "Should not be recording after error")
        }

        // AND: Can create new coordinator with valid config
        let validConfig = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: validConfig)

        // Should be able to start successfully
        try await coordinator.startRecording(title: "After Error Test")
        let isRecording = await coordinator.isRecording
        XCTAssertTrue(isRecording, "Should be able to record after previous error")

        try await coordinator.stopRecording()
    }

    // MARK: - State Transition Tests

    /// Test 10: Handles rapid start/stop cycles
    ///
    /// Validates:
    /// - Can stop recording immediately after start
    /// - Can start new recording immediately after stop
    /// - State remains consistent through rapid transitions
    func testHandlesRapidStartStopCycles() async throws {
        // GIVEN: Valid configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Performing rapid start/stop cycles
        for i in 1...3 {
            try await coordinator.startRecording(title: "Rapid Test \(i)")

            var isRecording = await coordinator.isRecording
            XCTAssertTrue(isRecording, "Should be recording after start")

            // Minimal recording time
            try await Task.sleep(for: .milliseconds(100))

            let transcriptURL = try await coordinator.stopRecording()

            isRecording = await coordinator.isRecording
            XCTAssertFalse(isRecording, "Should not be recording after stop")

            // Verify file was created
            XCTAssertTrue(FileManager.default.fileExists(atPath: transcriptURL.path), "Transcript \(i) should exist")
        }

        // THEN: All files should exist and be valid
        let files = try FileManager.default.contentsOfDirectory(at: testOutputFolder, includingPropertiesForKeys: nil)
        let transcriptFiles = files.filter { $0.pathExtension == "txt" }
        XCTAssertEqual(transcriptFiles.count, 3, "Should have created 3 transcript files")
    }

    /// Test 11: UI state updates correctly during recording
    ///
    /// Validates:
    /// - State is idle initially
    /// - State transitions to recording on start
    /// - State transitions back to idle on stop
    /// - State remains consistent throughout lifecycle
    func testUIStateUpdatesCorrectlyDuringRecording() async throws {
        // GIVEN: Valid configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Checking state throughout lifecycle

        // Initial state
        var isRecording = await coordinator.isRecording
        XCTAssertFalse(isRecording, "Should not be recording initially")

        // After start
        try await coordinator.startRecording(title: "State Test")
        isRecording = await coordinator.isRecording
        XCTAssertTrue(isRecording, "Should be recording after start")

        // During recording
        try await Task.sleep(for: .milliseconds(500))
        isRecording = await coordinator.isRecording
        XCTAssertTrue(isRecording, "Should still be recording")

        // After stop
        try await coordinator.stopRecording()
        isRecording = await coordinator.isRecording
        XCTAssertFalse(isRecording, "Should not be recording after stop")
    }

    /// Test 12: Cannot start multiple concurrent recordings
    ///
    /// Validates:
    /// - Starting while already recording throws error
    /// - Original recording continues unaffected
    /// - State remains consistent
    func testCannotStartMultipleConcurrentRecordings() async throws {
        // GIVEN: Active recording
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        try await coordinator.startRecording(title: "First Recording")

        var isRecording = await coordinator.isRecording
        XCTAssertTrue(isRecording)

        // WHEN: Attempting to start second recording
        do {
            try await coordinator.startRecording(title: "Second Recording")
            XCTFail("Should not allow concurrent recording start")

        } catch let error as CallTranscriptionError {
            // THEN: Should throw error
            XCTAssertNotNil(error.errorDescription)
        }

        // Original recording should still be active
        isRecording = await coordinator.isRecording
        XCTAssertTrue(isRecording, "Original recording should still be active")

        // Should be able to stop original recording
        let transcriptURL = try await coordinator.stopRecording()
        XCTAssertNotNil(transcriptURL)
    }

    // MARK: - Output Validation Tests

    /// Test 13: Transcript file format is correct
    ///
    /// Validates:
    /// - Header contains "Olive - Call Transcription Transcript"
    /// - Header contains formatted date
    /// - Header contains title if provided
    /// - Header has separator line
    /// - Body has proper structure
    func testTranscriptFileFormatIsCorrect() async throws {
        // GIVEN: Valid configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        let testTitle = "Format Validation Test"

        // WHEN: Creating a transcript
        try await coordinator.startRecording(title: testTitle)
        try await Task.sleep(for: .seconds(1))
        let transcriptURL = try await coordinator.stopRecording()

        // THEN: Verify format
        let content = try String(contentsOf: transcriptURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        // Verify header structure
        XCTAssertTrue(lines.count >= 4, "Should have at least 4 header lines")
        XCTAssertEqual(lines[0], "Olive - Call Transcription Transcript", "First line should be app title")
        XCTAssertTrue(lines[1].hasPrefix("Date:"), "Second line should be date")
        XCTAssertEqual(lines[2], "Title: \(testTitle)", "Third line should be title")
        XCTAssertEqual(lines[3], "================================================================================", "Fourth line should be separator")

        // Verify date format is human-readable
        XCTAssertTrue(lines[1].contains("Date:"), "Date line should have label")
        let dateString = lines[1].replacingOccurrences(of: "Date: ", with: "")
        XCTAssertFalse(dateString.isEmpty, "Date should not be empty")
    }

    /// Test 14: Timestamps are formatted correctly
    ///
    /// Validates:
    /// - Timestamps use [MM:SS] format for short recordings
    /// - Timestamps use [HH:MM:SS] format for long recordings
    /// - Timestamps are properly bracketed
    func testTimestampsAreFormattedCorrectly() async throws {
        // GIVEN: Valid configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        var capturedTranscriptions: [(text: String, isFinal: Bool)] = []
        await coordinator.onTranscriptionResult { text, isFinal in
            capturedTranscriptions.append((text, isFinal))
        }

        // WHEN: Recording for a few seconds
        try await coordinator.startRecording(title: "Timestamp Test")
        try await Task.sleep(for: .seconds(2))
        let transcriptURL = try await coordinator.stopRecording()

        // THEN: If any transcriptions were captured, check timestamp format
        let content = try String(contentsOf: transcriptURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        // Look for timestamp lines (format: [MM:SS] text or [HH:MM:SS] text)
        let timestampPattern = /\[(\d+:)?\d{2}:\d{2}\]/

        for line in lines {
            if line.contains("[") && line.contains("]") {
                // Found a line with brackets - verify timestamp format
                let hasValidTimestamp = line.contains(timestampPattern)
                if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                    XCTAssertTrue(hasValidTimestamp || !line.contains("["), "Lines with brackets should have valid timestamp format")
                }
            }
        }
    }

    /// Test 15: Content is readable and UTF-8 encoded
    ///
    /// Validates:
    /// - File can be read as UTF-8
    /// - Content is not corrupted
    /// - Special characters are preserved
    func testContentIsReadableAndUTF8Encoded() async throws {
        // GIVEN: Valid configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        let testTitle = "UTF-8 Test: Special chars → ñ ü ø ∞ 日本語"

        // WHEN: Creating transcript with special characters in title
        try await coordinator.startRecording(title: testTitle)
        try await Task.sleep(for: .seconds(1))
        let transcriptURL = try await coordinator.stopRecording()

        // THEN: Verify UTF-8 encoding
        do {
            let content = try String(contentsOf: transcriptURL, encoding: .utf8)

            // Should be able to read without errors
            XCTAssertFalse(content.isEmpty, "Content should not be empty")

            // Should preserve special characters in title
            XCTAssertTrue(content.contains(testTitle), "Should preserve special characters in UTF-8")

            // Verify we can read it as data and decode as UTF-8
            let data = try Data(contentsOf: transcriptURL)
            let decodedString = String(data: data, encoding: .utf8)
            XCTAssertNotNil(decodedString, "Should be valid UTF-8 data")
            XCTAssertEqual(content, decodedString, "Content should match when read as UTF-8")

        } catch {
            XCTFail("Should be able to read file as UTF-8: \(error)")
        }
    }

    /// Test 16: Multiple recordings create unique files
    ///
    /// Validates:
    /// - Each recording creates a separate file
    /// - Files have unique names
    /// - All files are valid and readable
    func testMultipleRecordingsCreateUniqueFiles() async throws {
        // GIVEN: Valid configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        var transcriptURLs: [URL] = []

        // WHEN: Creating multiple recordings
        for i in 1...3 {
            try await coordinator.startRecording(title: "Recording \(i)")
            try await Task.sleep(for: .milliseconds(500))
            let url = try await coordinator.stopRecording()
            transcriptURLs.append(url)

            // Small delay between recordings to ensure unique timestamps
            try await Task.sleep(for: .milliseconds(100))
        }

        // THEN: Verify all files are unique
        XCTAssertEqual(transcriptURLs.count, 3, "Should have 3 URLs")

        let uniqueURLs = Set(transcriptURLs)
        XCTAssertEqual(uniqueURLs.count, 3, "All URLs should be unique")

        // Verify all files exist and are readable
        for (index, url) in transcriptURLs.enumerated() {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "File \(index + 1) should exist")

            let content = try String(contentsOf: url, encoding: .utf8)
            XCTAssertTrue(content.contains("Olive - Call Transcription Transcript"), "File \(index + 1) should have valid header")
            XCTAssertTrue(content.contains("Recording \(index + 1)"), "File \(index + 1) should have correct title")
        }
    }
}
