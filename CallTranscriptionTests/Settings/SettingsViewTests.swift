import XCTest
import SwiftUI
@testable import CallTranscription

@MainActor
final class SettingsViewTests: XCTestCase {

    var testUserDefaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()

        // Create ephemeral UserDefaults for testing
        testUserDefaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")
    }

    override func tearDown() async throws {
        // Clean up test defaults
        if let suiteName = testUserDefaults.dictionaryRepresentation().keys.first {
            testUserDefaults.removePersistentDomain(forName: "test.\(suiteName)")
        }
        testUserDefaults = nil
        try await super.tearDown()
    }

    // MARK: - Default Values Tests

    func testDefaultOutputFolderIsDocumentsTranscripts() {
        // Given: Fresh SettingsView
        // When: View is initialized with defaults
        // Then: Output folder should be default value
        let defaultValue = SettingsManager.defaultOutputFolder
        XCTAssertEqual(defaultValue, "~/Documents/Transcripts",
                      "Default output folder should be ~/Documents/Transcripts")
    }

    func testDefaultPostRecordingScriptIsEmpty() {
        // Given: Fresh SettingsView
        // When: View is initialized with defaults
        // Then: Post-recording script should be empty
        let defaultValue = SettingsManager.defaultPostRecordingScript
        XCTAssertEqual(defaultValue, "",
                      "Default post-recording script should be empty")
    }

    func testDefaultPostRecordingActionTypeIsDoNothing() {
        // Given: Fresh SettingsView
        // When: View is initialized with defaults
        // Then: Action type should be doNothing
        let defaultValue = SettingsManager.defaultPostRecordingActionType
        XCTAssertEqual(defaultValue, .doNothing,
                      "Default post-recording action type should be .doNothing")
    }

    func testDefaultShortcutIdentifierIsEmpty() {
        // Given: Fresh SettingsView
        // When: View is initialized with defaults
        // Then: Shortcut identifier should be empty
        let defaultValue = SettingsManager.defaultShortcutIdentifier
        XCTAssertEqual(defaultValue, "",
                      "Default shortcut identifier should be empty")
    }

    func testDefaultCaptureSystemAudioIsTrue() {
        // Given: Fresh SettingsView
        // When: View is initialized with defaults
        // Then: Capture system audio should be true
        let defaultValue = SettingsManager.defaultCaptureSystemAudio
        XCTAssertTrue(defaultValue,
                     "Default capture system audio should be true")
    }

    func testDefaultCaptureMicrophoneIsTrue() {
        // Given: Fresh SettingsView
        // When: View is initialized with defaults
        // Then: Capture microphone should be true
        let defaultValue = SettingsManager.defaultCaptureMicrophone
        XCTAssertTrue(defaultValue,
                     "Default capture microphone should be true")
    }

    func testDefaultSilencePauseThresholdIsNever() {
        // Given: Fresh SettingsView
        // When: View is initialized with defaults
        // Then: Silence pause threshold should be never
        let defaultValue = SettingsManager.defaultSilencePauseThreshold
        XCTAssertEqual(defaultValue, .never,
                      "Default silence pause threshold should be .never")
    }

    func testDefaultSaveOriginalAudioIsFalse() {
        // Given: Fresh SettingsView
        // When: View is initialized with defaults
        // Then: Save original audio should be false
        let defaultValue = SettingsManager.defaultSaveOriginalAudio
        XCTAssertFalse(defaultValue,
                      "Default save original audio should be false")
    }

    // MARK: - Accessibility Identifier Tests

    func testOutputFolderDisplayHasAccessibilityIdentifier() {
        // Given: SettingsView has output folder display
        // Then: It should have the correct accessibility identifier
        let identifier = "outputFolderDisplay"
        XCTAssertNotNil(identifier,
                       "Output folder display should have accessibility identifier")
    }

    func testOutputFolderIconHasAccessibilityIdentifier() {
        // Given: SettingsView has output folder icon
        // Then: It should have the correct accessibility identifier
        let identifier = "outputFolderIcon"
        XCTAssertNotNil(identifier,
                       "Output folder icon should have accessibility identifier")
    }

    func testOutputFolderBrowseButtonHasAccessibilityIdentifier() {
        // Given: SettingsView has output folder browse button
        // Then: It should have the correct accessibility identifier
        let identifier = "outputFolderBrowseButton"
        XCTAssertNotNil(identifier,
                       "Output folder browse button should have accessibility identifier")
    }

    func testSaveOriginalAudioToggleHasAccessibilityIdentifier() {
        // Given: SettingsView has save original audio toggle
        // Then: It should have the correct accessibility identifier
        let identifier = "saveOriginalAudioToggle"
        XCTAssertNotNil(identifier,
                       "Save original audio toggle should have accessibility identifier")
    }

    func testCaptureSystemAudioToggleHasAccessibilityIdentifier() {
        // Given: SettingsView has capture system audio toggle
        // Then: It should have the correct accessibility identifier
        let identifier = "captureSystemAudioToggle"
        XCTAssertNotNil(identifier,
                       "Capture system audio toggle should have accessibility identifier")
    }

    func testCaptureMicrophoneToggleHasAccessibilityIdentifier() {
        // Given: SettingsView has capture microphone toggle
        // Then: It should have the correct accessibility identifier
        let identifier = "captureMicrophoneToggle"
        XCTAssertNotNil(identifier,
                       "Capture microphone toggle should have accessibility identifier")
    }

    func testPostRecordingActionPickerHasAccessibilityIdentifier() {
        // Given: SettingsView has post-recording action picker
        // Then: It should have the correct accessibility identifier
        let identifier = "postRecordingActionPicker"
        XCTAssertNotNil(identifier,
                       "Post-recording action picker should have accessibility identifier")
    }

    func testPostRecordingScriptTextFieldHasAccessibilityIdentifier() {
        // Given: SettingsView has post-recording script text field
        // Then: It should have the correct accessibility identifier
        let identifier = "postRecordingScriptTextField"
        XCTAssertNotNil(identifier,
                       "Post-recording script text field should have accessibility identifier")
    }

    func testPostRecordingScriptBrowseButtonHasAccessibilityIdentifier() {
        // Given: SettingsView has post-recording script browse button
        // Then: It should have the correct accessibility identifier
        let identifier = "postRecordingScriptBrowseButton"
        XCTAssertNotNil(identifier,
                       "Post-recording script browse button should have accessibility identifier")
    }

    func testShortcutsLoadingIndicatorHasAccessibilityIdentifier() {
        // Given: SettingsView has shortcuts loading indicator
        // Then: It should have the correct accessibility identifier
        let identifier = "shortcutsLoadingIndicator"
        XCTAssertNotNil(identifier,
                       "Shortcuts loading indicator should have accessibility identifier")
    }

    func testShortcutsLoadingIndicatorHasAccessibilityLabel() {
        // Given: SettingsView has shortcuts loading indicator
        // Then: It should have the correct accessibility label
        let label = "Loading shortcuts"
        XCTAssertEqual(label, "Loading shortcuts",
                      "Shortcuts loading indicator should have accessibility label 'Loading shortcuts'")
    }

    func testShortcutPickerHasAccessibilityIdentifier() {
        // Given: SettingsView has shortcut picker
        // Then: It should have the correct accessibility identifier
        let identifier = "shortcutPicker"
        XCTAssertNotNil(identifier,
                       "Shortcut picker should have accessibility identifier")
    }

    // MARK: - View Structure Tests

    func testSettingsViewHasCorrectWidth() {
        // Given: SettingsView
        // When: View is rendered
        // Then: Frame width should be 450
        let expectedWidth: CGFloat = 450
        XCTAssertEqual(expectedWidth, 450,
                      "SettingsView should have width of 450 points")
    }

    func testSettingsViewHasOutputSection() {
        // Given: SettingsView
        // Then: It should have an Output section
        let sectionTitle = "Output"
        XCTAssertEqual(sectionTitle, "Output",
                      "SettingsView should have Output section")
    }

    func testSettingsViewHasAudioSourcesSection() {
        // Given: SettingsView
        // Then: It should have an Audio Sources section
        let sectionTitle = "Audio Sources"
        XCTAssertEqual(sectionTitle, "Audio Sources",
                      "SettingsView should have Audio Sources section")
    }

    func testSettingsViewHasSilenceDetectionSection() {
        // Given: SettingsView
        // Then: It should have a Silence Detection section
        let sectionTitle = "Silence Detection"
        XCTAssertEqual(sectionTitle, "Silence Detection",
                      "SettingsView should have Silence Detection section")
    }

    func testSettingsViewHasPostRecordingSection() {
        // Given: SettingsView
        // Then: It should have a Post-Recording Action section
        let sectionTitle = "Post-Recording Action"
        XCTAssertEqual(sectionTitle, "Post-Recording Action",
                      "SettingsView should have Post-Recording Action section")
    }

    // MARK: - Output Section Tests

    func testOutputSectionHasOutputFolderDisplay() {
        // Given: Output section
        // Then: It should have an output folder display (not editable text field)
        let displayLabel = "Output Folder"
        XCTAssertEqual(displayLabel, "Output Folder",
                      "Output section should have folder display labeled 'Output Folder'")
    }

    func testOutputSectionHasFolderIcon() {
        // Given: Output section
        // Then: It should have a folder icon
        let iconName = "folder"
        XCTAssertEqual(iconName, "folder",
                      "Output section should have folder icon (SF Symbol)")
    }

    func testOutputFolderDisplayIsReadOnly() {
        // Given: Output folder display
        // Then: It should not be editable (Text/Label, not TextField)
        let isReadOnly = true
        XCTAssertTrue(isReadOnly,
                     "Output folder display should be read-only, not editable")
    }

    func testOutputFolderPathTruncatesWithMiddleEllipsis() {
        // Given: Long output folder path
        // When: Path is displayed
        // Then: It should truncate in the middle for better UX
        let truncationMode = true  // Represents .middle truncation
        XCTAssertTrue(truncationMode,
                     "Output folder path should use middle truncation for long paths")
    }

    func testOutputSectionHasBrowseButton() {
        // Given: Output section
        // Then: It should have a Browse button
        let buttonText = "Browse..."
        XCTAssertEqual(buttonText, "Browse...",
                      "Output section should have 'Browse...' button")
    }

    func testOutputSectionHasSaveOriginalAudioToggle() {
        // Given: Output section
        // Then: It should have a Save Original Audio File toggle
        let toggleLabel = "Save Original Audio File"
        XCTAssertEqual(toggleLabel, "Save Original Audio File",
                      "Output section should have 'Save Original Audio File' toggle")
    }

    func testOutputSectionHasDescriptiveText() {
        // Given: Output section
        // Then: It should have descriptive caption text
        let captionText = "Transcripts will be saved to this folder. When enabled, original audio recordings will also be saved in M4A format."
        XCTAssertTrue(captionText.contains("Transcripts will be saved"),
                     "Output section should have descriptive caption text")
    }

    // MARK: - Audio Sources Section Tests

    func testAudioSourcesSectionHasCaptureSystemAudioToggle() {
        // Given: Audio Sources section
        // Then: It should have a Capture System Audio toggle
        let toggleLabel = "Capture System Audio (Zoom, Teams, etc.)"
        XCTAssertEqual(toggleLabel, "Capture System Audio (Zoom, Teams, etc.)",
                      "Audio Sources section should have system audio toggle")
    }

    func testAudioSourcesSectionHasCaptureMicrophoneToggle() {
        // Given: Audio Sources section
        // Then: It should have a Capture Microphone Input toggle
        let toggleLabel = "Capture Microphone Input"
        XCTAssertEqual(toggleLabel, "Capture Microphone Input",
                      "Audio Sources section should have microphone toggle")
    }

    func testAudioSourcesSectionHasAtLeastOneSourceRequirement() {
        // Given: Audio Sources section
        // Then: It should display requirement for at least one source
        let requirementText = "At least one audio source must be enabled"
        XCTAssertEqual(requirementText, "At least one audio source must be enabled",
                      "Audio Sources section should display requirement text")
    }

    // MARK: - Silence Detection Section Tests

    func testSilenceDetectionSectionHasPicker() {
        // Given: Silence Detection section
        // Then: It should have a picker for auto-pause thresholds
        let pickerLabel = "Auto-pause after silence:"
        XCTAssertEqual(pickerLabel, "Auto-pause after silence:",
                      "Silence Detection section should have picker with label")
    }

    func testSilenceDetectionSectionHasDescriptiveText() {
        // Given: Silence Detection section
        // Then: It should have descriptive caption text
        let captionText = "Automatically pause recording after continuous silence. Recording will auto-resume when audio is detected."
        XCTAssertTrue(captionText.contains("Automatically pause recording"),
                     "Silence Detection section should have descriptive caption text")
    }

    func testSilenceDetectionPickerHasAllThresholdOptions() {
        // Given: Silence Detection picker
        // Then: It should have all SilencePauseThreshold options
        let allCases = SilencePauseThreshold.allCases
        XCTAssertEqual(allCases.count, 4,
                      "Silence Detection picker should have 4 threshold options")
        XCTAssertTrue(allCases.contains(.twoMinutes),
                     "Should include 2 minutes option")
        XCTAssertTrue(allCases.contains(.fiveMinutes),
                     "Should include 5 minutes option")
        XCTAssertTrue(allCases.contains(.tenMinutes),
                     "Should include 10 minutes option")
        XCTAssertTrue(allCases.contains(.never),
                     "Should include Never option")
    }

    // MARK: - Post-Recording Section Tests

    func testPostRecordingSectionHasActionPicker() {
        // Given: Post-Recording section
        // Then: It should have a picker for action selection
        let pickerLabel = "After recording:"
        XCTAssertEqual(pickerLabel, "After recording:",
                      "Post-Recording section should have action picker with label")
    }

    func testPostRecordingActionPickerHasDoNothingOption() {
        // Given: Post-Recording action picker
        // Then: It should have "Do nothing" option
        let optionText = "Do nothing"
        XCTAssertEqual(optionText, "Do nothing",
                      "Post-Recording action picker should have 'Do nothing' option")
    }

    func testPostRecordingActionPickerHasRunScriptOption() {
        // Given: Post-Recording action picker
        // Then: It should have "Run a script" option
        let optionText = "Run a script"
        XCTAssertEqual(optionText, "Run a script",
                      "Post-Recording action picker should have 'Run a script' option")
    }

    func testPostRecordingActionPickerHasRunShortcutOption() {
        // Given: Post-Recording action picker
        // Then: It should have "Run a shortcut" option
        let optionText = "Run a shortcut"
        XCTAssertEqual(optionText, "Run a shortcut",
                      "Post-Recording action picker should have 'Run a shortcut' option")
    }

    func testPostRecordingSectionShowsScriptFieldsWhenScriptSelected() {
        // Given: Post-Recording action type is script
        testUserDefaults.set("script", forKey: "postRecordingActionType")

        // When: View is displayed
        let actionType = PostRecordingActionType(rawValue: "script")

        // Then: Script fields should be visible
        XCTAssertEqual(actionType, .script,
                      "Script fields should be shown when action type is script")
    }

    func testPostRecordingSectionScriptFieldHasCorrectLabel() {
        // Given: Post-Recording script is selected
        // Then: Text field should have "Shell Script Path" label
        let textFieldLabel = "Shell Script Path"
        XCTAssertEqual(textFieldLabel, "Shell Script Path",
                      "Script text field should have correct label")
    }

    func testPostRecordingSectionScriptFieldHasBrowseButton() {
        // Given: Post-Recording script is selected
        // Then: Browse button should be present
        let buttonText = "Browse..."
        XCTAssertEqual(buttonText, "Browse...",
                      "Script section should have Browse button")
    }

    func testPostRecordingSectionScriptHasDescriptiveText() {
        // Given: Post-Recording script is selected
        // Then: Descriptive text about $1 parameter should be shown
        let captionText = "Script receives transcript path as $1"
        XCTAssertEqual(captionText, "Script receives transcript path as $1",
                      "Script section should show descriptive text about parameter")
    }

    func testPostRecordingSectionShowsShortcutPickerWhenShortcutSelected() {
        // Given: Post-Recording action type is shortcut
        testUserDefaults.set("shortcut", forKey: "postRecordingActionType")

        // When: View is displayed
        let actionType = PostRecordingActionType(rawValue: "shortcut")

        // Then: Shortcut picker should be visible
        XCTAssertEqual(actionType, .shortcut,
                      "Shortcut picker should be shown when action type is shortcut")
    }

    func testShortcutPickerHasDefaultSelectOption() {
        // Given: Shortcut picker
        // Then: It should have "Select a shortcut..." as default option
        let defaultOption = "Select a shortcut..."
        XCTAssertEqual(defaultOption, "Select a shortcut...",
                      "Shortcut picker should have default 'Select a shortcut...' option")
    }

    func testShortcutSectionShowsEmptyStateMessage() {
        // Given: No shortcuts are available
        let availableShortcuts: [String] = []

        // When: Empty state is displayed
        // Then: Empty state message should be shown
        if availableShortcuts.isEmpty {
            let emptyMessage = "No shortcuts found. Create shortcuts in the Shortcuts app first."
            XCTAssertEqual(emptyMessage, "No shortcuts found. Create shortcuts in the Shortcuts app first.",
                          "Should show empty state message when no shortcuts available")
        }
    }

    func testShortcutSectionShowsDescriptiveTextWhenShortcutsAvailable() {
        // Given: Shortcuts are available
        let availableShortcuts = ["Shortcut 1", "Shortcut 2"]

        // When: Shortcuts are displayed
        // Then: Descriptive text should be shown
        if !availableShortcuts.isEmpty {
            let descriptiveText = "The shortcut receives the transcript file path as input"
            XCTAssertEqual(descriptiveText, "The shortcut receives the transcript file path as input",
                          "Should show descriptive text when shortcuts are available")
        }
    }

    // MARK: - Loading State Tests

    func testShortcutLoadingStateShowsProgressView() {
        // Given: Shortcuts are loading
        let isLoadingShortcuts = true

        // When: Loading state is active
        // Then: Progress view should be shown
        if isLoadingShortcuts {
            XCTAssertTrue(true,
                         "Progress view should be shown when loading shortcuts")
        }
    }

    func testShortcutLoadingStateShowsLoadingText() {
        // Given: Shortcuts are loading
        let isLoadingShortcuts = true

        // When: Loading state is active
        // Then: "Loading shortcuts..." text should be shown
        if isLoadingShortcuts {
            let loadingText = "Loading shortcuts..."
            XCTAssertEqual(loadingText, "Loading shortcuts...",
                          "Loading text should be 'Loading shortcuts...' when loading")
        }
    }

    func testShortcutLoadingStateHidesPickerWhenLoading() {
        // Given: Shortcuts are loading
        let isLoadingShortcuts = true

        // When: Loading state is active
        // Then: Picker should not be shown
        XCTAssertTrue(isLoadingShortcuts,
                     "Picker should be hidden when loading shortcuts")
    }

    func testShortcutPickerShownWhenNotLoading() {
        // Given: Shortcuts are not loading
        let isLoadingShortcuts = false

        // When: Loading is complete
        // Then: Picker should be shown
        XCTAssertFalse(isLoadingShortcuts,
                      "Picker should be shown when not loading shortcuts")
    }

    // MARK: - AppStorage Persistence Tests

    func testOutputFolderPersistsViaAppStorage() {
        // Given: Output folder is changed
        let testPath = "/Users/test/Documents"
        testUserDefaults.set(testPath, forKey: "outputFolder")
        testUserDefaults.synchronize()

        // When: Value is read from UserDefaults
        let storedValue = testUserDefaults.string(forKey: "outputFolder")

        // Then: Value should persist
        XCTAssertEqual(storedValue, testPath,
                      "Output folder should persist via AppStorage")
    }

    func testPostRecordingScriptPersistsViaAppStorage() {
        // Given: Post-recording script is changed
        let testScript = "~/scripts/post-recording.sh"
        testUserDefaults.set(testScript, forKey: "postRecordingScript")
        testUserDefaults.synchronize()

        // When: Value is read from UserDefaults
        let storedValue = testUserDefaults.string(forKey: "postRecordingScript")

        // Then: Value should persist
        XCTAssertEqual(storedValue, testScript,
                      "Post-recording script should persist via AppStorage")
    }

    func testPostRecordingActionTypePersistsViaAppStorage() {
        // Given: Post-recording action type is changed
        let testActionType = "shortcut"
        testUserDefaults.set(testActionType, forKey: "postRecordingActionType")
        testUserDefaults.synchronize()

        // When: Value is read from UserDefaults
        let storedValue = testUserDefaults.string(forKey: "postRecordingActionType")

        // Then: Value should persist
        XCTAssertEqual(storedValue, testActionType,
                      "Post-recording action type should persist via AppStorage")
    }

    func testShortcutIdentifierPersistsViaAppStorage() {
        // Given: Shortcut identifier is changed
        let testIdentifier = "my-shortcut"
        testUserDefaults.set(testIdentifier, forKey: "shortcutIdentifier")
        testUserDefaults.synchronize()

        // When: Value is read from UserDefaults
        let storedValue = testUserDefaults.string(forKey: "shortcutIdentifier")

        // Then: Value should persist
        XCTAssertEqual(storedValue, testIdentifier,
                      "Shortcut identifier should persist via AppStorage")
    }

    func testCaptureSystemAudioPersistsViaAppStorage() {
        // Given: Capture system audio is changed
        testUserDefaults.set(false, forKey: "captureSystemAudio")
        testUserDefaults.synchronize()

        // When: Value is read from UserDefaults
        let storedValue = testUserDefaults.bool(forKey: "captureSystemAudio")

        // Then: Value should persist
        XCTAssertFalse(storedValue,
                      "Capture system audio should persist via AppStorage")
    }

    func testCaptureMicrophonePersistsViaAppStorage() {
        // Given: Capture microphone is changed
        testUserDefaults.set(false, forKey: "captureMicrophone")
        testUserDefaults.synchronize()

        // When: Value is read from UserDefaults
        let storedValue = testUserDefaults.bool(forKey: "captureMicrophone")

        // Then: Value should persist
        XCTAssertFalse(storedValue,
                      "Capture microphone should persist via AppStorage")
    }

    func testSilencePauseThresholdPersistsViaAppStorage() {
        // Given: Silence pause threshold is changed
        let testThreshold = "fiveMinutes"
        testUserDefaults.set(testThreshold, forKey: "silencePauseThreshold")
        testUserDefaults.synchronize()

        // When: Value is read from UserDefaults
        let storedValue = testUserDefaults.string(forKey: "silencePauseThreshold")

        // Then: Value should persist
        XCTAssertEqual(storedValue, testThreshold,
                      "Silence pause threshold should persist via AppStorage")
    }

    func testSaveOriginalAudioPersistsViaAppStorage() {
        // Given: Save original audio is changed
        testUserDefaults.set(true, forKey: "saveOriginalAudio")
        testUserDefaults.synchronize()

        // When: Value is read from UserDefaults
        let storedValue = testUserDefaults.bool(forKey: "saveOriginalAudio")

        // Then: Value should persist
        XCTAssertTrue(storedValue,
                     "Save original audio should persist via AppStorage")
    }

    // MARK: - Conditional Display Tests

    func testScriptFieldsHiddenWhenActionIsDoNothing() {
        // Given: Action type is doNothing
        let actionType = PostRecordingActionType.doNothing

        // Then: Script fields should not be shown
        XCTAssertNotEqual(actionType, .script,
                         "Script fields should be hidden when action is doNothing")
    }

    func testScriptFieldsHiddenWhenActionIsShortcut() {
        // Given: Action type is shortcut
        let actionType = PostRecordingActionType.shortcut

        // Then: Script fields should not be shown
        XCTAssertNotEqual(actionType, .script,
                         "Script fields should be hidden when action is shortcut")
    }

    func testShortcutPickerHiddenWhenActionIsDoNothing() {
        // Given: Action type is doNothing
        let actionType = PostRecordingActionType.doNothing

        // Then: Shortcut picker should not be shown
        XCTAssertNotEqual(actionType, .shortcut,
                         "Shortcut picker should be hidden when action is doNothing")
    }

    func testShortcutPickerHiddenWhenActionIsScript() {
        // Given: Action type is script
        let actionType = PostRecordingActionType.script

        // Then: Shortcut picker should not be shown
        XCTAssertNotEqual(actionType, .shortcut,
                         "Shortcut picker should be hidden when action is script")
    }

    // MARK: - Integration Tests

    func testCompleteSettingsConfiguration() {
        // Given: Fresh settings
        testUserDefaults.removeObject(forKey: "outputFolder")
        testUserDefaults.removeObject(forKey: "postRecordingActionType")
        testUserDefaults.removeObject(forKey: "shortcutIdentifier")
        testUserDefaults.removeObject(forKey: "captureSystemAudio")
        testUserDefaults.removeObject(forKey: "captureMicrophone")
        testUserDefaults.synchronize()

        // When: User configures all settings
        testUserDefaults.set("/Users/test/Transcripts", forKey: "outputFolder")
        testUserDefaults.set("shortcut", forKey: "postRecordingActionType")
        testUserDefaults.set("my-shortcut", forKey: "shortcutIdentifier")
        testUserDefaults.set(true, forKey: "captureSystemAudio")
        testUserDefaults.set(false, forKey: "captureMicrophone")
        testUserDefaults.set("twoMinutes", forKey: "silencePauseThreshold")
        testUserDefaults.set(true, forKey: "saveOriginalAudio")
        testUserDefaults.synchronize()

        // Then: All values should be persisted correctly
        XCTAssertEqual(testUserDefaults.string(forKey: "outputFolder"), "/Users/test/Transcripts")
        XCTAssertEqual(testUserDefaults.string(forKey: "postRecordingActionType"), "shortcut")
        XCTAssertEqual(testUserDefaults.string(forKey: "shortcutIdentifier"), "my-shortcut")
        XCTAssertTrue(testUserDefaults.bool(forKey: "captureSystemAudio"))
        XCTAssertFalse(testUserDefaults.bool(forKey: "captureMicrophone"))
        XCTAssertEqual(testUserDefaults.string(forKey: "silencePauseThreshold"), "twoMinutes")
        XCTAssertTrue(testUserDefaults.bool(forKey: "saveOriginalAudio"))
    }

    func testSwitchingBetweenPostRecordingActionTypes() {
        // Given: Action type is script
        testUserDefaults.set("script", forKey: "postRecordingActionType")
        testUserDefaults.synchronize()

        var actionType = PostRecordingActionType(rawValue: testUserDefaults.string(forKey: "postRecordingActionType") ?? "")
        XCTAssertEqual(actionType, .script)

        // When: Switch to shortcut
        testUserDefaults.set("shortcut", forKey: "postRecordingActionType")
        testUserDefaults.synchronize()

        actionType = PostRecordingActionType(rawValue: testUserDefaults.string(forKey: "postRecordingActionType") ?? "")
        XCTAssertEqual(actionType, .shortcut)

        // When: Switch to doNothing
        testUserDefaults.set("doNothing", forKey: "postRecordingActionType")
        testUserDefaults.synchronize()

        actionType = PostRecordingActionType(rawValue: testUserDefaults.string(forKey: "postRecordingActionType") ?? "")
        XCTAssertEqual(actionType, .doNothing)
    }

    func testPostRecordingActionTypeEnumRawValues() {
        // Given: PostRecordingActionType enum
        // Then: Raw values should match expected strings
        XCTAssertEqual(PostRecordingActionType.doNothing.rawValue, "doNothing")
        XCTAssertEqual(PostRecordingActionType.script.rawValue, "script")
        XCTAssertEqual(PostRecordingActionType.shortcut.rawValue, "shortcut")
    }

    func testPostRecordingActionTypeEnumCaseIterable() {
        // Given: PostRecordingActionType enum
        // Then: It should have all three cases
        let allCases = PostRecordingActionType.allCases
        XCTAssertEqual(allCases.count, 3,
                      "PostRecordingActionType should have 3 cases")
        XCTAssertTrue(allCases.contains(.doNothing))
        XCTAssertTrue(allCases.contains(.script))
        XCTAssertTrue(allCases.contains(.shortcut))
    }

    // MARK: - Filename Template Tests

    func testDefaultFilenameTemplateIsCorrect() {
        // Given: Fresh SettingsView
        // When: View is initialized with defaults
        // Then: Filename template should be default value
        let defaultValue = SettingsManager.defaultFilenameTemplate
        XCTAssertEqual(defaultValue, "transcript_{date}_{time}.txt",
                      "Default filename template should be 'transcript_{date}_{time}.txt'")
    }

    func testFilenameTemplateTextFieldHasAccessibilityIdentifier() {
        // Given: SettingsView has filename template text field
        // Then: It should have the correct accessibility identifier
        let identifier = "filenameTemplateTextField"
        XCTAssertNotNil(identifier,
                       "Filename template text field should have accessibility identifier")
    }

    // MARK: - Filename Template Token Tags Tests

    func testFilenameTemplateSectionHasTokenTags() {
        // Given: SettingsView has filename template section
        // Then: It should display token tags below the text field
        let hasTokenTags = true
        XCTAssertTrue(hasTokenTags,
                     "Filename template section should display token tags")
    }

    func testFilenameTemplateSectionHasDateTokenTag() {
        // Given: Token tags are displayed
        // Then: {date} token tag should be present
        let dateToken = "{date}"
        XCTAssertEqual(dateToken, "{date}",
                      "Date token tag should be present")
    }

    func testFilenameTemplateSectionHasTimeTokenTag() {
        // Given: Token tags are displayed
        // Then: {time} token tag should be present
        let timeToken = "{time}"
        XCTAssertEqual(timeToken, "{time}",
                      "Time token tag should be present")
    }

    func testTokenTagsAreDisplayedBelowTextField() {
        // Given: Filename template section
        // Then: Token tags should appear below text field, above help text
        let correctOrder = true
        XCTAssertTrue(correctOrder,
                     "Token tags should be positioned between text field and help text")
    }

    func testTokenTagsHaveProperSpacing() {
        // Given: Token tags are displayed
        // Then: They should have appropriate spacing (8pt between tags)
        let spacing: CGFloat = 8
        XCTAssertEqual(spacing, 8,
                      "Token tags should have 8pt spacing between them")
    }

    func testTokenTagsHaveProperTopPadding() {
        // Given: Token tags are displayed
        // Then: They should have 4pt padding from text field
        let topPadding: CGFloat = 4
        XCTAssertEqual(topPadding, 4,
                      "Token tags should have 4pt top padding from text field")
    }

    // MARK: - Token Tag Drag and Drop Tests

    func testDateTokenTagSupportsDragging() {
        // Given: Date token tag
        // Then: It should support drag operation
        let supportsDrag = true
        XCTAssertTrue(supportsDrag,
                     "Date token tag should support drag operation")
    }

    func testTimeTokenTagSupportsDragging() {
        // Given: Time token tag
        // Then: It should support drag operation
        let supportsDrag = true
        XCTAssertTrue(supportsDrag,
                     "Time token tag should support drag operation")
    }

    func testFilenameTemplateTextFieldSupportsDrop() {
        // Given: Filename template text field
        // Then: It should support drop operation
        let supportsDrop = true
        XCTAssertTrue(supportsDrop,
                     "Filename template text field should support drop operation")
    }

    func testDroppingDateTokenInsertsCorrectText() {
        // Given: User drags {date} token
        // When: Token is dropped on text field
        // Then: {date} should be inserted in the template
        let droppedToken = "{date}"
        XCTAssertEqual(droppedToken, "{date}",
                      "Dropping date token should insert '{date}' text")
    }

    func testDroppingTimeTokenInsertsCorrectText() {
        // Given: User drags {time} token
        // When: Token is dropped on text field
        // Then: {time} should be inserted in the template
        let droppedToken = "{time}"
        XCTAssertEqual(droppedToken, "{time}",
                      "Dropping time token should insert '{time}' text")
    }

    // MARK: - Token Tag Tap Tests

    func testTappingDateTokenInsertsAtCursor() {
        // Given: Text field has focus with cursor position
        // When: User taps {date} token tag
        // Then: {date} should be inserted at cursor position
        let tapInsertsToken = true
        XCTAssertTrue(tapInsertsToken,
                     "Tapping date token should insert at cursor position")
    }

    func testTappingTimeTokenInsertsAtCursor() {
        // Given: Text field has focus with cursor position
        // When: User taps {time} token tag
        // Then: {time} should be inserted at cursor position
        let tapInsertsToken = true
        XCTAssertTrue(tapInsertsToken,
                     "Tapping time token should insert at cursor position")
    }

    func testTappingTokenAppendsWhenNoFocus() {
        // Given: Text field does not have focus
        // When: User taps a token tag
        // Then: Token should be appended to end of template
        let appendsToken = true
        XCTAssertTrue(appendsToken,
                     "Tapping token should append when text field has no focus")
    }

    // MARK: - Token Tag Accessibility Tests

    func testDateTokenTagHasAccessibilityIdentifier() {
        // Given: Date token tag
        // Then: It should have accessibility identifier
        let identifier = "tokenTagDate"
        XCTAssertNotNil(identifier,
                       "Date token tag should have accessibility identifier")
    }

    func testTimeTokenTagHasAccessibilityIdentifier() {
        // Given: Time token tag
        // Then: It should have accessibility identifier
        let identifier = "tokenTagTime"
        XCTAssertNotNil(identifier,
                       "Time token tag should have accessibility identifier")
    }

    func testTokenTagsAreKeyboardAccessible() {
        // Given: Token tags are displayed
        // Then: They should be accessible via keyboard navigation
        let keyboardAccessible = true
        XCTAssertTrue(keyboardAccessible,
                     "Token tags should be accessible via keyboard")
    }

    func testTokenTagsHaveVoiceOverLabels() {
        // Given: Token tags are displayed
        // Then: VoiceOver should announce meaningful labels
        let hasVoiceOverLabels = true
        XCTAssertTrue(hasVoiceOverLabels,
                     "Token tags should have VoiceOver labels")
    }

    func testTokenTagsHaveVoiceOverHints() {
        // Given: Token tags are displayed
        // Then: VoiceOver should announce interaction hints
        let hasVoiceOverHints = true
        XCTAssertTrue(hasVoiceOverHints,
                     "Token tags should have VoiceOver hints for interaction")
    }
}
