# Olive: Call Transcription

Olive is a macOS application for recording and transcribing calls with automatic silence detection and pause functionality.

## Development Setup

### Visual Assets Configuration

After cloning the repository, you need to manually add visual assets to the Xcode project (XcodeGen doesn't fully support Icon Composer packages):

1. Open `Olive.xcodeproj` in Xcode
2. Drag `CallTranscription/icon.icon` into the project navigator
3. Drag `CallTranscription/Assets.xcassets` into the project navigator
4. Verify both are listed in the target's "Copy Bundle Resources" build phase
5. Build and run to verify assets load correctly

**Note:** Do not run `xcodegen generate` after manually adding assets, as it will remove them. The `project.yml` file documents the intended resource configuration for future XcodeGen updates.
