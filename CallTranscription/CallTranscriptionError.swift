import Foundation
import AVFoundation

/// Errors that can occur during CallTranscription operations.
///
/// All errors provide user-friendly descriptions through LocalizedError conformance,
/// with actionable guidance on how to resolve the issue.
public enum CallTranscriptionError: LocalizedError {
    /// Microphone permission was denied by the user.
    case microphonePermissionDenied

    /// Speech recognition is not available (model not downloaded or service unavailable).
    case speechRecognitionUnavailable

    /// The specified locale is not supported for speech recognition.
    case localeNotSupported(Locale)

    /// The output folder is not writable (permissions or path issue).
    case outputFolderNotWritable(URL)

    /// Failed to create Core Audio tap for system audio capture.
    case audioTapCreationFailed(OSStatus)

    /// Requested feature is not yet implemented.
    case featureNotImplemented(String)

    /// Post-recording script was not found at the specified path.
    case postRecordingScriptNotFound(String)

    /// Post-recording script exists but is not executable.
    case postRecordingScriptNotExecutable(String)

    /// Post-recording script exceeded timeout.
    case postRecordingScriptTimeout(TimeInterval)

    /// Failed to create output directory.
    case outputFolderCreationFailed(String, Error)

    /// Attempted to write to a transcript that has already been finalized.
    case transcriptAlreadyFinalized

    /// Attempted to write to an audio file that has already been finalized.
    case audioFileAlreadyFinalized

    /// Attempted to stop recording when not currently recording.
    case notRecording

    /// Attempted to resume recording when not paused.
    case notPaused

    /// Audio processing failed during transcription.
    case audioProcessingFailed(String)

    /// Path traversal attack detected in file path.
    case pathTraversalDetected(String, reason: String)

    /// Path is outside allowed directories.
    case pathOutsideAllowedDirectories(String, allowedDirectories: [String])

    /// Symlink attack detected - symlink points outside allowed directories.
    case symlinkAttackDetected(String, resolvedPath: String)

    /// Invalid path provided.
    case invalidPath(String, reason: String)

    /// Failed to create security-scoped bookmark.
    case bookmarkCreationFailed(String, reason: String)

    /// Failed to resolve security-scoped bookmark.
    case bookmarkResolutionFailed(reason: String)

    /// Failed to access security-scoped resource.
    case securityScopedAccessFailed(String)

    // MARK: - LocalizedError Conformance

    public var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return NSLocalizedString("error.microphonePermissionDenied.description", comment: "Microphone permission denied error description")

        case .speechRecognitionUnavailable:
            return NSLocalizedString("error.speechRecognitionUnavailable.description", comment: "Speech recognition unavailable error description")

        case .localeNotSupported(let locale):
            return String(format: NSLocalizedString("error.localeNotSupported.description", comment: "Locale not supported error description"), locale.identifier)

        case .outputFolderNotWritable(let url):
            return String(format: NSLocalizedString("error.outputFolderNotWritable.description", comment: "Output folder not writable error description"), url.path)

        case .audioTapCreationFailed(let status):
            return String(format: NSLocalizedString("error.audioTapCreationFailed.description", comment: "Audio tap creation failed error description"), status)

        case .featureNotImplemented(let feature):
            return String(format: NSLocalizedString("error.featureNotImplemented.description", comment: "Feature not implemented error description"), feature)

        case .postRecordingScriptNotFound(let path):
            return String(format: NSLocalizedString("error.postRecordingScriptNotFound.description", comment: "Post-recording script not found error description"), path)

        case .postRecordingScriptNotExecutable(let path):
            return String(format: NSLocalizedString("error.postRecordingScriptNotExecutable.description", comment: "Post-recording script not executable error description"), path)

        case .postRecordingScriptTimeout(let timeout):
            return String(format: NSLocalizedString("error.postRecordingScriptTimeout.description", comment: "Post-recording script timeout error description"), timeout)

        case .outputFolderCreationFailed(let path, _):
            return String(format: NSLocalizedString("error.outputFolderCreationFailed.description", comment: "Output folder creation failed error description"), path)

        case .transcriptAlreadyFinalized:
            return NSLocalizedString("error.transcriptAlreadyFinalized.description", comment: "Transcript already finalized error description")

