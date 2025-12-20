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
    @AppStorage("filenameTemplate") private var filenameTemplate: String = SettingsManager.defaultFilenameTemplate
    @AppStorage("outputFolderBookmark") private var outputFolderBookmark: Data?
    @AppStorage("postRecordingScriptBookmark") private var postRecordingScriptBookmark: Data?

    @State private var availableShortcuts: [String] = []
    @State private var isLoadingShortcuts: Bool = false
    // Cache persists across view updates (not recreations) due to @State
    // SettingsView is typically a singleton in the app, so this provides adequate caching
    @State private var shortcutsCache = SettingsViewCache()
    @State private var bookmarkManager = SecurityScopedBookmarkManager()

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
                Image(systemName: "folder")
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("outputFolderIcon")
                    .accessibilityHidden(true)

                Text(outputFolder)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .accessibilityIdentifier("outputFolderDisplay")
                    .accessibilityLabel(LocalizedStringKey("settings.output.folder.accessibility.label"))
                    .accessibilityValue(outputFolder)

                Spacer()

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

            VStack(alignment: .leading, spacing: 4) {
                TextField(LocalizedStringKey("settings.filenameTemplate.label"), text: $filenameTemplate)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("filenameTemplateTextField")
                    .accessibilityLabel(LocalizedStringKey("settings.filenameTemplate.accessibility.label"))
                    .accessibilityHint(LocalizedStringKey("settings.filenameTemplate.accessibility.hint"))

                Text(LocalizedStringKey("settings.filenameTemplate.helpText"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }

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
            Picker(LocalizedStringKey("settings.postRecording.afterRecording.label"), selection: Binding(
                get: { PostRecordingActionType(rawValue: postRecordingActionTypeRaw) ?? .doNothing },
                set: { postRecordingActionTypeRaw = $0.rawValue }
            )) {
                Text(LocalizedStringKey("settings.postRecording.action.doNothing")).tag(PostRecordingActionType.doNothing)
                Text(LocalizedStringKey("settings.postRecording.action.runScript")).tag(PostRecordingActionType.script)
                Text(LocalizedStringKey("settings.postRecording.action.runShortcut")).tag(PostRecordingActionType.shortcut)
            }
            .pickerStyle(.radioGroup)
            .accessibilityIdentifier("postRecordingActionPicker")
            .accessibilityLabel(LocalizedStringKey("settings.postRecording.afterRecording.accessibility.label"))
            .accessibilityHint(LocalizedStringKey("settings.postRecording.afterRecording.accessibility.hint"))

            // Show script picker when script is selected
            if PostRecordingActionType(rawValue: postRecordingActionTypeRaw) == .script {
                HStack {
                    TextField(LocalizedStringKey("settings.postRecording.script.path.label"), text: $postRecordingScript)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("postRecordingScriptTextField")
                        .accessibilityLabel(LocalizedStringKey("settings.postRecording.script.path.accessibility.label"))
                        .accessibilityHint(LocalizedStringKey("settings.postRecording.script.path.accessibility.hint"))

                    Button(LocalizedStringKey("settings.postRecording.script.browseButton")) {
                        selectPostRecordingScript()
                    }
                    .accessibilityIdentifier("postRecordingScriptBrowseButton")
                    .accessibilityLabel(LocalizedStringKey("settings.postRecording.script.browse.accessibility.label"))
                    .accessibilityHint(LocalizedStringKey("settings.postRecording.script.browse.accessibility.hint"))
                }

                Text(LocalizedStringKey("settings.postRecording.script.helpText"))
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
                            .accessibilityLabel(LocalizedStringKey("settings.postRecording.shortcut.loading.accessibility.label"))
                            .accessibilityIdentifier("shortcutsLoadingIndicator")
                        Text(LocalizedStringKey("settings.postRecording.shortcut.loading"))
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                    }
                } else {
                    Picker(LocalizedStringKey("settings.postRecording.shortcut.picker.label"), selection: $shortcutIdentifier) {
                        Text(LocalizedStringKey("settings.postRecording.shortcut.placeholder")).tag("")
                        ForEach(availableShortcuts, id: \.self) { shortcut in
                            Text(shortcut).tag(shortcut)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("shortcutPicker")
                    .accessibilityLabel(LocalizedStringKey("settings.postRecording.shortcut.picker.accessibility.label"))
                    .accessibilityHint(LocalizedStringKey("settings.postRecording.shortcut.picker.accessibility.hint"))

                    if availableShortcuts.isEmpty {
                        Text(LocalizedStringKey("settings.postRecording.shortcut.noShortcuts"))
                            .font(.caption)
                            .foregroundColor(.orange)
                            .accessibilityHidden(true)
                    } else {
                        Text(LocalizedStringKey("settings.postRecording.shortcut.helpText"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                    }
                }
            }
        } header: {
            Text(LocalizedStringKey("settings.postRecording.header"))
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
            // Save the path
            outputFolder = url.path

            // Create and save security-scoped bookmark
            do {
                let bookmarkData = try bookmarkManager.createBookmark(for: url)
                outputFolderBookmark = bookmarkData
            } catch {
                // Log error but don't block the user - path is still saved
                print("Warning: Failed to create bookmark for output folder: \(error.localizedDescription)")
            }
        }
    }

    private func selectPostRecordingScript() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.shellScript, .executable, .unixExecutable]
        panel.prompt = NSLocalizedString("settings.postRecording.script.dialog.prompt", comment: "Script dialog prompt")
        panel.message = NSLocalizedString("settings.postRecording.script.dialog.message", comment: "Script dialog message")

        // Set initial directory if current path exists
        if !postRecordingScript.isEmpty {
            let expandedPath = NSString(string: postRecordingScript).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expandedPath) {
                panel.directoryURL = URL(fileURLWithPath: expandedPath).deletingLastPathComponent()
            }
        }

        if panel.runModal() == .OK, let url = panel.url {
            // Save the path
            postRecordingScript = url.path

            // Create and save security-scoped bookmark for the script's parent directory
            do {
                let parentDirectory = url.deletingLastPathComponent()
                let bookmarkData = try bookmarkManager.createBookmark(for: parentDirectory)
                postRecordingScriptBookmark = bookmarkData
            } catch {
                // Log error but don't block the user - path is still saved
                print("Warning: Failed to create bookmark for script directory: \(error.localizedDescription)")
            }
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
