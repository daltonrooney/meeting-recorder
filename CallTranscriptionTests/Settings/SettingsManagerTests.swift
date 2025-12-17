import XCTest
import Combine
@testable import CallTranscription

@MainActor
final class SettingsManagerTests: XCTestCase {

    var settingsManager: SettingsManager!
    var testUserDefaults: UserDefaults!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()

        // Create ephemeral UserDefaults for testing
        testUserDefaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")
        settingsManager = SettingsManager(userDefaults: testUserDefaults!)
        cancellables = []
    }

    override func tearDown() async throws {
        // Clean up test defaults
        if let suiteName = testUserDefaults.dictionaryRepresentation().keys.first {
            testUserDefaults.removePersistentDomain(forName: "test.\(suiteName)")
        }
        cancellables = nil
        settingsManager = nil
        testUserDefaults = nil
        try await super.tearDown()
    }

    // MARK: - Default Values Tests

    func testDefaultOutputFolderIsDesktopTranscripts() {
        XCTAssertEqual(settingsManager.outputFolder, "~/Desktop/Transcripts",
                      "Default output folder should be ~/Desktop/Transcripts")
    }

    func testDefaultPostRecordingScriptIsEmpty() {
        XCTAssertEqual(settingsManager.postRecordingScript, "",
                      "Default post-recording script should be empty string")
    }

    func testDefaultCaptureSystemAudioIsTrue() {
        XCTAssertTrue(settingsManager.captureSystemAudio,
                     "Default capture system audio should be true")
    }

    func testDefaultCaptureMicrophoneIsTrue() {
        XCTAssertTrue(settingsManager.captureMicrophone,
                     "Default capture microphone should be true")
    }

    // MARK: - Persistence Tests

    func testOutputFolderPersistsAcrossInstances() {
        let testPath = "/Users/test/Documents"
        settingsManager.outputFolder = testPath

        // Force save to UserDefaults
        testUserDefaults.set(testPath, forKey: "outputFolder")
        testUserDefaults.synchronize()

        // Create new instance
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertEqual(newManager.outputFolder, testPath,
                      "Output folder should persist across instances")
    }

    func testPostRecordingScriptPersistsAcrossInstances() {
        let testScript = "~/scripts/post-recording.sh"
        settingsManager.postRecordingScript = testScript

        // Force save to UserDefaults
        testUserDefaults.set(testScript, forKey: "postRecordingScript")
        testUserDefaults.synchronize()

        // Create new instance
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertEqual(newManager.postRecordingScript, testScript,
                      "Post-recording script should persist across instances")
    }

    func testCaptureSystemAudioPersistsAcrossInstances() {
        settingsManager.captureSystemAudio = false

        // Force save to UserDefaults
        testUserDefaults.set(false, forKey: "captureSystemAudio")
        testUserDefaults.synchronize()

        // Create new instance
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertFalse(newManager.captureSystemAudio,
                      "Capture system audio setting should persist across instances")
    }

    func testCaptureMicrophonePersistsAcrossInstances() {
        settingsManager.captureMicrophone = false

        // Force save to UserDefaults
        testUserDefaults.set(false, forKey: "captureMicrophone")
        testUserDefaults.synchronize()

        // Create new instance
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertFalse(newManager.captureMicrophone,
                      "Capture microphone setting should persist across instances")
    }

    func testSettingsPersistAfterAppRestart() {
        // Simulate app configuration
        let testPath = "/Users/test/Desktop/MyTranscripts"
        let testScript = "/usr/local/bin/process.sh"

        settingsManager.outputFolder = testPath
        settingsManager.postRecordingScript = testScript
        settingsManager.captureSystemAudio = false
        settingsManager.captureMicrophone = true

        // Force save
        testUserDefaults.set(testPath, forKey: "outputFolder")
        testUserDefaults.set(testScript, forKey: "postRecordingScript")
        testUserDefaults.set(false, forKey: "captureSystemAudio")
        testUserDefaults.set(true, forKey: "captureMicrophone")
        testUserDefaults.synchronize()

        // Simulate app restart with new instance
        let newManager = SettingsManager(userDefaults: testUserDefaults)

        XCTAssertEqual(newManager.outputFolder, testPath, "Output folder should persist")
        XCTAssertEqual(newManager.postRecordingScript, testScript, "Script should persist")
        XCTAssertFalse(newManager.captureSystemAudio, "System audio setting should persist")
        XCTAssertTrue(newManager.captureMicrophone, "Microphone setting should persist")
    }

    // MARK: - Path Validation Tests

    func testTildeExpansionInOutputFolder() {
        settingsManager.outputFolder = "~/Desktop"
        let expanded = settingsManager.expandedOutputFolderPath()

        XCTAssertTrue(expanded.hasPrefix("/Users/") || expanded.hasPrefix("/home/"),
                     "Tilde should expand to home directory path")
        XCTAssertFalse(expanded.hasPrefix("~"),
                      "Expanded path should not start with tilde")
    }

    func testTildeExpansionInPostRecordingScript() {
        settingsManager.postRecordingScript = "~/scripts/post.sh"
        let expanded = settingsManager.expandedPostRecordingScriptPath()

        XCTAssertTrue(expanded.hasPrefix("/Users/") || expanded.hasPrefix("/home/"),
                     "Tilde should expand to home directory path")
        XCTAssertFalse(expanded.hasPrefix("~"),
                      "Expanded path should not start with tilde")
    }

    func testAbsolutePathsArePreserved() {
        let absolutePath = "/Users/testuser/Documents"
        settingsManager.outputFolder = absolutePath
        let expanded = settingsManager.expandedOutputFolderPath()

        XCTAssertEqual(expanded, absolutePath,
                      "Absolute paths should remain unchanged")
    }

    func testEmptyPathIsHandledCorrectly() {
        settingsManager.postRecordingScript = ""
        let expanded = settingsManager.expandedPostRecordingScriptPath()

        XCTAssertEqual(expanded, "",
                      "Empty path should remain empty")
    }

    // MARK: - Observable Properties Tests

    func testOutputFolderChangePublishes() {
        let expectation = expectation(description: "Output folder change should publish")
        var receivedValues: [String] = []

        settingsManager.$outputFolder
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValues.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        settingsManager.outputFolder = "/new/path"

        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedValues.first, "/new/path",
                      "Output folder changes should be published")
    }

    func testPostRecordingScriptChangePublishes() {
        let expectation = expectation(description: "Script change should publish")
        var receivedValues: [String] = []

        settingsManager.$postRecordingScript
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValues.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        settingsManager.postRecordingScript = "/new/script.sh"

        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedValues.first, "/new/script.sh",
                      "Script changes should be published")
    }

    func testAudioSourceTogglesPublish() {
        let expectation = expectation(description: "Audio toggles should publish")
        expectation.expectedFulfillmentCount = 2
        var systemAudioChanges: [Bool] = []
        var microphoneChanges: [Bool] = []

        settingsManager.$captureSystemAudio
            .dropFirst() // Skip initial value
            .sink { value in
                systemAudioChanges.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        settingsManager.$captureMicrophone
            .dropFirst() // Skip initial value
            .sink { value in
                microphoneChanges.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        settingsManager.captureSystemAudio = false
        settingsManager.captureMicrophone = false

        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(systemAudioChanges.first, false,
                      "System audio changes should be published")
        XCTAssertEqual(microphoneChanges.first, false,
                      "Microphone changes should be published")
    }

    // MARK: - Write-Through Persistence Tests

    func testOutputFolderChangeWritesToUserDefaults() async {
        let newPath = "/Users/test/NewFolder"
        settingsManager.outputFolder = newPath

        // Give Combine pipeline time to process
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Verify it was written to UserDefaults
        let storedValue = testUserDefaults.string(forKey: "outputFolder")
        XCTAssertEqual(storedValue, newPath,
                      "Output folder changes should be written to UserDefaults")
    }

    func testPostRecordingScriptChangeWritesToUserDefaults() async {
        let newScript = "/usr/local/bin/new-script.sh"
        settingsManager.postRecordingScript = newScript

        // Give Combine pipeline time to process
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Verify it was written to UserDefaults
        let storedValue = testUserDefaults.string(forKey: "postRecordingScript")
        XCTAssertEqual(storedValue, newScript,
                      "Post-recording script changes should be written to UserDefaults")
    }

    func testCaptureSystemAudioChangeWritesToUserDefaults() async {
        settingsManager.captureSystemAudio = false

        // Give Combine pipeline time to process
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Verify it was written to UserDefaults
        let storedValue = testUserDefaults.bool(forKey: "captureSystemAudio")
        XCTAssertFalse(storedValue,
                      "Capture system audio changes should be written to UserDefaults")
    }

    func testCaptureMicrophoneChangeWritesToUserDefaults() async {
        settingsManager.captureMicrophone = false

        // Give Combine pipeline time to process
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Verify it was written to UserDefaults
        let storedValue = testUserDefaults.bool(forKey: "captureMicrophone")
        XCTAssertFalse(storedValue,
                      "Capture microphone changes should be written to UserDefaults")
    }

    func testMultipleChangesAllPersist() async {
        // Make multiple changes
        settingsManager.outputFolder = "/new/output"
        settingsManager.postRecordingScript = "/new/script.sh"
        settingsManager.captureSystemAudio = false
        settingsManager.captureMicrophone = false

        // Give Combine pipeline time to process
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Verify all were written
        XCTAssertEqual(testUserDefaults.string(forKey: "outputFolder"), "/new/output")
        XCTAssertEqual(testUserDefaults.string(forKey: "postRecordingScript"), "/new/script.sh")
        XCTAssertFalse(testUserDefaults.bool(forKey: "captureSystemAudio"))
        XCTAssertFalse(testUserDefaults.bool(forKey: "captureMicrophone"))
    }

    func testChangesPersistToNewInstance() async {
        // Make a change
        settingsManager.outputFolder = "/persistent/folder"

        // Give Combine pipeline time to process
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Create new instance - should read the persisted value
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertEqual(newManager.outputFolder, "/persistent/folder",
                      "Changes should persist to new instances via UserDefaults")
    }

    // MARK: - Consent Dialog Tests

    func testDefaultHasAcceptedConsentDialogIsFalse() {
        XCTAssertFalse(settingsManager.hasAcceptedConsentDialog,
                      "Default hasAcceptedConsentDialog should be false for first-run detection")
    }

    func testHasAcceptedConsentDialogCanBeSetToTrue() {
        settingsManager.hasAcceptedConsentDialog = true
        XCTAssertTrue(settingsManager.hasAcceptedConsentDialog,
                     "Should be able to set hasAcceptedConsentDialog to true")
    }

    func testHasAcceptedConsentDialogCanBeSetToFalse() {
        settingsManager.hasAcceptedConsentDialog = true
        settingsManager.hasAcceptedConsentDialog = false
        XCTAssertFalse(settingsManager.hasAcceptedConsentDialog,
                      "Should be able to set hasAcceptedConsentDialog to false")
    }

    func testHasAcceptedConsentDialogPersistsAcrossInstances() {
        // Set to true
        settingsManager.hasAcceptedConsentDialog = true

        // Force save to UserDefaults
        testUserDefaults.set(true, forKey: "hasAcceptedConsentDialog")
        testUserDefaults.synchronize()

        // Create new instance
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertTrue(newManager.hasAcceptedConsentDialog,
                     "hasAcceptedConsentDialog should persist across instances")
    }

    func testHasAcceptedConsentDialogPropertyIsPublished() async {
        let expectation = expectation(description: "hasAcceptedConsentDialog change should be published")
        var receivedValues: [Bool] = []

        settingsManager.$hasAcceptedConsentDialog
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Change the value
        settingsManager.hasAcceptedConsentDialog = true

        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedValues, [true],
                      "hasAcceptedConsentDialog change should be published")
    }

    func testHasAcceptedConsentDialogWritesToUserDefaults() async {
        // Set value
        settingsManager.hasAcceptedConsentDialog = true

        // Give Combine pipeline time to write
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Check UserDefaults directly
        let storedValue = testUserDefaults.bool(forKey: "hasAcceptedConsentDialog")
        XCTAssertTrue(storedValue,
                     "hasAcceptedConsentDialog should write to UserDefaults")
    }

    func testHasAcceptedConsentDialogReadsFromUserDefaults() {
        // Set value directly in UserDefaults
        testUserDefaults.set(true, forKey: "hasAcceptedConsentDialog")
        testUserDefaults.synchronize()

        // Create new instance - should read from UserDefaults
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertTrue(newManager.hasAcceptedConsentDialog,
                     "Should read hasAcceptedConsentDialog from UserDefaults on init")
    }

    func testHasAcceptedConsentDialogDefaultValueWhenNotInUserDefaults() {
        // Ensure key doesn't exist in UserDefaults
        testUserDefaults.removeObject(forKey: "hasAcceptedConsentDialog")
        testUserDefaults.synchronize()

        // Create new instance
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertFalse(newManager.hasAcceptedConsentDialog,
                      "Should default to false when not in UserDefaults")
    }
}
