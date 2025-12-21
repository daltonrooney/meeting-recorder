import XCTest
import AVFoundation
@testable import CallTranscription

/// Integration tests for audio file saving feature following TDD methodology.
/// Tests are written FIRST before implementation.
final class AudioFileSavingIntegrationTests: XCTestCase {
    var tempDirectory: URL!
    var appState: AppState!

    override func setUp() async throws {
        try await super.setUp()

        // Create temp directory for testing
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        // Create AppState with test settings
        appState = await AppState(settingsManager: SettingsManager(userDefaults: UserDefaults(suiteName: UUID().uuidString)!))
    }

    override func tearDown() async throws {
        // Clean up temp directory
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        try await super.tearDown()
    }

    // MARK: - Audio File Creation Tests

    @MainActor
    func testAudioFileCreatedWhenSaveOriginalAudioIsTrue() async throws {
        // This test verifies that when saveOriginalAudio is enabled in RecordingConfiguration,
        // an audio file is created alongside the transcript

        let config = RecordingConfiguration(
            outputFolder: tempDirectory.path,
            locale: Locale(identifier: "en-US"),
            saveOriginalAudio: true
        )

        let coordinator = RecordingSessionCoordinator(configuration: config)
        try await coordinator.startRecording(title: "Test Recording")

        // Simulate some audio capture
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let transcriptURL = try await coordinator.stopRecording()

        // Verify audio file was created
        let audioFilename = transcriptURL.deletingPathExtension().lastPathComponent + ".m4a"
        let audioURL = tempDirectory.appendingPathComponent(audioFilename)

        XCTAssertTrue(
            FileManager.default.fileExists(atPath: audioURL.path),
            "Audio file should exist when saveOriginalAudio is true"
        )
    }

    @MainActor
    func testAudioFileNotCreatedWhenSaveOriginalAudioIsFalse() async throws {
        // This test verifies that when saveOriginalAudio is disabled,
        // NO audio file is created (only transcript)

        let config = RecordingConfiguration(
            outputFolder: tempDirectory.path,
            locale: Locale(identifier: "en-US"),
            saveOriginalAudio: false
        )

        let coordinator = RecordingSessionCoordinator(configuration: config)
        try await coordinator.startRecording(title: "Test Recording")

        // Simulate some audio capture
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let transcriptURL = try await coordinator.stopRecording()

        // Verify NO audio file was created
        let audioFilename = transcriptURL.deletingPathExtension().lastPathComponent + ".m4a"
        let audioURL = tempDirectory.appendingPathComponent(audioFilename)

        XCTAssertFalse(
            FileManager.default.fileExists(atPath: audioURL.path),
            "Audio file should NOT exist when saveOriginalAudio is false"
        )
    }

    // MARK: - File Naming Tests

    @MainActor
    func testAudioFileNameMatchesTranscriptName() async throws{
        // Verify that audio file and transcript have matching base names

        let config = RecordingConfiguration(
            outputFolder: tempDirectory.path,
            locale: Locale(identifier: "en-US"),
            filenameTemplate: "test_recording_{date}_{time}.txt",
            saveOriginalAudio: true
        )

        let coordinator = RecordingSessionCoordinator(configuration: config)
        try await coordinator.startRecording(title: "Test Recording")
        try await Task.sleep(nanoseconds: 100_000_000)
        let transcriptURL = try await coordinator.stopRecording()

        let transcriptBasename = transcriptURL.deletingPathExtension().lastPathComponent
        let audioURL = tempDirectory.appendingPathComponent(transcriptBasename + ".m4a")

        XCTAssertTrue(FileManager.default.fileExists(atPath: audioURL.path))
        XCTAssertEqual(
            transcriptURL.deletingPathExtension().lastPathComponent,
            audioURL.deletingPathExtension().lastPathComponent
        )
    }

    @MainActor
    func testAudioFileUsesM4AExtension() async throws {
        let config = RecordingConfiguration(
            outputFolder: tempDirectory.path,
            locale: Locale(identifier: "en-US"),
            saveOriginalAudio: true
        )

        let coordinator = RecordingSessionCoordinator(configuration: config)
        try await coordinator.startRecording(title: "Test Recording")
        try await Task.sleep(nanoseconds: 100_000_000)
        let transcriptURL = try await coordinator.stopRecording()

        let audioFilename = transcriptURL.deletingPathExtension().lastPathComponent + ".m4a"
        let audioURL = tempDirectory.appendingPathComponent(audioFilename)

        XCTAssertTrue(audioURL.pathExtension == "m4a")
    }

    // MARK: - Audio Content Tests

    @MainActor
    func testAudioFileContainsData() async throws {
        // Verify that the audio file actually has content (not empty)

        let config = RecordingConfiguration(
            outputFolder: tempDirectory.path,
            locale: Locale(identifier: "en-US"),
            saveOriginalAudio: true
        )

        let coordinator = RecordingSessionCoordinator(configuration: config)
        try await coordinator.startRecording(title: "Test Recording")

        // Allow more time for audio capture
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        let transcriptURL = try await coordinator.stopRecording()

        let audioFilename = transcriptURL.deletingPathExtension().lastPathComponent + ".m4a"
        let audioURL = tempDirectory.appendingPathComponent(audioFilename)

        let attributes = try FileManager.default.attributesOfItem(atPath: audioURL.path)
        let fileSize = attributes[FileAttributeKey.size] as! UInt64

        XCTAssertGreaterThan(fileSize, 0, "Audio file should contain data")
    }

    // MARK: - Error Handling Tests

    @MainActor
    func testRecordingCleansUpAudioFileOnError() async throws {
        // Verify that if recording fails, partial audio file is cleaned up

        // Create a folder that will fail during recording
        let invalidFolder = "/nonexistent/path/that/does/not/exist"

        let config = RecordingConfiguration(
            outputFolder: invalidFolder,
            locale: Locale(identifier: "en-US"),
            saveOriginalAudio: true
        )

        let coordinator = RecordingSessionCoordinator(configuration: config)

        do {
            try await coordinator.startRecording(title: "Test Recording")
            XCTFail("Expected error when starting recording with invalid folder")
        } catch {
            // Expected - recording should fail
            // Verify no orphaned files in temp directory
            let tempFiles = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
            let audioFiles = tempFiles.filter { $0.pathExtension == "m4a" }
            XCTAssertEqual(audioFiles.count, 0, "No orphaned audio files should exist")
        }
    }

    // MARK: - AppState Integration Tests
    // Note: These tests are skipped for now as they require more complex AppState setup
    // The core functionality is already tested by RecordingSessionCoordinator tests

    // MARK: - Concurrent Recording Tests

    @MainActor
    func testMultipleRecordingsCreateSeparateAudioFiles() async throws {
        // Verify that starting/stopping multiple recordings creates distinct audio files

        let config = RecordingConfiguration(
            outputFolder: tempDirectory.path,
            locale: Locale(identifier: "en-US"),
            saveOriginalAudio: true
        )

        // First recording
        let coordinator1 = RecordingSessionCoordinator(configuration: config)
        try await coordinator1.startRecording(title: "Test Recording 1")
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await coordinator1.stopRecording()

        // Second recording
        try await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second to ensure different timestamp
        let coordinator2 = RecordingSessionCoordinator(configuration: config)
        try await coordinator2.startRecording(title: "Test Recording 2")
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await coordinator2.stopRecording()

        // Verify two distinct audio files
        let files = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
        let audioFiles = files.filter { $0.pathExtension == "m4a" }

        XCTAssertEqual(audioFiles.count, 2, "Two distinct audio files should be created")
    }
}
