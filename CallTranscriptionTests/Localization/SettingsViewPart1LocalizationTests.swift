import XCTest
@testable import CallTranscription

/// Tests for SettingsView Part 1 localization (Output, Audio Sources, Silence Detection sections).
///
/// These tests verify that all user-facing strings in the first three sections of
/// SettingsView are properly externalized to the String Catalog.
final class SettingsViewPart1LocalizationTests: XCTestCase {

    // MARK: - Output Section Tests

    func testOutputSectionHeaderIsLocalized() {
        let key = "settings.output.header"
        let localizedValue = NSLocalizedString(key, comment: "Output section header")

        XCTAssertNotEqual(localizedValue, key, "Output section header should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Output section header should not be empty")
    }

    func testOutputFolderLabelIsLocalized() {
        let key = "settings.output.folder.label"
        let localizedValue = NSLocalizedString(key, comment: "Output folder label")

        XCTAssertNotEqual(localizedValue, key, "Output folder label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Output folder label should not be empty")
    }

    func testOutputFolderBrowseButtonIsLocalized() {
        let key = "settings.output.folder.browseButton"
        let localizedValue = NSLocalizedString(key, comment: "Browse button for output folder")

        XCTAssertNotEqual(localizedValue, key, "Browse button label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Browse button label should not be empty")
    }

    func testSaveOriginalAudioToggleLabelIsLocalized() {
        let key = "settings.output.saveOriginalAudio.label"
        let localizedValue = NSLocalizedString(key, comment: "Save original audio toggle label")

        XCTAssertNotEqual(localizedValue, key, "Save original audio toggle label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Save original audio toggle label should not be empty")
    }

    func testOutputHelpTextIsLocalized() {
        let key = "settings.output.helpText"
        let localizedValue = NSLocalizedString(key, comment: "Output section help text")

        XCTAssertNotEqual(localizedValue, key, "Output help text should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Output help text should not be empty")
    }

    // MARK: - Output Section Accessibility Tests

    func testOutputFolderAccessibilityLabelIsLocalized() {
        let key = "settings.output.folder.accessibility.label"
        let localizedValue = NSLocalizedString(key, comment: "Output folder accessibility label")

        XCTAssertNotEqual(localizedValue, key, "Output folder accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Output folder accessibility label should not be empty")
    }

    func testOutputFolderAccessibilityHintIsLocalized() {
        let key = "settings.output.folder.accessibility.hint"
        let localizedValue = NSLocalizedString(key, comment: "Output folder accessibility hint")

        XCTAssertNotEqual(localizedValue, key, "Output folder accessibility hint should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Output folder accessibility hint should not be empty")
    }

    func testOutputFolderBrowseAccessibilityLabelIsLocalized() {
        let key = "settings.output.folder.browse.accessibility.label"
        let localizedValue = NSLocalizedString(key, comment: "Browse button accessibility label")

        XCTAssertNotEqual(localizedValue, key, "Browse button accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Browse button accessibility label should not be empty")
    }

    func testOutputFolderBrowseAccessibilityHintIsLocalized() {
        let key = "settings.output.folder.browse.accessibility.hint"
        let localizedValue = NSLocalizedString(key, comment: "Browse button accessibility hint")

        XCTAssertNotEqual(localizedValue, key, "Browse button accessibility hint should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Browse button accessibility hint should not be empty")
    }

    func testSaveOriginalAudioAccessibilityLabelIsLocalized() {
        let key = "settings.output.saveOriginalAudio.accessibility.label"
        let localizedValue = NSLocalizedString(key, comment: "Save original audio accessibility label")

        XCTAssertNotEqual(localizedValue, key, "Save original audio accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Save original audio accessibility label should not be empty")
    }

    func testSaveOriginalAudioAccessibilityHintIsLocalized() {
        let key = "settings.output.saveOriginalAudio.accessibility.hint"
        let localizedValue = NSLocalizedString(key, comment: "Save original audio accessibility hint")

        XCTAssertNotEqual(localizedValue, key, "Save original audio accessibility hint should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Save original audio accessibility hint should not be empty")
    }

    // MARK: - Output Dialog Tests

    func testOutputFolderDialogPromptIsLocalized() {
        let key = "settings.output.folder.dialog.prompt"
        let localizedValue = NSLocalizedString(key, comment: "Output folder dialog prompt")

        XCTAssertNotEqual(localizedValue, key, "Output folder dialog prompt should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Output folder dialog prompt should not be empty")
    }

    func testOutputFolderDialogMessageIsLocalized() {
        let key = "settings.output.folder.dialog.message"
        let localizedValue = NSLocalizedString(key, comment: "Output folder dialog message")

        XCTAssertNotEqual(localizedValue, key, "Output folder dialog message should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Output folder dialog message should not be empty")
    }

