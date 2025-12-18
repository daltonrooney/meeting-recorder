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
            // Use custom SVG: monochrome when inactive, color when recording/paused
            if appState.isRecording || appState.isPaused {
                Image("MenuBarIconRecording")
                    .renderingMode(.original) // Preserve colors
            } else {
                Image("MenuBarIconInactive")
                    .renderingMode(.template) // Allow system tinting
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(settingsManager)
        }
    }
}
