import AppIntents

/// Provides default app shortcuts that appear in the Shortcuts app.
///
/// These shortcuts are automatically discovered by the Shortcuts app
/// and can be added with a single tap by users.
@available(macOS 13.0, *)
struct OliveAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartRecordingIntent(),
            phrases: [
                "Start recording in \(.applicationName)",
                "Begin recording in \(.applicationName)",
                "Start a new recording in \(.applicationName)"
            ],
            shortTitle: "Start Recording",
            systemImageName: "record.circle"
        )

        AppShortcut(
            intent: StopRecordingIntent(),
            phrases: [
                "Stop recording in \(.applicationName)",
                "End recording in \(.applicationName)",
                "Finish recording in \(.applicationName)"
            ],
            shortTitle: "Stop Recording",
            systemImageName: "stop.circle"
        )

        AppShortcut(
            intent: GetRecordingStatusIntent(),
            phrases: [
                "Get recording status in \(.applicationName)",
                "Check recording in \(.applicationName)",
                "Am I recording in \(.applicationName)"
            ],
            shortTitle: "Recording Status",
            systemImageName: "info.circle"
        )

        AppShortcut(
            intent: ConfigureSettingsIntent(),
            phrases: [
                "Configure \(.applicationName) settings",
                "Change \(.applicationName) settings"
            ],
            shortTitle: "Configure Settings",
            systemImageName: "gearshape"
        )
    }
}
