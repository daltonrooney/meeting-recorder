import AppIntents
import Foundation

/// App Intent for stopping the current recording session.
///
/// This intent allows users to stop recording through Shortcuts or Siri.
/// It returns the file path of the saved transcript for further processing.
@available(macOS 13.0, *)
struct StopRecordingIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Stop Recording"
    nonisolated(unsafe) static var description: IntentDescription? = IntentDescription("Stops the current recording session and returns the transcript file path")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // Get the shared AppState instance
        let appState = try AppStateContainer.shared.requireAppState()

        do {
            // Stop recording and get the transcript URL
            let transcriptURL = try await appState.stopActualRecording()

            // Return the file path as a string for use in Shortcuts
            return .result(value: transcriptURL.path)
        } catch {
            // Convert CallTranscriptionError to IntentError for better Shortcuts feedback
            if let transcriptionError = error as? CallTranscriptionError {
                if transcriptionError == .notRecording {
                    throw IntentError.notRecording
                }
                throw IntentError.recordingFailed(transcriptionError.localizedDescription)
            }
            throw error
        }
    }
}
