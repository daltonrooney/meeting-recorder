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
                .accessibilityLabel("Start Recording")
                .accessibilityHint("Begins a new recording session. Keyboard shortcut: Command Shift R")
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
                .accessibilityLabel("Resume Recording")
                .accessibilityHint("Resumes the paused recording. Keyboard shortcut: Command Shift R")
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
                .accessibilityLabel("Pause Recording")
                .accessibilityHint("Pauses the current recording. Keyboard shortcut: Command Shift P")
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
                .accessibilityLabel("Stop Recording")
                .accessibilityHint("Stops the recording and saves the transcript. Keyboard shortcut: Command Shift S")
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
        .onChange(of: appState.isRecording) { oldValue, newValue in
            // Announce when recording starts
            if newValue && !oldValue {
                DispatchQueue.main.async {
                    NSAccessibility.post(
                        element: NSApp as Any,
                        notification: .announcementRequested,
                        userInfo: [
                            .announcement: "Recording started",
                            .priority: NSAccessibilityPriorityLevel.high.rawValue
                        ]
                    )
                }
            }
            // Announce when recording stops
            else if !newValue && oldValue {
                DispatchQueue.main.async {
                    NSAccessibility.post(
                        element: NSApp as Any,
                        notification: .announcementRequested,
                        userInfo: [
                            .announcement: "Recording stopped",
                            .priority: NSAccessibilityPriorityLevel.high.rawValue
                        ]
                    )
                }
            }
        }
        .onChange(of: appState.isPaused) { oldValue, newValue in
            // Announce when recording pauses
            if newValue && !oldValue {
                DispatchQueue.main.async {
                    NSAccessibility.post(
                        element: NSApp as Any,
                        notification: .announcementRequested,
                        userInfo: [
                            .announcement: "Recording paused",
                            .priority: NSAccessibilityPriorityLevel.high.rawValue
                        ]
                    )
                }
            }
            // Announce when recording resumes
            else if !newValue && oldValue && appState.isRecording {
                DispatchQueue.main.async {
                    NSAccessibility.post(
                        element: NSApp as Any,
                        notification: .announcementRequested,
                        userInfo: [
                            .announcement: "Recording resumed",
                            .priority: NSAccessibilityPriorityLevel.high.rawValue
                        ]
                    )
                }
            }
        }

        if appState.isRecording {
            Divider()
            if appState.isPaused {
                Text("Paused: \(appState.elapsedTime)")
                    .foregroundColor(.orange)
                    .accessibilityLabel("Paused duration")
                    .accessibilityValue(appState.elapsedTime)
            } else {
                Text("Recording: \(appState.elapsedTime)")
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Recording duration")
                    .accessibilityValue(appState.elapsedTime)
            }
        }

        Divider()

        SettingsLink {
            Text("Settings...")
        }
        .keyboardShortcut(",")
        .accessibilityLabel("Settings")
        .accessibilityHint("Opens application settings. Keyboard shortcut: Command Comma")

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("Q")
        .accessibilityLabel("Quit")
        .accessibilityHint("Quits the application. Keyboard shortcut: Command Q")
    }
}
