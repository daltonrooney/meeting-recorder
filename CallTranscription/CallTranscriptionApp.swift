import SwiftUI

@main
struct CallTranscriptionApp: App {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var appState: AppState
    @StateObject private var urlHandlerContainer = URLHandlerContainer()

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
                .onOpenURL { url in
                    Task { @MainActor in
                        await urlHandlerContainer.handler(for: appState, settingsManager: settingsManager).handle(url)
                    }
                }
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

// MARK: - URL Handler Container

@MainActor
final class URLHandlerContainer: ObservableObject {
    private var _handler: URLSchemeHandler?

    func handler(for appState: any RecordingActionHandler, settingsManager: SettingsManager) -> URLSchemeHandler {
        if let existing = _handler {
            return existing
        }
        let handler = URLSchemeHandler(appState: appState, settingsManager: settingsManager)
        _handler = handler
        return handler
    }
}
