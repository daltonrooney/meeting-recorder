import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    // Direct @AppStorage bindings for automatic persistence
    @AppStorage("outputFolder") private var outputFolder: String = SettingsManager.defaultOutputFolder
    @AppStorage("postRecordingScript") private var postRecordingScript: String = SettingsManager.defaultPostRecordingScript
    @AppStorage("captureSystemAudio") private var captureSystemAudio: Bool = SettingsManager.defaultCaptureSystemAudio
    @AppStorage("captureMicrophone") private var captureMicrophone: Bool = SettingsManager.defaultCaptureMicrophone
    @AppStorage("silencePauseThreshold") private var silencePauseThresholdRaw: String = SettingsManager.defaultSilencePauseThreshold.rawValue

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
        Section("Output") {
            HStack {
                TextField("Output Folder", text: $outputFolder)
                    .textFieldStyle(.roundedBorder)

                Button("Browse...") {
                    selectOutputFolder()
                }
            }

            Text("Transcripts will be saved to this folder")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Audio Sources Section

    private var audioSourcesSection: some View {
        Section("Audio Sources") {
            Toggle("Capture System Audio (Zoom, Teams, etc.)", isOn: $captureSystemAudio)
            Toggle("Capture Microphone Input", isOn: $captureMicrophone)

            Text("At least one audio source must be enabled")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Silence Detection Section

    private var silenceDetectionSection: some View {
        Section("Silence Detection") {
            Picker("Auto-pause after silence:", selection: Binding(
                get: { SilencePauseThreshold(rawValue: silencePauseThresholdRaw) ?? .never },
                set: { silencePauseThresholdRaw = $0.rawValue }
            )) {
                ForEach(SilencePauseThreshold.allCases, id: \.self) { threshold in
                    Text(threshold.displayName).tag(threshold)
                }
            }
            .pickerStyle(.menu)

            Text("Automatically pause recording after continuous silence. Recording will auto-resume when audio is detected.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Post-Recording Section

    private var postRecordingSection: some View {
        Section("Post-Recording Script") {
            HStack {
                TextField("Shell Script Path (optional)", text: $postRecordingScript)
                    .textFieldStyle(.roundedBorder)

                Button("Browse...") {
                    selectPostRecordingScript()
                }
            }

            Text("Script receives transcript path as $1")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - File Selection

    private func selectOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Output Folder"
        panel.message = "Choose where transcripts will be saved"

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
}

#Preview {
    SettingsView()
        .frame(width: 450)
}
