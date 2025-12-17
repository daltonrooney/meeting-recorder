import SwiftUI

@main
struct CallTranscriptionApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Image(systemName: appState.isRecording ? "waveform.circle.fill" : "waveform.circle")
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
