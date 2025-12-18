# Olive: Architecture Document

## Overview

Olive is a macOS menu bar application that captures audio from both sides of a Zoom call (or any other application producing system audio), transcribes it using Apple's native Speech framework, and saves the transcript to a user-defined folder.

**Critical Requirement**: Audio capture must be completely non-invasive. The application taps into audio streams passively—no interruption, no delay, no quality degradation to the actual audio being played or recorded.

## Target Platform

- **Minimum macOS Version**: macOS 26.0 for `SpeechTranscriber` API
- **Language**: Swift 6 / SwiftUI
- **Architecture**: Native macOS app bundle

## Core Features

1. **Menu Bar Interface**: Start/Stop toggle button
2. **Dual Audio Capture**: Microphone input + System audio output
3. **Real-time Transcription**: Using Apple's `SpeechTranscriber` API
4. **Transcript Output**: Save to user-configurable folder
5. **Post-Recording Hook**: Execute arbitrary shell script after recording stops

---

## Architecture Components

### 1. App Structure

```
Olive/
├── OliveApp.swift                    # App entry point, MenuBarExtra
├── Models/
│   └── AppState.swift           # Observable recording state
├── Audio/
│   ├── SystemAudioCapture.swift # Core Audio Tap for system audio
│   ├── MicrophoneCapture.swift  # AVAudioEngine for mic input
│   └── AudioMixer.swift         # Combines both streams (optional)
├── Transcription/
│   └── TranscriptionManager.swift # SpeechAnalyzer/SpeechTranscriber
├── Storage/
│   └── TranscriptWriter.swift   # File output handling
├── Settings/
│   └── SettingsView.swift       # Output folder + shell script config
└── Resources/
    └── Info.plist               # Privacy descriptions
```

### 2. Audio Capture Strategy

#### System Audio (What Zoom plays to you)

Use **Core Audio Taps** (`AudioHardwareCreateProcessTap`). This is the recommended API for audio-only capture—it's designed specifically for this use case and does not require screen recording permissions (unlike ScreenCaptureKit).

**Key characteristics:**
- Passive tap—audio passes through unmodified
- Can filter by process (e.g., only capture Zoom) or capture all system audio
- Creates an aggregate device that can be used as an input source
- No latency added to the audio path

```swift
// Pseudocode structure
class SystemAudioCapture {
    private var tapDescription: CATapDescription
    private var aggregateDevice: AudioDeviceID
    private var processCallback: AudioDeviceIOProc
    
    func startCapture(excludingProcesses: [pid_t] = []) async throws
    func stopCapture() async
    
    // Callback delivers PCM buffers
    var audioBufferHandler: ((AVAudioPCMBuffer) -> Void)?
}
```

