import AppIntents
import Foundation

/// App Intent for starting a recording session.
///
/// This intent allows users to start recording through Shortcuts or Siri.
/// It integrates with the app's AppState to initiate recording with optional title customization.
@available(macOS 13.0, *)
struct StartRecordingIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Start Recording"
    nonisolated(unsafe) static var description: IntentDescription? = IntentDescription("Starts a new recording session in Olive")

    @Parameter(title: "Recording Title", description: "Optional title for the recording")
    var title: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Start recording \(\.$title)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // Get the shared AppState instance
        let appState = try AppStateContainer.shared.requireAppState()
        let recordingTitle = title ?? NSLocalizedString("intent.recording.defaultTitle", comment: "Default recording title")

        do {
            // Use startActualRecording for real recording
            // For permission issues or hardware failures, this will throw
            try await appState.startActualRecording(title: recordingTitle)
            return .result()
        } catch {
            // Convert CallTranscriptionError to IntentError for better Shortcuts feedback
            if let transcriptionError = error as? CallTranscriptionError {
                throw IntentError.recordingFailed(transcriptionError.localizedDescription)
            }
            throw error
        }
    }
}

/// Errors that can occur during intent execution
enum IntentError: Error, LocalizedError {
    case appNotAvailable
    case recordingFailed(String)
    case notRecording
    case configurationFailed(String)

    var errorDescription: String? {
        switch self {
        case .appNotAvailable:
            return NSLocalizedString("intent.error.appNotAvailable", comment: "App not available error description")
        case .recordingFailed(let reason):
            return String(format: NSLocalizedString("intent.error.recordingFailed", comment: "Recording failed error description"), reason)
        case .notRecording:
            return NSLocalizedString("intent.error.notRecording", comment: "Not recording error description")
        case .configurationFailed(let reason):
            return String(format: NSLocalizedString("intent.error.configurationFailed", comment: "Configuration failed error description"), reason)
        }
    }
}
