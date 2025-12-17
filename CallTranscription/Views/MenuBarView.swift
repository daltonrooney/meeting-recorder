import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @State private var errorMessage: String?
    @State private var showError = false

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
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
        .keyboardShortcut("R", modifiers: [.command, .shift])
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
