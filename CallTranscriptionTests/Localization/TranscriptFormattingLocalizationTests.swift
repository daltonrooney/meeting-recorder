import XCTest
@testable import CallTranscription

/// Tests for transcript file formatting string localization.
///
/// These tests verify that all user-facing strings in transcript file headers
/// and formatting are properly localized.
final class TranscriptFormattingLocalizationTests: XCTestCase {

    // MARK: - Header String Tests

    func testHeaderTitleIsLocalized() {
        let key = "transcript.header.title"
        let localizedValue = NSLocalizedString(key, comment: "Transcript file header title")

        XCTAssertNotEqual(localizedValue, key, "Header title should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Header title should not be empty")
    }

    func testDateLabelIsLocalized() {
        let key = "transcript.header.dateLabel"
        let localizedValue = NSLocalizedString(key, comment: "Date label in transcript header")

        XCTAssertNotEqual(localizedValue, key, "Date label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Date label should not be empty")
    }

    func testTitleLabelIsLocalized() {
        let key = "transcript.header.titleLabel"
        let localizedValue = NSLocalizedString(key, comment: "Title label in transcript header")

        XCTAssertNotEqual(localizedValue, key, "Title label should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Title label should not be empty")
    }

    func testSeparatorIsLocalized() {
        let key = "transcript.header.separator"
        let localizedValue = NSLocalizedString(key, comment: "Separator line in transcript header")

        XCTAssertNotEqual(localizedValue, key, "Separator should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Separator should not be empty")
    }
}
