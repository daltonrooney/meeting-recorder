import Foundation
import AVFoundation

/// Errors that can occur during CallTranscription operations.
///
/// All errors provide user-friendly descriptions through LocalizedError conformance,
/// with actionable guidance on how to resolve the issue.
public enum CallTranscriptionError: LocalizedError, Equatable {
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
        }
    }
}
