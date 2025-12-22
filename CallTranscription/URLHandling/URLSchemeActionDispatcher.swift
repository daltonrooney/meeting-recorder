import Foundation

/// Protocol for types that can handle recording actions
@MainActor
protocol RecordingActionHandler {
    var isRecording: Bool { get }
    var isPaused: Bool { get }
    func startActualRecording(title: String, overrides: RecordingSessionOverrides?) async throws
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
    private let pathValidator: PathValidator
    private let filenameTemplateProcessor: FilenameTemplateProcessor

    init(
        appState: any RecordingActionHandler,
        pathValidator: PathValidator = PathValidator(),
        filenameTemplateProcessor: FilenameTemplateProcessor = FilenameTemplateProcessor()
    ) {
        self.appState = appState
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

        // Create session overrides if output folder or filename template provided
        let overrides: RecordingSessionOverrides?
        if request.outputFolder != nil || request.filenameTemplate != nil {
            // Validate and create overrides (does NOT modify persistent settings)
            overrides = try RecordingSessionOverrides.urlScheme(
                outputFolder: request.outputFolder,
                filenameTemplate: request.filenameTemplate,
                pathValidator: pathValidator,
                filenameTemplateProcessor: filenameTemplateProcessor
            )
        } else {
            overrides = nil
        }

        // Start recording with optional title and session overrides
        let recordingTitle = request.title ?? NSLocalizedString("url.recording.defaultTitle", comment: "Default recording title from URL scheme")
        try await appState.startActualRecording(title: recordingTitle, overrides: overrides)
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

}
