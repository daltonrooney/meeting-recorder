import XCTest
@testable import CallTranscription

/// Tests for SettingsView Part 2 localization (Post-Recording section).
///
/// These tests verify that all user-facing strings in the Post-Recording section
/// are properly externalized to the String Catalog.
final class SettingsViewPart2LocalizationTests: XCTestCase {

    // MARK: - Post-Recording Section Tests

    func testPostRecordingSectionHeaderIsLocalized() {
        let key = "settings.postRecording.header"
        let localizedValue = NSLocalizedString(key, comment: "Post-recording section header")

        XCTAssertNotEqual(localizedValue, key, "Post-recording section header should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Post-recording section header should not be empty")
    }

    func testAfterRecordingLabelIsLocalized() {
        let key = "settings.postRecording.afterRecording.label"
        let localizedValue = NSLocalizedString(key, comment: "After recording picker label")

        XCTAssertNotEqual(localizedValue, key, "After recording label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "After recording label should not be empty")
    }

    // MARK: - Action Type Radio Options Tests

    func testDoNothingOptionIsLocalized() {
        let key = "settings.postRecording.action.doNothing"
        let localizedValue = NSLocalizedString(key, comment: "Do nothing radio option")

        XCTAssertNotEqual(localizedValue, key, "Do nothing option should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Do nothing option should not be empty")
    }

    func testRunScriptOptionIsLocalized() {
        let key = "settings.postRecording.action.runScript"
        let localizedValue = NSLocalizedString(key, comment: "Run script radio option")

        XCTAssertNotEqual(localizedValue, key, "Run script option should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Run script option should not be empty")
    }

    func testRunShortcutOptionIsLocalized() {
        let key = "settings.postRecording.action.runShortcut"
        let localizedValue = NSLocalizedString(key, comment: "Run shortcut radio option")

        XCTAssertNotEqual(localizedValue, key, "Run shortcut option should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Run shortcut option should not be empty")
    }

    // MARK: - Script Section Tests

    func testScriptPathLabelIsLocalized() {
        let key = "settings.postRecording.script.path.label"
        let localizedValue = NSLocalizedString(key, comment: "Script path text field label")

        XCTAssertNotEqual(localizedValue, key, "Script path label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Script path label should not be empty")
    }

    func testScriptBrowseButtonIsLocalized() {
        let key = "settings.postRecording.script.browseButton"
        let localizedValue = NSLocalizedString(key, comment: "Browse button for script")

        XCTAssertNotEqual(localizedValue, key, "Script browse button should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Script browse button should not be empty")
    }

    func testScriptHelpTextIsLocalized() {
        let key = "settings.postRecording.script.helpText"
        let localizedValue = NSLocalizedString(key, comment: "Script help text")

        XCTAssertNotEqual(localizedValue, key, "Script help text should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Script help text should not be empty")
    }

    // MARK: - Shortcut Section Tests

    func testLoadingShortcutsTextIsLocalized() {
        let key = "settings.postRecording.shortcut.loading"
        let localizedValue = NSLocalizedString(key, comment: "Loading shortcuts text")

        XCTAssertNotEqual(localizedValue, key, "Loading shortcuts text should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Loading shortcuts text should not be empty")
    }

    func testShortcutPickerLabelIsLocalized() {
        let key = "settings.postRecording.shortcut.picker.label"
        let localizedValue = NSLocalizedString(key, comment: "Shortcut picker label")

        XCTAssertNotEqual(localizedValue, key, "Shortcut picker label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Shortcut picker label should not be empty")
    }

    func testShortcutPlaceholderIsLocalized() {
        let key = "settings.postRecording.shortcut.placeholder"
        let localizedValue = NSLocalizedString(key, comment: "Shortcut picker placeholder")

        XCTAssertNotEqual(localizedValue, key, "Shortcut placeholder should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Shortcut placeholder should not be empty")
    }

    func testNoShortcutsMessageIsLocalized() {
        let key = "settings.postRecording.shortcut.noShortcuts"
        let localizedValue = NSLocalizedString(key, comment: "No shortcuts found message")

        XCTAssertNotEqual(localizedValue, key, "No shortcuts message should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "No shortcuts message should not be empty")
    }

    func testShortcutHelpTextIsLocalized() {
        let key = "settings.postRecording.shortcut.helpText"
        let localizedValue = NSLocalizedString(key, comment: "Shortcut help text")

        XCTAssertNotEqual(localizedValue, key, "Shortcut help text should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Shortcut help text should not be empty")
    }

    // MARK: - Post-Recording Accessibility Tests

    func testAfterRecordingAccessibilityLabelIsLocalized() {
        let key = "settings.postRecording.afterRecording.accessibility.label"
        let localizedValue = NSLocalizedString(key, comment: "After recording accessibility label")

        XCTAssertNotEqual(localizedValue, key, "After recording accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "After recording accessibility label should not be empty")
    }

    func testAfterRecordingAccessibilityHintIsLocalized() {
        let key = "settings.postRecording.afterRecording.accessibility.hint"
        let localizedValue = NSLocalizedString(key, comment: "After recording accessibility hint")

        XCTAssertNotEqual(localizedValue, key, "After recording accessibility hint should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "After recording accessibility hint should not be empty")
    }

    func testScriptPathAccessibilityLabelIsLocalized() {
        let key = "settings.postRecording.script.path.accessibility.label"
        let localizedValue = NSLocalizedString(key, comment: "Script path accessibility label")

        XCTAssertNotEqual(localizedValue, key, "Script path accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Script path accessibility label should not be empty")
    }

    func testScriptPathAccessibilityHintIsLocalized() {
        let key = "settings.postRecording.script.path.accessibility.hint"
        let localizedValue = NSLocalizedString(key, comment: "Script path accessibility hint")

        XCTAssertNotEqual(localizedValue, key, "Script path accessibility hint should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Script path accessibility hint should not be empty")
    }

    func testScriptBrowseAccessibilityLabelIsLocalized() {
        let key = "settings.postRecording.script.browse.accessibility.label"
        let localizedValue = NSLocalizedString(key, comment: "Script browse accessibility label")

        XCTAssertNotEqual(localizedValue, key, "Script browse accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Script browse accessibility label should not be empty")
    }

    func testScriptBrowseAccessibilityHintIsLocalized() {
        let key = "settings.postRecording.script.browse.accessibility.hint"
        let localizedValue = NSLocalizedString(key, comment: "Script browse accessibility hint")

        XCTAssertNotEqual(localizedValue, key, "Script browse accessibility hint should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Script browse accessibility hint should not be empty")
    }

    func testShortcutPickerAccessibilityLabelIsLocalized() {
        let key = "settings.postRecording.shortcut.picker.accessibility.label"
        let localizedValue = NSLocalizedString(key, comment: "Shortcut picker accessibility label")

        XCTAssertNotEqual(localizedValue, key, "Shortcut picker accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Shortcut picker accessibility label should not be empty")
    }

    func testShortcutPickerAccessibilityHintIsLocalized() {
        let key = "settings.postRecording.shortcut.picker.accessibility.hint"
        let localizedValue = NSLocalizedString(key, comment: "Shortcut picker accessibility hint")

        XCTAssertNotEqual(localizedValue, key, "Shortcut picker accessibility hint should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Shortcut picker accessibility hint should not be empty")
    }

    func testLoadingShortcutsAccessibilityLabelIsLocalized() {
        let key = "settings.postRecording.shortcut.loading.accessibility.label"
        let localizedValue = NSLocalizedString(key, comment: "Loading shortcuts accessibility label")

        XCTAssertNotEqual(localizedValue, key, "Loading shortcuts accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Loading shortcuts accessibility label should not be empty")
    }

    // MARK: - Script Dialog Tests

    func testScriptDialogPromptIsLocalized() {
        let key = "settings.postRecording.script.dialog.prompt"
        let localizedValue = NSLocalizedString(key, comment: "Script dialog prompt")

        XCTAssertNotEqual(localizedValue, key, "Script dialog prompt should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Script dialog prompt should not be empty")
    }

    func testScriptDialogMessageIsLocalized() {
        let key = "settings.postRecording.script.dialog.message"
        let localizedValue = NSLocalizedString(key, comment: "Script dialog message")

        XCTAssertNotEqual(localizedValue, key, "Script dialog message should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Script dialog message should not be empty")
    }
}
