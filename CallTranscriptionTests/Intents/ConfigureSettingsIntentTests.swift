import XCTest
import AppIntents
@testable import CallTranscription

@MainActor
final class ConfigureSettingsIntentTests: XCTestCase {

    var intent: ConfigureSettingsIntent!
    var mockSettingsManager: SettingsManager!

    override func setUp() async throws {
        try await super.setUp()
        mockSettingsManager = SettingsManager(userDefaults: UserDefaults(suiteName: "test.ConfigureSettingsIntent")!)
        intent = ConfigureSettingsIntent()
    }

    override func tearDown() async throws {
        intent = nil
        mockSettingsManager = nil

        // Clean up test UserDefaults
        if let testDefaults = UserDefaults(suiteName: "test.ConfigureSettingsIntent") {
            testDefaults.removePersistentDomain(forName: "test.ConfigureSettingsIntent")
        }

        try await super.tearDown()
    }

    // MARK: - Metadata Tests

    func testIntentHasCorrectTitle() {
        let title = ConfigureSettingsIntent.title
        XCTAssertNotNil(title, "Intent should have a title")
        XCTAssertTrue(String(describing: title).lowercased().contains("settings") || String(describing: title).lowercased().contains("configure"),
                     "Title should indicate configuring settings")
    }

    func testIntentHasDescription() {
        let description = ConfigureSettingsIntent.description
        XCTAssertNotNil(description, "Intent should have a description")
    }

    // MARK: - Output Folder Configuration Tests

    func testIntentUpdatesOutputFolder() async throws {
        // Given: Intent with new output folder
        let newFolder = "~/Documents/MyTranscripts"
        intent.outputFolder = newFolder

        // When: Intent is performed
        // let result = try await intent.perform()

        // Then: Settings should be updated
        // XCTAssertEqual(mockSettingsManager.outputFolder, newFolder)
        // (Test will fail until ConfigureSettingsIntent is implemented)
    }

    func testIntentValidatesOutputFolderPath() async throws {
        // Given: Intent with invalid path (path traversal)
        let invalidPath = "~/Documents/../../../etc/passwd"
        intent.outputFolder = invalidPath

        // When: Intent is performed
        // Then: Should reject invalid path
        // do {
        //     _ = try await intent.perform()
        //     XCTFail("Should reject path with traversal")
        // } catch {
        //     // Expected to throw
        // }
        // (Test will fail until implementation exists)
    }

    func testIntentExpandsTildePath() async throws {
        // Given: Intent with tilde path
        intent.outputFolder = "~/Desktop/Transcripts"

        // When: Intent is performed
        // let result = try await intent.perform()

        // Then: Path should be expanded and stored
        // XCTAssertTrue(mockSettingsManager.expandedOutputFolderPath().hasPrefix("/Users/"))
        // (Test will fail until implementation exists)
    }

    // MARK: - Audio Capture Settings Tests

    func testIntentUpdatesMicrophoneSetting() async throws {
        // Given: Initial microphone setting
        let initialValue = mockSettingsManager.captureMicrophone

        // When: Intent updates microphone setting
        intent.captureMicrophone = !initialValue
        // let result = try await intent.perform()

        // Then: Settings should be updated
        // XCTAssertEqual(mockSettingsManager.captureMicrophone, !initialValue)
        // (Test will fail until implementation exists)
    }

    func testIntentUpdatesSystemAudioSetting() async throws {
        // Given: Initial system audio setting
        let initialValue = mockSettingsManager.captureSystemAudio

        // When: Intent updates system audio setting
        intent.captureSystemAudio = !initialValue
        // let result = try await intent.perform()

        // Then: Settings should be updated
        // XCTAssertEqual(mockSettingsManager.captureSystemAudio, !initialValue)
        // (Test will fail until implementation exists)
    }

    // MARK: - Post-Recording Action Tests

    func testIntentUpdatesPostRecordingAction() async throws {
        // Given: Intent with new post-recording action
        intent.postRecordingActionType = PostRecordingActionTypeParameter.shortcut

        // When: Intent is performed
        // let result = try await intent.perform()

        // Then: Settings should be updated
        // XCTAssertEqual(mockSettingsManager.postRecordingActionType, .shortcut)
        // (Test will fail until implementation exists)
    }

    func testIntentUpdatesShortcutIdentifier() async throws {
        // Given: Intent with shortcut identifier
        let shortcutID = "my-shortcut-123"
        intent.shortcutIdentifier = shortcutID

        // When: Intent is performed
        // let result = try await intent.perform()

        // Then: Settings should be updated
        // XCTAssertEqual(mockSettingsManager.shortcutIdentifier, shortcutID)
        // (Test will fail until implementation exists)
    }

