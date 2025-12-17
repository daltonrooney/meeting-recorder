import Foundation

/// Configuration for a recording session.
///
/// Specifies all settings needed to start a recording:
/// - Output folder for transcript files
/// - Locale for speech recognition
/// - Which audio sources are enabled
/// - Optional post-recording script path
public struct RecordingConfiguration {
    /// Path to output folder for transcript files
    public let outputFolder: String

    /// Locale for speech recognition (e.g., en-US, es-ES)
    public let locale: Locale

    /// Whether to capture microphone audio
    public let microphoneEnabled: Bool

    /// Whether to capture system audio
    public let systemAudioEnabled: Bool

    /// Optional path to script to execute after recording completes
    public let postRecordingScriptPath: String?

    /// Creates a new recording configuration.
    ///
    /// - Parameters:
    ///   - outputFolder: Path to output folder for transcript files
    ///   - locale: Locale for speech recognition
    ///   - microphoneEnabled: Whether to capture microphone audio (default: true)
    ///   - systemAudioEnabled: Whether to capture system audio (default: false)
    ///   - postRecordingScriptPath: Optional path to post-recording script (default: nil)
    public init(
        outputFolder: String,
        locale: Locale,
        microphoneEnabled: Bool = true,
        systemAudioEnabled: Bool = false,
        postRecordingScriptPath: String? = nil
    ) {
        self.outputFolder = outputFolder
        self.locale = locale
        self.microphoneEnabled = microphoneEnabled
        self.systemAudioEnabled = systemAudioEnabled
        self.postRecordingScriptPath = postRecordingScriptPath
    }
}
