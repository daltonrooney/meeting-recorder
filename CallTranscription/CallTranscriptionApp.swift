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
            Image(systemName: appState.isRecording ? "waveform.circle.fill" : "waveform.circle")
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(settingsManager)
        }
    }
}
