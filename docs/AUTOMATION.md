# Olive Automation Guide

Olive supports automation through **App Intents** (Shortcuts/Siri) and **AppleScript**, allowing you to control recording, query status, and configure settings programmatically.

## Table of Contents

- [App Intents (Shortcuts)](#app-intents-shortcuts)
- [AppleScript](#applescript)
- [Common Use Cases](#common-use-cases)
- [Troubleshooting](#troubleshooting)

## App Intents (Shortcuts)

App Intents allow you to control Olive through the macOS Shortcuts app and Siri.

### Available Intents

#### Start Recording
Starts a new recording session with an optional title.

**Parameters:**
- `title` (optional): Title for the recording

**Example Shortcut:**
1. Open Shortcuts app
2. Add "Start Recording" action from Olive
3. Optionally set the title parameter
4. Run the shortcut

**Siri:**
```
"Hey Siri, start recording in Olive"
```

#### Stop Recording
Stops the current recording session and returns the transcript file path.

**Returns:** File path to the saved transcript (String)

**Example Shortcut:**
1. Add "Stop Recording" action from Olive
2. Use the returned file path in subsequent actions
3. Example: Open the file, share it, or process it

#### Get Recording Status
Queries the current recording status.

**Returns:** Status message including:
- Whether currently recording
- Elapsed time (if recording)
- Pause state

**Example Shortcut:**
1. Add "Get Recording Status" action
2. Use the result in conditional logic
3. Example: Only stop if currently recording

#### Configure Settings
Modify Olive settings programmatically.

**Parameters:**
- `outputFolder` (optional): Path to save transcripts
- `captureMicrophone` (optional): Enable/disable microphone
- `captureSystemAudio` (optional): Enable/disable system audio
- `postRecordingActionType` (optional): do nothing, script, or shortcut
- `shortcutIdentifier` (optional): ID of shortcut to run after recording
- `postRecordingScript` (optional): Path to script to run after recording

**Example Shortcut:**
1. Add "Configure Settings" action
2. Set desired parameters
3. Leave unneeded parameters empty (they won't be changed)

### Complete Workflow Example

**Timed Recording Shortcut:**
```
1. Start Recording (title: "Meeting Notes")
2. Wait 30 minutes
3. Stop Recording → Get file path
4. Show Notification "Recording saved to [file path]"
```

## AppleScript

AppleScript provides scripting access to Olive's recording features and settings.

### Commands

#### Start Recording
Starts a new recording session.

```applescript
tell application "Olive"
    start recording
end tell
```

**With title:**
```applescript
tell application "Olive"
    start recording with title "My Meeting"
end tell
```

#### Stop Recording
Stops the current recording and returns the file path.

```applescript
tell application "Olive"
    set transcriptPath to stop recording
    -- transcriptPath contains the file path as text
end tell
```

#### Get Status
Retrieves the current recording status as a record.

```applescript
tell application "Olive"
    set status to get status
    set isRec to isRecording of status
    set elapsed to elapsedTime of status
    set paused to isPaused of status
end tell
```

### Properties

Query or modify app properties directly:

```applescript
tell application "Olive"
    -- Get recording state
    set recording to isRecording
    set time to elapsedTime
    set paused to isPaused

    -- Get settings
    set folder to outputFolder
    set mic to captureMicrophone
    set sysAudio to captureSystemAudio

    -- Set settings
    set outputFolder to "~/Documents/MyTranscripts"
    set captureMicrophone to true
    set captureSystemAudio to false
end tell
```

### Complete Workflow Example

**Scheduled Recording:**
```applescript
tell application "Olive"
    -- Configure settings
    set outputFolder to "~/Documents/Meetings"
    set captureMicrophone to true
    set captureSystemAudio to true

    -- Start recording
    start recording with title "Team Standup"

    -- Wait 15 minutes (900 seconds)
    delay 900

    -- Stop and get file path
    set transcriptFile to stop recording

    -- Display notification
    display notification "Transcript saved" with title "Olive" subtitle transcriptFile
end tell
```

### Running from Terminal

Execute AppleScript from command line using `osascript`:

```bash
osascript -e 'tell application "Olive" to start recording'
```

**From a file:**
```bash
osascript my_script.scpt
```

## Common Use Cases

### 1. Calendar Integration
Automatically start/stop recording for calendar events:

**Shortcuts Automation:**
1. Create automation triggered by calendar event
2. At event start: Run "Start Recording" with event title
3. At event end: Run "Stop Recording"

### 2. Focus Mode Integration
Start recording when entering Focus mode:

**Shortcuts Automation:**
1. Trigger: Focus mode activated
2. Action: Start Recording (title: Focus mode name)

### 3. SSH/Remote Control
Control recording remotely via SSH:

```bash
ssh user@mac 'osascript -e "tell application \"Olive\" to start recording"'
```

### 4. Keyboard Maestro Integration
Create keyboard shortcuts to control recording:

**Keyboard Maestro Macro:**
1. Trigger: Hotkey (e.g., ⌘⌥R)
2. Action: Execute AppleScript → "tell application \"Olive\" to start recording"

### 5. Time-Based Automation
Schedule recording windows:

**Cron + AppleScript:**
```bash
# Start recording at 9 AM weekdays
0 9 * * 1-5 osascript -e 'tell application "Olive" to start recording'

# Stop at 5 PM weekdays
0 17 * * 1-5 osascript -e 'tell application "Olive" to stop recording'
```

### 6. Conditional Recording
Only record when specific conditions are met:

**Shortcuts Example:**
```
1. Get Recording Status
2. If not recording:
   3. Start Recording
4. Otherwise:
   5. Show notification "Already recording"
```

## Troubleshooting

### App Intents Not Appearing in Shortcuts

1. Ensure Olive is installed in /Applications
2. Open Olive at least once
3. Restart Shortcuts app
4. Search for "Olive" in Shortcuts action browser

### AppleScript "Application isn't running" Error

1. Ensure Olive is running
2. Check app name in Scripts → Applications
3. Try fully qualified path:
   ```applescript
   tell application "/Applications/Olive.app"
   ```

### Permission Errors

1. Check System Settings → Privacy & Security → Automation
2. Ensure Shortcuts/Script Editor has permission to control Olive
3. Grant permission when prompted

### Recording Doesn't Start

1. Check microphone permissions (System Settings → Privacy & Security)
2. Verify speech recognition permissions
3. Ensure no other recording is in progress
4. Check Console app for error messages from Olive

### File Path Not Returned

1. Ensure recording was actually started before stopping
2. Check that recording completed successfully
3. Verify output folder exists and is writable

## Advanced Topics

### Error Handling in Shortcuts

Always check recording status before stopping:
```
1. Get Recording Status
2. If "Recording in progress":
   3. Stop Recording
4. Otherwise:
   5. Show Alert "No active recording"
```

### Multiple Shortcuts Integration

Chain Olive intents with other app actions:
```
1. Start Recording (Olive)
2. Open Zoom
3. Wait 1 hour
4. Close Zoom
5. Stop Recording (Olive) → Get file path
6. Upload file to Dropbox
```

### Script-Based Processing

Combine with post-recording script for automated processing:
```
1. Configure Settings (postRecordingActionType: script)
2. Configure Settings (postRecordingScript: "~/Scripts/process.sh")
3. Start Recording
4. [Recording happens]
5. Stop Recording
6. [Script automatically runs on transcript]
```

## API Reference

### App Intents

| Intent | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| StartRecordingIntent | title: String? | - | Start recording |
| StopRecordingIntent | - | String | Stop and get file path |
| GetRecordingStatusIntent | - | String | Get status message |
| ConfigureSettingsIntent | Various | - | Update settings |

### AppleScript Commands

| Command | Parameters | Returns | Description |
|---------|------------|---------|-------------|
| start recording | title: text (optional) | boolean | Start recording |
| stop recording | - | text | Stop and get file path |
| get status | - | record | Get full status |

### AppleScript Properties

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| isRecording | boolean | read-only | Currently recording? |
| elapsedTime | text | read-only | Elapsed time string |
| isPaused | boolean | read-only | Recording paused? |
| outputFolder | text | read-write | Transcript folder path |
| captureMicrophone | boolean | read-write | Microphone enabled? |
| captureSystemAudio | boolean | read-write | System audio enabled? |

## Contributing

When adding new automation features:
1. Add corresponding App Intent
2. Add corresponding AppleScript command/property
3. Update this documentation with examples
4. Test in both Shortcuts and Script Editor

See [CONTRIBUTING.md](../CONTRIBUTING.md) for detailed guidelines.

## Support

For issues with automation:
1. Check this guide's Troubleshooting section
2. Review Console app for error messages
3. File an issue on GitHub with:
   - macOS version
   - Olive version
   - Exact automation code/shortcut
   - Error messages from Console

## Version Compatibility

- App Intents: Requires macOS 13.0+
- AppleScript: All macOS versions supported by Olive
- Siri: Requires macOS 13.0+ for App Intents support
