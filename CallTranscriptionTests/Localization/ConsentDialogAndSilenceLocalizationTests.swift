import XCTest
@testable import CallTranscription

/// Tests for ConsentDialogView and SilencePauseThreshold localization.
///
/// These tests verify that all user-facing strings in ConsentDialogView and
/// SilencePauseThreshold are properly externalized to the String Catalog.
final class ConsentDialogAndSilenceLocalizationTests: XCTestCase {

    // MARK: - ConsentDialogView Tests

    func testConsentDialogTitleIsLocalized() {
        let key = "consentDialog.title"
        let localizedValue = NSLocalizedString(key, comment: "Consent dialog title")

        XCTAssertNotEqual(localizedValue, key, "Consent dialog title should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Consent dialog title should not be empty")
    }

    func testConsentDialogIntroTextIsLocalized() {
        let key = "consentDialog.intro"
        let localizedValue = NSLocalizedString(key, comment: "Consent dialog intro text")

        XCTAssertNotEqual(localizedValue, key, "Consent dialog intro should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Consent dialog intro should not be empty")
    }

    func testConsentDialogBullet1IsLocalized() {
        let key = "consentDialog.bullet1"
        let localizedValue = NSLocalizedString(key, comment: "First bullet point")

        XCTAssertNotEqual(localizedValue, key, "Bullet point 1 should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Bullet point 1 should not be empty")
    }

    func testConsentDialogBullet2IsLocalized() {
        let key = "consentDialog.bullet2"
        let localizedValue = NSLocalizedString(key, comment: "Second bullet point")

        XCTAssertNotEqual(localizedValue, key, "Bullet point 2 should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Bullet point 2 should not be empty")
    }

    func testConsentDialogBullet3IsLocalized() {
        let key = "consentDialog.bullet3"
        let localizedValue = NSLocalizedString(key, comment: "Third bullet point")

        XCTAssertNotEqual(localizedValue, key, "Bullet point 3 should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Bullet point 3 should not be empty")
    }

    func testConsentDialogBullet4IsLocalized() {
        let key = "consentDialog.bullet4"
        let localizedValue = NSLocalizedString(key, comment: "Fourth bullet point")

        XCTAssertNotEqual(localizedValue, key, "Bullet point 4 should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Bullet point 4 should not be empty")
    }

    func testConsentDialogResponsibilityTextIsLocalized() {
        let key = "consentDialog.responsibility"
        let localizedValue = NSLocalizedString(key, comment: "User responsibility text")

        XCTAssertNotEqual(localizedValue, key, "Responsibility text should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Responsibility text should not be empty")
    }

    func testConsentDialogWarningTextIsLocalized() {
        let key = "consentDialog.warning"
        let localizedValue = NSLocalizedString(key, comment: "Legal warning text")

        XCTAssertNotEqual(localizedValue, key, "Warning text should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Warning text should not be empty")
    }

    func testConsentDialogCheckboxLabelIsLocalized() {
        let key = "consentDialog.checkbox.label"
        let localizedValue = NSLocalizedString(key, comment: "Do not remind checkbox label")

        XCTAssertNotEqual(localizedValue, key, "Checkbox label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Checkbox label should not be empty")
    }

    func testConsentDialogQuitButtonIsLocalized() {
        let key = "consentDialog.button.quit"
        let localizedValue = NSLocalizedString(key, comment: "Quit button label")

        XCTAssertNotEqual(localizedValue, key, "Quit button should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Quit button should not be empty")
    }

