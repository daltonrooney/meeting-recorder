import XCTest

/// UI tests for SettingsView to verify user interface behavior and state management
final class SettingsViewUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // Give the app time to fully launch
        sleep(1)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Output Section Tests

    func testOutputFolderTextFieldExists() throws {
        // Given: Settings window is open
        try openSettings()

        // When: Looking for output folder text field
        let outputFolderTextField = app.textFields["outputFolderTextField"]

        // Then: Text field should exist and be visible
        XCTAssertTrue(outputFolderTextField.exists, "Output folder text field should exist")
    }

    func testOutputFolderBrowseButtonExists() throws {
        // Given: Settings window is open
        try openSettings()

        // When: Looking for browse button for output folder
        let browseButton = app.buttons["outputFolderBrowseButton"]

        // Then: Button should exist
        XCTAssertTrue(browseButton.exists, "Output folder browse button should exist")
    }

    func testSaveOriginalAudioToggleExists() throws {
        // Given: Settings window is open
        try openSettings()

        // When: Looking for save original audio toggle
        let saveAudioToggle = app.checkBoxes["saveOriginalAudioToggle"]

        // Then: Toggle should exist
        XCTAssertTrue(saveAudioToggle.exists, "Save original audio toggle should exist")
    }

    // MARK: - Audio Sources Section Tests

    func testSystemAudioToggleExists() throws {
        // Given: Settings window is open
        try openSettings()

        // When: Looking for system audio toggle
        let systemAudioToggle = app.checkBoxes["captureSystemAudioToggle"]

        // Then: Toggle should exist
        XCTAssertTrue(systemAudioToggle.exists, "System audio toggle should exist")
    }

    func testMicrophoneToggleExists() throws {
        // Given: Settings window is open
        try openSettings()

        // When: Looking for microphone toggle
        let micToggle = app.checkBoxes["captureMicrophoneToggle"]

        // Then: Toggle should exist
        XCTAssertTrue(micToggle.exists, "Microphone toggle should exist")
    }

    // MARK: - Post-Recording Section Tests

    func testPostRecordingActionPickerExists() throws {
        // Given: Settings window is open
        try openSettings()

        // When: Looking for post-recording action picker
        let actionPicker = app.radioGroups["postRecordingActionPicker"]

        // Then: Picker should exist
        XCTAssertTrue(actionPicker.exists, "Post-recording action picker should exist")
    }

    func testPostRecordingActionOptionsExist() throws {
        // Given: Settings window is open
        try openSettings()

        // When: Looking for action options
        let doNothingOption = app.radioButtons["postRecordingActionDoNothing"]
        let scriptOption = app.radioButtons["postRecordingActionScript"]
        let shortcutOption = app.radioButtons["postRecordingActionShortcut"]

        // Then: All three options should exist
        XCTAssertTrue(doNothingOption.exists, "Do nothing option should exist")
        XCTAssertTrue(scriptOption.exists, "Script option should exist")
        XCTAssertTrue(shortcutOption.exists, "Shortcut option should exist")
    }

    func testScriptPathTextFieldAppearsWhenScriptSelected() throws {
        // Given: Settings window is open
        try openSettings()

        // When: Selecting script option
        let scriptOption = app.radioButtons["postRecordingActionScript"]
        scriptOption.click()

        // Then: Script path text field should appear
        let scriptPathTextField = app.textFields["postRecordingScriptTextField"]
        XCTAssertTrue(scriptPathTextField.waitForExistence(timeout: 1), "Script path text field should appear when script option is selected")
    }

    func testShortcutPickerAppearsWhenShortcutSelected() throws {
        // Given: Settings window is open
        try openSettings()

        // When: Selecting shortcut option
        let shortcutOption = app.radioButtons["postRecordingActionShortcut"]
        shortcutOption.click()

        // Then: Shortcut picker or loading indicator should appear
        // Check for either the loading indicator or the shortcut picker
        let loadingIndicator = app.progressIndicators["shortcutsLoadingIndicator"]
        let shortcutPicker = app.popUpButtons["shortcutPicker"]

        let exists = loadingIndicator.waitForExistence(timeout: 1) || shortcutPicker.waitForExistence(timeout: 2)
        XCTAssertTrue(exists, "Shortcut picker or loading indicator should appear when shortcut option is selected")
    }

    // MARK: - Helper Methods

    /// Opens the Settings window
    /// - Throws: XCTestError if Settings cannot be opened
    private func openSettings() throws {
        // For a menu bar app, we need to click the menu bar item and then Settings
        // This assumes the app has a menu bar presence

        // Try to find and click Settings menu item or button
        // Note: The exact implementation depends on how the Settings window is accessed in the app
        // This is a placeholder - may need adjustment based on actual app structure

        let settingsButton = app.buttons["Settings"]
        let settingsMenuItem = app.menuItems["Settings..."]

        if settingsButton.exists {
            settingsButton.click()
        } else if settingsMenuItem.exists {
            settingsMenuItem.click()
        } else {
            // If neither exists, settings might already be open or we need a different approach
            // For now, assume settings window is accessible
        }

        // Wait for settings window to appear
        let settingsWindow = app.windows.firstMatch
        let exists = settingsWindow.waitForExistence(timeout: 3)

        if !exists {
            throw XCTestError(.failureWhileWaiting, userInfo: [
                "description": "Settings window did not appear within timeout"
            ])
        }
    }
}
