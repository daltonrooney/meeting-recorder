import SwiftUI
import OSLog

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isStarting: Bool = false

    private let logger = Logger(subsystem: "dev.rygn.CallTranscription", category: "MenuBarView")

    var body: some View {
        Group {
            // Main recording control button
            if !appState.isRecording {
                // Not recording - show start button
                Button(LocalizedStringKey("menubar.button.startRecording")) {
                    logger.debug("Start Recording button clicked")
                    Task {
                        logger.info("Initiating recording start sequence")
                        isStarting = true
                        defer {
                            isStarting = false
                            logger.debug("Task completed, isStarting reset to false")
                        }

                        do {
                            try await appState.startActualRecording(title: "Recording")
                            logger.info("Recording started successfully")
                        } catch {
                            logger.error("Failed to start recording: \(error.localizedDescription)")
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
                .disabled(isStarting || appState.isRecording)
                .opacity(isStarting ? 0.6 : 1.0)
                .keyboardShortcut("R", modifiers: [.command, .shift])
                .accessibilityLabel(LocalizedStringKey("menubar.accessibility.startRecording.label"))
                .accessibilityHint(LocalizedStringKey("menubar.accessibility.startRecording.hint"))
            } else if appState.isPaused {
                // Recording but paused - show resume button
                Button(LocalizedStringKey("menubar.button.resumeRecording")) {
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
                .accessibilityLabel(LocalizedStringKey("menubar.accessibility.resumeRecording.label"))
                .accessibilityHint(LocalizedStringKey("menubar.accessibility.resumeRecording.hint"))
            } else {
                // Recording and active - show pause button
                Button(LocalizedStringKey("menubar.button.pauseRecording")) {
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
                .accessibilityLabel(LocalizedStringKey("menubar.accessibility.pauseRecording.label"))
                .accessibilityHint(LocalizedStringKey("menubar.accessibility.pauseRecording.hint"))
            }

            // Stop button (always available when recording)
            if appState.isRecording {
                Button(LocalizedStringKey("menubar.button.stopRecording")) {
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
                .accessibilityLabel(LocalizedStringKey("menubar.accessibility.stopRecording.label"))
                .accessibilityHint(LocalizedStringKey("menubar.accessibility.stopRecording.hint"))
            }
        }
        .alert(LocalizedStringKey("menubar.alert.error.title"), isPresented: $showError) {
            Button(LocalizedStringKey("menubar.alert.button.ok")) { showError = false }
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
                            .announcement: NSLocalizedString("menubar.announcement.recordingStarted", comment: "Recording started announcement"),
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
                            .announcement: NSLocalizedString("menubar.announcement.recordingStopped", comment: "Recording stopped announcement"),
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
                            .announcement: NSLocalizedString("menubar.announcement.recordingPaused", comment: "Recording paused announcement"),
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
                            .announcement: NSLocalizedString("menubar.announcement.recordingResumed", comment: "Recording resumed announcement"),
                            .priority: NSAccessibilityPriorityLevel.high.rawValue
                        ]
                    )
                }
            }
        }

        if appState.isRecording {
            Divider()
            if appState.isPaused {
                Text(LocalizedStringKey(String(format: NSLocalizedString("menubar.status.paused", comment: "Paused status"), appState.elapsedTime)))
                    .foregroundColor(.orange)
                    .accessibilityLabel(LocalizedStringKey("menubar.accessibility.pausedDuration.label"))
                    .accessibilityValue(appState.elapsedTime)
            } else {
                Text(LocalizedStringKey(String(format: NSLocalizedString("menubar.status.recording", comment: "Recording status"), appState.elapsedTime)))
                    .foregroundColor(.secondary)
                    .accessibilityLabel(LocalizedStringKey("menubar.accessibility.recordingDuration.label"))
                    .accessibilityValue(appState.elapsedTime)
            }
        }

        Divider()

        SettingsLink {
            Text(LocalizedStringKey("menubar.link.settings"))
        }
        .keyboardShortcut(",")
        .accessibilityLabel(LocalizedStringKey("menubar.accessibility.settings.label"))
        .accessibilityHint(LocalizedStringKey("menubar.accessibility.settings.hint"))

        Divider()

        Button(LocalizedStringKey("menubar.button.quit")) {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("Q")
        .accessibilityLabel(LocalizedStringKey("menubar.accessibility.quit.label"))
        .accessibilityHint(LocalizedStringKey("menubar.accessibility.quit.hint"))
    }
}
