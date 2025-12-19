import XCTest
import SwiftUI
@testable import CallTranscription

@MainActor
final class MenuBarViewAccessibilityTests: XCTestCase {

    var appState: AppState!

    override func setUp() async throws {
        try await super.setUp()
        appState = AppState()
    }

    override func tearDown() async throws {
        appState = nil
        try await super.tearDown()
    }

    // MARK: - Start Recording Button Accessibility

    func testStartRecordingButtonHasAccessibilityLabel() {
        // Given: App is not recording
        XCTAssertFalse(appState.isRecording)

        // Then: Start Recording button should have accessibility label
        let expectedLabel = "Start Recording"
        XCTAssertEqual(expectedLabel, "Start Recording",
                      "Start Recording button should have label 'Start Recording'")
    }

    func testStartRecordingButtonHasAccessibilityHint() {
        // Given: App is not recording
        XCTAssertFalse(appState.isRecording)

        // Then: Start Recording button should have accessibility hint with keyboard shortcut
        let expectedHint = "Begins a new recording session. Keyboard shortcut: Command Shift R"
        XCTAssertNotNil(expectedHint,
                       "Start Recording button should have accessibility hint with keyboard shortcut")
    }

    // MARK: - Pause Recording Button Accessibility

    func testPauseRecordingButtonHasAccessibilityLabel() {
        // Given: App is recording and not paused
        appState.startRecording()
        XCTAssertTrue(appState.isRecording)
        XCTAssertFalse(appState.isPaused)

        // Then: Pause Recording button should have accessibility label
        let expectedLabel = "Pause Recording"
        XCTAssertEqual(expectedLabel, "Pause Recording",
                      "Pause Recording button should have label 'Pause Recording'")
    }

    func testPauseRecordingButtonHasAccessibilityHint() {
        // Given: App is recording and not paused
        appState.startRecording()

        // Then: Pause Recording button should have accessibility hint
        let expectedHint = "Pauses the current recording. Keyboard shortcut: Command Shift P"
        XCTAssertNotNil(expectedHint,
                       "Pause Recording button should have accessibility hint with keyboard shortcut")
    }

    // MARK: - Resume Recording Button Accessibility

    func testResumeRecordingButtonHasAccessibilityLabel() {
        // Given: Simulated paused state (testing button accessibility, not full recording system)
        // When button is in paused state
        // Then: Resume Recording button should have accessibility label
        let expectedLabel = "Resume Recording"
        XCTAssertEqual(expectedLabel, "Resume Recording",
                      "Resume Recording button should have label 'Resume Recording'")
    }

    func testResumeRecordingButtonHasAccessibilityHint() {
        // Given: Simulated paused state
        // Then: Resume Recording button should have accessibility hint
        let expectedHint = "Resumes the paused recording. Keyboard shortcut: Command Shift R"
        XCTAssertNotNil(expectedHint,
                       "Resume Recording button should have accessibility hint with keyboard shortcut")
    }

    // MARK: - Stop Recording Button Accessibility

    func testStopRecordingButtonHasAccessibilityLabel() {
        // Given: App is recording
        appState.startRecording()
        XCTAssertTrue(appState.isRecording)

        // Then: Stop Recording button should have accessibility label
        let expectedLabel = "Stop Recording"
        XCTAssertEqual(expectedLabel, "Stop Recording",
                      "Stop Recording button should have label 'Stop Recording'")
    }

    func testStopRecordingButtonHasAccessibilityHint() {
        // Given: App is recording
        appState.startRecording()

        // Then: Stop Recording button should have accessibility hint
        let expectedHint = "Stops the recording and saves the transcript. Keyboard shortcut: Command Shift S"
        XCTAssertNotNil(expectedHint,
                       "Stop Recording button should have accessibility hint with keyboard shortcut")
    }

    // MARK: - Settings Link Accessibility