        case .audioFileAlreadyFinalized:
            return NSLocalizedString("error.audioFileAlreadyFinalized.description", comment: "Audio file already finalized error description")

        case .notRecording:
            return NSLocalizedString("error.notRecording.description", comment: "Not recording error description")

        case .notPaused:
            return NSLocalizedString("error.notPaused.description", comment: "Not paused error description")

        case .audioProcessingFailed(let reason):
            return String(format: NSLocalizedString("error.audioProcessingFailed.description", comment: "Audio processing failed error description"), reason)

        case .pathTraversalDetected(let path, let reason):
            return String(format: NSLocalizedString("error.pathTraversalDetected.description", comment: "Path traversal attack detected error description"), path, reason)

        case .pathOutsideAllowedDirectories(let path, let allowedDirs):
            let dirList = allowedDirs.joined(separator: ", ")
            return String(format: NSLocalizedString("error.pathOutsideAllowedDirectories.description", comment: "Path outside allowed directories error description"), path, dirList)

        case .symlinkAttackDetected(let path, let resolvedPath):
            return String(format: NSLocalizedString("error.symlinkAttackDetected.description", comment: "Symlink attack detected error description"), path, resolvedPath)

        case .invalidPath(let path, let reason):
            return String(format: NSLocalizedString("error.invalidPath.description", comment: "Invalid path error description"), path, reason)

        case .bookmarkCreationFailed(let path, let reason):
            return String(format: NSLocalizedString("error.bookmarkCreationFailed.description", comment: "Bookmark creation failed error description"), path, reason)

        case .bookmarkResolutionFailed(let reason):
            return String(format: NSLocalizedString("error.bookmarkResolutionFailed.description", comment: "Bookmark resolution failed error description"), reason)

