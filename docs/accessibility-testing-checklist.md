# VoiceOver Accessibility Testing Checklist

This document provides comprehensive testing procedures for verifying VoiceOver accessibility support in Olive (Meeting Recorder). Use this checklist when making changes to UI components or before releasing new versions.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Menu Bar Icon](#menu-bar-icon)
3. [MenuBarView (Dropdown Menu)](#menubarview-dropdown-menu)
4. [ConsentDialogView](#consentdialogview)
5. [SettingsView](#settingsview)
6. [Keyboard Navigation](#keyboard-navigation)
7. [Regression Testing](#regression-testing)

## Prerequisites

### Enabling VoiceOver

1. **Enable VoiceOver**: Press `Cmd+F5` or go to System Settings → Accessibility → VoiceOver
2. **Quick Navigation**: Ensure VoiceOver is using standard navigation (not Quick Nav)
3. **Verbosity**: Set VoiceOver verbosity to at least "Medium" for hints
4. **Test Environment**: Test on a clean install or with UserDefaults cleared for first-launch behavior

### VoiceOver Navigation Basics

- **Navigate Forward**: `VO+Right Arrow` (VO = Control+Option)
- **Navigate Backward**: `VO+Left Arrow`
- **Activate**: `VO+Space`
- **Read Hint**: `VO+Shift+H`
- **Navigate by Headers**: `VO+Cmd+H`

## Menu Bar Icon

**Purpose**: Verify the menu bar icon announces current recording state.

### Test Cases

#### 1. Not Recording State

- **Action**: Start app with no active recording
- **Expected**: Icon should announce "Meeting Recorder - Not Recording"
- **Visual**: Gray stop circle icon

#### 2. Recording State

- **Action**: Start a recording
- **Expected**:
  - Icon should announce "Meeting Recorder - Recording"
  - Value should include elapsed time (e.g., "00:15")
- **Visual**: Red record circle icon

#### 3. Paused State

- **Action**: Start recording, then pause
- **Expected**:
  - Icon should announce "Meeting Recorder - Paused"
  - Value should include elapsed time when paused
- **Visual**: Orange pause circle icon

#### 4. Dynamic Updates

- **Action**: Navigate through states (not recording → recording → paused → recording → stopped)
- **Expected**: Label updates reflect current state each time icon is focused

## MenuBarView (Dropdown Menu)

**Purpose**: Verify all menu controls are accessible and announce state correctly.

### Test Cases

#### 1. Start Recording Button

- **When**: Not recording
- **Navigate to button**: Should announce "Start Recording, button"
- **Read hint** (`VO+Shift+H`): Should announce "Begins a new recording session. Keyboard shortcut: Command Shift R"
- **Activate**: Should start recording
- **Announcement**: Should hear "Recording started" announcement

#### 2. Pause Recording Button

- **When**: Recording and not paused
- **Navigate to button**: Should announce "Pause Recording, button"
- **Read hint**: Should announce "Pauses the current recording. Keyboard shortcut: Command Shift P"
- **Activate**: Should pause recording
- **Announcement**: Should hear "Recording paused" announcement

#### 3. Resume Recording Button

- **When**: Recording and paused
- **Navigate to button**: Should announce "Resume Recording, button"
- **Read hint**: Should announce "Resumes the paused recording. Keyboard shortcut: Command Shift R"
- **Activate**: Should resume recording
- **Announcement**: Should hear "Recording resumed" announcement

#### 4. Stop Recording Button

- **When**: Recording (paused or active)
- **Navigate to button**: Should announce "Stop Recording, button"
- **Read hint**: Should announce "Stops the recording and saves the transcript. Keyboard shortcut: Command Shift S"
- **Activate**: Should stop recording
- **Announcement**: Should hear "Recording stopped" announcement

#### 5. Recording Status Display

- **When**: Recording and active
- **Navigate to status**: Should announce "Recording duration" with value showing elapsed time (e.g., "Recording: 00:42")
- **Updates**: Should NOT announce every second (verify silence between manual navigations)

#### 6. Paused Status Display

- **When**: Recording and paused
- **Navigate to status**: Should announce "Paused duration" with value showing elapsed time (e.g., "Paused: 00:42")
- **Color**: Text should appear orange for visual users

#### 7. Settings Link

- **Navigate to link**: Should announce "Settings, link"
- **Read hint**: Should announce "Opens application settings. Keyboard shortcut: Command Comma"
- **Activate**: Should open Settings window
- **Keyboard shortcut**: `Cmd+,` should also work

#### 8. Quit Button

- **Navigate to button**: Should announce "Quit, button"
- **Read hint**: Should announce "Quits the application. Keyboard shortcut: Command Q"
- **Activate**: Should quit the application
- **Keyboard shortcut**: `Cmd+Q` should also work

### Navigation Flow

- **Expected order**: Start/Pause/Resume → Stop (if recording) → [Divider] → Status (if recording) → [Divider] → Settings → [Divider] → Quit
- **Conditional visibility**: Verify buttons appear/disappear based on state
- **No orphaned elements**: All elements should be reachable and have proper labels

## ConsentDialogView

**Purpose**: Verify first-launch consent dialog is fully accessible.

### Test Cases

#### 1. Dialog Title

- **Navigate to title**: Should announce as header "Important: Recording Consent Requirements, heading level 2"
- **Navigation**: `VO+Cmd+H` should jump to this header

#### 2. Body Text

- **Navigate to body**: Should announce "Legal requirements" followed by combined bullet points
- **Content**: Should read all 4 bullet points as one cohesive unit:
  - "Recording laws vary significantly by jurisdiction"
  - "Some regions require only one party's consent"
  - "Other regions require all parties to consent"
  - "International laws differ dramatically"
- **Emphasis**: VoiceOver should convey emphasis on "You are solely responsible" text

#### 3. Checkbox

- **Navigate to checkbox**: Should announce "Do not remind me again, unchecked, checkbox"
- **Read hint**: Should announce "When checked, this consent dialog will not be shown again on future launches"
- **Activate**: Should toggle checkbox state
- **State change**: Should announce "checked" or "unchecked" after toggling

#### 4. Quit Button

- **Navigate to button**: Should announce "Quit, button"
- **Read hint**: Should announce "Quits the application without accepting consent requirements. Keyboard shortcut: Escape"
- **Keyboard shortcut**: `Escape` should activate quit
- **Result**: Application should terminate

#### 5. I Understand Button

- **Navigate to button**: Should announce "I Understand, default button" or "I Understand, button"
- **Read hint**: Should announce "Acknowledges consent requirements and dismisses this dialog. Keyboard shortcut: Return"
- **Keyboard shortcut**: `Return` should activate acceptance
- **Result**: Dialog should dismiss

### Navigation Flow

- **Expected order**: Title → Body text → Checkbox → Quit → I Understand
- **Modal behavior**: Should not be able to access other UI while dialog is open
- **Focus trap**: Tab/arrow navigation should cycle within dialog

### Behavioral Tests

#### First Launch
- **Clear UserDefaults**: `defaults delete dev.rygn.Olive`
- **Launch app**: Dialog should appear
- **Accept**: Check "Do not remind me again" and click "I Understand"
- **Verify**: Dialog should not appear on next launch

#### Subsequent Launches
- **Launch app**: Dialog should not appear if previously dismissed with checkbox
- **Manual reset**: Dialog should appear again after clearing UserDefaults

## SettingsView

**Purpose**: Verify all settings controls are accessible across 4 sections.

### Test Cases

#### Output Section

##### 1. Section Header
- **Navigate to header**: `VO+Cmd+H` should find "Output, heading level 1"
- **Announcement**: Should announce as header

##### 2. Output Folder Text Field
- **Navigate to field**: Should announce "Output Folder, text field"
- **Read hint**: Should announce "Path where transcripts will be saved"
- **Value**: Should read current path value
- **Edit**: Should allow text entry

##### 3. Browse Button
- **Navigate to button**: Should announce "Browse for Output Folder, button"
- **Read hint**: Should announce "Opens a dialog to select where transcripts will be saved"
- **Activate**: Should open folder picker dialog

##### 4. Save Original Audio Toggle
- **Navigate to toggle**: Should announce "Save Original Audio File, [checked/unchecked], checkbox"
- **Read hint**: Should announce "When enabled, saves original audio recordings in M4A format alongside transcripts"
- **Activate**: Should toggle state

##### 5. Helper Text
- **Navigate**: Helper text should NOT be announced separately (marked as hidden)
- **Information**: All info should be in control hints

#### Audio Sources Section

##### 1. Section Header
- **Navigate**: Should announce "Audio Sources, heading level 1"

##### 2. Capture System Audio Toggle
- **Navigate to toggle**: Should announce "Capture System Audio, [checked/unchecked], checkbox"
- **Read hint**: Should announce "Records audio from applications like Zoom, Teams, and other system sounds"
- **Activate**: Should toggle state

##### 3. Capture Microphone Toggle
- **Navigate to toggle**: Should announce "Capture Microphone Input, [checked/unchecked], checkbox"
- **Read hint**: Should announce "Records audio from your microphone. At least one audio source must be enabled"
- **Activate**: Should toggle state
- **Context**: Hint includes requirement that at least one source must be enabled

##### 4. Helper Text
- **Navigate**: Should NOT be announced separately

#### Silence Detection Section

##### 1. Section Header
- **Navigate**: Should announce "Silence Detection, heading level 1"

##### 2. Auto-pause Picker
- **Navigate to picker**: Should announce "Auto-pause after silence, pop up button"
- **Read hint**: Should announce "Automatically pause recording after continuous silence. Recording will auto-resume when audio is detected"
- **Activate**: Should open dropdown menu
- **Options**: Should list all threshold options (Never, 3 seconds, 5 seconds, etc.)

##### 3. Helper Text
- **Navigate**: Should NOT be announced separately

#### Post-Recording Section

##### 1. Section Header
- **Navigate**: Should announce "Post-Recording Action, heading level 1"

##### 2. Action Picker (Radio Group)
- **Navigate to picker**: Should announce "After recording, radio group"
- **Read hint**: Should announce "Choose what happens when recording stops: do nothing, run a script, or run a shortcut"
- **Options**: Should list 3 radio options: "Do nothing", "Run a script", "Run a shortcut"
- **Selection**: Should announce current selection

##### 3. Script Path Field (Conditional)
- **When**: "Run a script" is selected
- **Navigate to field**: Should announce "Shell Script Path, text field"
- **Read hint**: Should announce "Path to shell script that will receive the transcript file path as its first argument"

##### 4. Script Browse Button (Conditional)
- **When**: "Run a script" is selected
- **Navigate to button**: Should announce "Browse for Script, button"
- **Read hint**: Should announce "Opens a dialog to select a shell script to run after recording"

##### 5. Shortcut Picker (Conditional)
- **When**: "Run a shortcut" is selected
- **Navigate to picker**: Should announce "Shortcut, pop up button"
- **Read hint**: Should announce "Choose a shortcut that will receive the transcript file path as input"
- **Options**: Should list available shortcuts

##### 6. Loading Indicator (Conditional)
- **When**: Shortcuts are loading
- **Navigate**: Should announce "Loading shortcuts"
- **Visual**: Progress indicator should be visible

##### 7. Helper Texts (Conditional)
- **Navigate**: Should NOT be announced separately
- **All variations**: Script helper, shortcut helper, no shortcuts message all hidden

### Navigation Flow

- **Section order**: Output → Audio Sources → Silence Detection → Post-Recording
- **Header navigation**: `VO+Cmd+H` should cycle through 4 section headers
- **Tab order**: Should flow logically within each section
- **Conditional controls**: Should only be accessible when their conditions are met

## Keyboard Navigation

**Purpose**: Verify all keyboard shortcuts work and are documented in hints.

### Global Shortcuts

| Action | Shortcut | Where | Verification |
|--------|----------|-------|--------------|
| Start/Resume Recording | `Cmd+Shift+R` | MenuBarView | Start when not recording, resume when paused |
| Pause Recording | `Cmd+Shift+P` | MenuBarView | Pause active recording |
| Stop Recording | `Cmd+Shift+S` | MenuBarView | Stop recording and save |
| Open Settings | `Cmd+,` | MenuBarView | Open settings window |
| Quit App | `Cmd+Q` | MenuBarView | Quit application |
| Cancel Dialog | `Escape` | ConsentDialogView | Quit from consent dialog |
| Accept Dialog | `Return` | ConsentDialogView | Accept consent dialog |

### Testing Procedure

1. **Verify shortcuts work**: Test each shortcut in appropriate context
2. **Verify hints**: Read hint on each control and verify shortcut is documented
3. **Verify conflicts**: Ensure no conflicts with system shortcuts
4. **Verify consistency**: Same action should use same shortcut across contexts (e.g., `Cmd+Shift+R` for both start and resume)

## Regression Testing

**Purpose**: Ensure accessibility remains functional after code changes.

### Before Each Release

Run through this complete checklist and verify:
- [ ] All unit tests pass (MenuBarView, SettingsView, ConsentDialogView)
- [ ] Menu bar icon announces correctly in all states
- [ ] MenuBarView controls announce labels and hints
- [ ] MenuBarView state announcements work (start/pause/resume/stop)
- [ ] ConsentDialogView is fully accessible
- [ ] SettingsView all controls have labels and hints
- [ ] SettingsView section headers are marked as headers
- [ ] SettingsView conditional controls are accessible when shown
- [ ] All keyboard shortcuts work as documented
- [ ] No regressions in existing functionality

### After UI Changes

When modifying any SwiftUI view:
1. **Run unit tests**: `xcodebuild test -scheme Olive`
2. **Manual VoiceOver test**: Test the modified view(s) from this checklist
3. **Verify announcements**: If state changes are involved, verify announcements still work
4. **Check labels**: Ensure new controls have both labels and hints
5. **Update tests**: Add tests for new accessibility attributes

### Common Issues to Check

- [ ] Controls without labels (announced as "button" or "text field" only)
- [ ] Controls without hints (user doesn't know what they do)
- [ ] Helper text not hidden (duplicate information)
- [ ] Section headers without header trait (can't navigate by headings)
- [ ] Conditional controls inaccessible (not properly shown/hidden)
- [ ] Missing keyboard shortcuts in hints
- [ ] Announcements firing too frequently (every second during recording)
- [ ] State announcements not working (onChange not triggered)

## Automated Testing

### Running Unit Tests

```bash
# Run all tests
xcodebuild test -scheme Olive -destination 'platform=macOS'

# Run specific test suite
xcodebuild test -scheme Olive -destination 'platform=macOS' \
  -only-testing:CallTranscriptionTests/MenuBarViewAccessibilityTests

# Run specific test
xcodebuild test -scheme Olive -destination 'platform=macOS' \
  -only-testing:CallTranscriptionTests/MenuBarViewAccessibilityTests/testStartRecordingButtonHasAccessibilityLabel
```

### Test Coverage

- **MenuBarViewAccessibilityTests**: 27 tests
- **SettingsViewAccessibilityTests**: 30 tests
- **ConsentDialogViewAccessibilityTests**: 19 tests
- **Total**: 76 automated accessibility tests

## Resources

### Apple Documentation

- [Accessibility for macOS](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [VoiceOver Testing](https://developer.apple.com/library/archive/technotes/TestingAccessibilityOfiOSApps/TestAccessibilityonYourDevicewithVoiceOver/TestAccessibilityonYourDevicewithVoiceOver.html)
- [SwiftUI Accessibility Modifiers](https://developer.apple.com/documentation/swiftui/view-accessibility)

### Internal Documentation

- `CLAUDE.md`: Project development guidelines (TDD methodology)
- `README.md`: Project overview and accessibility features

## Version History

- **v1.0** (2025-01-18): Initial accessibility testing checklist for Issue #45
  - MenuBarView accessibility
  - SettingsView accessibility
  - ConsentDialogView accessibility
  - Menu bar icon accessibility
