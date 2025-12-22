import SwiftUI

@main
struct CallTranscriptionApp: App {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var appState: AppState

    init() {
        let settings = SettingsManager()
        _settingsManager = StateObject(wrappedValue: settings)
        let state = AppState(settingsManager: settings)
        _appState = StateObject(wrappedValue: state)

        // Register AppState and SettingsManager for App Intents access
        Task { @MainActor in
            AppStateContainer.shared.setAppState(state, settingsManager: settings)
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
                .environmentObject(settingsManager)
        } label: {
            // Show different icon based on recording state
            if appState.isPaused {
                if settingsManager.showRecordingTimeInMenuBar {
                    Label(appState.elapsedTime, systemImage: "pause.circle.fill")
                        .foregroundColor(.orange)
                        .accessibilityLabel("Meeting Recorder - Paused")
                        .accessibilityValue(appState.elapsedTime)
                } else {
                    Image(systemName: "pause.circle.fill")
                        .foregroundColor(.orange)
                        .accessibilityLabel("Meeting Recorder - Paused")
                        .accessibilityValue(appState.elapsedTime)
                }
            } else if appState.isRecording {
                if settingsManager.showRecordingTimeInMenuBar {
                    Label(appState.elapsedTime, systemImage: "record.circle")
                        .foregroundColor(.red)
                        .accessibilityLabel("Meeting Recorder - Recording")
                        .accessibilityValue(appState.elapsedTime)
                } else {
                    Image(systemName: "record.circle")
                        .foregroundColor(.red)
                        .accessibilityLabel("Meeting Recorder - Recording")
                        .accessibilityValue(appState.elapsedTime)
                }
            } else {
                Image(systemName: "stop.circle")
                    .accessibilityLabel("Meeting Recorder - Not Recording")
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(settingsManager)
        }
    }
}
