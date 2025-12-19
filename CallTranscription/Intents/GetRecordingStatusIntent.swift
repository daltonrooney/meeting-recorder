import AppIntents
import Foundation

/// App Intent for querying the current recording status.
///
/// This intent allows users to check if recording is active, get elapsed time,
/// and check if the recording is paused through Shortcuts or Siri.
///
/// Returns a formatted string with the status information.
@available(macOS 13.0, *)
struct GetRecordingStatusIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Get Recording Status"
    nonisolated(unsafe) static var description: IntentDescription? = IntentDescription("Get the current recording status including elapsed time and paused state")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        // Get the shared AppState instance
        let appState = try AppStateContainer.shared.requireAppState()

        // Create status message
        let statusMessage: String
        if appState.isRecording {
            if appState.isPaused {
                statusMessage = String(format: NSLocalizedString("intent.status.recordingPaused", comment: "Recording paused status message"), appState.elapsedTime)
            } else {
                statusMessage = String(format: NSLocalizedString("intent.status.recordingInProgress", comment: "Recording in progress status message"), appState.elapsedTime)
            }
        } else {
            statusMessage = NSLocalizedString("intent.status.notRecording", comment: "Not recording status message")
        }

        return .result(value: statusMessage, dialog: IntentDialog(stringLiteral: statusMessage))
    }
}
