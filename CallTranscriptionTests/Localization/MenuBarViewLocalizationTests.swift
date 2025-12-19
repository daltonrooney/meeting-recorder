import XCTest
@testable import CallTranscription

/// Tests for MenuBarView localization implementation.
///
/// These tests verify that all user-facing strings in MenuBarView are properly
/// externalized to the String Catalog and accessible at runtime.
final class MenuBarViewLocalizationTests: XCTestCase {

    // MARK: - Button Label Localization Tests

    func testStartRecordingButtonLabelIsLocalized() {
        // Given: MenuBarView start recording button
        let key = "menubar.button.startRecording"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Start recording button label")

        // Then: Should return a localized value (not the key itself)
        XCTAssertNotEqual(localizedValue, key,
                         "Start Recording button label should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Start Recording button label should not be empty")
    }

    func testResumeRecordingButtonLabelIsLocalized() {
        // Given: MenuBarView resume recording button
        let key = "menubar.button.resumeRecording"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Resume recording button label")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Resume Recording button label should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Resume Recording button label should not be empty")
    }

    func testPauseRecordingButtonLabelIsLocalized() {
        // Given: MenuBarView pause recording button
        let key = "menubar.button.pauseRecording"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Pause recording button label")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Pause Recording button label should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Pause Recording button label should not be empty")
    }

    func testStopRecordingButtonLabelIsLocalized() {
        // Given: MenuBarView stop recording button
        let key = "menubar.button.stopRecording"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Stop recording button label")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Stop Recording button label should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Stop Recording button label should not be empty")
    }

    func testQuitButtonLabelIsLocalized() {
        // Given: MenuBarView quit button
        let key = "menubar.button.quit"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Quit button label")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Quit button label should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Quit button label should not be empty")
    }

    // MARK: - Settings Link Localization Tests

    func testSettingsLinkLabelIsLocalized() {
        // Given: MenuBarView settings link
        let key = "menubar.link.settings"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Settings link label")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Settings link label should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Settings link label should not be empty")
    }

    // MARK: - Status Display Localization Tests

    func testPausedStatusPrefixIsLocalized() {
        // Given: MenuBarView paused status display
        let key = "menubar.status.paused"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Paused status prefix")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Paused status prefix should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Paused status prefix should not be empty")
    }

    func testRecordingStatusPrefixIsLocalized() {
        // Given: MenuBarView recording status display
        let key = "menubar.status.recording"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Recording status prefix")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Recording status prefix should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Recording status prefix should not be empty")
    }

    // MARK: - Alert/Dialog Localization Tests

    func testErrorAlertTitleIsLocalized() {
        // Given: MenuBarView error alert title
        let key = "menubar.alert.error.title"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Error alert title")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Error alert title should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Error alert title should not be empty")
    }

    func testErrorAlertOkButtonIsLocalized() {
        // Given: MenuBarView error alert OK button
        let key = "menubar.alert.button.ok"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "OK button label")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "OK button label should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "OK button label should not be empty")
    }

    // MARK: - Accessibility Label Localization Tests

    func testStartRecordingAccessibilityLabelIsLocalized() {
        // Given: MenuBarView start recording accessibility label
        let key = "menubar.accessibility.startRecording.label"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Start recording accessibility label")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Start Recording accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Start Recording accessibility label should not be empty")
    }

    func testStartRecordingAccessibilityHintIsLocalized() {
        // Given: MenuBarView start recording accessibility hint
        let key = "menubar.accessibility.startRecording.hint"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Start recording accessibility hint")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Start Recording accessibility hint should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Start Recording accessibility hint should not be empty")
    }

    func testResumeRecordingAccessibilityLabelIsLocalized() {
        // Given: MenuBarView resume recording accessibility label
        let key = "menubar.accessibility.resumeRecording.label"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Resume recording accessibility label")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Resume Recording accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Resume Recording accessibility label should not be empty")
    }

    func testResumeRecordingAccessibilityHintIsLocalized() {
        // Given: MenuBarView resume recording accessibility hint
        let key = "menubar.accessibility.resumeRecording.hint"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Resume recording accessibility hint")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Resume Recording accessibility hint should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Resume Recording accessibility hint should not be empty")
    }

    func testPauseRecordingAccessibilityLabelIsLocalized() {
        // Given: MenuBarView pause recording accessibility label
        let key = "menubar.accessibility.pauseRecording.label"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Pause recording accessibility label")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Pause Recording accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Pause Recording accessibility label should not be empty")
    }

    func testPauseRecordingAccessibilityHintIsLocalized() {
        // Given: MenuBarView pause recording accessibility hint
        let key = "menubar.accessibility.pauseRecording.hint"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Pause recording accessibility hint")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Pause Recording accessibility hint should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Pause Recording accessibility hint should not be empty")
    }

    func testStopRecordingAccessibilityLabelIsLocalized() {
        // Given: MenuBarView stop recording accessibility label
        let key = "menubar.accessibility.stopRecording.label"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Stop recording accessibility label")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Stop Recording accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Stop Recording accessibility label should not be empty")
    }

    func testStopRecordingAccessibilityHintIsLocalized() {
        // Given: MenuBarView stop recording accessibility hint
        let key = "menubar.accessibility.stopRecording.hint"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Stop recording accessibility hint")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Stop Recording accessibility hint should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Stop Recording accessibility hint should not be empty")
    }

    func testSettingsAccessibilityLabelIsLocalized() {
        // Given: MenuBarView settings accessibility label
        let key = "menubar.accessibility.settings.label"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Settings accessibility label")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Settings accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Settings accessibility label should not be empty")
    }

    func testSettingsAccessibilityHintIsLocalized() {
        // Given: MenuBarView settings accessibility hint
        let key = "menubar.accessibility.settings.hint"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Settings accessibility hint")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Settings accessibility hint should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Settings accessibility hint should not be empty")
    }

    func testQuitAccessibilityLabelIsLocalized() {
        // Given: MenuBarView quit accessibility label
        let key = "menubar.accessibility.quit.label"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Quit accessibility label")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Quit accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Quit accessibility label should not be empty")
    }

    func testQuitAccessibilityHintIsLocalized() {
        // Given: MenuBarView quit accessibility hint
        let key = "menubar.accessibility.quit.hint"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Quit accessibility hint")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Quit accessibility hint should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Quit accessibility hint should not be empty")
    }

    func testPausedDurationAccessibilityLabelIsLocalized() {
        // Given: MenuBarView paused duration accessibility label
        let key = "menubar.accessibility.pausedDuration.label"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Paused duration accessibility label")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Paused duration accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Paused duration accessibility label should not be empty")
    }

    func testRecordingDurationAccessibilityLabelIsLocalized() {
        // Given: MenuBarView recording duration accessibility label
        let key = "menubar.accessibility.recordingDuration.label"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Recording duration accessibility label")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Recording duration accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Recording duration accessibility label should not be empty")
    }

    // MARK: - VoiceOver Announcement Localization Tests

    func testRecordingStartedAnnouncementIsLocalized() {
        // Given: VoiceOver announcement for recording started
        let key = "menubar.announcement.recordingStarted"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Recording started announcement")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Recording started announcement should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Recording started announcement should not be empty")
    }

    func testRecordingStoppedAnnouncementIsLocalized() {
        // Given: VoiceOver announcement for recording stopped
        let key = "menubar.announcement.recordingStopped"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Recording stopped announcement")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Recording stopped announcement should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Recording stopped announcement should not be empty")
    }

    func testRecordingPausedAnnouncementIsLocalized() {
        // Given: VoiceOver announcement for recording paused
        let key = "menubar.announcement.recordingPaused"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Recording paused announcement")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Recording paused announcement should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Recording paused announcement should not be empty")
    }

    func testRecordingResumedAnnouncementIsLocalized() {
        // Given: VoiceOver announcement for recording resumed
        let key = "menubar.announcement.recordingResumed"

        // When: Looking up the localized string
        let localizedValue = NSLocalizedString(key, comment: "Recording resumed announcement")

        // Then: Should return a localized value
        XCTAssertNotEqual(localizedValue, key,
                         "Recording resumed announcement should be localized")
        XCTAssertFalse(localizedValue.isEmpty,
                      "Recording resumed announcement should not be empty")
    }
}
