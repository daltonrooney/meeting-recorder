import XCTest
import AVFoundation
import Combine
@testable import CallTranscription

@MainActor
final class MicrophonePermissionStateTests: XCTestCase {

    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        cancellables = []
    }

    override func tearDown() async throws {
        cancellables = nil
        try await super.tearDown()
    }

    // MARK: - AppState Permission Property Tests

    func testAppStateHasMicrophonePermissionGrantedProperty() {
        let appState = AppState()

        // Property should exist and be readable
        let _ = appState.microphonePermissionGranted

        // Property should be @Published (has objectWillChange)
        XCTAssertNotNil(appState.objectWillChange,
                       "AppState should conform to ObservableObject")
    }

    func testMicrophonePermissionGrantedDefaultsBasedOnSystemStatus() {
        let appState = AppState()
        let systemStatus = MicrophonePermissionHandler.checkAuthorizationStatus()
        let expectedValue = (systemStatus == .authorized)

        XCTAssertEqual(appState.microphonePermissionGranted, expectedValue,
                      "microphonePermissionGranted should match system authorization status")
    }

    func testMicrophonePermissionGrantedPropertyIsPublished() {
        let appState = AppState()
        let expectation = expectation(description: "microphonePermissionGranted change should be published")
        var receivedValues: [Bool] = []

        appState.$microphonePermissionGranted
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Trigger change by updating permission status
        Task {
            await appState.updateMicrophonePermissionStatus()
        }

        wait(for: [expectation], timeout: 2.0)
        XCTAssertFalse(receivedValues.isEmpty,
                      "microphonePermissionGranted changes should be published")
    }

    func testUpdateMicrophonePermissionStatusChecksSystemPermission() async {
        let appState = AppState()

        await appState.updateMicrophonePermissionStatus()

        let systemStatus = MicrophonePermissionHandler.checkAuthorizationStatus()
        let expectedValue = (systemStatus == .authorized)

        XCTAssertEqual(appState.microphonePermissionGranted, expectedValue,
                      "updateMicrophonePermissionStatus should sync with system permission")
    }

    func testUpdateMicrophonePermissionStatusSetsToTrueWhenAuthorized() async {
        let appState = AppState()

        // If system is authorized, property should be true
        await appState.updateMicrophonePermissionStatus()

        let systemStatus = MicrophonePermissionHandler.checkAuthorizationStatus()
        if systemStatus == .authorized {
            XCTAssertTrue(appState.microphonePermissionGranted,
                         "Should be true when system permission is authorized")
        }
    }

    func testUpdateMicrophonePermissionStatusSetsToFalseWhenNotAuthorized() async {
        let appState = AppState()

        await appState.updateMicrophonePermissionStatus()

        let systemStatus = MicrophonePermissionHandler.checkAuthorizationStatus()
        if systemStatus != .authorized {
            XCTAssertFalse(appState.microphonePermissionGranted,
                          "Should be false when system permission is not authorized")
        }
    }

    // MARK: - Permission Monitoring Tests

    func testPermissionStatusIsCheckedAtAppStateInit() {
        let appState = AppState()

        // Permission should be checked during initialization
        let systemStatus = MicrophonePermissionHandler.checkAuthorizationStatus()
        let expectedValue = (systemStatus == .authorized)

        XCTAssertEqual(appState.microphonePermissionGranted, expectedValue,
                      "Permission should be checked at initialization")
    }

    func testPermissionStatusCanBeRefreshedManually() async {
        let appState = AppState()

        let initialValue = appState.microphonePermissionGranted

        // Manually refresh
        await appState.updateMicrophonePermissionStatus()

        // Value should reflect current system status
        let systemStatus = MicrophonePermissionHandler.checkAuthorizationStatus()
        let expectedValue = (systemStatus == .authorized)

        XCTAssertEqual(appState.microphonePermissionGranted, expectedValue,
                      "Should be able to manually refresh permission status")
    }

    // MARK: - Start Recording Permission Check Tests

    func testStartActualRecordingChecksPermissionBeforeStarting() async {
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        settings.captureMicrophone = true // Microphone enabled

        let appState = AppState(settingsManager: settings)

        // If permission is not granted, starting recording should fail
        if !appState.microphonePermissionGranted {
            do {
                try await appState.startActualRecording(title: "Test")
                XCTFail("Should throw error when microphone permission not granted")
            } catch CallTranscriptionError.microphonePermissionDenied {
                // Expected error
                XCTAssertFalse(appState.isRecording,
                              "Should not be recording after permission error")
            } catch {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testStartActualRecordingSucceedsWhenPermissionGranted() async throws {
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        settings.captureMicrophone = true

        let appState = AppState(settingsManager: settings)

        // If permission is granted, recording should start
        if appState.microphonePermissionGranted {
            try await appState.startActualRecording(title: "Test")
            XCTAssertTrue(appState.isRecording,
                         "Should start recording when permission granted")

            // Cleanup
            _ = try await appState.stopActualRecording()
        }
    }

    func testStartActualRecordingSkipsPermissionCheckWhenMicrophoneDisabled() async throws {
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        settings.captureMicrophone = false // Microphone disabled in settings
        settings.captureSystemAudio = true

        let appState = AppState(settingsManager: settings)

        // Recording should start even if microphone permission not granted
        // because microphone is disabled in settings
        try await appState.startActualRecording(title: "Test")
        XCTAssertTrue(appState.isRecording,
                     "Should start recording when microphone is disabled in settings")

        // Cleanup
        _ = try await appState.stopActualRecording()
    }

    func testStartActualRecordingThrowsMicrophonePermissionDeniedError() async {
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        settings.captureMicrophone = true

        let appState = AppState(settingsManager: settings)

        // If permission not granted, should throw specific error
        if !appState.microphonePermissionGranted {
            do {
                try await appState.startActualRecording(title: "Test")
                XCTFail("Should throw microphonePermissionDenied error")
            } catch CallTranscriptionError.microphonePermissionDenied {
                // Expected error type
                XCTAssertTrue(true, "Correct error type thrown")
            } catch {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testStartActualRecordingErrorIncludesRecoverySuggestion() async {
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        settings.captureMicrophone = true

        let appState = AppState(settingsManager: settings)

        if !appState.microphonePermissionGranted {
            do {
                try await appState.startActualRecording(title: "Test")
                XCTFail("Should throw error")
            } catch let error as CallTranscriptionError {
                // Error should have recovery suggestion
                XCTAssertNotNil(error.recoverySuggestion,
                               "Error should include recovery suggestion")
                XCTAssertTrue(error.recoverySuggestion?.contains("Settings") ?? false,
                             "Recovery suggestion should mention Settings")
            } catch {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Integration Tests

    func testPermissionStatusReflectsActualSystemState() {
        let appState = AppState()
        let systemStatus = MicrophonePermissionHandler.checkAuthorizationStatus()

        switch systemStatus {
        case .authorized:
            XCTAssertTrue(appState.microphonePermissionGranted,
                         "Should be true when system permission is authorized")
        case .notDetermined, .denied, .restricted:
            XCTAssertFalse(appState.microphonePermissionGranted,
                          "Should be false when system permission is not authorized")
        @unknown default:
            XCTFail("Unknown authorization status")
        }
    }

    func testMultiplePermissionChecksAreConsistent() async {
        let appState = AppState()

        let check1 = appState.microphonePermissionGranted
        await appState.updateMicrophonePermissionStatus()
        let check2 = appState.microphonePermissionGranted
        await appState.updateMicrophonePermissionStatus()
        let check3 = appState.microphonePermissionGranted

        // All checks should be consistent (system permission doesn't change during test)
        XCTAssertEqual(check1, check2,
                      "Permission checks should be consistent")
        XCTAssertEqual(check2, check3,
                      "Permission checks should be consistent")
    }

    func testPermissionCheckIsMainActorSafe() async {
        let appState = AppState()

        // All property access should be safe from main actor
        await MainActor.run {
            let _ = appState.microphonePermissionGranted
        }
    }

    // MARK: - Edge Cases

    func testPermissionStatusAfterRecordingError() async {
        let settings = SettingsManager()
        settings.outputFolder = NSTemporaryDirectory()
        settings.captureMicrophone = true

        let appState = AppState(settingsManager: settings)

        if !appState.microphonePermissionGranted {
            // Try to start recording (will fail)
            do {
                try await appState.startActualRecording(title: "Test")
            } catch {
                // Expected error
            }

            // Permission status should still be accurate
            let systemStatus = MicrophonePermissionHandler.checkAuthorizationStatus()
            let expectedValue = (systemStatus == .authorized)

            XCTAssertEqual(appState.microphonePermissionGranted, expectedValue,
                          "Permission status should remain accurate after error")
        }
    }

    func testPermissionStatusCanChangeAtRuntime() async {
        let appState = AppState()

        let initialStatus = appState.microphonePermissionGranted

        // Simulate permission change by refreshing status
        // (In real app, user would grant/revoke in System Settings)
        await appState.updateMicrophonePermissionStatus()

        let newStatus = appState.microphonePermissionGranted

        // Status should be retrievable (may or may not have changed)
        let _ = newStatus // Verify property is accessible

        // Permission status should match system
        let systemStatus = MicrophonePermissionHandler.checkAuthorizationStatus()
        XCTAssertEqual(newStatus, systemStatus == .authorized,
                      "Permission status should match system")
    }
}
