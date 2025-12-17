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

    // MARK: - LocalizedError Conformance

    public var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access is required."

        case .speechRecognitionUnavailable:
            return "Speech recognition is not available."

        case .localeNotSupported(let locale):
            return "Speech recognition is not available for \(locale.identifier)."

        case .outputFolderNotWritable(let url):
            return "Cannot write to \(url.path)."

        case .audioTapCreationFailed(let status):
            return "Failed to create audio tap (error \(status))."

        case .featureNotImplemented(let feature):
            return "\(feature) is not yet implemented."

        case .postRecordingScriptNotFound(let path):
            return "Post-recording script not found at \(path)."

        case .postRecordingScriptNotExecutable(let path):
            return "Post-recording script at \(path) is not executable."

        case .postRecordingScriptTimeout(let timeout):
            return "Post-recording script exceeded timeout of \(timeout) seconds."

        case .outputFolderCreationFailed(let path, _):
            return "Failed to create output folder at \(path)."
        }
    }

    public var failureReason: String? {
        switch self {
        case .microphonePermissionDenied:
            return "The app does not have permission to access the microphone."

        case .speechRecognitionUnavailable:
            return "The speech recognition service is unavailable or the language model has not been downloaded."

        case .localeNotSupported(let locale):
            return "The locale \(locale.identifier) is not supported by the speech recognition service."

        case .outputFolderNotWritable(let url):
            return "The output folder at \(url.path) is not writable due to permissions or path issues."

        case .audioTapCreationFailed(let status):
            return "Core Audio returned error code \(status) when attempting to create a system audio tap."

        case .featureNotImplemented(let feature):
            return "\(feature) functionality has not been implemented yet."

        case .postRecordingScriptNotFound(let path):
            return "The script file could not be found at the specified path: \(path)."

        case .postRecordingScriptNotExecutable(let path):
            return "The script file exists but does not have execute permissions."

        case .postRecordingScriptTimeout(let timeout):
            return "The script did not complete within \(timeout) seconds."

        case .outputFolderCreationFailed(let path, let error):
            return "Could not create directory at \(path): \(error.localizedDescription)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Enable microphone access in System Settings > Privacy & Security > Microphone."

        case .speechRecognitionUnavailable:
            return "Check your internet connection to allow the speech recognition model to download, or try again later."

        case .localeNotSupported:
            return "Try selecting a different language or locale that is supported by speech recognition."

        case .outputFolderNotWritable:
            return "Select a different folder where you have write permissions, such as your Documents or Desktop folder."

        case .audioTapCreationFailed:
            return "System audio capture is unavailable. Try restarting the app or check for system audio conflicts."

        case .featureNotImplemented:
            return "This feature will be available in a future version."

        case .postRecordingScriptNotFound(let path):
            return "Check that the script path '\(path)' is correct and the file exists."

        case .postRecordingScriptNotExecutable(let path):
            return "Make the script executable by running: chmod +x '\(path)'"

        case .postRecordingScriptTimeout:
            return "Ensure your script completes in a reasonable time, or increase the timeout setting."

        case .outputFolderCreationFailed:
            return "Check folder permissions and ensure you have access to create directories at this location."
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
        default:
            return false
        }
    }
}