        case .securityScopedAccessFailed(let path):
            return String(format: NSLocalizedString("error.securityScopedAccessFailed.description", comment: "Security-scoped access failed error description"), path)
        }
    }

    public var failureReason: String? {
        switch self {
        case .microphonePermissionDenied:
            return NSLocalizedString("error.microphonePermissionDenied.failureReason", comment: "Microphone permission denied failure reason")

        case .speechRecognitionUnavailable:
            return NSLocalizedString("error.speechRecognitionUnavailable.failureReason", comment: "Speech recognition unavailable failure reason")

        case .localeNotSupported(let locale):
            return String(format: NSLocalizedString("error.localeNotSupported.failureReason", comment: "Locale not supported failure reason"), locale.identifier)

        case .outputFolderNotWritable(let url):
            return String(format: NSLocalizedString("error.outputFolderNotWritable.failureReason", comment: "Output folder not writable failure reason"), url.path)

        case .audioTapCreationFailed(let status):
            return String(format: NSLocalizedString("error.audioTapCreationFailed.failureReason", comment: "Audio tap creation failed failure reason"), status)

        case .featureNotImplemented(let feature):
            return String(format: NSLocalizedString("error.featureNotImplemented.failureReason", comment: "Feature not implemented failure reason"), feature)

        case .postRecordingScriptNotFound(let path):
            return String(format: NSLocalizedString("error.postRecordingScriptNotFound.failureReason", comment: "Post-recording script not found failure reason"), path)

        case .postRecordingScriptNotExecutable(let path):
            return NSLocalizedString("error.postRecordingScriptNotExecutable.failureReason", comment: "Post-recording script not executable failure reason")

        case .postRecordingScriptTimeout(let timeout):
            return String(format: NSLocalizedString("error.postRecordingScriptTimeout.failureReason", comment: "Post-recording script timeout failure reason"), timeout)

        case .outputFolderCreationFailed(let path, let error):
            return String(format: NSLocalizedString("error.outputFolderCreationFailed.failureReason", comment: "Output folder creation failed failure reason"), path, error.localizedDescription)

        case .transcriptAlreadyFinalized:
            return NSLocalizedString("error.transcriptAlreadyFinalized.failureReason", comment: "Transcript already finalized failure reason")

        case .audioFileAlreadyFinalized:
            return NSLocalizedString("error.audioFileAlreadyFinalized.failureReason", comment: "Audio file already finalized failure reason")

        case .notRecording:
            return NSLocalizedString("error.notRecording.failureReason", comment: "Not recording failure reason")

        case .notPaused:
            return NSLocalizedString("error.notPaused.failureReason", comment: "Not paused failure reason")

        case .audioProcessingFailed(let reason):
            return String(format: NSLocalizedString("error.audioProcessingFailed.failureReason", comment: "Audio processing failed failure reason"), reason)

        case .pathTraversalDetected(let path, let reason):
            return String(format: NSLocalizedString("error.pathTraversalDetected.failureReason", comment: "Path traversal attack detected failure reason"), path, reason)

        case .pathOutsideAllowedDirectories(let path, _):
            return String(format: NSLocalizedString("error.pathOutsideAllowedDirectories.failureReason", comment: "Path outside allowed directories failure reason"), path)

        case .symlinkAttackDetected(let path, let resolvedPath):
            return String(format: NSLocalizedString("error.symlinkAttackDetected.failureReason", comment: "Symlink attack detected failure reason"), path, resolvedPath)

        case .invalidPath(let path, let reason):
            return String(format: NSLocalizedString("error.invalidPath.failureReason", comment: "Invalid path failure reason"), path, reason)

        case .bookmarkCreationFailed(let path, let reason):
            return String(format: NSLocalizedString("error.bookmarkCreationFailed.failureReason", comment: "Bookmark creation failed failure reason"), path, reason)

        case .bookmarkResolutionFailed(let reason):
            return String(format: NSLocalizedString("error.bookmarkResolutionFailed.failureReason", comment: "Bookmark resolution failed failure reason"), reason)

        case .securityScopedAccessFailed(let path):
            return String(format: NSLocalizedString("error.securityScopedAccessFailed.failureReason", comment: "Security-scoped access failed failure reason"), path)
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .microphonePermissionDenied:
            return NSLocalizedString("error.microphonePermissionDenied.recoverySuggestion", comment: "Microphone permission denied recovery suggestion")

        case .speechRecognitionUnavailable:
            return NSLocalizedString("error.speechRecognitionUnavailable.recoverySuggestion", comment: "Speech recognition unavailable recovery suggestion")

        case .localeNotSupported:
            return NSLocalizedString("error.localeNotSupported.recoverySuggestion", comment: "Locale not supported recovery suggestion")

        case .outputFolderNotWritable:
            return NSLocalizedString("error.outputFolderNotWritable.recoverySuggestion", comment: "Output folder not writable recovery suggestion")

        case .audioTapCreationFailed:
            return NSLocalizedString("error.audioTapCreationFailed.recoverySuggestion", comment: "Audio tap creation failed recovery suggestion")

        case .featureNotImplemented:
            return NSLocalizedString("error.featureNotImplemented.recoverySuggestion", comment: "Feature not implemented recovery suggestion")

        case .postRecordingScriptNotFound(let path):
            return String(format: NSLocalizedString("error.postRecordingScriptNotFound.recoverySuggestion", comment: "Post-recording script not found recovery suggestion"), path)

        case .postRecordingScriptNotExecutable(let path):
            return String(format: NSLocalizedString("error.postRecordingScriptNotExecutable.recoverySuggestion", comment: "Post-recording script not executable recovery suggestion"), path)

        case .postRecordingScriptTimeout:
            return NSLocalizedString("error.postRecordingScriptTimeout.recoverySuggestion", comment: "Post-recording script timeout recovery suggestion")

        case .outputFolderCreationFailed:
            return NSLocalizedString("error.outputFolderCreationFailed.recoverySuggestion", comment: "Output folder creation failed recovery suggestion")

        case .transcriptAlreadyFinalized:
            return NSLocalizedString("error.transcriptAlreadyFinalized.recoverySuggestion", comment: "Transcript already finalized recovery suggestion")

        case .audioFileAlreadyFinalized:
            return NSLocalizedString("error.audioFileAlreadyFinalized.recoverySuggestion", comment: "Audio file already finalized recovery suggestion")

        case .notRecording:
            return NSLocalizedString("error.notRecording.recoverySuggestion", comment: "Not recording recovery suggestion")

        case .notPaused:
            return NSLocalizedString("error.notPaused.recoverySuggestion", comment: "Not paused recovery suggestion")

        case .audioProcessingFailed:
            return NSLocalizedString("error.audioProcessingFailed.recoverySuggestion", comment: "Audio processing failed recovery suggestion")

        case .pathTraversalDetected:
            return NSLocalizedString("error.pathTraversalDetected.recoverySuggestion", comment: "Path traversal attack detected recovery suggestion")

        case .pathOutsideAllowedDirectories(_, let allowedDirs):
            let dirList = allowedDirs.joined(separator: "\n  - ")
            return String(format: NSLocalizedString("error.pathOutsideAllowedDirectories.recoverySuggestion", comment: "Path outside allowed directories recovery suggestion"), dirList)

        case .symlinkAttackDetected:
            return NSLocalizedString("error.symlinkAttackDetected.recoverySuggestion", comment: "Symlink attack detected recovery suggestion")

        case .invalidPath:
            return NSLocalizedString("error.invalidPath.recoverySuggestion", comment: "Invalid path recovery suggestion")

        case .bookmarkCreationFailed:
            return NSLocalizedString("error.bookmarkCreationFailed.recoverySuggestion", comment: "Bookmark creation failed recovery suggestion")

        case .bookmarkResolutionFailed:
            return NSLocalizedString("error.bookmarkResolutionFailed.recoverySuggestion", comment: "Bookmark resolution failed recovery suggestion")

        case .securityScopedAccessFailed:
            return NSLocalizedString("error.securityScopedAccessFailed.recoverySuggestion", comment: "Security-scoped access failed recovery suggestion")
        }
    }
}

