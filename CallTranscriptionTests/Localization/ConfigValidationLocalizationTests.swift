import XCTest
@testable import CallTranscription

/// Tests for configuration validation message localization.
///
/// These tests verify that all validation error messages in ConfigureSettingsIntent
/// are properly localized for folder and script path validation.
final class ConfigValidationLocalizationTests: XCTestCase {

    // MARK: - Folder Path Validation Tests

    func testSystemDirectoryErrorIsLocalized() {
        let key = "config.validation.systemDirectory"
        let localizedValue = NSLocalizedString(key, comment: "System directory error message")

        XCTAssertNotEqual(localizedValue, key, "System directory error should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "System directory error should not be empty")
    }

    func testPathTraversalErrorIsLocalized() {
        let key = "config.validation.pathTraversal"
        let localizedValue = NSLocalizedString(key, comment: "Path traversal error message")

        XCTAssertNotEqual(localizedValue, key, "Path traversal error should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Path traversal error should not be empty")
    }

    func testNotDirectoryErrorIsLocalized() {
        let key = "config.validation.notDirectory"
        let localizedValue = NSLocalizedString(key, comment: "Not a directory error message")

        XCTAssertNotEqual(localizedValue, key, "Not a directory error should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Not a directory error should not be empty")
    }

    func testNotWritableErrorIsLocalized() {
        let key = "config.validation.notWritable"
        let localizedValue = NSLocalizedString(key, comment: "Directory not writable error message")

        XCTAssertNotEqual(localizedValue, key, "Not writable error should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Not writable error should not be empty")
    }

    func testCannotCreateDirectoryErrorIsLocalized() {
        let key = "config.validation.cannotCreateDirectory"
        let localizedValue = NSLocalizedString(key, comment: "Cannot create directory error message")

        XCTAssertNotEqual(localizedValue, key, "Cannot create directory error should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Cannot create directory error should not be empty")
    }

    // MARK: - Script Path Validation Tests

    func testScriptNotFoundErrorIsLocalized() {
        let key = "config.validation.scriptNotFound"
        let localizedValue = NSLocalizedString(key, comment: "Script not found error message")

        XCTAssertNotEqual(localizedValue, key, "Script not found error should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Script not found error should not be empty")
    }

    func testScriptIsDirectoryErrorIsLocalized() {
        let key = "config.validation.scriptIsDirectory"
        let localizedValue = NSLocalizedString(key, comment: "Script is directory error message")

        XCTAssertNotEqual(localizedValue, key, "Script is directory error should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Script is directory error should not be empty")
    }

    func testScriptNotExecutableErrorIsLocalized() {
        let key = "config.validation.scriptNotExecutable"
        let localizedValue = NSLocalizedString(key, comment: "Script not executable error message")

        XCTAssertNotEqual(localizedValue, key, "Script not executable error should be localized")
        XCTAssertFalse(localizedValue.isEmpty, "Script not executable error should not be empty")
    }
}
