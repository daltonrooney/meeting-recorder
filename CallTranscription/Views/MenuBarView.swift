import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        Group {
            // Main recording control button
            if !appState.isRecording {
                // Not recording - show start button
                Button("Start Recording") {
                    Task {
                        do {
                            try await appState.startActualRecording(title: "Recording")
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
                .keyboardShortcut("R", modifiers: [.command, .shift])
            } else if appState.isPaused {
                // Recording but paused - show resume button
                Button("Resume Recording") {
                    Task {
                        do {
                            try await appState.resumeRecording()
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
                .keyboardShortcut("R", modifiers: [.command, .shift])
            } else {
                // Recording and active - show pause button
                Button("Pause Recording") {
                    Task {
                        do {
                            try await appState.pauseRecording()
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
                .keyboardShortcut("P", modifiers: [.command, .shift])
            }

            // Stop button (always available when recording)
            if appState.isRecording {
                Button("Stop Recording") {
                    Task {
                        do {
                            try await appState.stopActualRecording()
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
                .keyboardShortcut("S", modifiers: [.command, .shift])
            }
        }
        .alert("Recording Error", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .sheet(isPresented: Binding(
            get: { appState.showConsentDialog },
            set: { _ in }
        )) {
            ConsentDialogView()
                .environmentObject(appState)
        }

        if appState.isRecording {
            Divider()
            if appState.isPaused {
                Text("Paused: \(appState.elapsedTime)")
                    .foregroundColor(.orange)
            } else {
                Text("Recording: \(appState.elapsedTime)")
                    .foregroundColor(.secondary)
            }
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
