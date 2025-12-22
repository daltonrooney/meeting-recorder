import Foundation

/// Protocol for types that can handle recording actions
@MainActor
protocol RecordingActionHandler {
    var isRecording: Bool { get }
    var isPaused: Bool { get }
    func startActualRecording(title: String) async throws
    func stopActualRecording() async throws -> URL
    func pauseRecording() async throws
    func resumeRecording() async throws
}

/// AppState conforms to RecordingActionHandler
@MainActor
extension AppState: RecordingActionHandler {
    // AppState already has all required properties and methods
}

/// Dispatches URL scheme actions to the appropriate AppState methods
@MainActor
final class URLSchemeActionDispatcher {
    private let appState: any RecordingActionHandler
    private let settingsManager: SettingsManager
    private let pathValidator: PathValidator
    private let filenameTemplateProcessor: FilenameTemplateProcessor

    init(
        appState: any RecordingActionHandler,
        settingsManager: SettingsManager,
        pathValidator: PathValidator = PathValidator(),
        filenameTemplateProcessor: FilenameTemplateProcessor = FilenameTemplateProcessor()
    ) {
        self.appState = appState
        self.settingsManager = settingsManager
        self.pathValidator = pathValidator
        self.filenameTemplateProcessor = filenameTemplateProcessor
    }

    /// Dispatch a URL scheme request to the appropriate action
    /// - Parameter request: The parsed URL scheme request
    /// - Returns: The result of the action (may include transcript URL for stop action)
    /// - Throws: CallTranscriptionError if the action fails
    func dispatch(_ request: URLSchemeRequest) async throws -> URLSchemeActionResult {
        switch request.action {
        case .start:
            try await handleStart(request)
        case .stop:
            return try await handleStop(request)
        case .pause:
            try await handlePause(request)
        case .resume:
            try await handleResume(request)
        }

        return URLSchemeActionResult(transcriptURL: nil)
    }

    // MARK: - Action Handlers

    private func handleStart(_ request: URLSchemeRequest) async throws {
        // Check if already recording
        if appState.isRecording {
            throw CallTranscriptionError.alreadyRecording
        }

        // Validate and apply output folder if provided
        if let outputFolder = request.outputFolder {
            try validateAndSetOutputFolder(outputFolder)
        }

        // Validate and apply filename template if provided
        if let filenameTemplate = request.filenameTemplate {
            try validateAndSetFilenameTemplate(filenameTemplate)
        }

        // Start recording with optional title
        let recordingTitle = request.title ?? NSLocalizedString("url.recording.defaultTitle", comment: "Default recording title from URL scheme")
        try await appState.startActualRecording(title: recordingTitle)
    }

    private func handleStop(_ request: URLSchemeRequest) async throws -> URLSchemeActionResult {
        // Check if currently recording
        if !appState.isRecording {
            throw CallTranscriptionError.notRecording
        }

        // Stop recording and get transcript URL
        let transcriptURL = try await appState.stopActualRecording()

        return URLSchemeActionResult(transcriptURL: transcriptURL)
    }

    private func handlePause(_ request: URLSchemeRequest) async throws {
        // Check if currently recording
        if !appState.isRecording {
            throw CallTranscriptionError.notRecording
        }

        // Check if already paused
        if appState.isPaused {
            throw CallTranscriptionError.alreadyPaused
        }

        // Pause recording
        try await appState.pauseRecording()
    }

    private func handleResume(_ request: URLSchemeRequest) async throws {
        // Check if currently recording
        if !appState.isRecording {
            throw CallTranscriptionError.notRecording
        }

        // Check if currently paused
        if !appState.isPaused {
            throw CallTranscriptionError.notPaused
        }

        // Resume recording
        try await appState.resumeRecording()
    }

    // MARK: - Validation Helpers

    /// Validates and permanently sets the output folder in user settings.
    ///
    /// - Warning: This permanently modifies the user's default output folder setting.
    ///   Subsequent manual recordings will use this automation-provided folder until
    ///   the user manually changes it in settings.
    ///
    /// - Parameter folder: The folder path to validate and set
    /// - Throws: CallTranscriptionError if path validation fails or folder doesn't exist
    private func validateAndSetOutputFolder(_ folder: String) throws {
        // Get allowed base directories
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

        // IMPORTANT: This permanently modifies user settings
        settingsManager.outputFolder = folder
    }

    /// Validates and permanently sets the filename template in user settings.
    ///
    /// - Warning: This permanently modifies the user's default filename template setting.
    ///   Subsequent manual recordings will use this automation-provided template until
    ///   the user manually changes it in settings.
    ///
    /// - Parameter template: The template string to validate and set
    /// - Throws: CallTranscriptionError.invalidFilenameTemplate if validation fails
    private func validateAndSetFilenameTemplate(_ template: String) throws {
        // Validate template (reject paths with / or ../)
        guard filenameTemplateProcessor.validate(template) else {
            throw CallTranscriptionError.invalidFilenameTemplate(template)
        }

        // IMPORTANT: This permanently modifies user settings
        settingsManager.filenameTemplate = template
    }
}