    // MARK: - Audio Sources Section Tests

    func testAudioSourcesSectionHeaderIsLocalized() {
        let key = "settings.audioSources.header"
        let localizedValue = NSLocalizedString(key, comment: "Audio sources section header")

        XCTAssertNotEqual(localizedValue, key, "Audio sources section header should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Audio sources section header should not be empty")
    }

    func testCaptureSystemAudioLabelIsLocalized() {
        let key = "settings.audioSources.captureSystemAudio.label"
        let localizedValue = NSLocalizedString(key, comment: "Capture system audio toggle label")

        XCTAssertNotEqual(localizedValue, key, "Capture system audio label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Capture system audio label should not be empty")
    }

    func testCaptureMicrophoneLabelIsLocalized() {
        let key = "settings.audioSources.captureMicrophone.label"
        let localizedValue = NSLocalizedString(key, comment: "Capture microphone toggle label")

        XCTAssertNotEqual(localizedValue, key, "Capture microphone label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Capture microphone label should not be empty")
    }

    func testAudioSourcesHelpTextIsLocalized() {
        let key = "settings.audioSources.helpText"
        let localizedValue = NSLocalizedString(key, comment: "Audio sources help text")

        XCTAssertNotEqual(localizedValue, key, "Audio sources help text should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Audio sources help text should not be empty")
    }

    // MARK: - Audio Sources Accessibility Tests

    func testCaptureSystemAudioAccessibilityLabelIsLocalized() {
        let key = "settings.audioSources.captureSystemAudio.accessibility.label"
        let localizedValue = NSLocalizedString(key, comment: "Capture system audio accessibility label")

        XCTAssertNotEqual(localizedValue, key, "Capture system audio accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Capture system audio accessibility label should not be empty")
    }

    func testCaptureSystemAudioAccessibilityHintIsLocalized() {
        let key = "settings.audioSources.captureSystemAudio.accessibility.hint"
        let localizedValue = NSLocalizedString(key, comment: "Capture system audio accessibility hint")

        XCTAssertNotEqual(localizedValue, key, "Capture system audio accessibility hint should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Capture system audio accessibility hint should not be empty")
    }

    func testCaptureMicrophoneAccessibilityLabelIsLocalized() {
        let key = "settings.audioSources.captureMicrophone.accessibility.label"
        let localizedValue = NSLocalizedString(key, comment: "Capture microphone accessibility label")

        XCTAssertNotEqual(localizedValue, key, "Capture microphone accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Capture microphone accessibility label should not be empty")
    }

    func testCaptureMicrophoneAccessibilityHintIsLocalized() {
        let key = "settings.audioSources.captureMicrophone.accessibility.hint"
        let localizedValue = NSLocalizedString(key, comment: "Capture microphone accessibility hint")

        XCTAssertNotEqual(localizedValue, key, "Capture microphone accessibility hint should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Capture microphone accessibility hint should not be empty")
    }

    // MARK: - Silence Detection Section Tests

    func testSilenceDetectionSectionHeaderIsLocalized() {
        let key = "settings.silenceDetection.header"
        let localizedValue = NSLocalizedString(key, comment: "Silence detection section header")

        XCTAssertNotEqual(localizedValue, key, "Silence detection section header should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Silence detection section header should not be empty")
    }

    func testAutoPauseLabelIsLocalized() {
        let key = "settings.silenceDetection.autoPause.label"
        let localizedValue = NSLocalizedString(key, comment: "Auto-pause picker label")

        XCTAssertNotEqual(localizedValue, key, "Auto-pause label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Auto-pause label should not be empty")
    }

    func testSilenceDetectionHelpTextIsLocalized() {
        let key = "settings.silenceDetection.helpText"
        let localizedValue = NSLocalizedString(key, comment: "Silence detection help text")

        XCTAssertNotEqual(localizedValue, key, "Silence detection help text should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Silence detection help text should not be empty")
    }

    // MARK: - Silence Detection Accessibility Tests

    func testAutoPauseAccessibilityLabelIsLocalized() {
        let key = "settings.silenceDetection.autoPause.accessibility.label"
        let localizedValue = NSLocalizedString(key, comment: "Auto-pause accessibility label")

        XCTAssertNotEqual(localizedValue, key, "Auto-pause accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Auto-pause accessibility label should not be empty")
    }

    func testAutoPauseAccessibilityHintIsLocalized() {
        let key = "settings.silenceDetection.autoPause.accessibility.hint"
        let localizedValue = NSLocalizedString(key, comment: "Auto-pause accessibility hint")

        XCTAssertNotEqual(localizedValue, key, "Auto-pause accessibility hint should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Auto-pause accessibility hint should not be empty")
    }
}
