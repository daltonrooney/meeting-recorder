import AppIntents
import Foundation

/// App Intent for configuring app settings programmatically.
///
/// This intent allows users to modify app settings through Shortcuts,
/// including output folder, audio sources, and post-recording actions.
@available(macOS 13.0, *)
struct ConfigureSettingsIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Configure Settings"
    nonisolated(unsafe) static var description: IntentDescription? = IntentDescription("Configure Olive settings including output folder and audio capture options")

    @Parameter(title: "Output Folder", description: "Path to save transcripts (e.g., ~/Documents/Transcripts)")
    var outputFolder: String?

    @Parameter(title: "Capture Microphone", description: "Enable or disable microphone capture")
    var captureMicrophone: Bool?

    @Parameter(title: "Capture System Audio", description: "Enable or disable system audio capture")
    var captureSystemAudio: Bool?

    @Parameter(title: "Post-Recording Action", description: "Action to perform after recording completes")
    var postRecordingActionType: PostRecordingActionTypeParameter?

    @Parameter(title: "Shortcut Identifier", description: "Identifier of shortcut to run after recording")
    var shortcutIdentifier: String?

    @Parameter(title: "Post-Recording Script", description: "Path to script to run after recording")
    var postRecordingScript: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Configure Olive settings")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // Get the shared SettingsManager instance
        let settingsManager = try AppStateContainer.shared.requireSettingsManager()

        // Update only the provided settings (nil values are ignored)
        if let outputFolder = outputFolder, !outputFolder.isEmpty {
            // Basic validation: ensure path doesn't contain obvious path traversal
            if outputFolder.contains("..") {
                throw IntentError.configurationFailed("Output folder path contains invalid sequences")
            }
            settingsManager.outputFolder = outputFolder
        }

        if let captureMicrophone = captureMicrophone {
            settingsManager.captureMicrophone = captureMicrophone
        }

        if let captureSystemAudio = captureSystemAudio {
            settingsManager.captureSystemAudio = captureSystemAudio
        }

        if let postRecordingActionType = postRecordingActionType {
            settingsManager.postRecordingActionType = postRecordingActionType.toPostRecordingActionType()
        }

        if let shortcutIdentifier = shortcutIdentifier, !shortcutIdentifier.isEmpty {
            settingsManager.shortcutIdentifier = shortcutIdentifier
        }

        if let postRecordingScript = postRecordingScript, !postRecordingScript.isEmpty {
            settingsManager.postRecordingScript = postRecordingScript
        }

        return .result()
    }
}

/// App Intent parameter enum for PostRecordingActionType
@available(macOS 13.0, *)
enum PostRecordingActionTypeParameter: String, AppEnum {
    case doNothing
    case script
    case shortcut

    nonisolated(unsafe) static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Post-Recording Action")

    nonisolated(unsafe) static var caseDisplayRepresentations: [PostRecordingActionTypeParameter: DisplayRepresentation] = [
        .doNothing: "Do Nothing",
        .script: "Run Script",
        .shortcut: "Run Shortcut"
    ]

    func toPostRecordingActionType() -> PostRecordingActionType {
        switch self {
        case .doNothing:
            return .doNothing
        case .script:
            return .script
        case .shortcut:
            return .shortcut
        }
    }
}
