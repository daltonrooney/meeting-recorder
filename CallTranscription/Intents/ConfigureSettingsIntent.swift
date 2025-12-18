import AppIntents
import Foundation

/// Helper function to validate and expand folder paths for security
private func validateFolderPath(_ path: String) throws -> String {
    // Expand tilde and standardize path
    let expandedPath = (path as NSString).expandingTildeInPath
    let standardizedPath = (expandedPath as NSString).standardizingPath

    // Prevent path traversal and system directory access
    let dangerousPaths = ["/System", "/Library", "/bin", "/sbin", "/usr", "/etc", "/var", "/private"]
    for dangerousPath in dangerousPaths {
        if standardizedPath.hasPrefix(dangerousPath) {
            throw IntentError.configurationFailed("Cannot use system directories: \(standardizedPath)")
        }
    }

    // Check if path contains path traversal sequences
    if standardizedPath.contains("..") {
        throw IntentError.configurationFailed("Path contains invalid traversal sequences")
    }

    let fileManager = FileManager.default
    var isDirectory: ObjCBool = false

    // Check if path exists
    if fileManager.fileExists(atPath: standardizedPath, isDirectory: &isDirectory) {
        // Ensure it's a directory
        guard isDirectory.boolValue else {
            throw IntentError.configurationFailed("Path exists but is not a directory: \(standardizedPath)")
        }

        // Check if writable
        guard fileManager.isWritableFile(atPath: standardizedPath) else {
            throw IntentError.configurationFailed("Directory is not writable: \(standardizedPath)")
        }
    } else {
        // Path doesn't exist - try to create it
        do {
            try fileManager.createDirectory(atPath: standardizedPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            throw IntentError.configurationFailed("Cannot create directory: \(standardizedPath) - \(error.localizedDescription)")
        }
    }

    return standardizedPath
}

/// Helper function to validate script paths
private func validateScriptPath(_ path: String) throws -> String {
    // Expand tilde and standardize path
    let expandedPath = (path as NSString).expandingTildeInPath
    let standardizedPath = (expandedPath as NSString).standardizingPath

    let fileManager = FileManager.default

    // Check if file exists
    guard fileManager.fileExists(atPath: standardizedPath) else {
        throw IntentError.configurationFailed("Script file does not exist: \(standardizedPath)")
    }

    // Check if it's a regular file (not a directory)
    var isDirectory: ObjCBool = false
    fileManager.fileExists(atPath: standardizedPath, isDirectory: &isDirectory)
    guard !isDirectory.boolValue else {
        throw IntentError.configurationFailed("Script path is a directory, not a file: \(standardizedPath)")
    }

    // Check if executable
    guard fileManager.isExecutableFile(atPath: standardizedPath) else {
        throw IntentError.configurationFailed("Script file is not executable: \(standardizedPath)")
    }

    return standardizedPath
}

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
            // Validate and expand the path, checking for security issues
            let validatedPath = try validateFolderPath(outputFolder)
            settingsManager.outputFolder = validatedPath
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
            // Validate that the script exists and is executable
            let validatedScriptPath = try validateScriptPath(postRecordingScript)
            settingsManager.postRecordingScript = validatedScriptPath
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