    func testConsentDialogUnderstandButtonIsLocalized() {
        let key = "consentDialog.button.understand"
        let localizedValue = NSLocalizedString(key, comment: "I Understand button label")

        XCTAssertNotEqual(localizedValue, key, "I Understand button should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "I Understand button should not be empty")
    }

    // MARK: - ConsentDialogView Accessibility Tests

    func testConsentDialogTitleAccessibilityLabelIsLocalized() {
        let key = "consentDialog.title.accessibility.label"
        let localizedValue = NSLocalizedString(key, comment: "Title accessibility label")

        XCTAssertNotEqual(localizedValue, key, "Title accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Title accessibility label should not be empty")
    }

    func testConsentDialogBodyAccessibilityLabelIsLocalized() {
        let key = "consentDialog.body.accessibility.label"
        let localizedValue = NSLocalizedString(key, comment: "Body accessibility label")

        XCTAssertNotEqual(localizedValue, key, "Body accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Body accessibility label should not be empty")
    }

    func testConsentDialogCheckboxAccessibilityLabelIsLocalized() {
        let key = "consentDialog.checkbox.accessibility.label"
        let localizedValue = NSLocalizedString(key, comment: "Checkbox accessibility label")

        XCTAssertNotEqual(localizedValue, key, "Checkbox accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Checkbox accessibility label should not be empty")
    }

    func testConsentDialogCheckboxAccessibilityHintIsLocalized() {
        let key = "consentDialog.checkbox.accessibility.hint"
        let localizedValue = NSLocalizedString(key, comment: "Checkbox accessibility hint")

        XCTAssertNotEqual(localizedValue, key, "Checkbox accessibility hint should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Checkbox accessibility hint should not be empty")
    }

    func testConsentDialogQuitAccessibilityLabelIsLocalized() {
        let key = "consentDialog.quit.accessibility.label"
        let localizedValue = NSLocalizedString(key, comment: "Quit accessibility label")

        XCTAssertNotEqual(localizedValue, key, "Quit accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Quit accessibility label should not be empty")
    }

    func testConsentDialogQuitAccessibilityHintIsLocalized() {
        let key = "consentDialog.quit.accessibility.hint"
        let localizedValue = NSLocalizedString(key, comment: "Quit accessibility hint")

        XCTAssertNotEqual(localizedValue, key, "Quit accessibility hint should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Quit accessibility hint should not be empty")
    }

    func testConsentDialogUnderstandAccessibilityLabelIsLocalized() {
        let key = "consentDialog.understand.accessibility.label"
        let localizedValue = NSLocalizedString(key, comment: "I Understand accessibility label")

        XCTAssertNotEqual(localizedValue, key, "I Understand accessibility label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "I Understand accessibility label should not be empty")
    }

    func testConsentDialogUnderstandAccessibilityHintIsLocalized() {
        let key = "consentDialog.understand.accessibility.hint"
        let localizedValue = NSLocalizedString(key, comment: "I Understand accessibility hint")

        XCTAssertNotEqual(localizedValue, key, "I Understand accessibility hint should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "I Understand accessibility hint should not be empty")
    }

    // MARK: - SilencePauseThreshold Tests

    func testSilenceThresholdTwoMinutesIsLocalized() {
        let key = "silenceThreshold.twoMinutes"
        let localizedValue = NSLocalizedString(key, comment: "2 minutes threshold")

        XCTAssertNotEqual(localizedValue, key, "2 minutes threshold should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "2 minutes threshold should not be empty")
    }

    func testSilenceThresholdFiveMinutesIsLocalized() {
        let key = "silenceThreshold.fiveMinutes"
        let localizedValue = NSLocalizedString(key, comment: "5 minutes threshold")

        XCTAssertNotEqual(localizedValue, key, "5 minutes threshold should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "5 minutes threshold should not be empty")
    }

    func testSilenceThresholdTenMinutesIsLocalized() {
        let key = "silenceThreshold.tenMinutes"
        let localizedValue = NSLocalizedString(key, comment: "10 minutes threshold")

        XCTAssertNotEqual(localizedValue, key, "10 minutes threshold should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "10 minutes threshold should not be empty")
    }

    func testSilenceThresholdNeverIsLocalized() {
        let key = "silenceThreshold.never"
        let localizedValue = NSLocalizedString(key, comment: "Never threshold")

        XCTAssertNotEqual(localizedValue, key, "Never threshold should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Never threshold should not be empty")
    }
}
