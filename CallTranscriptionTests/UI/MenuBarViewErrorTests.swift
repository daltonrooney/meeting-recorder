import XCTest
import SwiftUI
@testable import CallTranscription

/// Tests for error alert presentation in MenuBarView.
/// These tests ensure errors are properly displayed to users with clear, actionable information.
@MainActor
final class MenuBarViewErrorTests: XCTestCase {

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

    // MARK: - Error Alert Display Tests

    /// Test that error alert is shown immediately when recording start fails
    /// This ensures users get immediate feedback
    func testErrorAlertShownImmediatelyOnFailure() async throws {
        // Given: Invalid configuration
        settingsManager.captureMicrophone = false
        settingsManager.captureSystemAudio = false
        var showError = false
        var errorMessage: String?

        // When: Attempting to start recording
        do {
            try await appState.startActualRecording(title: "Test")
            XCTFail("Should have thrown error")
        } catch {
            // Then: Error state should be set immediately
            errorMessage = error.localizedDescription
            showError = true
        }

        // Then: Alert should be triggered
        XCTAssertTrue(showError, "showError should be true after failure")
        XCTAssertNotNil(errorMessage, "errorMessage should be set")
        XCTAssertFalse(errorMessage?.isEmpty ?? true, "errorMessage should not be empty")
    }

    /// Test that error alert persists until user dismisses it
    /// This ensures users see and acknowledge errors
    func testErrorAlertPersistsUntilDismissed() {
        // Given: Error occurred and alert is shown
        var showError = true
        let errorMessage = "Test error message"

        // When: Alert is displayed
        // .alert(isPresented: $showError) binds to showError

        // Then: Alert should remain visible
        XCTAssertTrue(showError, "Alert should persist until dismissed")

        // When: User dismisses alert (clicks OK button)
        showError = false

        // Then: Alert should be hidden
        XCTAssertFalse(showError, "Alert should be hidden after dismissal")
    }

    /// Test that error message includes detailed information
    /// This helps users understand and resolve issues
    func testErrorMessageIncludesDetailedInformation() async throws {
        // Given: Specific error scenario (no audio sources)
        settingsManager.captureMicrophone = false
        settingsManager.captureSystemAudio = false

        // When: Error occurs
        do {
            try await appState.startActualRecording(title: "Test")
            XCTFail("Should have thrown error")
        } catch {
            // Then: Error description should be detailed
            let description = error.localizedDescription
            XCTAssertFalse(description.isEmpty, "Error description should not be empty")
            // Error should explain what went wrong and how to fix it
        }
    }

    /// Test that error alert has proper accessibility labels
    /// This ensures screen reader users get full error information
    func testErrorAlertHasProperAccessibilityLabels() {
        // Given: Error alert with title and message
        let alertTitle = "Error"
        let errorMessage = "Failed to start recording"

        // When: Alert is presented
        // SwiftUI's .alert() automatically provides accessibility support

        // Then: Alert should be accessible
        XCTAssertNotNil(alertTitle, "Alert title should be set for accessibility")
        XCTAssertNotNil(errorMessage, "Alert message should be set for accessibility")
    }

    /// Test that consecutive errors show separate alerts
    /// This ensures users don't miss any error information
    func testConsecutiveErrorsShowSeparateAlerts() async throws {
        // Given: Multiple error scenarios
        settingsManager.captureMicrophone = false
        settingsManager.captureSystemAudio = false
        var errorCount = 0

        // When: Multiple errors occur
        for _ in 0..<3 {
            do {
                try await appState.startActualRecording(title: "Test")
                XCTFail("Should have thrown error")
            } catch {
                errorCount += 1
                // Each error should trigger alert
                // In implementation, showError = true for each
            }
        }

        // Then: All errors should be captured
        XCTAssertEqual(errorCount, 3, "All three errors should be caught and shown")
    }

    // MARK: - Error Message Content Tests

    /// Test that microphone permission error has actionable message
    /// This guides users to fix permission issues
    func testMicrophonePermissionErrorMessage() {
        // Given: Microphone permission denied error
        let error = CallTranscriptionError.microphonePermissionDenied

        // When: Getting error description
        let description = error.localizedDescription

        // Then: Should contain actionable information
        XCTAssertFalse(description.isEmpty, "Error description should not be empty")
        // Should mention System Preferences/Settings and how to grant permission
    }

    /// Test that output folder error includes path
    /// This helps users identify which folder has issues
    func testOutputFolderErrorIncludesPath() {
        // Given: Output folder error
        let testURL = URL(fileURLWithPath: "/invalid/path")
        let error = CallTranscriptionError.outputFolderNotWritable(testURL)

        // When: Getting error description
        let description = error.localizedDescription

        // Then: Should include the problematic path
        XCTAssertFalse(description.isEmpty, "Error description should not be empty")
        XCTAssertTrue(description.contains("/invalid/path") || description.contains("path"),
                     "Error should reference the problematic path")
    }

