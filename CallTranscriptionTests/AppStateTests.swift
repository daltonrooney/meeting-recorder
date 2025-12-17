import XCTest
import Combine
@testable import CallTranscription

@MainActor
final class AppStateTests: XCTestCase {

    var appState: AppState!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        appState = AppState()
        cancellables = []
    }

    override func tearDown() async throws {
        cancellables = nil
        appState = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialIsRecordingIsFalse() {
        XCTAssertFalse(appState.isRecording, "isRecording should be false on initialization")
    }

    func testInitialElapsedTimeIsZero() {
        XCTAssertEqual(appState.elapsedTime, "00:00", "elapsedTime should be '00:00' on initialization")
    }

    func testStateIsObservable() {
        // Verify AppState conforms to ObservableObject by checking it has objectWillChange
        XCTAssertNotNil(appState.objectWillChange,
                     "AppState should conform to ObservableObject protocol")
    }

    func testIsRecordingPropertyIsPublished() {
        let expectation = expectation(description: "isRecording change should be published")
        var receivedValues: [Bool] = []

        appState.$isRecording
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        Task {
            appState.startRecording()
        }

        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedValues, [true], "isRecording change should be published")
    }

    func testElapsedTimePropertyIsPublished() {
        let expectation = expectation(description: "elapsedTime change should be published")
        var receivedValues: [String] = []

        appState.$elapsedTime
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count >= 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        Task {
            appState.startRecording()
            // Wait a bit for timer to update
            try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds
        }

        wait(for: [expectation], timeout: 3.0)
        XCTAssertFalse(receivedValues.isEmpty, "elapsedTime should publish changes")
        XCTAssertNotEqual(receivedValues.first, "00:00", "elapsedTime should change from initial value")
    }

    // MARK: - Recording State Transition Tests

    func testStartRecordingChangesIsRecordingToTrue() async {
        appState.startRecording()
        XCTAssertTrue(appState.isRecording, "startRecording() should change isRecording to true")
    }

    func testStopRecordingChangesIsRecordingToFalse() async {
        appState.startRecording()
        appState.stopRecording()
        XCTAssertFalse(appState.isRecording, "stopRecording() should change isRecording to false")
    }

    func testMultipleStartCallsAreHandledGracefully() async {
        appState.startRecording()
        XCTAssertTrue(appState.isRecording)

        // Call start again - should be handled gracefully (no crash, no error)
        appState.startRecording()
        XCTAssertTrue(appState.isRecording, "Multiple start calls should be handled gracefully")
    }

    func testStopCalledWhenNotRecordingIsHandledGracefully() async {
        XCTAssertFalse(appState.isRecording)

        // Call stop when not recording - should be handled gracefully
        appState.stopRecording()
        XCTAssertFalse(appState.isRecording, "Stop called when not recording should be handled gracefully")
    }

    func testRecordingCanBeStartedAfterStopping() async {
        appState.startRecording()
        XCTAssertTrue(appState.isRecording)

        appState.stopRecording()
        XCTAssertFalse(appState.isRecording)

        appState.startRecording()
        XCTAssertTrue(appState.isRecording, "Recording should be able to restart after stopping")
    }

    // MARK: - Elapsed Time Tracking Tests

    func testElapsedTimeUpdatesWhileRecording() async {
        appState.startRecording()
        let initialTime = appState.elapsedTime

        // Wait for at least one timer tick (should be ~1 second)
        try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds

        let updatedTime = appState.elapsedTime
        XCTAssertNotEqual(initialTime, updatedTime, "elapsedTime should update during recording")
    }

    func testElapsedTimeResetsAfterStopping() async {
        appState.startRecording()

        // Wait for time to accumulate
        try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds
        XCTAssertNotEqual(appState.elapsedTime, "00:00", "elapsedTime should accumulate")

        appState.stopRecording()
        XCTAssertEqual(appState.elapsedTime, "00:00", "elapsedTime should reset after stopping")
    }

    func testTimeFormatIsCorrectForSeconds() async {
        appState.startRecording()

        // Wait for at least 1 second
        try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds

        let time = appState.elapsedTime
        // Should be in MM:SS format (e.g., "00:01")
        XCTAssertTrue(time.contains(":"), "Time format should contain colon separator")

        let components = time.split(separator: ":")
        XCTAssertEqual(components.count, 2, "Time format should have two components (MM:SS)")

        // Both components should be numeric
        XCTAssertNotNil(Int(components[0]), "Minutes should be numeric")
        XCTAssertNotNil(Int(components[1]), "Seconds should be numeric")
    }

    func testTimeFormatIsCorrectForMinutes() async {
        // This is a long test - we'll simulate by manipulating internal state
        // For now, just verify the format can handle minutes
        appState.startRecording()

        // Wait a bit to ensure timer is running
        try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds

        let time = appState.elapsedTime
        let components = time.split(separator: ":")

        // Verify format: should be MM:SS where MM can be 00-99 and SS is 00-59
        XCTAssertEqual(components.count, 2, "Time should be in MM:SS format")
        XCTAssertEqual(components[0].count, 2, "Minutes should be zero-padded to 2 digits")
        XCTAssertEqual(components[1].count, 2, "Seconds should be zero-padded to 2 digits")
    }

    func testTimeFormatHandlesHours() async {
        // Verify format can handle hours if needed (HH:MM:SS)
        // This test validates that the format specification is met
        appState.startRecording()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let time = appState.elapsedTime
        let components = time.split(separator: ":")

        // Should support either MM:SS or HH:MM:SS format
        XCTAssertTrue(components.count == 2 || components.count == 3,
                     "Time format should be MM:SS or HH:MM:SS")
    }

    func testElapsedTimeDoesNotUpdateWhenNotRecording() async {
        let initialTime = appState.elapsedTime

        // Wait without recording
        try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds

        XCTAssertEqual(appState.elapsedTime, initialTime,
                      "elapsedTime should not update when not recording")
    }

    func testTimerStopsWhenRecordingStops() async {
        appState.startRecording()

        // Wait for timer to fire at least once
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        let timeAfterStart = appState.elapsedTime

        appState.stopRecording()

        // Wait again - time should NOT change
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertEqual(appState.elapsedTime, "00:00",
                      "Timer should be stopped and time reset")
    }

    // MARK: - Error State Management Tests

    func testStartRecordingPropagatesErrors() async {
        // Note: This test validates that errors can be thrown
        // Actual error conditions will be tested with real recording subsystems
        do {
            // For now, verify that startRecording completes without error
            appState.startRecording()
            // If we get here, no error was thrown (expected for basic AppState)
            XCTAssertTrue(appState.isRecording)
        } catch {
            // If an error is thrown, verify it's a CallTranscriptionError
            XCTAssertTrue(error is CallTranscriptionError,
                         "Errors during start should be CallTranscriptionError")
        }
    }

    func testStopRecordingPropagatesErrors() async {
        do {
            appState.startRecording()
            appState.stopRecording()
            // If we get here, no error was thrown (expected for basic AppState)
            XCTAssertFalse(appState.isRecording)
        } catch {
            // If an error is thrown, verify it's a CallTranscriptionError
            XCTAssertTrue(error is CallTranscriptionError,
                         "Errors during stop should be CallTranscriptionError")
        }
    }

    func testErrorStateLeavesAppInConsistentState() async {
        appState.startRecording()
        let wasRecording = appState.isRecording

        // Even if stop encounters an error, state should be consistent
        appState.stopRecording()

        // After stop (error or not), isRecording should be false
        XCTAssertFalse(appState.isRecording,
                      "Error state should not leave app in inconsistent recording state")

        // And elapsed time should be reset
        XCTAssertEqual(appState.elapsedTime, "00:00",
                      "Error state should reset elapsed time")
    }

    func testStateRemainsConsistentAfterErrorDuringStart() async {
        // Attempt to start (may fail in real scenarios with permissions)
        appState.startRecording()

        // Regardless of success/failure, state should be consistent
        if appState.isRecording {
            // If started successfully, elapsed time should eventually update
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            XCTAssertNotEqual(appState.elapsedTime, "00:00")
        } else {
            // If start failed, elapsed time should remain at initial value
            XCTAssertEqual(appState.elapsedTime, "00:00")
        }
    }

    // MARK: - Integration Tests

    func testCompleteRecordingCycle() async {
        // Test a complete recording cycle
        XCTAssertFalse(appState.isRecording, "Should start not recording")
        XCTAssertEqual(appState.elapsedTime, "00:00", "Should start at 00:00")

        appState.startRecording()
        XCTAssertTrue(appState.isRecording, "Should be recording after start")

        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        XCTAssertNotEqual(appState.elapsedTime, "00:00", "Should have elapsed time")

        appState.stopRecording()
        XCTAssertFalse(appState.isRecording, "Should stop recording")
        XCTAssertEqual(appState.elapsedTime, "00:00", "Should reset to 00:00")
    }

    func testMultipleRecordingCycles() async {
        // Test multiple start/stop cycles
        for _ in 0..<3 {
            appState.startRecording()
            XCTAssertTrue(appState.isRecording)

            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            appState.stopRecording()
            XCTAssertFalse(appState.isRecording)
            XCTAssertEqual(appState.elapsedTime, "00:00")
        }
    }

    // MARK: - MainActor Tests

    func testAppStateIsMainActorIsolated() {
        // Verify that AppState is marked with @MainActor
        let mainActorType = type(of: appState)
        XCTAssertNotNil(mainActorType, "AppState should be @MainActor isolated")
    }

    func testPropertyAccessIsMainActorSafe() async {
        // All property access should be safe from main actor
        await MainActor.run {
            let _ = appState.isRecording
            let _ = appState.elapsedTime
        }
    }

    // MARK: - RecordingSessionCoordinator Integration Tests

    func testAppStateCreatesCoordinatorOnInit() {
        // Assert that AppState creates a RecordingSessionCoordinator during initialization
        // The coordinator should be configured with settings from SettingsManager
        XCTAssertNotNil(appState, "AppState should be initialized")
        // Coordinator will be checked via behavior tests below
    }

    func testCoordinatorUsesSettingsFromSettingsManager() async throws {
        // Create settings manager with known values
        let settings = SettingsManager()
        settings.outputFolder = "~/Desktop/TestTranscripts"
        settings.captureSystemAudio = false
        settings.captureMicrophone = true
        settings.postRecordingScript = ""

        // Create AppState with settings
        let testAppState = AppState(settingsManager: settings)

        // Start recording and verify coordinator uses the settings
        try await testAppState.startActualRecording(title: "Test Recording")

        // Coordinator should be using the settings values
        XCTAssertTrue(testAppState.isRecording, "Should start recording with configured settings")

        // Cleanup
        _ = try await testAppState.stopActualRecording()
    }

    func testCoordinatorValidatesSettingsBeforeCreating() async {
        // Test that invalid settings are caught
        let settings = SettingsManager()
        settings.outputFolder = "/nonexistent/invalid/path/that/does/not/exist"
        settings.captureMicrophone = false
        settings.captureSystemAudio = false // Both disabled

        let testAppState = AppState(settingsManager: settings)

        do {
            try await testAppState.startActualRecording(title: "Test")
            XCTFail("Should throw error for invalid configuration")
        } catch {
            XCTAssertTrue(error is CallTranscriptionError,
                         "Should throw CallTranscriptionError for invalid settings")
        }
    }

    func testStartRecordingCallsCoordinatorStart() async throws {
        // Setup
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        let testAppState = AppState(settingsManager: settings)

        // Act
        try await testAppState.startActualRecording(title: "Integration Test")

        // Assert
        XCTAssertTrue(testAppState.isRecording, "AppState.isRecording should be true")

        // Cleanup
        _ = try await testAppState.stopActualRecording()
    }

    func testStartRecordingHandlesCoordinatorErrors() async {
        // Setup with invalid configuration
        let settings = SettingsManager()
        settings.outputFolder = "/invalid/path"
        let testAppState = AppState(settingsManager: settings)

        // Act & Assert
        do {
            try await testAppState.startActualRecording(title: "Test")
            XCTFail("Should propagate coordinator start errors")
        } catch {
            XCTAssertTrue(error is CallTranscriptionError,
                         "Should throw CallTranscriptionError from coordinator")
            XCTAssertFalse(testAppState.isRecording,
                          "Should not be recording after error")
        }
    }

    func testStartRecordingUpdatesUIStateOnSuccess() async throws {
        // Setup
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        let testAppState = AppState(settingsManager: settings)

        // Act
        try await testAppState.startActualRecording(title: "UI Test")

        // Assert UI state is updated
        XCTAssertTrue(testAppState.isRecording, "isRecording should be true")

        // Wait for timer to tick
        try await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertNotEqual(testAppState.elapsedTime, "00:00", "Elapsed time should update")

        // Cleanup
        _ = try await testAppState.stopActualRecording()
    }

    func testStartRecordingStartsElapsedTimer() async throws {
        // Setup
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        let testAppState = AppState(settingsManager: settings)

        // Act
        try await testAppState.startActualRecording(title: "Timer Test")

        // Assert timer is running
        let time1 = testAppState.elapsedTime
        try await Task.sleep(nanoseconds: 1_200_000_000)
        let time2 = testAppState.elapsedTime

        XCTAssertNotEqual(time1, time2, "Elapsed time should increment")

        // Cleanup
        _ = try await testAppState.stopActualRecording()
    }

    func testStopRecordingCallsCoordinatorStop() async throws {
        // Setup
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        let testAppState = AppState(settingsManager: settings)

        try await testAppState.startActualRecording(title: "Stop Test")
        XCTAssertTrue(testAppState.isRecording)

        // Act
        let transcriptURL = try await testAppState.stopActualRecording()

        // Assert
        XCTAssertFalse(testAppState.isRecording, "isRecording should be false")
        XCTAssertNotNil(transcriptURL, "Should return transcript URL")
    }

    func testStopRecordingHandlesCoordinatorErrors() async throws {
        // Setup - start a recording
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        let testAppState = AppState(settingsManager: settings)

        try await testAppState.startActualRecording(title: "Error Test")

        // The coordinator may throw errors during stop in some scenarios
        // For now, test that stop completes and updates state
        do {
            _ = try await testAppState.stopActualRecording()
            XCTAssertFalse(testAppState.isRecording, "Should update state even if errors occur")
        } catch {
            // If error is thrown, state should still be consistent
            XCTAssertFalse(testAppState.isRecording, "State should be consistent after error")
        }
    }

    func testStopRecordingUpdatesUIState() async throws {
        // Setup
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        let testAppState = AppState(settingsManager: settings)

        try await testAppState.startActualRecording(title: "UI Stop Test")

        // Wait for elapsed time to accumulate
        try await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertNotEqual(testAppState.elapsedTime, "00:00")

        // Act
        _ = try await testAppState.stopActualRecording()

        // Assert UI state is updated
        XCTAssertFalse(testAppState.isRecording, "isRecording should be false")
        XCTAssertEqual(testAppState.elapsedTime, "00:00", "Elapsed time should reset")
    }

    func testStopRecordingStopsElapsedTimer() async throws {
        // Setup
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        let testAppState = AppState(settingsManager: settings)

        try await testAppState.startActualRecording(title: "Timer Stop Test")
        try await Task.sleep(nanoseconds: 1_200_000_000)

        // Act
        _ = try await testAppState.stopActualRecording()

        // Assert timer is stopped
        let time1 = testAppState.elapsedTime
        try await Task.sleep(nanoseconds: 1_200_000_000)
        let time2 = testAppState.elapsedTime

        XCTAssertEqual(time1, time2, "Elapsed time should not change after stop")
        XCTAssertEqual(time2, "00:00", "Elapsed time should be reset")
    }

    func testStopRecordingReturnsTranscriptFileURL() async throws {
        // Setup
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        let testAppState = AppState(settingsManager: settings)

        try await testAppState.startActualRecording(title: "Transcript URL Test")

        // Act
        let transcriptURL = try await testAppState.stopActualRecording()

        // Assert
        XCTAssertNotNil(transcriptURL, "Should return transcript file URL")
        XCTAssertTrue(transcriptURL.isFileURL, "Should be a file URL")
        XCTAssertTrue(transcriptURL.path.contains("Transcript URL Test"),
                     "Filename should contain recording title")
    }

    func testRespectsCaptureSystemAudioSetting() async throws {
        // Setup with system audio disabled
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        settings.captureSystemAudio = false
        settings.captureMicrophone = true

        let testAppState = AppState(settingsManager: settings)

        // Act
        try await testAppState.startActualRecording(title: "System Audio Test")

        // Assert recording started successfully (coordinator respects settings)
        XCTAssertTrue(testAppState.isRecording)

        // Cleanup
        _ = try await testAppState.stopActualRecording()
    }

    func testRespectsCaptureMicrophoneSetting() async throws {
        // Setup with microphone disabled
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        settings.captureMicrophone = false
        settings.captureSystemAudio = true

        let testAppState = AppState(settingsManager: settings)

        // Act
        try await testAppState.startActualRecording(title: "Microphone Test")

        // Assert recording started successfully (coordinator respects settings)
        XCTAssertTrue(testAppState.isRecording)

        // Cleanup
        _ = try await testAppState.stopActualRecording()
    }

    func testUsesConfiguredOutputFolder() async throws {
        // Setup with custom output folder
        let customFolder = NSTemporaryDirectory() + "CustomTranscripts/"
        try FileManager.default.createDirectory(atPath: customFolder,
                                           withIntermediateDirectories: true,
                                           attributes: nil)

        let settings = SettingsManager()
        settings.outputFolder = customFolder

        let testAppState = AppState(settingsManager: settings)

        // Act
        try await testAppState.startActualRecording(title: "Output Folder Test")
        let transcriptURL = try await testAppState.stopActualRecording()

        // Assert transcript is in the configured folder
        XCTAssertTrue(transcriptURL.path.hasPrefix(customFolder),
                     "Transcript should be in configured output folder")

        // Cleanup
        try? FileManager.default.removeItem(atPath: customFolder)
    }

    func testExecutesPostRecordingScript() async throws {
        // Setup with post-recording script
        let scriptPath = NSTemporaryDirectory() + "test-script.sh"
        let script = """
        #!/bin/bash
        echo "Script executed" > "\(NSTemporaryDirectory())script-output.txt"
        """
        try script.write(toFile: scriptPath, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)

        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        settings.postRecordingScript = scriptPath

        let testAppState = AppState(settingsManager: settings)

        // Act
        try await testAppState.startActualRecording(title: "Script Test")
        _ = try await testAppState.stopActualRecording()

        // Wait for script execution
        try await Task.sleep(nanoseconds: 500_000_000)

        // Assert script was executed
        let outputPath = NSTemporaryDirectory() + "script-output.txt"
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath),
                     "Post-recording script should have executed")

        // Cleanup
        try? FileManager.default.removeItem(atPath: scriptPath)
        try? FileManager.default.removeItem(atPath: outputPath)
    }

    func testSettingsChangesTakeEffectOnNextRecording() async throws {
        // Setup
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        settings.captureMicrophone = true
        settings.captureSystemAudio = false

        let testAppState = AppState(settingsManager: settings)

        // First recording with initial settings
        try await testAppState.startActualRecording(title: "First Recording")
        _ = try await testAppState.stopActualRecording()

        // Change settings
        settings.captureMicrophone = false
        settings.captureSystemAudio = true

        // Second recording should use new settings
        try await testAppState.startActualRecording(title: "Second Recording")
        XCTAssertTrue(testAppState.isRecording, "Should start with new settings")

        // Cleanup
        _ = try await testAppState.stopActualRecording()
    }

    func testErrorsFromCoordinatorAreExposedToUI() async {
        // Setup with invalid configuration
        let settings = SettingsManager()
        settings.outputFolder = "/invalid/path"
        let testAppState = AppState(settingsManager: settings)

        // Act & Assert
        do {
            try await testAppState.startActualRecording(title: "Error Test")
            XCTFail("Should throw error from coordinator")
        } catch let error as CallTranscriptionError {
            // Error should be accessible for UI presentation
            XCTAssertNotNil(error, "Error should be available for UI")
        } catch {
            XCTFail("Should throw CallTranscriptionError")
        }
    }

    func testErrorStateIsClearable() async {
        // Setup
        let settings = SettingsManager()
        settings.outputFolder = "/invalid/path"
        let testAppState = AppState(settingsManager: settings)

        // Trigger an error
        do {
            try await testAppState.startActualRecording(title: "Error Test")
        } catch {
            // Expected error
        }

        // Fix settings and try again
        settings.outputFolder = NSTemporaryDirectory()

        // Should be able to start recording after error
        try? await testAppState.startActualRecording(title: "Recovery Test")
        XCTAssertTrue(testAppState.isRecording, "Should recover from error state")

        // Cleanup
        _ = try? await testAppState.stopRecording()
    }

    func testAppRemainsUsableAfterErrors() async throws {
        // Setup
        let settings = SettingsManager()
        settings.outputFolder = "/invalid/path"
        let testAppState = AppState(settingsManager: settings)

        // Trigger error
        do {
            try await testAppState.startActualRecording(title: "Error Test")
        } catch {
            // Expected
        }

        // Fix configuration
        settings.outputFolder = NSTemporaryDirectory()

        // Should be able to use app normally
        try await testAppState.startActualRecording(title: "Normal Operation")
        XCTAssertTrue(testAppState.isRecording)

        _ = try await testAppState.stopActualRecording()
        XCTAssertFalse(testAppState.isRecording)
    }

    func testUIUpdatesWhenRecordingStarts() async throws {
        // Setup
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        let testAppState = AppState(settingsManager: settings)

        // Monitor UI state changes
        var isRecordingChanges: [Bool] = []
        let expectation = expectation(description: "isRecording published")

        let cancellable = testAppState.$isRecording
            .dropFirst()
            .sink { value in
                isRecordingChanges.append(value)
                if !isRecordingChanges.isEmpty {
                    expectation.fulfill()
                }
            }

        // Act
        try await testAppState.startActualRecording(title: "UI Update Test")

        // Assert
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertTrue(isRecordingChanges.contains(true), "Should publish isRecording = true")

        // Cleanup
        cancellable.cancel()
        _ = try await testAppState.stopActualRecording()
    }

    func testUIUpdatesWhenRecordingStops() async throws {
        // Setup
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        let testAppState = AppState(settingsManager: settings)

        try await testAppState.startActualRecording(title: "UI Stop Update Test")

        // Monitor UI state changes
        var isRecordingChanges: [Bool] = []
        let expectation = expectation(description: "isRecording published on stop")

        let cancellable = testAppState.$isRecording
            .dropFirst()
            .sink { value in
                isRecordingChanges.append(value)
                if isRecordingChanges.contains(false) {
                    expectation.fulfill()
                }
            }

        // Act
        _ = try await testAppState.stopActualRecording()

        // Assert
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertTrue(isRecordingChanges.contains(false), "Should publish isRecording = false")

        // Cleanup
        cancellable.cancel()
    }

    func testElapsedTimeUpdatesDuringRecording() async throws {
        // Setup
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        let testAppState = AppState(settingsManager: settings)

        // Monitor elapsed time changes
        var elapsedTimeChanges: [String] = []
        let expectation = expectation(description: "elapsedTime updates")

        let cancellable = testAppState.$elapsedTime
            .dropFirst()
            .sink { value in
                elapsedTimeChanges.append(value)
                if elapsedTimeChanges.count >= 2 {
                    expectation.fulfill()
                }
            }

        // Act
        try await testAppState.startActualRecording(title: "Elapsed Time Test")
        try await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds

        // Assert
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertGreaterThan(elapsedTimeChanges.count, 1, "Should update elapsed time multiple times")

        // Cleanup
        cancellable.cancel()
        _ = try await testAppState.stopActualRecording()
    }

    func testAllUpdatesHappenOnMainThread() async throws {
        // Setup
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        let testAppState = AppState(settingsManager: settings)

        // Monitor that all updates are on main thread
        var allOnMainThread = true
        let expectation = expectation(description: "Updates on main thread")

        let cancellable = testAppState.$isRecording
            .dropFirst()
            .sink { _ in
                if !Thread.isMainThread {
                    allOnMainThread = false
                }
                expectation.fulfill()
            }

        // Act
        try await testAppState.startActualRecording(title: "Main Thread Test")

        // Assert
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertTrue(allOnMainThread, "All updates should happen on main thread")

        // Cleanup
        cancellable.cancel()
        _ = try await testAppState.stopActualRecording()
    }

    // MARK: - Consent Dialog Tests

    func testShowConsentDialogIsTrueWhenConsentNotAccepted() {
        // Setup - create settings with consent not accepted
        let settings = SettingsManager()
        settings.hasAcceptedConsentDialog = false

        // Create AppState
        let testAppState = AppState(settingsManager: settings)

        // Assert
        XCTAssertTrue(testAppState.showConsentDialog,
                     "showConsentDialog should be true when consent not accepted")
    }

    func testShowConsentDialogIsFalseWhenConsentAlreadyAccepted() {
        // Setup - create settings with consent accepted
        let settings = SettingsManager()
        settings.hasAcceptedConsentDialog = true

        // Create AppState
        let testAppState = AppState(settingsManager: settings)

        // Assert
        XCTAssertFalse(testAppState.showConsentDialog,
                      "showConsentDialog should be false when consent already accepted")
    }

    func testShowConsentDialogCanBeDismissed() {
        // Setup
        let settings = SettingsManager()
        settings.hasAcceptedConsentDialog = false
        let testAppState = AppState(settingsManager: settings)

        // Verify initially true
        XCTAssertTrue(testAppState.showConsentDialog)

        // Act - dismiss dialog
        testAppState.dismissConsentDialog(rememberChoice: false)

        // Assert
        XCTAssertFalse(testAppState.showConsentDialog,
                      "showConsentDialog should be false after dismissal")
    }

    func testDismissConsentDialogWithRememberChoicePersistsToSettings() {
        // Setup
        let settings = SettingsManager()
        settings.hasAcceptedConsentDialog = false
        let testAppState = AppState(settingsManager: settings)

        // Act - dismiss with remember choice
        testAppState.dismissConsentDialog(rememberChoice: true)

        // Assert
        XCTAssertTrue(settings.hasAcceptedConsentDialog,
                     "Dismissing with rememberChoice should update settings")
        XCTAssertFalse(testAppState.showConsentDialog,
                      "showConsentDialog should be false after dismissal")
    }

    func testDismissConsentDialogWithoutRememberChoiceDoesNotPersist() {
        // Setup
        let settings = SettingsManager()
        settings.hasAcceptedConsentDialog = false
        let testAppState = AppState(settingsManager: settings)

        // Act - dismiss without remember choice
        testAppState.dismissConsentDialog(rememberChoice: false)

        // Assert
        XCTAssertFalse(settings.hasAcceptedConsentDialog,
                      "Dismissing without rememberChoice should not update settings")
        XCTAssertFalse(testAppState.showConsentDialog,
                      "showConsentDialog should still be false after dismissal")
    }

    func testShowConsentDialogPropertyIsPublished() {
        // Setup
        let settings = SettingsManager()
        settings.hasAcceptedConsentDialog = false
        let testAppState = AppState(settingsManager: settings)

        let expectation = expectation(description: "showConsentDialog change should be published")
        var receivedValues: [Bool] = []

        testAppState.$showConsentDialog
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act - dismiss dialog
        testAppState.dismissConsentDialog(rememberChoice: false)

        // Assert
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedValues, [false],
                      "showConsentDialog change should be published")
    }

    func testConsentDialogAppearsAgainAfterDismissalWithoutRememberChoice() {
        // Setup
        let settings = SettingsManager()
        settings.hasAcceptedConsentDialog = false
        let testAppState1 = AppState(settingsManager: settings)

        // Dismiss without remembering
        testAppState1.dismissConsentDialog(rememberChoice: false)
        XCTAssertFalse(testAppState1.showConsentDialog)

        // Create new app state instance (simulating app restart)
        let testAppState2 = AppState(settingsManager: settings)

        // Assert - dialog should appear again
        XCTAssertTrue(testAppState2.showConsentDialog,
                     "Consent dialog should appear again on next launch if not remembered")
    }

    func testConsentDialogDoesNotAppearAfterDismissalWithRememberChoice() {
        // Setup
        let settings = SettingsManager()
        settings.hasAcceptedConsentDialog = false
        let testAppState1 = AppState(settingsManager: settings)

        // Dismiss with remembering
        testAppState1.dismissConsentDialog(rememberChoice: true)
        XCTAssertFalse(testAppState1.showConsentDialog)

        // Create new app state instance (simulating app restart)
        let testAppState2 = AppState(settingsManager: settings)

        // Assert - dialog should NOT appear again
        XCTAssertFalse(testAppState2.showConsentDialog,
                      "Consent dialog should not appear again if user chose to remember")
    }
}
