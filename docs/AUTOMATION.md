# Olive Automation Guide

Olive supports automation through **App Intents** (Shortcuts/Siri), **AppleScript**, and **x-callback-url**, allowing you to control recording, query status, and configure settings programmatically.

## Table of Contents

- [App Intents (Shortcuts)](#app-intents-shortcuts)
- [AppleScript](#applescript)
- [x-callback-url](#x-callback-url)
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

## x-callback-url

Olive supports the [x-callback-url specification](http://x-callback-url.com/) for URL-based automation, allowing integration with tools like Shortcuts, Keyboard Maestro, BetterTouchTool, and web applications.

### URL Scheme

All Olive automation URLs use the `olive://` scheme with the x-callback-url format:

```
olive://x-callback-url/<action>?<parameters>
```

### Actions

#### Start Recording

Starts a new recording session.

**URL Format:**
```
olive://x-callback-url/start?title=<title>&outputFolder=<path>&filenameTemplate=<template>
```

**Parameters:**
- `title` (optional): Recording title
- `outputFolder` (optional): Path to save transcripts (session-specific override, doesn't modify settings)
- `filenameTemplate` (optional): Filename template (session-specific override, doesn't modify settings)
- `x-success` (optional): Callback URL on success
- `x-error` (optional): Callback URL on error
- `x-cancel` (optional): Callback URL on cancel

**Example:**
```
olive://x-callback-url/start?title=Team%20Meeting
```

**With callbacks:**
```
olive://x-callback-url/start?title=Meeting&x-success=shortcuts://success&x-error=shortcuts://error
```

**Session Overrides:** The `outputFolder` and `filenameTemplate` parameters are session-specific overrides that apply only to the current recording. Your user settings remain unchanged, and subsequent manual recordings will use your configured preferences.

#### Stop Recording

Stops the current recording and returns the transcript file path.

**URL Format:**
```
olive://x-callback-url/stop?x-success=<callback>
```

**Returns:** Via x-success callback:
- `transcriptURL`: File path to saved transcript

**Example:**
```
olive://x-callback-url/stop?x-success=shortcuts://process-transcript
```

**Success callback receives:**
```
shortcuts://process-transcript?transcriptURL=file:///Users/name/Documents/transcript.txt
```

#### Pause Recording

Pauses the current recording session.

**URL Format:**
```
olive://x-callback-url/pause?x-success=<callback>&x-error=<callback>
```

**Example:**
```
olive://x-callback-url/pause?x-success=shortcuts://paused
```

#### Resume Recording

Resumes a paused recording session.

**URL Format:**
```
olive://x-callback-url/resume?x-success=<callback>&x-error=<callback>
```

**Example:**
```
olive://x-callback-url/resume?x-success=shortcuts://resumed
```

### Error Handling

When an error occurs, Olive calls the `x-error` callback with:
- `errorMessage`: Human-readable error description

**Example error callback:**
```
shortcuts://error?errorMessage=A%20recording%20session%20is%20already%20in%20progress
```

**Common errors:**
- `A recording session is already in progress` - Start called while recording
- `No recording session is currently active` - Stop/pause/resume called when not recording
- `Recording is already paused` - Pause called on paused recording
- `Recording is not currently paused` - Resume called on active recording
- `Invalid filename template` - Template contains `/` or `..`
- `Output folder is not writable` - Invalid or inaccessible folder path

### Allowed Callback Schemes

For security, Olive only permits these callback URL schemes:
- `shortcuts://` - macOS Shortcuts app
- `x-callback-url://` - Standard x-callback-url
- `http://` - Web callbacks (consider privacy implications)
- `https://` - Secure web callbacks (consider privacy implications)

Dangerous schemes like `applescript://`, `file://`, `javascript://`, and `data://` are explicitly blocked.

### Shortcuts Integration

#### Basic Start/Stop Workflow

1. Create new shortcut in Shortcuts app
2. Add "Open URL" action
3. Enter: `olive://x-callback-url/start?title=My%20Recording`
4. Add delay or other actions
5. Add "Open URL" action
6. Enter: `olive://x-callback-url/stop`

#### Advanced: Process Transcript After Recording

```
1. Open URL: olive://x-callback-url/start?title=Meeting&x-success=shortcuts://run-shortcut?name=RecordingStarted
2. [RecordingStarted shortcut runs]
3. Wait 30 minutes
4. Open URL: olive://x-callback-url/stop?x-success=shortcuts://run-shortcut?name=ProcessTranscript
5. [ProcessTranscript shortcut receives transcriptURL parameter]
6. Get File from transcriptURL
7. Upload to Dropbox / Send email / etc.
```

#### Complete Shortcut Example

**Meeting Recorder with Notification:**

```
Action 1: Open URL
URL: olive://x-callback-url/start?title=Daily%20Standup&x-success=shortcuts://recording-started&x-error=shortcuts://recording-failed

[If success callback received]
Action 2: Show Notification
Title: Recording Started
Body: Daily Standup recording in progress

Action 3: Wait 15 minutes

Action 4: Open URL
URL: olive://x-callback-url/stop?x-success=shortcuts://recording-stopped

[If success callback received with transcriptURL]
Action 5: Show Notification
Title: Recording Complete
Body: Transcript saved to [transcriptURL]
```

### Keyboard Maestro Integration

**Trigger: Hotkey (⌘⌥R)**
```
Action: Execute Shell Script
  open "olive://x-callback-url/start?title=Quick%20Recording"
```

**Stop Recording:**
```
Action: Execute Shell Script
  open "olive://x-callback-url/stop"
```

### BetterTouchTool Integration

Create custom Touch Bar buttons or gestures:

**Start Button:**
```
Trigger: Touch Bar Button
Action: Open URL
URL: olive://x-callback-url/start
```

### Web Integration

Web applications can trigger Olive recordings via custom URL schemes:

**HTML Link:**
```html
<a href="olive://x-callback-url/start?title=Web%20Meeting">Start Recording</a>
```

**JavaScript:**
```javascript
// Start recording from web app
window.location = 'olive://x-callback-url/start?title=Customer%20Call&x-success=https://myapp.com/recording-started';

// Stop and send transcript to web server
window.location = 'olive://x-callback-url/stop?x-success=https://myapp.com/process-transcript';
```

### Security Considerations

#### Path Validation

Output folder paths are validated for security:
- Must be within user home directory or temp directory
- Path traversal (`..`) is blocked
- Symlinks are not followed outside allowed directories

**Allowed:**
- `/Users/name/Documents/Transcripts`
- `~/Documents/Meetings`
- `/tmp/recordings`

**Blocked:**
- `/etc/passwd`
- `../../sensitive-data`
- `/System/Library/`

#### Filename Template Validation

Templates are validated to prevent directory traversal:
- Cannot contain `/` (path separators)
- Cannot contain `..` (parent directory references)
- Must be a valid filename pattern

**Allowed:**
- `Meeting_{YYYY-MM-DD}`
- `transcript_{HH-mm-ss}`

**Blocked:**
- `../other-folder/transcript`
- `folder/transcript`

#### Session-Specific Configuration

The `outputFolder` and `filenameTemplate` parameters are session-specific overrides that apply only to the current recording session without modifying your permanent user settings.

**Behavior:**
- Automation starts recording with `outputFolder=/tmp/recordings`
- This recording saves to `/tmp/recordings`
- User manually starts another recording → saves to configured settings location
- Your permanent settings remain unchanged

This design ensures automation workflows can use custom paths without affecting your normal recording preferences.

### URL Encoding

Always URL-encode parameter values:

**Correct:**
```
olive://x-callback-url/start?title=Team%20Meeting%20%232
```

**Incorrect:**
```
olive://x-callback-url/start?title=Team Meeting #2
```

**Common encodings:**
- Space: `%20`
- `/`: `%2F`
- `?`: `%3F`
- `&`: `%26`
- `#`: `%23`

### Testing URLs

Test x-callback-url automation from Terminal:

```bash
# Start recording
open "olive://x-callback-url/start?title=Test"

# Stop recording
open "olive://x-callback-url/stop"

# With callbacks (callbacks won't work from Terminal, but action will execute)
open "olive://x-callback-url/start?title=Test&x-success=shortcuts://success"
```

### API Reference

| Action | Parameters | Returns | Errors |
|--------|------------|---------|--------|
| start | title, outputFolder, filenameTemplate | - | alreadyRecording, invalidFilenameTemplate, pathOutsideAllowedDirectories |
| stop | - | transcriptURL | notRecording |
| pause | - | - | notRecording, alreadyPaused |
| resume | - | - | notRecording, notPaused |

### Comparison with Other Automation Methods

| Feature | x-callback-url | App Intents | AppleScript |
|---------|----------------|-------------|-------------|
| URL-based triggering | ✅ | ❌ | ❌ |
| Web integration | ✅ | ❌ | ❌ |
| Callbacks | ✅ | ❌ | ❌ |
| Return values | Via callbacks | ✅ Direct | ✅ Direct |
| Settings persistence | ✅ Session-only | Temporary | Temporary |
| Type safety | ❌ String-based | ✅ | ❌ |
| macOS version | All | 13.0+ | All |

**When to use x-callback-url:**
- Web-based automation
- Cross-app workflows requiring callbacks
- Tools that support URL schemes (Keyboard Maestro, BetterTouchTool)
- Remote triggering via URL

**When to use App Intents:**
- Native Shortcuts integration
- Siri voice commands
- Focus mode automation
- Type-safe parameter passing

**When to use AppleScript:**
- Complex scripting logic
- Terminal/cron automation
- SSH remote control
- Legacy tool integration

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