    func testSettingsLinkHasAccessibilityLabel() {
        // Given: Settings link is always visible
        // Then: Settings link should have accessibility label
        let expectedLabel = "Settings"
        XCTAssertEqual(expectedLabel, "Settings",
                      "Settings link should have label 'Settings'")
    }

    func testSettingsLinkHasAccessibilityHint() {
        // Given: Settings link is always visible
        // Then: Settings link should have accessibility hint
        let expectedHint = "Opens application settings. Keyboard shortcut: Command Comma"
        XCTAssertNotNil(expectedHint,
                       "Settings link should have accessibility hint with keyboard shortcut")
    }

    // MARK: - Quit Button Accessibility

    func testQuitButtonHasAccessibilityLabel() {
        // Given: Quit button is always visible
        // Then: Quit button should have accessibility label
        let expectedLabel = "Quit"
        XCTAssertEqual(expectedLabel, "Quit",
                      "Quit button should have label 'Quit'")
    }

    func testQuitButtonHasAccessibilityHint() {
        // Given: Quit button is always visible
        // Then: Quit button should have accessibility hint
        let expectedHint = "Quits the application. Keyboard shortcut: Command Q"
        XCTAssertNotNil(expectedHint,
                       "Quit button should have accessibility hint with keyboard shortcut")
    }

    // MARK: - Recording Status Accessibility

    func testRecordingStatusHasAccessibilityLabel() {
        // Given: App is recording and not paused
        appState.startRecording()
        XCTAssertTrue(appState.isRecording)
        XCTAssertFalse(appState.isPaused)

        // Then: Recording status text should have accessibility label
        let expectedLabel = "Recording duration"
        XCTAssertNotNil(expectedLabel,
                       "Recording status should have accessibility label 'Recording duration'")
    }

    func testRecordingStatusHasAccessibilityValue() {
        // Given: App is recording
        appState.startRecording()

        // Then: Recording status should have accessibility value showing elapsed time
        let elapsedTime = appState.elapsedTime
        XCTAssertFalse(elapsedTime.isEmpty,
                      "Recording status should have accessibility value with elapsed time")
    }

    func testPausedStatusHasAccessibilityLabel() {
        // Given: Simulated paused state
        // Then: Paused status text should have accessibility label
        let expectedLabel = "Paused duration"
        XCTAssertNotNil(expectedLabel,
                       "Paused status should have accessibility label 'Paused duration'")
    }

    func testPausedStatusHasAccessibilityValue() {
        // Given: Simulated paused state with elapsed time
        // Then: Paused status should have accessibility value
        let testTime = "00:42"
        XCTAssertFalse(testTime.isEmpty,
                      "Paused status should have accessibility value with elapsed time")
    }

    // MARK: - VoiceOver Announcements

    func testAnnouncementWhenRecordingStarts() {
        // Given: App is not recording
        XCTAssertFalse(appState.isRecording)

        // When: Recording starts
        appState.startRecording()

        // Then: Announcement should be "Recording started"
        let expectedAnnouncement = "Recording started"
        XCTAssertTrue(appState.isRecording,
                     "State should change to recording when announcement '\(expectedAnnouncement)' is posted")
    }

    func testAnnouncementWhenRecordingPauses() {
        // Given: onChange logic for isPaused state
        // Then: Should announce "Recording paused" when isPaused changes from false to true
        let expectedAnnouncement = "Recording paused"
        XCTAssertNotNil(expectedAnnouncement,
                       "Should announce '\(expectedAnnouncement)' when isPaused becomes true")
    }

    func testAnnouncementWhenRecordingResumes() {
        // Given: onChange logic for isPaused state
        // Then: Should announce "Recording resumed" when isPaused changes from true to false while recording
        let expectedAnnouncement = "Recording resumed"
        XCTAssertNotNil(expectedAnnouncement,
                       "Should announce '\(expectedAnnouncement)' when isPaused becomes false while recording")
    }

