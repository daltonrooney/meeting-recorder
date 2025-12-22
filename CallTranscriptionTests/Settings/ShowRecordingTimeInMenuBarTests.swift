import XCTest
@testable import CallTranscription

/// Tests for show recording time in menu bar functionality following TDD methodology.
/// Tests are written FIRST before implementation.
@MainActor
final class ShowRecordingTimeInMenuBarTests: XCTestCase {
    var settingsManager: SettingsManager!
    var appState: AppState!

    override func setUp() async throws {
        try await super.setUp()

        // Create test settings manager with custom UserDefaults
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        settingsManager = SettingsManager(userDefaults: userDefaults)
        appState = AppState(settingsManager: settingsManager)
    }

    override func tearDown() async throws {
        try await super.tearDown()
    }

    // MARK: - Settings Tests

    func testShowRecordingTimeInMenuBarSettingExists() {
        // Test that the setting property exists in SettingsManager
        XCTAssertNotNil(settingsManager.showRecordingTimeInMenuBar)
    }

    func testShowRecordingTimeInMenuBarDefaultsToFalse() {
        // Test that the default value is false (opt-in feature)
        XCTAssertFalse(settingsManager.showRecordingTimeInMenuBar)
    }

    func testShowRecordingTimeInMenuBarCanBeSetToTrue() {
        settingsManager.showRecordingTimeInMenuBar = true
        XCTAssertTrue(settingsManager.showRecordingTimeInMenuBar)
    }

    func testShowRecordingTimeInMenuBarCanBeSetToFalse() {
        settingsManager.showRecordingTimeInMenuBar = true
        settingsManager.showRecordingTimeInMenuBar = false
        XCTAssertFalse(settingsManager.showRecordingTimeInMenuBar)
    }

    func testShowRecordingTimeInMenuBarPersistsToUserDefaults() {
        // Set value
        settingsManager.showRecordingTimeInMenuBar = true

        // Create new settings manager with same UserDefaults
        let userDefaults = settingsManager.userDefaults
        let newSettingsManager = SettingsManager(userDefaults: userDefaults)

        // Verify value persisted
        XCTAssertTrue(newSettingsManager.showRecordingTimeInMenuBar)
    }

    func testSettingIndependentOfOtherSettings() {
        // Verify showRecordingTimeInMenuBar doesn't interfere with other settings
        settingsManager.saveOriginalAudio = true
        settingsManager.captureMicrophone = false
        settingsManager.showRecordingTimeInMenuBar = true

        XCTAssertTrue(settingsManager.saveOriginalAudio)
        XCTAssertFalse(settingsManager.captureMicrophone)
        XCTAssertTrue(settingsManager.showRecordingTimeInMenuBar)
    }

    // MARK: - Integration Tests

    func testElapsedTimeAvailableWhenRecording() {
        // When recording starts, elapsed time should be available
        appState.startRecording()

        // Elapsed time should be initialized to "00:00"
        XCTAssertEqual(appState.elapsedTime, "00:00")
    }

    func testElapsedTimeFormatIsAvailable() {
        // Test that elapsed time string is available from AppState
        // The format is managed internally by AppState
        appState.startRecording()

        // Elapsed time should be in MM:SS format initially
        XCTAssertNotNil(appState.elapsedTime)
        XCTAssertFalse(appState.elapsedTime.isEmpty)
        XCTAssertEqual(appState.elapsedTime, "00:00")
    }
}
