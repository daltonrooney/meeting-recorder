import XCTest
@testable import CallTranscription

/// Tests for CallTranscriptionError localization.
///
/// These tests verify that all error messages (descriptions, failure reasons,
/// and recovery suggestions) are properly localized through the LocalizedError protocol.
final class ErrorMessageLocalizationTests: XCTestCase {

    // MARK: - Microphone Permission Denied Tests

    func testMicrophonePermissionDeniedDescriptionIsLocalized() {
        let error = CallTranscriptionError.microphonePermissionDenied
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testMicrophonePermissionDeniedFailureReasonIsLocalized() {
        let error = CallTranscriptionError.microphonePermissionDenied
        XCTAssertNotNil(error.failureReason, "Failure reason should not be nil")
        XCTAssertFalse(error.failureReason!.isEmpty, "Failure reason should not be empty")
    }

    func testMicrophonePermissionDeniedRecoverySuggestionIsLocalized() {
        let error = CallTranscriptionError.microphonePermissionDenied
        XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil")
        XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Recovery suggestion should not be empty")
    }

    // MARK: - Speech Recognition Unavailable Tests

    func testSpeechRecognitionUnavailableDescriptionIsLocalized() {
        let error = CallTranscriptionError.speechRecognitionUnavailable
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testSpeechRecognitionUnavailableFailureReasonIsLocalized() {
        let error = CallTranscriptionError.speechRecognitionUnavailable
        XCTAssertNotNil(error.failureReason, "Failure reason should not be nil")
        XCTAssertFalse(error.failureReason!.isEmpty, "Failure reason should not be empty")
    }

    func testSpeechRecognitionUnavailableRecoverySuggestionIsLocalized() {
        let error = CallTranscriptionError.speechRecognitionUnavailable
        XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil")
        XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Recovery suggestion should not be empty")
    }

    // MARK: - Locale Not Supported Tests

    func testLocaleNotSupportedDescriptionIsLocalized() {
        let error = CallTranscriptionError.localeNotSupported(Locale(identifier: "en_US"))
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testLocaleNotSupportedFailureReasonIsLocalized() {
        let error = CallTranscriptionError.localeNotSupported(Locale(identifier: "en_US"))
        XCTAssertNotNil(error.failureReason, "Failure reason should not be nil")
        XCTAssertFalse(error.failureReason!.isEmpty, "Failure reason should not be empty")
    }

    func testLocaleNotSupportedRecoverySuggestionIsLocalized() {
        let error = CallTranscriptionError.localeNotSupported(Locale(identifier: "en_US"))
        XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil")
        XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Recovery suggestion should not be empty")
    }

    // MARK: - Output Folder Not Writable Tests

    func testOutputFolderNotWritableDescriptionIsLocalized() {
        let url = URL(fileURLWithPath: "/tmp/test")
        let error = CallTranscriptionError.outputFolderNotWritable(url)
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testOutputFolderNotWritableFailureReasonIsLocalized() {
        let url = URL(fileURLWithPath: "/tmp/test")
        let error = CallTranscriptionError.outputFolderNotWritable(url)
        XCTAssertNotNil(error.failureReason, "Failure reason should not be nil")
        XCTAssertFalse(error.failureReason!.isEmpty, "Failure reason should not be empty")
    }

    func testOutputFolderNotWritableRecoverySuggestionIsLocalized() {
        let url = URL(fileURLWithPath: "/tmp/test")
        let error = CallTranscriptionError.outputFolderNotWritable(url)
        XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil")
        XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Recovery suggestion should not be empty")
    }

    // MARK: - Audio Tap Creation Failed Tests

    func testAudioTapCreationFailedDescriptionIsLocalized() {
        let error = CallTranscriptionError.audioTapCreationFailed(-1234)
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testAudioTapCreationFailedFailureReasonIsLocalized() {
        let error = CallTranscriptionError.audioTapCreationFailed(-1234)
        XCTAssertNotNil(error.failureReason, "Failure reason should not be nil")
        XCTAssertFalse(error.failureReason!.isEmpty, "Failure reason should not be empty")
    }

    func testAudioTapCreationFailedRecoverySuggestionIsLocalized() {
        let error = CallTranscriptionError.audioTapCreationFailed(-1234)
        XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil")
        XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Recovery suggestion should not be empty")
    }

    // MARK: - Feature Not Implemented Tests

    func testFeatureNotImplementedDescriptionIsLocalized() {
        let error = CallTranscriptionError.featureNotImplemented("Test Feature")
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testFeatureNotImplementedFailureReasonIsLocalized() {
        let error = CallTranscriptionError.featureNotImplemented("Test Feature")
        XCTAssertNotNil(error.failureReason, "Failure reason should not be nil")
        XCTAssertFalse(error.failureReason!.isEmpty, "Failure reason should not be empty")
    }

    func testFeatureNotImplementedRecoverySuggestionIsLocalized() {
        let error = CallTranscriptionError.featureNotImplemented("Test Feature")
        XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil")
        XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Recovery suggestion should not be empty")
    }

    // MARK: - Post Recording Script Not Found Tests

    func testPostRecordingScriptNotFoundDescriptionIsLocalized() {
        let error = CallTranscriptionError.postRecordingScriptNotFound("/path/to/script.sh")
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testPostRecordingScriptNotFoundFailureReasonIsLocalized() {
        let error = CallTranscriptionError.postRecordingScriptNotFound("/path/to/script.sh")
        XCTAssertNotNil(error.failureReason, "Failure reason should not be nil")
        XCTAssertFalse(error.failureReason!.isEmpty, "Failure reason should not be empty")
    }

    func testPostRecordingScriptNotFoundRecoverySuggestionIsLocalized() {
        let error = CallTranscriptionError.postRecordingScriptNotFound("/path/to/script.sh")
        XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil")
        XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Recovery suggestion should not be empty")
    }

    // MARK: - Post Recording Script Not Executable Tests

    func testPostRecordingScriptNotExecutableDescriptionIsLocalized() {
        let error = CallTranscriptionError.postRecordingScriptNotExecutable("/path/to/script.sh")
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testPostRecordingScriptNotExecutableFailureReasonIsLocalized() {
        let error = CallTranscriptionError.postRecordingScriptNotExecutable("/path/to/script.sh")
        XCTAssertNotNil(error.failureReason, "Failure reason should not be nil")
        XCTAssertFalse(error.failureReason!.isEmpty, "Failure reason should not be empty")
    }

    func testPostRecordingScriptNotExecutableRecoverySuggestionIsLocalized() {
        let error = CallTranscriptionError.postRecordingScriptNotExecutable("/path/to/script.sh")
        XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil")
        XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Recovery suggestion should not be empty")
    }

    // MARK: - Post Recording Script Timeout Tests

    func testPostRecordingScriptTimeoutDescriptionIsLocalized() {
        let error = CallTranscriptionError.postRecordingScriptTimeout(60.0)
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testPostRecordingScriptTimeoutFailureReasonIsLocalized() {
        let error = CallTranscriptionError.postRecordingScriptTimeout(60.0)
        XCTAssertNotNil(error.failureReason, "Failure reason should not be nil")
        XCTAssertFalse(error.failureReason!.isEmpty, "Failure reason should not be empty")
    }

    func testPostRecordingScriptTimeoutRecoverySuggestionIsLocalized() {
        let error = CallTranscriptionError.postRecordingScriptTimeout(60.0)
        XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil")
        XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Recovery suggestion should not be empty")
    }

    // MARK: - Output Folder Creation Failed Tests

    func testOutputFolderCreationFailedDescriptionIsLocalized() {
        let error = CallTranscriptionError.outputFolderCreationFailed("/path/to/folder", NSError(domain: "test", code: 1))
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testOutputFolderCreationFailedFailureReasonIsLocalized() {
        let error = CallTranscriptionError.outputFolderCreationFailed("/path/to/folder", NSError(domain: "test", code: 1))
        XCTAssertNotNil(error.failureReason, "Failure reason should not be nil")
        XCTAssertFalse(error.failureReason!.isEmpty, "Failure reason should not be empty")
    }

    func testOutputFolderCreationFailedRecoverySuggestionIsLocalized() {
        let error = CallTranscriptionError.outputFolderCreationFailed("/path/to/folder", NSError(domain: "test", code: 1))
        XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil")
        XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Recovery suggestion should not be empty")
    }

    // MARK: - Transcript Already Finalized Tests

    func testTranscriptAlreadyFinalizedDescriptionIsLocalized() {
        let error = CallTranscriptionError.transcriptAlreadyFinalized
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testTranscriptAlreadyFinalizedFailureReasonIsLocalized() {
        let error = CallTranscriptionError.transcriptAlreadyFinalized
        XCTAssertNotNil(error.failureReason, "Failure reason should not be nil")
        XCTAssertFalse(error.failureReason!.isEmpty, "Failure reason should not be empty")
    }

    func testTranscriptAlreadyFinalizedRecoverySuggestionIsLocalized() {
        let error = CallTranscriptionError.transcriptAlreadyFinalized
        XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil")
        XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Recovery suggestion should not be empty")
    }

    // MARK: - Not Recording Tests

    func testNotRecordingDescriptionIsLocalized() {
        let error = CallTranscriptionError.notRecording
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testNotRecordingFailureReasonIsLocalized() {
        let error = CallTranscriptionError.notRecording
        XCTAssertNotNil(error.failureReason, "Failure reason should not be nil")
        XCTAssertFalse(error.failureReason!.isEmpty, "Failure reason should not be empty")
    }

    func testNotRecordingRecoverySuggestionIsLocalized() {
        let error = CallTranscriptionError.notRecording
        XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil")
        XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Recovery suggestion should not be empty")
    }

    // MARK: - Not Paused Tests

    func testNotPausedDescriptionIsLocalized() {
        let error = CallTranscriptionError.notPaused
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testNotPausedFailureReasonIsLocalized() {
        let error = CallTranscriptionError.notPaused
        XCTAssertNotNil(error.failureReason, "Failure reason should not be nil")
        XCTAssertFalse(error.failureReason!.isEmpty, "Failure reason should not be empty")
    }

    func testNotPausedRecoverySuggestionIsLocalized() {
        let error = CallTranscriptionError.notPaused
        XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil")
        XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Recovery suggestion should not be empty")
    }

    // MARK: - Audio Processing Failed Tests

    func testAudioProcessingFailedDescriptionIsLocalized() {
        let error = CallTranscriptionError.audioProcessingFailed("Test reason")
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testAudioProcessingFailedFailureReasonIsLocalized() {
        let error = CallTranscriptionError.audioProcessingFailed("Test reason")
        XCTAssertNotNil(error.failureReason, "Failure reason should not be nil")
        XCTAssertFalse(error.failureReason!.isEmpty, "Failure reason should not be empty")
    }

    func testAudioProcessingFailedRecoverySuggestionIsLocalized() {
        let error = CallTranscriptionError.audioProcessingFailed("Test reason")
        XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil")
        XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Recovery suggestion should not be empty")
    }

    // MARK: - Path Traversal Detected Tests

    func testPathTraversalDetectedDescriptionIsLocalized() {
        let error = CallTranscriptionError.pathTraversalDetected("/test/../path", reason: "Contains ..")
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testPathTraversalDetectedFailureReasonIsLocalized() {
        let error = CallTranscriptionError.pathTraversalDetected("/test/../path", reason: "Contains ..")
        XCTAssertNotNil(error.failureReason, "Failure reason should not be nil")
        XCTAssertFalse(error.failureReason!.isEmpty, "Failure reason should not be empty")
    }

    func testPathTraversalDetectedRecoverySuggestionIsLocalized() {
        let error = CallTranscriptionError.pathTraversalDetected("/test/../path", reason: "Contains ..")
        XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil")
        XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Recovery suggestion should not be empty")
    }

    // MARK: - Path Outside Allowed Directories Tests

    func testPathOutsideAllowedDirectoriesDescriptionIsLocalized() {
        let error = CallTranscriptionError.pathOutsideAllowedDirectories("/test/path", allowedDirectories: ["/home", "/tmp"])
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testPathOutsideAllowedDirectoriesFailureReasonIsLocalized() {
        let error = CallTranscriptionError.pathOutsideAllowedDirectories("/test/path", allowedDirectories: ["/home", "/tmp"])
        XCTAssertNotNil(error.failureReason, "Failure reason should not be nil")
        XCTAssertFalse(error.failureReason!.isEmpty, "Failure reason should not be empty")
    }

    func testPathOutsideAllowedDirectoriesRecoverySuggestionIsLocalized() {
        let error = CallTranscriptionError.pathOutsideAllowedDirectories("/test/path", allowedDirectories: ["/home", "/tmp"])
        XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil")
        XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Recovery suggestion should not be empty")
    }

    // MARK: - Symlink Attack Detected Tests

    func testSymlinkAttackDetectedDescriptionIsLocalized() {
        let error = CallTranscriptionError.symlinkAttackDetected("/test/link", resolvedPath: "/etc/passwd")
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testSymlinkAttackDetectedFailureReasonIsLocalized() {
        let error = CallTranscriptionError.symlinkAttackDetected("/test/link", resolvedPath: "/etc/passwd")
        XCTAssertNotNil(error.failureReason, "Failure reason should not be nil")
        XCTAssertFalse(error.failureReason!.isEmpty, "Failure reason should not be empty")
    }

    func testSymlinkAttackDetectedRecoverySuggestionIsLocalized() {
        let error = CallTranscriptionError.symlinkAttackDetected("/test/link", resolvedPath: "/etc/passwd")
        XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil")
        XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Recovery suggestion should not be empty")
    }

    // MARK: - Invalid Path Tests

    func testInvalidPathDescriptionIsLocalized() {
        let error = CallTranscriptionError.invalidPath("/test/path", reason: "Invalid characters")
        XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
    }

    func testInvalidPathFailureReasonIsLocalized() {
        let error = CallTranscriptionError.invalidPath("/test/path", reason: "Invalid characters")
        XCTAssertNotNil(error.failureReason, "Failure reason should not be nil")
        XCTAssertFalse(error.failureReason!.isEmpty, "Failure reason should not be empty")
    }

    func testInvalidPathRecoverySuggestionIsLocalized() {
        let error = CallTranscriptionError.invalidPath("/test/path", reason: "Invalid characters")
        XCTAssertNotNil(error.recoverySuggestion, "Recovery suggestion should not be nil")
        XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Recovery suggestion should not be empty")
    }
}
