import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button(appState.isRecording ? "Stop Recording" : "Start Recording") {
            if appState.isRecording {
                appState.stopRecording()
            } else {
                appState.startRecording()
            }
        }
        .keyboardShortcut("R", modifiers: [.command, .shift])

        if appState.isRecording {
            Divider()
            Text("Recording: \(appState.elapsedTime)")
                .foregroundColor(.secondary)
        }

        Divider()

        SettingsLink {
            Text("Settings...")
        }
        .keyboardShortcut(",")

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("Q")
    }
}
