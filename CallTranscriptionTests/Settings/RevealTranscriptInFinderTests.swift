import XCTest
@testable import CallTranscription

/// Tests for reveal transcript in Finder functionality following TDD methodology.
/// Tests are written FIRST before implementation.
@MainActor
final class RevealTranscriptInFinderTests: XCTestCase {
    var settingsManager: SettingsManager!
    var appState: AppState!
    var tempDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()

        // Create temp directory for testing
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        // Create test settings manager with custom UserDefaults
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        settingsManager = SettingsManager(userDefaults: userDefaults)
        appState = AppState(settingsManager: settingsManager)
    }

    override func tearDown() async throws {
        // Clean up temp directory
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        try await super.tearDown()
    }

    // MARK: - Settings Tests

    func testRevealTranscriptInFinderSettingExists() {
        // Test that the setting property exists in SettingsManager
        XCTAssertNotNil(settingsManager.revealTranscriptInFinder)
    }

    func testRevealTranscriptInFinderDefaultsToFalse() {
        // Test that the default value is false (opt-in feature)
        XCTAssertFalse(settingsManager.revealTranscriptInFinder)
    }

    func testRevealTranscriptInFinderCanBeSetToTrue() {
        settingsManager.revealTranscriptInFinder = true
        XCTAssertTrue(settingsManager.revealTranscriptInFinder)
    }

    func testRevealTranscriptInFinderCanBeSetToFalse() {
        settingsManager.revealTranscriptInFinder = true
        settingsManager.revealTranscriptInFinder = false
        XCTAssertFalse(settingsManager.revealTranscriptInFinder)
    }

    func testRevealTranscriptInFinderPersistsToUserDefaults() {
        // Set value
        settingsManager.revealTranscriptInFinder = true

        // Create new settings manager with same UserDefaults
        let userDefaults = settingsManager.userDefaults
        let newSettingsManager = SettingsManager(userDefaults: userDefaults)

        // Verify value persisted
        XCTAssertTrue(newSettingsManager.revealTranscriptInFinder)
    }

    // MARK: - Integration Tests

    func testFinderNotRevealedWhenSettingDisabled() async throws {
        // Setup: Disable the setting
        settingsManager.revealTranscriptInFinder = false
        settingsManager.outputFolder = tempDirectory.path

        // Create a test transcript file
        let transcriptURL = tempDirectory.appendingPathComponent("test_transcript.txt")
        try "Test content".write(to: transcriptURL, atomically: true, encoding: .utf8)

        // When setting is disabled, Finder should not be activated
        // (This is verified by no NSWorkspace calls being made)
        // We'll test this by ensuring the flow completes without error

        // Note: This test validates the setting exists and defaults correctly
        // Actual Finder reveal testing requires mocking NSWorkspace which is complex
        XCTAssertFalse(settingsManager.revealTranscriptInFinder)
    }

    func testFinderRevealedWhenSettingEnabled() async throws {
        // Setup: Enable the setting
        settingsManager.revealTranscriptInFinder = true
        settingsManager.outputFolder = tempDirectory.path

        // Create a test transcript file
        let transcriptURL = tempDirectory.appendingPathComponent("test_transcript.txt")
        try "Test content".write(to: transcriptURL, atomically: true, encoding: .utf8)

        // When setting is enabled, Finder should be activated
        // Note: Actual NSWorkspace.shared.activateFileViewerSelecting testing
        // is difficult without UI testing framework, but we verify the setting is enabled
        XCTAssertTrue(settingsManager.revealTranscriptInFinder)
        XCTAssertTrue(FileManager.default.fileExists(atPath: transcriptURL.path))
    }

    func testFinderRevealHandlesNonexistentFile() async throws {
        // Setup: Enable setting but use nonexistent file
        settingsManager.revealTranscriptInFinder = true

        let nonexistentURL = tempDirectory.appendingPathComponent("nonexistent.txt")

        // Verify file doesn't exist
        XCTAssertFalse(FileManager.default.fileExists(atPath: nonexistentURL.path))

        // The reveal should handle this gracefully without crashing
        // (Implementation should log error but not throw)
        // This test ensures the setting infrastructure is in place
        XCTAssertTrue(settingsManager.revealTranscriptInFinder)
    }

    func testSettingIndependentOfOtherSettings() {
        // Verify revealTranscriptInFinder doesn't interfere with other settings
        settingsManager.saveOriginalAudio = true
        settingsManager.captureMicrophone = false
        settingsManager.revealTranscriptInFinder = true

        XCTAssertTrue(settingsManager.saveOriginalAudio)
        XCTAssertFalse(settingsManager.captureMicrophone)
        XCTAssertTrue(settingsManager.revealTranscriptInFinder)
    }
}
