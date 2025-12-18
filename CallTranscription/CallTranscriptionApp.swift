import SwiftUI

@main
struct CallTranscriptionApp: App {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var appState: AppState

    init() {
        let settings = SettingsManager()
        _settingsManager = StateObject(wrappedValue: settings)
        _appState = StateObject(wrappedValue: AppState(settingsManager: settings))
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
                Image(systemName: "waveform.circle.fill")
                    .foregroundColor(.red)
            } else {
                Image(systemName: "waveform.circle")
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(settingsManager)
        }
    }
}
