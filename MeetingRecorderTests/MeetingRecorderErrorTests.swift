import XCTest
@testable import MeetingRecorder

final class MeetingRecorderErrorTests: XCTestCase {

    // MARK: - Error Case Existence Tests

    func testMicrophonePermissionDeniedErrorExists() {
        let error = MeetingRecorderError.microphonePermissionDenied
        XCTAssertNotNil(error)
    }

    func testSpeechRecognitionUnavailableErrorExists() {
        let error = MeetingRecorderError.speechRecognitionUnavailable
        XCTAssertNotNil(error)
    }

    func testLocaleNotSupportedErrorExists() {
        let locale = Locale(identifier: "en_US")
        let error = MeetingRecorderError.localeNotSupported(locale)
        XCTAssertNotNil(error)
    }

    func testOutputFolderNotWritableErrorExists() {
        let url = URL(fileURLWithPath: "/tmp/test")
        let error = MeetingRecorderError.outputFolderNotWritable(url)
        XCTAssertNotNil(error)
    }

    func testAudioTapCreationFailedErrorExists() {
        let status: OSStatus = -50
        let error = MeetingRecorderError.audioTapCreationFailed(status)
        XCTAssertNotNil(error)
    }

    // MARK: - LocalizedError Conformance Tests

    func testErrorConformsToLocalizedError() {
        let error = MeetingRecorderError.microphonePermissionDenied
        XCTAssertTrue(error is LocalizedError)
    }

    // MARK: - Error Description Tests

    func testMicrophonePermissionDeniedHasDescription() {
        let error = MeetingRecorderError.microphonePermissionDenied
        let description = error.errorDescription

        XCTAssertNotNil(description)
        XCTAssertFalse(description?.isEmpty ?? true)
    }

    func testMicrophonePermissionDeniedDescriptionIsActionable() {
        let error = MeetingRecorderError.microphonePermissionDenied
        let description = error.errorDescription
        let recoverySuggestion = error.recoverySuggestion

        // Should mention microphone
        XCTAssertTrue(description?.lowercased().contains("microphone") ?? false)
        // Should mention System Settings in recovery suggestion (actionable guidance)
        XCTAssertTrue(recoverySuggestion?.contains("System Settings") ?? false)
        // Should mention Privacy & Security in recovery suggestion
        XCTAssertTrue(recoverySuggestion?.contains("Privacy") ?? false)
    }

    func testSpeechRecognitionUnavailableHasDescription() {
        let error = MeetingRecorderError.speechRecognitionUnavailable
        let description = error.errorDescription

        XCTAssertNotNil(description)
        XCTAssertFalse(description?.isEmpty ?? true)
    }

    func testSpeechRecognitionUnavailableDescriptionIsActionable() {
        let error = MeetingRecorderError.speechRecognitionUnavailable
        let description = error.errorDescription
        let recoverySuggestion = error.recoverySuggestion

        // Should mention speech recognition
        XCTAssertTrue(description?.lowercased().contains("speech recognition") ?? false)
        // Should provide actionable guidance in recovery suggestion (model download, connection)
        XCTAssertTrue(
            (recoverySuggestion?.contains("model") ?? false) ||
            (recoverySuggestion?.contains("connection") ?? false)
        )
    }

    func testLocaleNotSupportedHasDescription() {
        let locale = Locale(identifier: "fr_FR")
        let error = MeetingRecorderError.localeNotSupported(locale)
        let description = error.errorDescription

        XCTAssertNotNil(description)
        XCTAssertFalse(description?.isEmpty ?? true)
    }

    func testLocaleNotSupportedIncludesLocaleIdentifier() {
        let locale = Locale(identifier: "fr_FR")
        let error = MeetingRecorderError.localeNotSupported(locale)
        let description = error.errorDescription

        // Should include the locale identifier
        XCTAssertTrue(description?.contains("fr_FR") ?? false)
    }

    func testLocaleNotSupportedDescriptionIsActionable() {
        let locale = Locale(identifier: "es_ES")
        let error = MeetingRecorderError.localeNotSupported(locale)
        let description = error.errorDescription

        // Should mention speech recognition not available
        XCTAssertTrue(description?.lowercased().contains("speech recognition") ?? false)
        // Should contain locale identifier
        XCTAssertTrue(description?.contains("es_ES") ?? false)
    }

    func testOutputFolderNotWritableHasDescription() {
        let url = URL(fileURLWithPath: "/System/Library")
        let error = MeetingRecorderError.outputFolderNotWritable(url)
        let description = error.errorDescription

        XCTAssertNotNil(description)
        XCTAssertFalse(description?.isEmpty ?? true)
    }

    func testOutputFolderNotWritableIncludesPath() {
        let url = URL(fileURLWithPath: "/System/Library")
        let error = MeetingRecorderError.outputFolderNotWritable(url)
        let description = error.errorDescription

        // Should include the path
        XCTAssertTrue(description?.contains("/System/Library") ?? false)
    }

    func testOutputFolderNotWritableDescriptionIsActionable() {
        let url = URL(fileURLWithPath: "/protected/folder")
        let error = MeetingRecorderError.outputFolderNotWritable(url)
        let description = error.errorDescription
        let recoverySuggestion = error.recoverySuggestion

        // Should mention cannot write
        XCTAssertTrue(
            (description?.lowercased().contains("write") ?? false) ||
            (description?.lowercased().contains("writable") ?? false)
        )
        // Should suggest selecting different folder in recovery suggestion
        XCTAssertTrue(recoverySuggestion?.lowercased().contains("select") ?? false)
    }

