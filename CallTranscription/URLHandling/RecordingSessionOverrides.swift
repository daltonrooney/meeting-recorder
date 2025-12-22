import Foundation

/// Represents temporary session-specific overrides for recording configuration.
///
/// These overrides are applied for a single recording session without modifying
/// the user's persistent settings in SettingsManager. This is primarily used
/// by URL scheme automation (x-callback-url) to provide session-specific
/// configuration without permanently changing user preferences.
///
/// ## Design Rationale
///
/// This struct follows the configuration object pattern to enable:
/// - **Stable signatures**: Adding new override fields doesn't break call sites
/// - **Semantic clarity**: Clear distinction between session params and overrides
/// - **Encapsulation**: Validation and merging logic lives on the type
/// - **Extensibility**: Future overrides (locale, audio sources) add fields, not parameters
///
/// ## Usage
///
/// ### URL Scheme Automation
/// ```swift
/// let overrides = try RecordingSessionOverrides.urlScheme(
///     outputFolder: "/tmp/recordings",
///     filenameTemplate: "meeting_{YYYY-MM-DD}"
/// )
/// try await appState.startActualRecording(title: "Meeting", overrides: overrides)
/// ```
///
/// ### No Overrides (Use Settings)
/// ```swift
/// try await appState.startActualRecording(title: "Meeting", overrides: nil)
/// ```
@MainActor
public struct RecordingSessionOverrides: Sendable {
    /// Optional override for the output folder path.
    ///
    /// When provided, transcripts will be saved to this folder instead of
    /// the user's configured output folder. This does NOT modify the user's
    /// persistent settings - it only affects the current recording session.
    public let outputFolder: String?

    /// Optional override for the filename template.
    ///
    /// When provided, the transcript filename will use this template instead
    /// of the user's configured template. This does NOT modify the user's
    /// persistent settings - it only affects the current recording session.
    public let filenameTemplate: String?

    /// Creates recording session overrides.
    ///
    /// - Parameters:
    ///   - outputFolder: Optional path to save transcripts (must be validated)
    ///   - filenameTemplate: Optional filename template (must be validated)
    public init(
        outputFolder: String? = nil,
        filenameTemplate: String? = nil
    ) {
        self.outputFolder = outputFolder
        self.filenameTemplate = filenameTemplate
    }
}

// MARK: - URL Scheme Factory

extension RecordingSessionOverrides {
    /// Creates and validates URL scheme overrides.
    ///
    /// Validates paths and templates according to security requirements:
    /// - Output folder must be within allowed directories (home/temp)
    /// - Path traversal (`..`) is blocked
    /// - Filename template cannot contain `/` or `..`
    /// - Creates output folder with intermediate directories if missing
    ///
    /// - Parameters:
    ///   - outputFolder: Optional output folder path to validate and use
    ///   - filenameTemplate: Optional filename template to validate and use
    ///   - pathValidator: Path validator instance (injectable for testing)
    ///   - filenameTemplateProcessor: Template validator (injectable for testing)
    /// - Returns: Validated overrides ready to use
    /// - Throws: CallTranscriptionError if validation fails
    public static func urlScheme(
        outputFolder: String?,
        filenameTemplate: String?,
        pathValidator: PathValidator = PathValidator(),
        filenameTemplateProcessor: FilenameTemplateProcessor = FilenameTemplateProcessor()
    ) throws -> Self {
        // Validate output folder if provided
        if let folder = outputFolder {
            let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
            let tempDirectory = FileManager.default.temporaryDirectory
            let allowedDirectories = [homeDirectory, tempDirectory]

            // Validate path security
            _ = try pathValidator.validate(path: folder, againstBaseDirectories: allowedDirectories)

            // Check folder existence and create if needed
            let folderURL = URL(fileURLWithPath: folder)
            var isDirectory: ObjCBool = false
            if !FileManager.default.fileExists(atPath: folder, isDirectory: &isDirectory) {
                // Create directory with intermediate directories
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            } else if !isDirectory.boolValue {
                // Path exists but is not a directory
                throw CallTranscriptionError.outputFolderNotWritable(folderURL)
            }
        }

        // Validate filename template if provided
        if let template = filenameTemplate {
            guard filenameTemplateProcessor.validate(template) else {
                throw CallTranscriptionError.invalidFilenameTemplate(template)
            }
        }

        return Self(outputFolder: outputFolder, filenameTemplate: filenameTemplate)
    }
}
