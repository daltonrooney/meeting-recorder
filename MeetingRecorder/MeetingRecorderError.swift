import Foundation
import AVFoundation

/// Errors that can occur during MeetingRecorder operations.
///
/// All errors provide user-friendly descriptions through LocalizedError conformance,
/// with actionable guidance on how to resolve the issue.
enum MeetingRecorderError: LocalizedError {
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

    // MARK: - LocalizedError Conformance

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access is required. Please enable in System Settings > Privacy & Security > Microphone."

        case .speechRecognitionUnavailable:
            return "Speech recognition is not available. Please check your internet connection for model download."

        case .localeNotSupported(let locale):
            return "Speech recognition is not available for \(locale.identifier)."

        case .outputFolderNotWritable(let url):
            return "Cannot write to \(url.path). Please select a different folder."

        case .audioTapCreationFailed(let status):
            return "Failed to create audio tap (error \(status)). System audio capture unavailable."
        }
    }
}