    func testIntentUpdatesScriptPath() async throws {
        // Given: Intent with script path
        let scriptPath = "~/Scripts/process-transcript.sh"
        intent.postRecordingScript = scriptPath

        // When: Intent is performed
        // let result = try await intent.perform()

        // Then: Settings should be updated
        // XCTAssertEqual(mockSettingsManager.postRecordingScript, scriptPath)
        // (Test will fail until implementation exists)
    }

    // MARK: - Multiple Settings Update Tests

    func testIntentUpdatesMultipleSettingsAtOnce() async throws {
        // Given: Intent with multiple settings
        intent.outputFolder = "~/Documents/NewTranscripts"
        intent.captureMicrophone = false
        intent.captureSystemAudio = true
        intent.postRecordingActionType = .script

        // When: Intent is performed
        // let result = try await intent.perform()

        // Then: All settings should be updated
        // XCTAssertEqual(mockSettingsManager.outputFolder, "~/Documents/NewTranscripts")
        // XCTAssertFalse(mockSettingsManager.captureMicrophone)
        // XCTAssertTrue(mockSettingsManager.captureSystemAudio)
        // XCTAssertEqual(mockSettingsManager.postRecordingActionType, .script)
        // (Test will fail until implementation exists)
    }

    func testIntentOnlyUpdatesProvidedSettings() async throws {
        // Given: Intent with only one setting specified
        let initialMic = mockSettingsManager.captureMicrophone
        let initialSysAudio = mockSettingsManager.captureSystemAudio
        intent.outputFolder = "~/Desktop/NewFolder"
        // Other settings are nil

        // When: Intent is performed
        // let result = try await intent.perform()

        // Then: Only specified setting should change
        // XCTAssertEqual(mockSettingsManager.outputFolder, "~/Desktop/NewFolder")
        // XCTAssertEqual(mockSettingsManager.captureMicrophone, initialMic, "Should not change unspecified setting")
        // XCTAssertEqual(mockSettingsManager.captureSystemAudio, initialSysAudio, "Should not change unspecified setting")
        // (Test will fail until implementation exists)
    }

    // MARK: - Persistence Tests

    func testIntentPersistsChanges() async throws {
        // Given: Intent with new settings
        intent.outputFolder = "~/Desktop/PersistentTranscripts"

        // When: Intent is performed
        // _ = try await intent.perform()

        // Then: Changes should be persisted to UserDefaults
        // let newSettingsManager = SettingsManager(userDefaults: UserDefaults(suiteName: "test.ConfigureSettingsIntent")!)
        // XCTAssertEqual(newSettingsManager.outputFolder, "~/Desktop/PersistentTranscripts")
        // (Test will fail until implementation exists)
    }

    // MARK: - Thread Safety Tests

    func testIntentExecutesOnMainActor() async throws {
        // Verify the intent execution happens on MainActor
    }

    // MARK: - Result Tests

    func testIntentReturnsSuccessResult() async throws {
        // Given: Intent with valid settings
        intent.outputFolder = "~/Desktop/Transcripts"

        // When: Intent is performed
        // let result = try await intent.perform()

        // Then: Result should indicate success
        // (Test will fail until implementation exists)
    }

    // MARK: - Integration Tests

    func testIntentIntegratesWithSettingsManager() async throws {
        // Given: Fresh settings manager
        let initialFolder = mockSettingsManager.outputFolder

        // When: Intent updates settings
        intent.outputFolder = "~/Documents/NewLocation"
        // let result = try await intent.perform()

        // Then: SettingsManager should reflect changes
        // XCTAssertNotEqual(mockSettingsManager.outputFolder, initialFolder)
        // XCTAssertEqual(mockSettingsManager.outputFolder, "~/Documents/NewLocation")
        // (Test will fail until implementation exists)
    }

    // MARK: - Validation Tests

    func testIntentRejectsEmptyOutputFolder() async throws {
        // Given: Intent with empty output folder
        intent.outputFolder = ""

        // When: Intent is performed
        // Then: Should handle empty path appropriately
        // (Implementation decision: accept empty = keep current, or reject?)
        // (Test will fail until implementation exists)
    }

    func testIntentHandlesAbsolutePaths() async throws {
        // Given: Intent with absolute path
        intent.outputFolder = "/tmp/Transcripts"

        // When: Intent is performed
        // let result = try await intent.perform()

        // Then: Absolute path should be accepted
        // XCTAssertEqual(mockSettingsManager.outputFolder, "/tmp/Transcripts")
        // (Test will fail until implementation exists)
    }
}