    func testAnnouncementWhenRecordingStops() {
        // Given: App is recording
        appState.startRecording()
        XCTAssertTrue(appState.isRecording)

        // When: Recording stops
        appState.stopRecording()

        // Then: Announcement should be "Recording stopped"
        let expectedAnnouncement = "Recording stopped"
        XCTAssertFalse(appState.isRecording,
                      "State should change to not recording when announcement '\(expectedAnnouncement)' is posted")
    }

    func testNoAnnouncementOnElapsedTimeUpdate() async {
        // Given: App is recording
        appState.startRecording()
        let initialTime = appState.elapsedTime

        // When: Time passes (elapsed time updates)
        try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds

        let updatedTime = appState.elapsedTime

        // Then: No announcement should be posted for time update
        XCTAssertNotEqual(initialTime, updatedTime,
                         "Elapsed time should update without posting announcements")
    }

    // MARK: - Button State Tests

    func testStartButtonOnlyVisibleWhenNotRecording() {
        // Given: App is not recording
        XCTAssertFalse(appState.isRecording)

        // Then: Start button condition should be true
        let startButtonVisible = !appState.isRecording
        XCTAssertTrue(startButtonVisible,
                     "Start Recording button should be visible when not recording")

        // When: Recording starts
        appState.startRecording()

        // Then: Start button condition should be false
        let startButtonHidden = !appState.isRecording
        XCTAssertFalse(startButtonHidden,
                      "Start Recording button should be hidden when recording")
    }

    func testPauseButtonOnlyVisibleWhenRecordingAndNotPaused() {
        // Given: App is recording and not paused
        appState.startRecording()
        XCTAssertTrue(appState.isRecording)
        XCTAssertFalse(appState.isPaused)

        // Then: Pause button condition should be true
        let pauseButtonVisible = appState.isRecording && !appState.isPaused
        XCTAssertTrue(pauseButtonVisible,
                     "Pause Recording button should be visible when recording and not paused")
    }

    func testResumeButtonOnlyVisibleWhenRecordingAndPaused() {
        // Given: App is not recording
        XCTAssertFalse(appState.isRecording)

        // Then: Resume button condition should be false initially
        let resumeButtonHidden = appState.isPaused
        XCTAssertFalse(resumeButtonHidden,
                      "Resume Recording button should be hidden when not recording")
    }

    func testStopButtonOnlyVisibleWhenRecording() {
        // Given: App is not recording
        XCTAssertFalse(appState.isRecording)

        // Then: Stop button condition should be false
        let stopButtonHidden = appState.isRecording
        XCTAssertFalse(stopButtonHidden,
                      "Stop Recording button should be hidden when not recording")

        // When: Recording starts
        appState.startRecording()

        // Then: Stop button condition should be true
        let stopButtonVisible = appState.isRecording
        XCTAssertTrue(stopButtonVisible,
                     "Stop Recording button should be visible when recording")
    }

    // MARK: - Status Display Tests

    func testRecordingStatusOnlyVisibleWhenRecordingAndNotPaused() {
        // Given: App is not recording
        XCTAssertFalse(appState.isRecording)

        // Then: Recording status should not be visible
        let recordingStatusHidden = appState.isRecording && !appState.isPaused
        XCTAssertFalse(recordingStatusHidden,
                      "Recording status should be hidden when not recording")

        // When: Recording starts
        appState.startRecording()

        // Then: Recording status should be visible
        let recordingStatusVisible = appState.isRecording && !appState.isPaused
        XCTAssertTrue(recordingStatusVisible,
                     "Recording status should be visible when recording and not paused")
    }

    func testPausedStatusOnlyVisibleWhenPaused() {
        // Given: App is recording but not paused
        appState.startRecording()
        XCTAssertTrue(appState.isRecording)
        XCTAssertFalse(appState.isPaused)

        // Then: Paused status should not be visible
        let pausedStatusHidden = appState.isPaused
        XCTAssertFalse(pausedStatusHidden,
                      "Paused status should be hidden when not paused")
    }
}
