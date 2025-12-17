import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button(appState.isRecording ? "Stop Recording" : "Start Recording") {
            Task {
                do {
                    if appState.isRecording {
                        try await appState.stopActualRecording()
                    } else {
                        try await appState.startActualRecording(title: "Recording")
                    }
                } catch {
                    // TODO: Present error to user
                    print("Recording error: \(error.localizedDescription)")
                }
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
