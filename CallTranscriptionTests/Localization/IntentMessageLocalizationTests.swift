import XCTest
@testable import CallTranscription

/// Tests for Intent message localization.
///
/// These tests verify that all user-facing strings in App Intents
/// (status messages, error messages, default values) are properly localized.
final class IntentMessageLocalizationTests: XCTestCase {

    // MARK: - Recording Status Messages Tests

    func testRecordingPausedStatusIsLocalized() {
        let key = "intent.status.recordingPaused"
        let localizedValue = NSLocalizedString(key, comment: "Recording paused status message")

        XCTAssertNotEqual(localizedValue, key, "Recording paused status should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Recording paused status should not be empty")
    }

    func testRecordingInProgressStatusIsLocalized() {
        let key = "intent.status.recordingInProgress"
        let localizedValue = NSLocalizedString(key, comment: "Recording in progress status message")

        XCTAssertNotEqual(localizedValue, key, "Recording in progress status should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Recording in progress status should not be empty")
    }

    func testNotRecordingStatusIsLocalized() {
        let key = "intent.status.notRecording"
        let localizedValue = NSLocalizedString(key, comment: "Not recording status message")

        XCTAssertNotEqual(localizedValue, key, "Not recording status should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Not recording status should not be empty")
    }

    // MARK: - IntentError Messages Tests

    func testAppNotAvailableErrorIsLocalized() {
        let error = IntentError.appNotAvailable
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testRecordingFailedErrorIsLocalized() {
        let error = IntentError.recordingFailed("Test reason")
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
        XCTAssertTrue(error.errorDescription!.contains("Test reason"), "Error should include the reason")
    }

    func testNotRecordingErrorIsLocalized() {
        let error = IntentError.notRecording
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testConfigurationFailedErrorIsLocalized() {
        let error = IntentError.configurationFailed("Test reason")
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
        XCTAssertTrue(error.errorDescription!.contains("Test reason"), "Error should include the reason")
    }

    // MARK: - Default Value Tests

    func testUntitledRecordingDefaultIsLocalized() {
        let key = "intent.recording.defaultTitle"
        let localizedValue = NSLocalizedString(key, comment: "Default recording title")

        XCTAssertNotEqual(localizedValue, key, "Default recording title should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Default recording title should not be empty")
    }
}
