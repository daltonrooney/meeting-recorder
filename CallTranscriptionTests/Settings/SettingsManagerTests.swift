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

    // MARK: - Silence Detection Settings Tests

    func testDefaultSilencePauseThresholdIsNever() {
        XCTAssertEqual(settingsManager.silencePauseThreshold, .never,
                      "Default silencePauseThreshold should be .never (disabled)")
    }

    func testSilencePauseThresholdCanBeSetToTwoMinutes() {
        settingsManager.silencePauseThreshold = .twoMinutes
        XCTAssertEqual(settingsManager.silencePauseThreshold, .twoMinutes,
                     "Should be able to set silencePauseThreshold to .twoMinutes")
    }

    func testSilencePauseThresholdCanBeSetToFiveMinutes() {
        settingsManager.silencePauseThreshold = .fiveMinutes
        XCTAssertEqual(settingsManager.silencePauseThreshold, .fiveMinutes,
                     "Should be able to set silencePauseThreshold to .fiveMinutes")
    }

    func testSilencePauseThresholdCanBeSetToTenMinutes() {
        settingsManager.silencePauseThreshold = .tenMinutes
        XCTAssertEqual(settingsManager.silencePauseThreshold, .tenMinutes,
                     "Should be able to set silencePauseThreshold to .tenMinutes")
    }

    func testSilencePauseThresholdCanBeSetToNever() {
        settingsManager.silencePauseThreshold = .twoMinutes
        settingsManager.silencePauseThreshold = .never
        XCTAssertEqual(settingsManager.silencePauseThreshold, .never,
                     "Should be able to set silencePauseThreshold back to .never")
    }

    func testSilencePauseThresholdPersistsAcrossInstances() {
        // Set to five minutes
        settingsManager.silencePauseThreshold = .fiveMinutes

        // Force save to UserDefaults
        testUserDefaults.set("fiveMinutes", forKey: "silencePauseThreshold")
        testUserDefaults.synchronize()

        // Create new instance
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertEqual(newManager.silencePauseThreshold, .fiveMinutes,
                     "silencePauseThreshold should persist across instances")
    }

    func testSilencePauseThresholdPropertyIsPublished() async {
        let expectation = expectation(description: "silencePauseThreshold change should be published")
        var receivedValues: [SilencePauseThreshold] = []

        settingsManager.$silencePauseThreshold
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Change the value
        settingsManager.silencePauseThreshold = .twoMinutes

        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedValues, [.twoMinutes],
                      "silencePauseThreshold change should be published")
    }

    func testSilencePauseThresholdWritesToUserDefaults() async {
        // Set value
        settingsManager.silencePauseThreshold = .tenMinutes

        // Give Combine pipeline time to write
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Check UserDefaults directly
        let storedValue = testUserDefaults.string(forKey: "silencePauseThreshold")
        XCTAssertEqual(storedValue, "tenMinutes",
                     "silencePauseThreshold should write to UserDefaults")
    }

    func testSilencePauseThresholdReadsFromUserDefaults() {
        // Set value directly in UserDefaults
        testUserDefaults.set("twoMinutes", forKey: "silencePauseThreshold")
        testUserDefaults.synchronize()

        // Create new instance - should read from UserDefaults
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertEqual(newManager.silencePauseThreshold, .twoMinutes,
                     "Should read silencePauseThreshold from UserDefaults on init")
    }

    func testSilencePauseThresholdDefaultValueWhenNotInUserDefaults() {
        // Ensure key doesn't exist in UserDefaults
        testUserDefaults.removeObject(forKey: "silencePauseThreshold")
        testUserDefaults.synchronize()

        // Create new instance
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertEqual(newManager.silencePauseThreshold, .never,
                      "Should default to .never when not in UserDefaults")
    }

    func testSilencePauseThresholdTimeIntervalForTwoMinutes() {
        XCTAssertEqual(SilencePauseThreshold.twoMinutes.timeInterval, 120.0,
                      "twoMinutes should return 120 seconds")
    }

    func testSilencePauseThresholdTimeIntervalForFiveMinutes() {
        XCTAssertEqual(SilencePauseThreshold.fiveMinutes.timeInterval, 300.0,
                      "fiveMinutes should return 300 seconds")
    }

    func testSilencePauseThresholdTimeIntervalForTenMinutes() {
        XCTAssertEqual(SilencePauseThreshold.tenMinutes.timeInterval, 600.0,
                      "tenMinutes should return 600 seconds")
    }

    func testSilencePauseThresholdTimeIntervalForNever() {
        XCTAssertNil(SilencePauseThreshold.never.timeInterval,
                    "never should return nil (disabled)")
    }

    // MARK: - Save Original Audio Tests

    func testDefaultSaveOriginalAudioIsFalse() {
        XCTAssertFalse(settingsManager.saveOriginalAudio,
                      "Default saveOriginalAudio should be false")
    }

    func testSaveOriginalAudioCanBeSetToTrue() {
        settingsManager.saveOriginalAudio = true
        XCTAssertTrue(settingsManager.saveOriginalAudio,
                     "Should be able to set saveOriginalAudio to true")
    }

    func testSaveOriginalAudioCanBeSetToFalse() {
        settingsManager.saveOriginalAudio = true
        settingsManager.saveOriginalAudio = false
        XCTAssertFalse(settingsManager.saveOriginalAudio,
                      "Should be able to set saveOriginalAudio to false")
    }

    func testSaveOriginalAudioPersistsAcrossInstances() {
        // Set to true
        settingsManager.saveOriginalAudio = true

        // Force save to UserDefaults
        testUserDefaults.set(true, forKey: "saveOriginalAudio")
        testUserDefaults.synchronize()

        // Create new instance
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertTrue(newManager.saveOriginalAudio,
                     "saveOriginalAudio should persist across instances")
    }

    func testSaveOriginalAudioPropertyIsPublished() async {
        let expectation = expectation(description: "saveOriginalAudio change should be published")
        var receivedValues: [Bool] = []

        settingsManager.$saveOriginalAudio
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Change the value
        settingsManager.saveOriginalAudio = true

        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedValues, [true],
                      "saveOriginalAudio change should be published")
    }

    func testSaveOriginalAudioWritesToUserDefaults() async {
        // Set value
        settingsManager.saveOriginalAudio = true

        // Give Combine pipeline time to write
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Check UserDefaults directly
        let storedValue = testUserDefaults.bool(forKey: "saveOriginalAudio")
        XCTAssertTrue(storedValue,
                     "saveOriginalAudio should write to UserDefaults")
    }

    func testSaveOriginalAudioReadsFromUserDefaults() {
        // Set value directly in UserDefaults
        testUserDefaults.set(true, forKey: "saveOriginalAudio")
        testUserDefaults.synchronize()

        // Create new instance - should read from UserDefaults
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertTrue(newManager.saveOriginalAudio,
                     "Should read saveOriginalAudio from UserDefaults on init")
    }

    func testSaveOriginalAudioDefaultValueWhenNotInUserDefaults() {
        // Ensure key doesn't exist in UserDefaults
        testUserDefaults.removeObject(forKey: "saveOriginalAudio")
        testUserDefaults.synchronize()

        // Create new instance
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertFalse(newManager.saveOriginalAudio,
                      "Should default to false when not in UserDefaults")
    }

    // MARK: - Post-Recording Action Type Tests

    func testDefaultPostRecordingActionTypeIsDoNothing() {
        XCTAssertEqual(settingsManager.postRecordingActionType, .doNothing,
                      "Default post-recording action type should be .doNothing")
    }

    func testPostRecordingActionTypeCanBeSetToScript() {
        settingsManager.postRecordingActionType = .script
        XCTAssertEqual(settingsManager.postRecordingActionType, .script,
                     "Should be able to set post-recording action type to .script")
    }

    func testPostRecordingActionTypeCanBeSetToShortcut() {
        settingsManager.postRecordingActionType = .shortcut
        XCTAssertEqual(settingsManager.postRecordingActionType, .shortcut,
                     "Should be able to set post-recording action type to .shortcut")
    }

    func testPostRecordingActionTypePersistsAcrossInstances() {
        // Set to shortcut
        settingsManager.postRecordingActionType = .shortcut

        // Force save to UserDefaults
        testUserDefaults.set("shortcut", forKey: "postRecordingActionType")
        testUserDefaults.synchronize()

        // Create new instance
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertEqual(newManager.postRecordingActionType, .shortcut,
                     "Post-recording action type should persist across instances")
    }

    func testPostRecordingActionTypePropertyIsPublished() async {
        let expectation = expectation(description: "postRecordingActionType change should be published")
        var receivedValues: [PostRecordingActionType] = []

        settingsManager.$postRecordingActionType
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Change the value
        settingsManager.postRecordingActionType = .script

        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedValues, [.script],
                      "postRecordingActionType change should be published")
    }

    func testPostRecordingActionTypeWritesToUserDefaults() async {
        // Set value
        settingsManager.postRecordingActionType = .shortcut

        // Give Combine pipeline time to write
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Check UserDefaults directly
        let storedValue = testUserDefaults.string(forKey: "postRecordingActionType")
        XCTAssertEqual(storedValue, "shortcut",
                     "postRecordingActionType should write to UserDefaults")
    }

    func testPostRecordingActionTypeReadsFromUserDefaults() {
        // Set value directly in UserDefaults
        testUserDefaults.set("script", forKey: "postRecordingActionType")
        testUserDefaults.synchronize()

        // Create new instance - should read from UserDefaults
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertEqual(newManager.postRecordingActionType, .script,
                     "Should read postRecordingActionType from UserDefaults on init")
    }

    func testPostRecordingActionTypeDefaultValueWhenNotInUserDefaults() {
        // Ensure key doesn't exist in UserDefaults
        testUserDefaults.removeObject(forKey: "postRecordingActionType")
        testUserDefaults.synchronize()

        // Create new instance
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertEqual(newManager.postRecordingActionType, .doNothing,
                      "Should default to .doNothing when not in UserDefaults")
    }

    // MARK: - Shortcut Identifier Tests

    func testDefaultShortcutIdentifierIsEmpty() {
        XCTAssertEqual(settingsManager.shortcutIdentifier, "",
                      "Default shortcut identifier should be empty string")
    }

    func testShortcutIdentifierCanBeSet() {
        let testIdentifier = "my-shortcut-id"
        settingsManager.shortcutIdentifier = testIdentifier
        XCTAssertEqual(settingsManager.shortcutIdentifier, testIdentifier,
                     "Should be able to set shortcut identifier")
    }

    func testShortcutIdentifierPersistsAcrossInstances() {
        let testIdentifier = "persistent-shortcut"
        settingsManager.shortcutIdentifier = testIdentifier

        // Force save to UserDefaults
        testUserDefaults.set(testIdentifier, forKey: "shortcutIdentifier")
        testUserDefaults.synchronize()

        // Create new instance
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertEqual(newManager.shortcutIdentifier, testIdentifier,
                     "Shortcut identifier should persist across instances")
    }

    func testShortcutIdentifierPropertyIsPublished() async {
        let expectation = expectation(description: "shortcutIdentifier change should be published")
        var receivedValues: [String] = []

        settingsManager.$shortcutIdentifier
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Change the value
        settingsManager.shortcutIdentifier = "test-shortcut"

        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedValues, ["test-shortcut"],
                      "shortcutIdentifier change should be published")
    }

    func testShortcutIdentifierWritesToUserDefaults() async {
        let testIdentifier = "write-test-shortcut"
        settingsManager.shortcutIdentifier = testIdentifier

        // Give Combine pipeline time to write
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Check UserDefaults directly
        let storedValue = testUserDefaults.string(forKey: "shortcutIdentifier")
        XCTAssertEqual(storedValue, testIdentifier,
                     "shortcutIdentifier should write to UserDefaults")
    }

    func testShortcutIdentifierReadsFromUserDefaults() {
        let testIdentifier = "read-test-shortcut"
        testUserDefaults.set(testIdentifier, forKey: "shortcutIdentifier")
        testUserDefaults.synchronize()

        // Create new instance - should read from UserDefaults
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertEqual(newManager.shortcutIdentifier, testIdentifier,
                     "Should read shortcutIdentifier from UserDefaults on init")
    }

    // MARK: - Backward Compatibility Tests

    func testBackwardCompatibilityWithExistingScriptPath() {
        // Simulate existing installation with postRecordingScript set
        testUserDefaults.set("/path/to/script.sh", forKey: "postRecordingScript")
        testUserDefaults.synchronize()

        // Create new instance - should default to doNothing but preserve script path
        let newManager = SettingsManager(userDefaults: testUserDefaults)
        XCTAssertEqual(newManager.postRecordingActionType, .doNothing,
                     "Should default to doNothing for backward compatibility")
        XCTAssertEqual(newManager.postRecordingScript, "/path/to/script.sh",
                     "Should preserve existing script path")
    }

    func testMigratingFromScriptToActionType() async {
        // Set existing script path
        settingsManager.postRecordingScript = "/path/to/script.sh"
        try? await Task.sleep(nanoseconds: 100_000_000)

        // User updates to use the new action type
        settingsManager.postRecordingActionType = .script

        // Give pipeline time
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Both should be set
        XCTAssertEqual(settingsManager.postRecordingActionType, .script)
        XCTAssertEqual(settingsManager.postRecordingScript, "/path/to/script.sh")
    }
}