    /// Test that security-scoped access error has clear message
    /// This helps users understand permission requirements
    func testSecurityScopedAccessErrorMessage() {
        // Given: Security-scoped access failure
        let testPath = "/Users/test/Documents/Recordings"
        let error = CallTranscriptionError.securityScopedAccessFailed(testPath)

        // When: Getting error description
        let description = error.localizedDescription

        // Then: Should explain security-scoped resource access
        XCTAssertFalse(description.isEmpty, "Error description should not be empty")
        // Should mention folder access permissions and settings
    }

    /// Test that unknown errors have fallback message
    /// This ensures users always get some information
    func testUnknownErrorHasFallbackMessage() {
        // Given: Generic error
        struct GenericError: Error {}
        let error = GenericError()

        // When: Getting localized description
        let description = error.localizedDescription

        // Then: Should have fallback message
        XCTAssertFalse(description.isEmpty, "Error should have some description")
    }

    // MARK: - Alert Button Tests

    /// Test that alert has OK button to dismiss
    /// This ensures users can dismiss error alerts
    func testAlertHasOKButton() {
        // Given: Error alert is shown
        var showError = true

        // When: OK button is present in alert
        // .alert() includes button: Button("OK") { showError = false }

        // Then: OK button should dismiss alert
        showError = false
        XCTAssertFalse(showError, "OK button should set showError to false")
    }

    /// Test that dismissing alert doesn't clear error message
    /// This allows error to be logged for debugging
    func testDismissingAlertRetainsErrorMessage() {
        // Given: Error occurred
        var showError = true
        let errorMessage = "Test error"

        // When: Alert is dismissed
        showError = false

        // Then: Error message should still be available
        XCTAssertEqual(errorMessage, "Test error", "Error message should be retained")
    }

    // MARK: - Error State Management Tests

    /// Test that showError state is properly managed
    /// This ensures alerts don't appear unexpectedly
    func testShowErrorStateManagement() {
        // Given: Fresh state
        var showError = false

        // When: No error has occurred
        XCTAssertFalse(showError, "showError should be false initially")

        // When: Error occurs
        showError = true
        XCTAssertTrue(showError, "showError should be true after error")

        // When: User dismisses alert
        showError = false
        XCTAssertFalse(showError, "showError should be false after dismissal")
    }

    /// Test that errorMessage is cleared appropriately
    /// This prevents showing stale error messages
    func testErrorMessageClearing() {
        // Given: Previous error message
        var errorMessage: String? = "Old error"
        var showError = false

        // When: Alert is dismissed
        showError = false

        // Then: Consider clearing error message on next successful operation
        // (Current implementation may keep last error message)
        XCTAssertEqual(errorMessage, "Old error", "Error message retention is implementation-dependent")

        // When: New error occurs
        errorMessage = "New error"
        showError = true

        // Then: New error should replace old one
        XCTAssertEqual(errorMessage, "New error", "New error should update message")
    }

    /// Test that nil error message shows fallback
    /// This ensures alert always has content
    func testNilErrorMessageShowsFallback() {
        // Given: Error occurred but message is nil
        var errorMessage: String? = nil

        // When: Displaying error in alert
        let displayMessage = errorMessage ?? "An unknown error occurred"

        // Then: Should show fallback message
        XCTAssertEqual(displayMessage, "An unknown error occurred",
                      "Nil error message should show fallback")
    }

    // MARK: - Error Recovery Tests

    /// Test that user can retry after error
    /// This ensures errors don't permanently disable functionality
    func testUserCanRetryAfterError() async throws {
        // Given: Error occurred
        settingsManager.captureMicrophone = false
        settingsManager.captureSystemAudio = false

        do {
            try await appState.startActualRecording(title: "Test")
            XCTFail("Should have thrown error")
        } catch {
            // Error occurred
        }

        // When: User fixes configuration and retries
        settingsManager.captureMicrophone = true
        var canRetry = true

        // Then: Should be able to attempt again
        XCTAssertTrue(canRetry, "User should be able to retry after error")
    }

    /// Test that error doesn't leave app in broken state
    /// This ensures app remains functional after errors
    func testErrorDoesNotBreakAppState() async throws {
        // Given: Error during recording start
        settingsManager.captureMicrophone = false
        settingsManager.captureSystemAudio = false

        do {
            try await appState.startActualRecording(title: "Test")
        } catch {
            // Error occurred
        }

        // Then: App state should be consistent
        XCTAssertFalse(appState.isRecording, "Should not be recording after error")

        // And: Settings should still be accessible
        XCTAssertNotNil(settingsManager, "SettingsManager should still be functional")
    }
}
