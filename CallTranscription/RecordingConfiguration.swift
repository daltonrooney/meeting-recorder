import Foundation

/// Configuration for a recording session.
///
/// Specifies all settings needed to start a recording:
/// - Output folder for transcript files
/// - Locale for speech recognition
/// - Which audio sources are enabled
/// - Post-recording action configuration
public struct RecordingConfiguration {
    /// Path to output folder for transcript files
    public let outputFolder: String

    /// Locale for speech recognition (e.g., en-US, es-ES)
    public let locale: Locale

    /// Whether to capture microphone audio
    public let microphoneEnabled: Bool

    /// Whether to capture system audio
    public let systemAudioEnabled: Bool

    /// Type of action to perform after recording completes
    public let postRecordingActionType: PostRecordingActionType

    /// Optional path to script to execute after recording completes (when actionType is .script)
    public let postRecordingScriptPath: String?

    /// Optional shortcut identifier to execute after recording completes (when actionType is .shortcut)
    public let shortcutIdentifier: String?

    /// Silence detection threshold for automatic pause
    public let silencePauseThreshold: SilencePauseThreshold

    /// Filename template for transcript files (with {date} and {time} tokens)
    public let filenameTemplate: String

    /// Creates a new recording configuration.
    ///
    /// - Parameters:
    ///   - outputFolder: Path to output folder for transcript files
    ///   - locale: Locale for speech recognition
    ///   - microphoneEnabled: Whether to capture microphone audio (default: true)
    ///   - systemAudioEnabled: Whether to capture system audio (default: false)
    ///   - postRecordingActionType: Type of post-recording action (default: .doNothing)
    ///   - postRecordingScriptPath: Optional path to post-recording script (default: nil)
    ///   - shortcutIdentifier: Optional shortcut identifier (default: nil)
    ///   - silencePauseThreshold: Silence detection threshold (default: .never)
    ///   - filenameTemplate: Filename template for transcript files (default: "transcript_{date}_{time}.txt")
    public init(
        outputFolder: String,
        locale: Locale,
        microphoneEnabled: Bool = true,
        systemAudioEnabled: Bool = false,
        postRecordingActionType: PostRecordingActionType = .doNothing,
        postRecordingScriptPath: String? = nil,
        shortcutIdentifier: String? = nil,
        silencePauseThreshold: SilencePauseThreshold = .never,
        filenameTemplate: String = "transcript_{date}_{time}.txt"
    ) {
        self.outputFolder = outputFolder
        self.locale = locale
        self.microphoneEnabled = microphoneEnabled
        self.systemAudioEnabled = systemAudioEnabled
        self.postRecordingActionType = postRecordingActionType
        self.postRecordingScriptPath = postRecordingScriptPath
        self.shortcutIdentifier = shortcutIdentifier
        self.silencePauseThreshold = silencePauseThreshold
        self.filenameTemplate = filenameTemplate
    }
}
