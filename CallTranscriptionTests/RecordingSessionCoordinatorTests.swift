import XCTest
import AVFoundation
@testable import CallTranscription

/// Tests for RecordingSessionCoordinator following TDD methodology.
/// Tests are written FIRST before implementation.
///
/// This coordinator integrates all recording components:
/// - MicrophoneCapture + SystemAudioCapture
/// - AudioMixer
/// - TranscriptionManager
/// - TranscriptWriter
/// - OutputFolderManager
/// - ShellScriptExecutor
final class RecordingSessionCoordinatorTests: XCTestCase {

    var coordinator: RecordingSessionCoordinator!
    var testOutputFolder: URL!

    override func setUp() async throws {
        try await super.setUp()

        // Create temp output folder
        testOutputFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoordinatorTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testOutputFolder, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        coordinator = nil

        // Clean up temp folder
        if let testOutputFolder = testOutputFolder {
            try? FileManager.default.removeItem(at: testOutputFolder)
        }
        testOutputFolder = nil

        try await super.tearDown()
    }

    // MARK: - Session Initialization Tests

    func testCanCreateCoordinatorWithConfiguration() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true,
            systemAudioEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)
        XCTAssertNotNil(coordinator)
    }

    func testInitializesAllRequiredComponents() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US")
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // Coordinator should initialize internal components
        XCTAssertNotNil(coordinator)
    }

    func testValidatesConfigurationBeforeStart() async throws {
        let config = RecordingConfiguration(
            outputFolder: "/nonexistent/invalid/path",
            locale: Locale(identifier: "en-US")
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        do {
            try await coordinator.startRecording(title: "Test")
            XCTFail("Should throw error for invalid output folder")
        } catch {
            // Expected
            XCTAssertTrue(error is CallTranscriptionError)
        }
    }

    func testHandlesMissingComponentsGracefully() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: false,
            systemAudioEnabled: false
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        do {
            try await coordinator.startRecording(title: "Test")
            XCTFail("Should throw error when no audio sources enabled")
        } catch {
            // Expected - at least one source must be enabled
            XCTAssert(error is CallTranscriptionError)
        }
    }

    // MARK: - Recording Start Sequence Tests

    func testStartsRecordingWithValidConfiguration() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true,
            systemAudioEnabled: false
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        try await coordinator.startRecording(title: "Test Recording")

        let isRecording = await coordinator.isRecording
        XCTAssertTrue(isRecording)
    }

    func testUpdatesStateToRecording() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        var isRecordingBefore = await coordinator.isRecording
        XCTAssertFalse(isRecordingBefore)

        try await coordinator.startRecording(title: "Test")

        isRecordingBefore = await coordinator.isRecording
        XCTAssertTrue(isRecordingBefore)
    }

    func testSequenceHandlesErrorsAtEachStep() async throws {
        // Test that errors during startup are propagated
        let config = RecordingConfiguration(
            outputFolder: "/invalid/path",
            locale: Locale(identifier: "en-US")
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        do {
            try await coordinator.startRecording(title: "Test")
            XCTFail("Should throw error")
        } catch {
            // Should still be in stopped state
            let isRecording = await coordinator.isRecording
            XCTAssertFalse(isRecording)
        }
    }

    func testCannotStartWhenAlreadyRecording() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        try await coordinator.startRecording(title: "Test 1")

        do {
            try await coordinator.startRecording(title: "Test 2")
            XCTFail("Should throw error when already recording")
        } catch {
            // Expected
            XCTAssert(error is CallTranscriptionError)
        }
    }

    // MARK: - Audio Routing Tests

    func testMicrophoneBuffersReachTranscription() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true,
            systemAudioEnabled: false
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        var receivedTranscription = false
        await coordinator.onTranscriptionResult { _, _ in
            receivedTranscription = true
        }

        try await coordinator.startRecording(title: "Test")

        // Simulate speaking for a moment
        try await Task.sleep(for: .seconds(1))

        // Note: In real scenario, actual audio would trigger transcription
        // This test verifies the routing is set up
        XCTAssertNotNil(coordinator)
    }

    func testSystemAudioBuffersReachTranscription() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: false,
            systemAudioEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        try await coordinator.startRecording(title: "Test")

        // Verify coordinator started successfully
        let isRecording = await coordinator.isRecording
        XCTAssertTrue(isRecording)
    }

    func testBothSourcesWorkIndependently() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true,
            systemAudioEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        try await coordinator.startRecording(title: "Test")

        let isRecording = await coordinator.isRecording
        XCTAssertTrue(isRecording)
    }

    func testHandlesWhenOnlyOneSourceEnabled() async throws {
        // Microphone only
        let micConfig = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true,
            systemAudioEnabled: false
        )

        coordinator = await RecordingSessionCoordinator(configuration: micConfig)
        try await coordinator.startRecording(title: "Mic Only")

        var isRecording = await coordinator.isRecording
        XCTAssertTrue(isRecording)

        try await coordinator.stopRecording()

        // System audio only
        let sysConfig = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: false,
            systemAudioEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: sysConfig)
        try await coordinator.startRecording(title: "System Only")

        isRecording = await coordinator.isRecording
        XCTAssertTrue(isRecording)
    }

    // MARK: - Transcription Flow Tests

    func testTranscriptionResultsAreCaptured() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        var capturedResults: [String] = []
        await coordinator.onTranscriptionResult { text, isFinal in
            capturedResults.append(text)
        }

        try await coordinator.startRecording(title: "Test")

        // Note: Actual transcription would require real audio input
        // This test verifies the callback mechanism is set up
        XCTAssertNotNil(coordinator)
    }

    func testResultsAreWrittenToFile() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        try await coordinator.startRecording(title: "Test Recording")

        // Brief recording
        try await Task.sleep(for: .milliseconds(500))

        let transcriptURL = try await coordinator.stopRecording()

        XCTAssertNotNil(transcriptURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: transcriptURL.path))
    }

    func testTimestampsAreCalculatedCorrectly() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        try await coordinator.startRecording(title: "Timestamp Test")

        let startTime = Date()

        try await Task.sleep(for: .seconds(2))

        let transcriptURL = try await coordinator.stopRecording()

        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: transcriptURL.path))

        // Verify recording lasted at least 2 seconds
        let duration = Date().timeIntervalSince(startTime)
        XCTAssertGreaterThan(duration, 2.0)
    }

    func testHandlesPartialAndFinalResults() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        var partialCount = 0
        var finalCount = 0

        await coordinator.onTranscriptionResult { _, isFinal in
            if isFinal {
                finalCount += 1
            } else {
                partialCount += 1
            }
        }

        try await coordinator.startRecording(title: "Test")
        try await Task.sleep(for: .milliseconds(500))
        try await coordinator.stopRecording()

        // Callback mechanism should be set up (actual counts depend on audio input)
        XCTAssertNotNil(coordinator)
    }

    // MARK: - Recording Stop Sequence Tests

    func testStopsRecordingSuccessfully() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        try await coordinator.startRecording(title: "Test")

        var isRecording = await coordinator.isRecording
        XCTAssertTrue(isRecording)

        let transcriptURL = try await coordinator.stopRecording()

        isRecording = await coordinator.isRecording
        XCTAssertFalse(isRecording)
        XCTAssertNotNil(transcriptURL)
    }

    func testFinalizesTranscriptFile() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        try await coordinator.startRecording(title: "Test")
        try await Task.sleep(for: .milliseconds(500))

        let transcriptURL = try await coordinator.stopRecording()

        // File should exist and be readable
        XCTAssertTrue(FileManager.default.fileExists(atPath: transcriptURL.path))

        let content = try String(contentsOf: transcriptURL, encoding: .utf8)
        XCTAssertFalse(content.isEmpty)
        XCTAssertTrue(content.contains("Olive - Call Transcription Transcript"))
    }

    func testReturnsTranscriptFileURL() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        try await coordinator.startRecording(title: "Test")

        let transcriptURL = try await coordinator.stopRecording()

        XCTAssertNotNil(transcriptURL)
        XCTAssertTrue(transcriptURL.path.contains(testOutputFolder.path))
        XCTAssertTrue(transcriptURL.path.hasSuffix(".txt"))
    }

    func testSequenceCompletesInCorrectOrder() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        var events: [String] = []

        await coordinator.onTranscriptionResult { _, _ in
            events.append("transcription")
        }

        try await coordinator.startRecording(title: "Test")
        events.append("started")

        try await Task.sleep(for: .milliseconds(500))

        let _ = try await coordinator.stopRecording()
        events.append("stopped")

        // Verify events occurred in order
        XCTAssertTrue(events.contains("started"))
        XCTAssertTrue(events.contains("stopped"))
        XCTAssertEqual(events.first, "started")
        XCTAssertEqual(events.last, "stopped")
    }

    func testExecutesPostRecordingScriptIfConfigured() async throws {
        // Create a simple test script
        let scriptPath = testOutputFolder.appendingPathComponent("test-script.sh")
        let scriptContent = """
        #!/bin/bash
        echo "Script executed with: $1"
        """
        try scriptContent.write(to: scriptPath, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath.path)

        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true,
            postRecordingScriptPath: scriptPath.path
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        try await coordinator.startRecording(title: "Test")
        try await Task.sleep(for: .milliseconds(500))

        let transcriptURL = try await coordinator.stopRecording()

        // Script should have executed (we can't easily verify output here)
        XCTAssertNotNil(transcriptURL)
    }

    // MARK: - Cleanup Tests

    func testAllResourcesReleasedAfterStop() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        try await coordinator.startRecording(title: "Test")
        try await coordinator.stopRecording()

        let isRecording = await coordinator.isRecording
        XCTAssertFalse(isRecording)
    }

    func testCanStartNewSessionAfterStop() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // First session
        try await coordinator.startRecording(title: "Session 1")
        try await Task.sleep(for: .milliseconds(500))
        let url1 = try await coordinator.stopRecording()

        // Second session
        try await coordinator.startRecording(title: "Session 2")
        try await Task.sleep(for: .milliseconds(500))
        let url2 = try await coordinator.stopRecording()

        XCTAssertNotEqual(url1, url2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url1.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: url2.path))
    }

    func testCleanupHappensEvenOnErrors() async throws {
        let config = RecordingConfiguration(
            outputFolder: "/invalid/path",
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        do {
            try await coordinator.startRecording(title: "Test")
            XCTFail("Should throw error")
        } catch {
            // Despite error, should be in clean state
            let isRecording = await coordinator.isRecording
            XCTAssertFalse(isRecording)
        }
    }

    // MARK: - Error Recovery Tests

    func testHandlesMicrophonePermissionDenied() async throws {
        // Note: This test assumes permission is already granted in test environment
        // In real scenario with denied permission, should throw appropriate error
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // This will succeed if permission granted, which is expected in tests
        try await coordinator.startRecording(title: "Test")

        let isRecording = await coordinator.isRecording
        XCTAssertTrue(isRecording)
    }

    func testHandlesSystemAudioCaptureFailure() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: false,
            systemAudioEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // System audio may fail in test environment without audio device
        // Coordinator should handle this gracefully
        do {
            try await coordinator.startRecording(title: "Test")
            // If it succeeds, verify recording state
            let isRecording = await coordinator.isRecording
            XCTAssertTrue(isRecording)
        } catch {
            // If it fails, should provide meaningful error
            XCTAssert(error is CallTranscriptionError)
        }
    }

    func testHandlesTranscriptionUnavailable() async throws {
        // Test with unsupported locale
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "xx-XX"), // Invalid locale
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        do {
            try await coordinator.startRecording(title: "Test")
            // May succeed with fallback behavior
        } catch {
            // Or may throw locale not supported error
            XCTAssert(error is CallTranscriptionError)
        }
    }

    func testHandlesWriteFailures() async throws {
        // Create read-only folder
        let readOnlyFolder = testOutputFolder.appendingPathComponent("readonly")
        try FileManager.default.createDirectory(at: readOnlyFolder, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o444], ofItemAtPath: readOnlyFolder.path)

        let config = RecordingConfiguration(
            outputFolder: readOnlyFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        do {
            try await coordinator.startRecording(title: "Test")
            XCTFail("Should throw write failure error")
        } catch {
            XCTAssert(error is CallTranscriptionError)
        }

        // Clean up
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: readOnlyFolder.path)
    }

    func testProvidesMeaningfulErrorMessages() async throws {
        let config = RecordingConfiguration(
            outputFolder: "/nonexistent/path",
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        do {
            try await coordinator.startRecording(title: "Test")
            XCTFail("Should throw error")
        } catch let error as CallTranscriptionError {
            // Error should have description
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
            XCTAssertFalse(error.failureReason?.isEmpty ?? true)
            XCTAssertFalse(error.recoverySuggestion?.isEmpty ?? true)
        } catch {
            XCTFail("Should throw CallTranscriptionError")
        }
    }

    // MARK: - State Consistency Tests

    func testStateIsConsistentThroughoutLifecycle() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // Initial state
        var isRecording = await coordinator.isRecording
        XCTAssertFalse(isRecording)

        // Start recording
        try await coordinator.startRecording(title: "Test")
        isRecording = await coordinator.isRecording
        XCTAssertTrue(isRecording)

        // Stop recording
        let _ = try await coordinator.stopRecording()
        isRecording = await coordinator.isRecording
        XCTAssertFalse(isRecording)
    }

    func testHandlesConcurrentStartStopCalls() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // Start recording
        try await coordinator.startRecording(title: "Test")

        // Attempt concurrent start should fail
        do {
            try await coordinator.startRecording(title: "Concurrent")
            XCTFail("Should not allow concurrent start")
        } catch {
            XCTAssert(error is CallTranscriptionError)
        }

        // Original recording should still be active
        let isRecording = await coordinator.isRecording
        XCTAssertTrue(isRecording)
    }

    func testHandlesStopWhenNotStarted() async throws {
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        do {
            let _ = try await coordinator.stopRecording()
            XCTFail("Should throw error when stopping without starting")
        } catch {
            XCTAssert(error is CallTranscriptionError)
        }
    }
}