**Reference Implementation**: [AudioCap by insidegui](https://github.com/insidegui/AudioCap) and [AudioTee by makeusabrew](https://github.com/makeusabrew/audiotee)

#### Microphone Input (What you say)

Use **AVAudioEngine** with an input tap. This is the standard approach for microphone capture and is well-documented.

```swift
class MicrophoneCapture {
    private let audioEngine = AVAudioEngine()
    
    func startCapture() throws {
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, time in
            self.audioBufferHandler?(buffer)
        }
        
        try audioEngine.start()
    }
    
    var audioBufferHandler: ((AVAudioPCMBuffer) -> Void)?
}
```

### 3. Transcription Pipeline

#### Using SpeechTranscriber (macOS 26+)

The new `SpeechAnalyzer` framework provides `SpeechTranscriber` for raw speech-to-text without heavy formatting (ideal for conversation transcription).

```swift
import Speech

class TranscriptionManager {
    private var analyzer: SpeechAnalyzer?
    private var transcriber: SpeechTranscriber?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    
    func startTranscription(locale: Locale = .current) async throws {
        // 1. Create transcriber with options
        transcriber = SpeechTranscriber()
        
        // 2. Create analyzer session
        analyzer = SpeechAnalyzer()
        try await analyzer?.add(transcriber!)
        
        // 3. Ensure model is downloaded
        try await ensureModelAvailable(for: locale)
        
        // 4. Create input stream
        let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()
        inputContinuation = continuation
        
        // 5. Start analysis
        try await analyzer?.start(inputStream: stream)
        
        // 6. Process results
        Task {
            for try await result in transcriber!.results {
                if result.isFinal {
                    await handleFinalizedText(result.text)
                }
            }
        }
    }
    
    func feedAudio(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        let input = AnalyzerInput(buffer: buffer, at: time)
        inputContinuation?.yield(input)
    }
    
    func stopTranscription() async {
        inputContinuation?.finish()
        await analyzer?.stop()
    }
}
```

#### Model Download Handling

SpeechTranscriber requires on-device models. Handle download gracefully:

```swift
func ensureModelAvailable(for locale: Locale) async throws {
    guard await SpeechTranscriber.isSupported(locale: locale) else {
        throw TranscriptionError.localeNotSupported
    }
    
    if await SpeechTranscriber.isInstalled(locale: locale) {
        return
    }
    
    // Trigger download (shows system UI)
    try await transcriber?.downloadAssets(for: locale)
}
```

### 4. User Interface

#### Menu Bar Implementation

Use SwiftUI's `MenuBarExtra` for a native menu bar presence:

```swift
@main
struct OliveApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Image(systemName: appState.isRecording ? "waveform.circle.fill" : "waveform.circle")
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Button(appState.isRecording ? "Stop Recording" : "Start Recording") {
            Task {
                if appState.isRecording {
                    await appState.stopRecording()
                } else {
                    await appState.startRecording()
                }
            }
        }
        .keyboardShortcut("R", modifiers: [.command, .shift])
        
        Divider()
        
        if appState.isRecording {
            Text("Recording: \(appState.elapsedTime)")
                .foregroundColor(.secondary)
        }
        
        Divider()
        
        SettingsLink {
            Text("Settings...")
        }
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("Q")
    }
}
```

#### Settings View

```swift
struct SettingsView: View {
    @AppStorage("outputFolder") private var outputFolder: String = "~/Desktop/Transcripts"
    @AppStorage("postRecordingScript") private var postRecordingScript: String = ""
    @AppStorage("captureSystemAudio") private var captureSystemAudio: Bool = true
    @AppStorage("captureMicrophone") private var captureMicrophone: Bool = true
    
    var body: some View {
        Form {
            Section("Output") {
                HStack {
                    TextField("Output Folder", text: $outputFolder)
                    Button("Browse...") {
                        selectFolder()
                    }
                }
            }
            
            Section("Audio Sources") {
                Toggle("Capture System Audio (Zoom, etc.)", isOn: $captureSystemAudio)
                Toggle("Capture Microphone", isOn: $captureMicrophone)
            }
            
            Section("Post-Recording") {
                TextField("Shell Script Path", text: $postRecordingScript)
                Text("Script receives transcript path as $1")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 450)
    }
}
```

### 5. Transcript Output

#### File Format

Save transcripts as plain text with timestamps:

```
Olive Transcript
Date: 2025-12-15 14:30:00
Duration: 45:23

---

[00:00:12] Hello, thanks for joining the call today.
[00:00:18] Hi, good to be here. Let's dive into the quarterly results.
[00:00:25] Sure. So looking at Q4, we've seen significant growth...
```

#### Writer Implementation

```swift
class TranscriptWriter {
    private let outputURL: URL
    private var fileHandle: FileHandle?
    private let startTime: Date
    
    init(folder: URL, filename: String? = nil) throws {
        let name = filename ?? "transcript-\(ISO8601DateFormatter().string(from: Date())).txt"
        outputURL = folder.appendingPathComponent(name)
        
        // Create file with header
        let header = """
        Olive Transcript
        Date: \(Date().formatted())

        ---

        """
        try header.write(to: outputURL, atomically: true, encoding: .utf8)
        fileHandle = try FileHandle(forWritingTo: outputURL)
        fileHandle?.seekToEndOfFile()
        startTime = Date()
    }
    
    func append(text: String, timestamp: TimeInterval) {
        let formatted = "[\(formatTimestamp(timestamp))] \(text)\n"
        if let data = formatted.data(using: .utf8) {
            fileHandle?.write(data)
        }
    }
    
    func finalize() -> URL {
        fileHandle?.closeFile()
        return outputURL
    }
    
    private func formatTimestamp(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
```

### 6. Post-Recording Shell Script Execution (Future Feature)

> **Note**: This feature is not yet implemented. When implementing, add the required entitlement documented below.

```swift
func executePostRecordingScript(scriptPath: String, transcriptPath: URL) async throws {
    guard !scriptPath.isEmpty else { return }

    let expandedPath = NSString(string: scriptPath).expandingTildeInPath

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = [expandedPath, transcriptPath.path]
    process.environment = ProcessInfo.processInfo.environment

    try process.run()
    process.waitUntilExit()

    if process.terminationStatus != 0 {
        print("Warning: Post-recording script exited with status \(process.terminationStatus)")
    }
}
```

---

## Required Permissions

### Info.plist Keys

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Olive needs microphone access to record and transcribe your side of the conversation during calls. All audio processing happens on-device.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Olive uses on-device speech recognition to transcribe your calls in real-time. Your audio never leaves your Mac.</string>
```

### Entitlements

```xml
<key>com.apple.security.app-sandbox</key>
<true/>

<key>com.apple.security.device.audio-input</key>
<true/>

<!-- For file access outside sandbox -->
<key>com.apple.security.files.user-selected.read-write</key>
<true/>

<!-- TODO: Add when implementing post-recording shell script execution (Section 6) -->
<!-- SECURITY NOTE: Only add this broad exception when actually needed -->
<!-- <key>com.apple.security.temporary-exception.files.absolute-path.read-write</key>
<array>
    <string>/</string>
</array> -->
```

---

## Error Handling

### Key Error Cases

1. **Microphone permission denied**: Show alert directing to System Settings
2. **Speech recognition unavailable**: Model not downloaded, prompt download
3. **Locale not supported**: Fall back to English or show error
4. **Output folder not writable**: Prompt user to select different folder
5. **Post-recording script not found/not executable**: Log warning, continue

```swift
enum OliveError: LocalizedError {
    case microphonePermissionDenied
    case speechRecognitionUnavailable
    case localeNotSupported(Locale)
    case outputFolderNotWritable(URL)
    case audioTapCreationFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access is required. Please enable in System Settings > Privacy & Security > Microphone."
        case .speechRecognitionUnavailable:
            return "Speech recognition is not available. Please check your internet connection for model download."
        case .localeNotSupported(let locale):
            return "Speech recognition is not available for \(locale.identifier)."
        case .outputFolderNotWritable(let url):
            return "Cannot write to \(url.path). Please select a different folder."
        case .audioTapCreationFailed(let status):
            return "Failed to create audio tap (error \(status)). System audio capture unavailable."
        }
    }
}
```

---

## Testing Considerations

1. **Audio capture without Zoom**: Test with any audio source (YouTube, Music app)
2. **Long recordings**: Verify memory usage stays stable over 1+ hour sessions
3. **Permission denial flows**: Test all permission denied scenarios
4. **Model download**: Test first-launch experience when model needs download
5. **Post-recording script**: Test with scripts that succeed, fail, and hang

---

## Build & Distribution

### Development

```bash
# Build
xcodebuild -scheme Olive -configuration Debug build

# Run
open ./build/Debug/Olive.app
```

### Release

1. Archive with notarization
2. Distribute via DMG or direct .app download
3. Consider Mac App Store (requires full sandboxing)

---

## Dependencies

**None required**—this app uses only Apple frameworks:

- `SwiftUI` - UI
- `AVFoundation` - Microphone capture
- `CoreAudio` - System audio tap
- `Speech` - Transcription (SpeechAnalyzer/SpeechTranscriber)
- `Foundation` - File I/O, Process execution

---

## Future Enhancements (Out of Scope)

- Speaker diarization (who said what)
- Multiple language detection
- Real-time display of transcript in menu bar popover
- Audio recording alongside transcript
- Integration with note-taking apps
- Zoom-specific process filtering