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
                Image(systemName: "pause.circle.fill")
                    .foregroundColor(.orange)
            } else if appState.isRecording {
                Image(systemName: "record.circle")
                    .foregroundColor(.red)
            } else {
                Image(systemName: "stop.circle")
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(settingsManager)
        }
    }
}
