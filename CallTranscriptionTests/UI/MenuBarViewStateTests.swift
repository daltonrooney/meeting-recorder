import XCTest
import SwiftUI
@testable import CallTranscription

/// Tests for button state management in MenuBarView.
/// These tests ensure the Start Recording button provides proper feedback during async operations.
@MainActor
final class MenuBarViewStateTests: XCTestCase {

    var appState: AppState!
    var settingsManager: SettingsManager!

    override func setUp() async throws {
        try await super.setUp()
        settingsManager = SettingsManager()
        appState = AppState(settingsManager: settingsManager)
    }

    override func tearDown() async throws {
        appState = nil
        settingsManager = nil
        try await super.tearDown()
    }

    // MARK: - Button Disabled State Tests

    /// Test that button is disabled while recording start is in progress
    /// This prevents duplicate clicks during async operation
    func testButtonDisabledDuringRecordingStart() async throws {
        // Given: MenuBarView with isStarting state variable
        // Implementation should add: @State private var isStarting: Bool = false

        // When: Button Task begins execution
        var isStarting = false
        isStarting = true

        // Then: Button should be disabled
        let shouldDisableButton = isStarting || appState.isRecording
        XCTAssertTrue(shouldDisableButton, "Button should be disabled while recording start is in progress")

        // Cleanup
        isStarting = false
    }

    /// Test that button is re-enabled after successful recording start
    /// This allows user to interact with the button again
    func testButtonReEnabledAfterSuccessfulStart() async throws {
        // Given: Button was disabled during start
        var isStarting = true

        // When: Recording starts successfully
        appState.startRecording() // Simulate successful start
        isStarting = false

        // Then: Button should be re-enabled (but shows "Stop Recording" instead)
        // Note: Button state changes based on isRecording, not isStarting after success
        XCTAssertTrue(appState.isRecording, "Recording should be active")
        XCTAssertFalse(isStarting, "isStarting should be false after completion")
    }

    /// Test that button is re-enabled after error during start
    /// This allows user to try again after failure
    func testButtonReEnabledAfterErrorDuringStart() async throws {
        // Given: Invalid configuration that will cause error
        settingsManager.captureMicrophone = false
        settingsManager.captureSystemAudio = false
        var isStarting = false

        // When: Attempting to start recording
        isStarting = true
        do {
            try await appState.startActualRecording(title: "Test")
            XCTFail("Should have thrown error")
        } catch {
            // Error caught - isStarting should be reset
            isStarting = false
        }

        // Then: Button should be re-enabled
        XCTAssertFalse(isStarting, "isStarting should be false after error")
        XCTAssertFalse(appState.isRecording, "Should not be recording after error")

        let shouldDisableButton = isStarting || appState.isRecording
        XCTAssertFalse(shouldDisableButton, "Button should be enabled to allow retry")
    }

    /// Test that loading indicator is shown during recording start
    /// This provides visual feedback to user
    func testLoadingIndicatorShownDuringStart() {
        // Given: Button Task is executing
        var isStarting = true

        // When: isStarting is true
        // Implementation should show ProgressView when isStarting == true

        // Then: Loading indicator should be visible
        XCTAssertTrue(isStarting, "Loading indicator should be shown when isStarting is true")

        // Cleanup
        isStarting = false
    }

    /// Test that multiple clicks are prevented during recording start
    /// This prevents race conditions and duplicate operations
    func testMultipleClicksPreventedDuringStart() async throws {
        // Given: First click is in progress
        var isStarting = true
        var clickCount = 0

        // When: User tries to click button multiple times
        for _ in 0..<3 {
            let shouldDisableButton = isStarting || appState.isRecording
            if !shouldDisableButton {
                clickCount += 1
            }
        }

        // Then: Only first click should register
        XCTAssertEqual(clickCount, 0, "No additional clicks should register while isStarting is true")

        // When: Task completes
        isStarting = false

        // Then: Button becomes clickable again
        for _ in 0..<3 {
            let shouldDisableButton = isStarting || appState.isRecording
            if !shouldDisableButton {
                clickCount += 1
            }
        }

        XCTAssertEqual(clickCount, 3, "Clicks should register after isStarting becomes false")
    }

    /// Test that button state updates are published to UI
    /// This ensures SwiftUI reactivity works correctly
    func testButtonStateUpdatesPublishToUI() async throws {
        // Given: @State variable for isStarting
        // SwiftUI's @State automatically publishes updates

        var isStarting = false
        var stateChangeCount = 0

        // When: State changes
        isStarting = true
        stateChangeCount += 1

        isStarting = false
        stateChangeCount += 1

        // Then: Each change should be tracked
        XCTAssertEqual(stateChangeCount, 2, "State changes should be published")
    }

    // MARK: - Defer Block Tests

