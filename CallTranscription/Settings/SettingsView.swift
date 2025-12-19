import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    // Direct @AppStorage bindings for automatic persistence
    @AppStorage("outputFolder") private var outputFolder: String = SettingsManager.defaultOutputFolder
    @AppStorage("postRecordingScript") private var postRecordingScript: String = SettingsManager.defaultPostRecordingScript
    @AppStorage("postRecordingActionType") private var postRecordingActionTypeRaw: String = SettingsManager.defaultPostRecordingActionType.rawValue
    @AppStorage("shortcutIdentifier") private var shortcutIdentifier: String = SettingsManager.defaultShortcutIdentifier
    @AppStorage("captureSystemAudio") private var captureSystemAudio: Bool = SettingsManager.defaultCaptureSystemAudio
    @AppStorage("captureMicrophone") private var captureMicrophone: Bool = SettingsManager.defaultCaptureMicrophone
    @AppStorage("silencePauseThreshold") private var silencePauseThresholdRaw: String = SettingsManager.defaultSilencePauseThreshold.rawValue
    @AppStorage("saveOriginalAudio") private var saveOriginalAudio: Bool = SettingsManager.defaultSaveOriginalAudio

    @State private var availableShortcuts: [String] = []
    @State private var isLoadingShortcuts: Bool = false
    // Cache persists across view updates (not recreations) due to @State
    // SettingsView is typically a singleton in the app, so this provides adequate caching
    @State private var shortcutsCache = SettingsViewCache()

    var body: some View {
        Form {
            outputSection
            audioSourcesSection
            silenceDetectionSection
            postRecordingSection
        }
        .padding()
        .frame(width: 450)
    }

    // MARK: - Output Section

    private var outputSection: some View {
        Section {
            HStack {
                TextField(LocalizedStringKey("settings.output.folder.label"), text: $outputFolder)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("outputFolderTextField")
                    .accessibilityLabel(LocalizedStringKey("settings.output.folder.accessibility.label"))
                    .accessibilityHint(LocalizedStringKey("settings.output.folder.accessibility.hint"))

                Button(LocalizedStringKey("settings.output.folder.browseButton")) {
                    selectOutputFolder()
                }
                .accessibilityIdentifier("outputFolderBrowseButton")
                .accessibilityLabel(LocalizedStringKey("settings.output.folder.browse.accessibility.label"))
                .accessibilityHint(LocalizedStringKey("settings.output.folder.browse.accessibility.hint"))
            }

            Toggle(LocalizedStringKey("settings.output.saveOriginalAudio.label"), isOn: $saveOriginalAudio)
                .accessibilityIdentifier("saveOriginalAudioToggle")
                .accessibilityLabel(LocalizedStringKey("settings.output.saveOriginalAudio.accessibility.label"))
                .accessibilityHint(LocalizedStringKey("settings.output.saveOriginalAudio.accessibility.hint"))

            Text(LocalizedStringKey("settings.output.helpText"))
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        } header: {
            Text(LocalizedStringKey("settings.output.header"))
                .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: - Audio Sources Section

    private var audioSourcesSection: some View {
        Section {
            Toggle(LocalizedStringKey("settings.audioSources.captureSystemAudio.label"), isOn: $captureSystemAudio)
                .accessibilityIdentifier("captureSystemAudioToggle")
                .accessibilityLabel(LocalizedStringKey("settings.audioSources.captureSystemAudio.accessibility.label"))
                .accessibilityHint(LocalizedStringKey("settings.audioSources.captureSystemAudio.accessibility.hint"))

            Toggle(LocalizedStringKey("settings.audioSources.captureMicrophone.label"), isOn: $captureMicrophone)
                .accessibilityIdentifier("captureMicrophoneToggle")
                .accessibilityLabel(LocalizedStringKey("settings.audioSources.captureMicrophone.accessibility.label"))
                .accessibilityHint(LocalizedStringKey("settings.audioSources.captureMicrophone.accessibility.hint"))

            Text(LocalizedStringKey("settings.audioSources.helpText"))
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        } header: {
            Text(LocalizedStringKey("settings.audioSources.header"))
                .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: - Silence Detection Section

    private var silenceDetectionSection: some View {
        Section {
            Picker(LocalizedStringKey("settings.silenceDetection.autoPause.label"), selection: Binding(
                get: { SilencePauseThreshold(rawValue: silencePauseThresholdRaw) ?? .never },
                set: { silencePauseThresholdRaw = $0.rawValue }
            )) {
                ForEach(SilencePauseThreshold.allCases, id: \.self) { threshold in
                    Text(threshold.displayName).tag(threshold)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("silencePauseThresholdPicker")
            .accessibilityLabel(LocalizedStringKey("settings.silenceDetection.autoPause.accessibility.label"))
            .accessibilityHint(LocalizedStringKey("settings.silenceDetection.autoPause.accessibility.hint"))

            Text(LocalizedStringKey("settings.silenceDetection.helpText"))
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        } header: {
            Text(LocalizedStringKey("settings.silenceDetection.header"))
                .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: - Post-Recording Section

    private var postRecordingSection: some View {
        Section {
            Picker("After recording:", selection: Binding(
                get: { PostRecordingActionType(rawValue: postRecordingActionTypeRaw) ?? .doNothing },
                set: { postRecordingActionTypeRaw = $0.rawValue }
            )) {
                Text("Do nothing").tag(PostRecordingActionType.doNothing)
                Text("Run a script").tag(PostRecordingActionType.script)
                Text("Run a shortcut").tag(PostRecordingActionType.shortcut)
            }
            .pickerStyle(.radioGroup)
            .accessibilityIdentifier("postRecordingActionPicker")
            .accessibilityLabel("After recording")
            .accessibilityHint("Choose what happens when recording stops: do nothing, run a script, or run a shortcut")

            // Show script picker when script is selected
            if PostRecordingActionType(rawValue: postRecordingActionTypeRaw) == .script {
                HStack {
                    TextField("Shell Script Path", text: $postRecordingScript)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("postRecordingScriptTextField")
                        .accessibilityLabel("Shell Script Path")
                        .accessibilityHint("Path to shell script that will receive the transcript file path as its first argument")

                    Button("Browse...") {
                        selectPostRecordingScript()
                    }
                    .accessibilityIdentifier("postRecordingScriptBrowseButton")
                    .accessibilityLabel("Browse for Script")
                    .accessibilityHint("Opens a dialog to select a shell script to run after recording")
                }

                Text("Script receives transcript path as $1")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }

            // Show shortcut picker when shortcut is selected
            if PostRecordingActionType(rawValue: postRecordingActionTypeRaw) == .shortcut {
                if isLoadingShortcuts {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.7)
                            .accessibilityLabel("Loading shortcuts")
                            .accessibilityIdentifier("shortcutsLoadingIndicator")
                        Text("Loading shortcuts...")
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                    }
                } else {
                    Picker("Shortcut:", selection: $shortcutIdentifier) {
                        Text("Select a shortcut...").tag("")
                        ForEach(availableShortcuts, id: \.self) { shortcut in
                            Text(shortcut).tag(shortcut)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("shortcutPicker")
                    .accessibilityLabel("Shortcut")
                    .accessibilityHint("Choose a shortcut that will receive the transcript file path as input")

                    if availableShortcuts.isEmpty {
                        Text("No shortcuts found. Create shortcuts in the Shortcuts app first.")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .accessibilityHidden(true)
                    } else {
                        Text("The shortcut receives the transcript file path as input")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                    }
                }
            }
        } header: {
            Text("Post-Recording Action")
                .accessibilityAddTraits(.isHeader)
        }
        .onAppear {
            loadAvailableShortcuts()
        }
    }

    // MARK: - File Selection

    private func selectOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = NSLocalizedString("settings.output.folder.dialog.prompt", comment: "Output folder dialog prompt")
        panel.message = NSLocalizedString("settings.output.folder.dialog.message", comment: "Output folder dialog message")

        // Set initial directory if current path exists
        let expandedPath = NSString(string: outputFolder).expandingTildeInPath
        if FileManager.default.fileExists(atPath: expandedPath) {
            panel.directoryURL = URL(fileURLWithPath: expandedPath)
        }

        if panel.runModal() == .OK, let url = panel.url {
            outputFolder = url.path
        }
    }

    private func selectPostRecordingScript() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.shellScript, .executable, .unixExecutable]
        panel.prompt = "Select Script"
        panel.message = "Choose a shell script to run after recording completes"

        // Set initial directory if current path exists
        if !postRecordingScript.isEmpty {
            let expandedPath = NSString(string: postRecordingScript).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expandedPath) {
                panel.directoryURL = URL(fileURLWithPath: expandedPath).deletingLastPathComponent()
            }
        }

        if panel.runModal() == .OK, let url = panel.url {
            postRecordingScript = url.path
        }
    }

    // MARK: - Shortcuts Integration

    private func loadAvailableShortcuts() {
        guard !isLoadingShortcuts else { return } // Prevent concurrent loads

        // Use cached shortcuts if not expired
        if !shortcutsCache.isCacheExpired() {
            availableShortcuts = shortcutsCache.getCachedShortcuts()
            return
        }

        // Load fresh shortcuts if cache expired
        Task {
            isLoadingShortcuts = true
            let executor = ShortcutExecutor()
            let shortcuts = await executor.listAvailableShortcuts()
            availableShortcuts = shortcuts
            shortcutsCache.updateCache(shortcuts: shortcuts)
            isLoadingShortcuts = false
        }
    }
}

#Preview {
    SettingsView()
        .frame(width: 450)
}
