# Olive: Call Transcription

Olive is a macOS menu bar application that records and transcribes audio from both sides of calls (Zoom, Teams, etc.) using Apple's native Speech framework. Features automatic silence detection, pause functionality, and non-invasive audio capture.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Settings](#settings)
- [Permissions](#permissions)
- [Development](#development)
- [Architecture](#architecture)
- [Testing](#testing)
- [Contributing](#contributing)
- [Troubleshooting](#troubleshooting)

## Features

- **Dual Audio Recording**: Captures both system audio (what you hear) and microphone input (what you say)
- **Real-time Transcription**: Uses Apple's SpeechTranscriber API for on-device transcription
- **Automatic Silence Detection**: Pauses transcription during silence periods to save processing
- **Menu Bar Interface**: Minimal, always-accessible controls
- **Post-Recording Automation**: Execute shell scripts or shortcuts after recording stops
- **Privacy-First**: All transcription happens on-device using Apple's Speech framework

## Requirements

- **macOS 26.0 or later** (required for SpeechTranscriber API - currently in beta/developer preview)
- **Swift 6** / SwiftUI
- **Xcode 16+** for building from source
- **XcodeGen** for project generation (optional, for development)

## Installation

### From Source

1. Clone the repository:
   ```bash
   git clone https://github.com/rygn-dev/olive-call-transcription.git
   cd olive-call-transcription
   ```

2. Configure visual assets (one-time setup):
   ```bash
   open Olive.xcodeproj
   ```
   Then drag these files into the Xcode project navigator:
   - `CallTranscription/icon.icon`
   - `CallTranscription/Assets.xcassets`

   Verify both are listed in the CallTranscription target's "Copy Bundle Resources" build phase.

3. Build and run in Xcode (⌘R)

**Note**: Do not run `xcodegen generate` after manually adding visual assets, as it will remove them.

## Usage

### Starting a Recording

1. Click the Olive menu bar icon
2. Click "Start Recording"
3. The app captures both system audio and microphone input
4. Transcription happens in real-time using on-device Speech recognition

### Stopping a Recording

1. Click the Olive menu bar icon again
2. Click "Stop Recording"
3. Transcript is automatically saved to your configured output folder
4. Optional post-recording script or shortcut executes

### Transcript Files

Transcripts are saved as `.txt` files in your configured output folder with timestamps:
```
Transcript_2025-01-15_14-30-00.txt
```

## Settings

Access settings by clicking "Settings..." in the menu bar.

### Output Folder

Choose where transcript files are saved. Click "Browse..." to select a folder.

### Audio Sources

- **System Audio**: Captures audio from applications (e.g., Zoom, Teams)
- **Microphone**: Captures your voice input

Both can be enabled independently or together.

### Post-Recording Script

Optionally execute a shell script after each recording completes. Useful for:
- Uploading transcripts to cloud storage
- Processing transcripts with custom tools
- Triggering notifications

## Permissions

Olive requires the following macOS permissions:

### Microphone Access

**Required for**: Recording your voice during calls

**How to grant**:
1. System Settings → Privacy & Security → Microphone
2. Enable "Olive"

### Speech Recognition

**Required for**: Transcribing audio to text

**How to grant**:
1. System Settings → Privacy & Security → Speech Recognition
2. Enable "Olive"

The app will prompt for these permissions on first launch.

## Development

### Project Setup

1. Install Xcode 16+ from the Mac App Store

2. Clone the repository:
   ```bash
   git clone https://github.com/rygn-dev/olive-call-transcription.git
   cd olive-call-transcription
   ```

3. (Optional) Install XcodeGen:
   ```bash
   brew install xcodegen
   ```

4. Open `Olive.xcodeproj` in Xcode

5. Configure visual assets as described in [Installation](#installation)

### Building

Open the project in Xcode and build with ⌘B or:

```bash
xcodebuild build -scheme Olive -configuration Debug
```

### Project Structure

```
Olive/
├── CallTranscription/           # Main application code
│   ├── Audio/                   # Audio capture components
│   ├── Transcription/           # Speech recognition
│   ├── Settings/                # User preferences
│   ├── Views/                   # SwiftUI interface
│   ├── Storage/                 # File writing
│   ├── Permissions/             # Permission handlers
│   └── PostProcessing/          # Post-recording automation
├── CallTranscriptionTests/      # Test suite
├── architecture.md              # Detailed architecture documentation
├── project.yml                  # XcodeGen configuration
└── README.md                    # This file
```

## Architecture

Olive follows a modular architecture with clear separation of concerns:

- **Audio Layer**: Non-invasive audio capture using Core Audio taps and AVAudioEngine
- **Transcription Layer**: Apple Speech framework integration
- **Storage Layer**: File output and naming
- **UI Layer**: SwiftUI menu bar interface
- **Settings Layer**: UserDefaults persistence

For detailed architecture information, see [architecture.md](architecture.md).

## Testing

Olive uses **Test-Driven Development (TDD)** with comprehensive test coverage.

### Running Tests

```bash
xcodebuild test -scheme Olive -destination 'platform=macOS'
```

Or in Xcode: Product → Test (⌘U)

### Test Categories

- **Unit Tests**: Individual component testing
- **Integration Tests**: Cross-component workflows
- **End-to-End Tests**: Full recording scenarios
- **Performance Tests**: Long recording sessions

### TDD Workflow

All features follow strict TDD methodology:

1. Write failing tests first
2. Implement minimal code to pass tests
3. Refactor while keeping tests green

See [claude.md](claude.md) for TDD requirements.

## Contributing

Contributions are welcome! Please follow these guidelines:

### Development Workflow

1. Fork the repository
2. Create a feature branch from `dev`
3. **Write tests first** (TDD is mandatory)
4. Implement the feature
5. Ensure all tests pass
6. Submit a pull request to `dev` branch

### Code Standards

- **Swift 6** strict concurrency
- **SwiftUI** for all UI components
- **Test coverage required** for all new code
- **TDD methodology mandatory** - tests before implementation
- Follow existing code patterns and structure

### Pull Request Requirements

- All tests must pass
- New features must have test coverage
- Commit messages follow conventional format
- Code must pass all linting checks
- PR description includes rationale and test plan

## Troubleshooting

### Common Errors

#### "Olive needs permission to access the microphone"

**Solution**: Grant microphone permission in System Settings → Privacy & Security → Microphone

#### "Speech recognition unavailable"

**Solution**: Grant speech recognition permission in System Settings → Privacy & Security → Speech Recognition

#### "Recording failed to start"

**Possible causes**:
- Microphone already in use by another application
- Permissions not granted
- Audio device disconnected

**Solution**: Close other apps using the microphone, check permissions, verify audio devices

### Permission Issues

If permission dialogs don't appear:

1. Reset permissions:
   ```bash
   tccutil reset Microphone
   tccutil reset SpeechRecognition
   ```

2. Restart Olive and try recording again

### Audio Capture Issues

#### No audio recorded from system

**Solution**: Enable "System Audio" in Settings and ensure the target app (Zoom, etc.) is playing audio

#### Microphone not recording

**Solution**:
- Check microphone is selected in System Settings → Sound → Input
- Verify microphone permission granted to Olive
- Test microphone in another app first

#### Transcript file is empty

**Possible causes**:
- No audio detected during recording
- Speech recognition didn't detect any speech
- Output folder permission denied

**Solution**: Verify audio sources enabled, check output folder write permissions, try longer recording

### Build Errors

#### "Missing privacy descriptions in Info.plist"

**Solution**: The project validation should catch this. Ensure Info.plist contains:
- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`

#### "Visual assets not found"

**Solution**: Follow the manual asset configuration steps in [Installation](#installation)

### Getting Help

- Check existing [GitHub Issues](https://github.com/rygn-dev/olive-call-transcription/issues)
- Review [architecture.md](architecture.md) for technical details
- Open a new issue with:
  - macOS version
  - Xcode version
  - Full error message
  - Steps to reproduce

## License

See LICENSE file for details.

## Acknowledgments

Built using Apple's native Speech framework and Core Audio APIs.