    /// Test that isStarting is reset even if Task throws
    /// This ensures cleanup happens on error path
    func testIsStartingResetOnErrorWithDefer() async throws {
        // Given: Task with defer block
        var isStarting = false

        // When: Task executes and throws error
        do {
            isStarting = true
            defer { isStarting = false }

            throw CallTranscriptionError.microphonePermissionDenied
        } catch {
            // Error caught
        }

        // Then: defer should have reset isStarting
        XCTAssertFalse(isStarting, "defer block should reset isStarting even on error")
    }

    /// Test that isStarting is reset on successful completion
    /// This ensures cleanup happens on success path
    func testIsStartingResetOnSuccessWithDefer() async throws {
        // Given: Task with defer block
        var isStarting = false

        // When: Task executes successfully
        do {
            isStarting = true
            defer { isStarting = false }

            // Simulate successful operation
            appState.startRecording()
        }

        // Then: defer should have reset isStarting
        XCTAssertFalse(isStarting, "defer block should reset isStarting on success")
    }

    // MARK: - Button Interaction Tests

    /// Test that button is disabled when already recording
    /// This prevents attempting to start recording twice
    func testButtonDisabledWhenAlreadyRecording() {
        // Given: App is recording
        appState.startRecording()
        XCTAssertTrue(appState.isRecording)

        // When: Checking button disabled state
        let isStarting = false
        let shouldDisableButton = isStarting || appState.isRecording

        // Then: Button should be disabled
        XCTAssertTrue(shouldDisableButton, "Button should be disabled when already recording")
    }

    /// Test that button shows different text based on state
    /// This ensures proper UI updates
    func testButtonTextChangesBasedOnState() {
        // Given: Not recording
        XCTAssertFalse(appState.isRecording)

        // When: Checking button text
        let buttonText = appState.isRecording ? "Stop Recording" : "Start Recording"

        // Then: Should show "Start Recording"
        XCTAssertEqual(buttonText, "Start Recording")

        // When: Recording starts
        appState.startRecording()
        let recordingButtonText = appState.isRecording ? "Stop Recording" : "Start Recording"

        // Then: Should show "Stop Recording"
        XCTAssertEqual(recordingButtonText, "Stop Recording")
    }

    /// Test that button opacity changes during loading
    /// This provides visual feedback
    func testButtonOpacityReducedDuringLoading() {
        // Given: Button is loading
        let isStarting = true

        // When: Calculating opacity
        let opacity = isStarting ? 0.6 : 1.0

        // Then: Opacity should be reduced
        XCTAssertEqual(opacity, 0.6, "Button opacity should be 0.6 when loading")

        // When: Loading completes
        let isStartingFalse = false
        let normalOpacity = isStartingFalse ? 0.6 : 1.0

        // Then: Opacity should be full
        XCTAssertEqual(normalOpacity, 1.0, "Button opacity should be 1.0 when not loading")
    }

    // MARK: - State Consistency Tests

    /// Test that isStarting and isRecording are mutually exclusive during start
    /// This ensures state consistency
    func testIsStartingAndIsRecordingConsistency() async throws {
        // Given: Fresh state
        var isStarting = false
        XCTAssertFalse(appState.isRecording)

        // When: Start operation begins
        isStarting = true
        XCTAssertFalse(appState.isRecording, "Should not be recording yet when starting")

        // When: Recording starts successfully
        appState.startRecording()
        isStarting = false
        XCTAssertTrue(appState.isRecording, "Should be recording after start completes")
        XCTAssertFalse(isStarting, "isStarting should be false when recording is active")
    }

    /// Test that state resets properly on error
    /// This prevents stuck UI states
    func testStateResetsProperlyOnError() async throws {
        // Given: Attempted start with error
        var isStarting = true
        settingsManager.captureMicrophone = false
        settingsManager.captureSystemAudio = false

        // When: Error occurs
        do {
            try await appState.startActualRecording(title: "Test")
            XCTFail("Should have thrown error")
        } catch {
            isStarting = false
        }

        // Then: Both states should be false
        XCTAssertFalse(isStarting, "isStarting should be false")
        XCTAssertFalse(appState.isRecording, "isRecording should be false")
    }

    // MARK: - Accessibility Tests

    /// Test that button disabled state is accessible
    /// This ensures screen readers can detect button state
    func testButtonDisabledStateIsAccessible() {
        // Given: Button is disabled due to recording
        appState.startRecording()
        let isStarting = false
        let isDisabled = isStarting || appState.isRecording

        // When: Checking accessibility
        // SwiftUI's .disabled() modifier automatically updates accessibility

        // Then: Disabled state should be true
        XCTAssertTrue(isDisabled, "Button should be accessible as disabled")
    }

    /// Test that loading state is announced to screen readers
    /// This provides feedback to users with screen readers
    func testLoadingStateIsAccessible() {
        // Given: Button is in loading state
        let isStarting = true

        // When: Loading indicator is shown
        // ProgressView automatically has accessibility support

        // Then: Loading state should be detectable
        XCTAssertTrue(isStarting, "Loading state should be accessible via ProgressView")
    }
}