// MARK: - Equatable Conformance

extension CallTranscriptionError: Equatable {
    public static func == (lhs: CallTranscriptionError, rhs: CallTranscriptionError) -> Bool {
        switch (lhs, rhs) {
        case (.microphonePermissionDenied, .microphonePermissionDenied):
            return true
        case (.speechRecognitionUnavailable, .speechRecognitionUnavailable):
            return true
        case (.localeNotSupported(let lhsLocale), .localeNotSupported(let rhsLocale)):
            return lhsLocale == rhsLocale
        case (.outputFolderNotWritable(let lhsURL), .outputFolderNotWritable(let rhsURL)):
            return lhsURL == rhsURL
        case (.audioTapCreationFailed(let lhsStatus), .audioTapCreationFailed(let rhsStatus)):
            return lhsStatus == rhsStatus
        case (.featureNotImplemented(let lhsFeature), .featureNotImplemented(let rhsFeature)):
            return lhsFeature == rhsFeature
        case (.postRecordingScriptNotFound(let lhsPath), .postRecordingScriptNotFound(let rhsPath)):
            return lhsPath == rhsPath
        case (.postRecordingScriptNotExecutable(let lhsPath), .postRecordingScriptNotExecutable(let rhsPath)):
            return lhsPath == rhsPath
        case (.postRecordingScriptTimeout(let lhsTimeout), .postRecordingScriptTimeout(let rhsTimeout)):
            return lhsTimeout == rhsTimeout
        case (.outputFolderCreationFailed(let lhsPath, _), .outputFolderCreationFailed(let rhsPath, _)):
            return lhsPath == rhsPath
        case (.transcriptAlreadyFinalized, .transcriptAlreadyFinalized):
            return true
        case (.notRecording, .notRecording):
            return true
        case (.notPaused, .notPaused):
            return true
        case (.audioProcessingFailed(let lhsReason), .audioProcessingFailed(let rhsReason)):
            return lhsReason == rhsReason
        case (.pathTraversalDetected(let lhsPath, let lhsReason), .pathTraversalDetected(let rhsPath, let rhsReason)):
            return lhsPath == rhsPath && lhsReason == rhsReason
        case (.pathOutsideAllowedDirectories(let lhsPath, let lhsDirs), .pathOutsideAllowedDirectories(let rhsPath, let rhsDirs)):
            return lhsPath == rhsPath && lhsDirs == rhsDirs
        case (.symlinkAttackDetected(let lhsPath, let lhsResolved), .symlinkAttackDetected(let rhsPath, let rhsResolved)):
            return lhsPath == rhsPath && lhsResolved == rhsResolved
        case (.invalidPath(let lhsPath, let lhsReason), .invalidPath(let rhsPath, let rhsReason)):
            return lhsPath == rhsPath && lhsReason == rhsReason
        default:
            return false
        }
    }
}