    func testAudioTapCreationFailedHasDescription() {
        let error = MeetingRecorderError.audioTapCreationFailed(-50)
        let description = error.errorDescription

        XCTAssertNotNil(description)
        XCTAssertFalse(description?.isEmpty ?? true)
    }

    func testAudioTapCreationFailedIncludesStatusCode() {
        let status: OSStatus = -12345
        let error = MeetingRecorderError.audioTapCreationFailed(status)
        let description = error.errorDescription

        // Should include the status code
        XCTAssertTrue(description?.contains("-12345") ?? false)
    }

    func testAudioTapCreationFailedDescriptionIsActionable() {
        let error = MeetingRecorderError.audioTapCreationFailed(-50)
        let description = error.errorDescription
        let recoverySuggestion = error.recoverySuggestion

        // Should mention audio tap
        XCTAssertTrue(description?.lowercased().contains("audio tap") ?? false)
        // Should mention system audio in recovery suggestion
        XCTAssertTrue(recoverySuggestion?.lowercased().contains("system audio") ?? false)
    }

    // MARK: - Associated Value Preservation Tests

    func testLocaleAssociatedValueIsPreserved() {
        let originalLocale = Locale(identifier: "ja_JP")
        let error = MeetingRecorderError.localeNotSupported(originalLocale)

        // Extract associated value
        if case .localeNotSupported(let extractedLocale) = error {
            XCTAssertEqual(extractedLocale.identifier, originalLocale.identifier)
        } else {
            XCTFail("Failed to extract locale from error")
        }
    }

    func testURLAssociatedValueIsPreserved() {
        let originalURL = URL(fileURLWithPath: "/tmp/meeting-recordings")
        let error = MeetingRecorderError.outputFolderNotWritable(originalURL)

        // Extract associated value
        if case .outputFolderNotWritable(let extractedURL) = error {
            XCTAssertEqual(extractedURL.path, originalURL.path)
        } else {
            XCTFail("Failed to extract URL from error")
        }
    }

    func testOSStatusAssociatedValueIsPreserved() {
        let originalStatus: OSStatus = -9876
        let error = MeetingRecorderError.audioTapCreationFailed(originalStatus)

        // Extract associated value
        if case .audioTapCreationFailed(let extractedStatus) = error {
            XCTAssertEqual(extractedStatus, originalStatus)
        } else {
            XCTFail("Failed to extract OSStatus from error")
        }
    }

    // MARK: - Error Throwing and Catching Tests

    func testErrorCanBeThrown() throws {
        func throwingFunction() throws {
            throw MeetingRecorderError.microphonePermissionDenied
        }

        XCTAssertThrowsError(try throwingFunction()) { error in
            XCTAssertTrue(error is MeetingRecorderError)
        }
    }

    func testErrorCanBeCaught() {
        do {
            throw MeetingRecorderError.speechRecognitionUnavailable
            XCTFail("Should have thrown error")
        } catch let error as MeetingRecorderError {
            XCTAssertNotNil(error)
        } catch {
            XCTFail("Caught wrong error type")
        }
    }

    func testErrorCanBeCaughtWithSpecificCase() {
        do {
            throw MeetingRecorderError.localeNotSupported(Locale(identifier: "de_DE"))
            XCTFail("Should have thrown error")
        } catch MeetingRecorderError.localeNotSupported(let locale) {
            XCTAssertEqual(locale.identifier, "de_DE")
        } catch {
            XCTFail("Caught wrong error type or case")
        }
    }

    // MARK: - Edge Case Tests

    func testMultipleDifferentLocaleErrors() {
        let error1 = MeetingRecorderError.localeNotSupported(Locale(identifier: "en_US"))
        let error2 = MeetingRecorderError.localeNotSupported(Locale(identifier: "fr_FR"))

        // Both should have descriptions
        XCTAssertNotNil(error1.errorDescription)
        XCTAssertNotNil(error2.errorDescription)

        // Descriptions should include respective locales
        XCTAssertTrue(error1.errorDescription?.contains("en_US") ?? false)
        XCTAssertTrue(error2.errorDescription?.contains("fr_FR") ?? false)
    }

    func testMultipleDifferentURLErrors() {
        let error1 = MeetingRecorderError.outputFolderNotWritable(URL(fileURLWithPath: "/path/one"))
        let error2 = MeetingRecorderError.outputFolderNotWritable(URL(fileURLWithPath: "/path/two"))

        // Both should have descriptions with respective paths
        XCTAssertTrue(error1.errorDescription?.contains("/path/one") ?? false)
        XCTAssertTrue(error2.errorDescription?.contains("/path/two") ?? false)
    }

    func testMultipleDifferentOSStatusErrors() {
        let error1 = MeetingRecorderError.audioTapCreationFailed(100)
        let error2 = MeetingRecorderError.audioTapCreationFailed(-500)

        // Both should have descriptions with respective status codes
        XCTAssertTrue(error1.errorDescription?.contains("100") ?? false)
        XCTAssertTrue(error2.errorDescription?.contains("-500") ?? false)
    }
}
