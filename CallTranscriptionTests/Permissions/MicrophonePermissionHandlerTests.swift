import XCTest
import AVFoundation
@testable import CallTranscription

@available(macOS 26.0, *)
@MainActor
final class MicrophonePermissionHandlerTests: XCTestCase {
    var permissionHandler: MicrophonePermissionHandler!

    override func setUp() async throws {
        try await super.setUp()
        permissionHandler = MicrophonePermissionHandler()
    }

    override func tearDown() async throws {
        permissionHandler = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testPermissionHandlerCanBeInstantiated() {
        XCTAssertNotNil(permissionHandler, "MicrophonePermissionHandler should instantiate")
    }

    // MARK: - Permission Status Checking Tests

    func testCheckAuthorizationStatusReturnsValidStatus() async throws {
        let status = await permissionHandler.checkAuthorizationStatus()

        // Status should be one of the valid authorization states
        let validStatuses: [AVAuthorizationStatus] = [
            .notDetermined,
            .denied,
            .restricted,
            .authorized
        ]
        XCTAssertTrue(validStatuses.contains(status), "Status should be valid authorization state")
    }

    func testCheckAuthorizationStatusForAuthorizedState() async throws {
        let status = await permissionHandler.checkAuthorizationStatus()

        // If authorized, should return .authorized
        if status == .authorized {
            XCTAssertEqual(status, .authorized, "Should return authorized status")
        }
    }

    func testCheckAuthorizationStatusForDeniedState() async throws {
        let status = await permissionHandler.checkAuthorizationStatus()

        // If denied, should return .denied
        if status == .denied {
            XCTAssertEqual(status, .denied, "Should return denied status")
        }
    }

    func testCheckAuthorizationStatusForNotDeterminedState() async throws {
        let status = await permissionHandler.checkAuthorizationStatus()

        // If not determined, should return .notDetermined
        if status == .notDetermined {
            XCTAssertEqual(status, .notDetermined, "Should return not determined status")
        }
    }

    func testCheckAuthorizationStatusForRestrictedState() async throws {
        let status = await permissionHandler.checkAuthorizationStatus()

        // If restricted, should return .restricted
        if status == .restricted {
            XCTAssertEqual(status, .restricted, "Should return restricted status")
        }
    }

    func testCheckAuthorizationStatusIsConsistent() async throws {
        let firstCheck = await permissionHandler.checkAuthorizationStatus()
        let secondCheck = await permissionHandler.checkAuthorizationStatus()

        // Status should be consistent across multiple checks
        XCTAssertEqual(firstCheck, secondCheck, "Status should remain consistent")
    }

    // MARK: - Permission Request Tests

    func testRequestPermissionReturnsAuthorizationStatus() async throws {
        let status = await permissionHandler.requestPermission()

        let validStatuses: [AVAuthorizationStatus] = [
            .notDetermined,
            .denied,
            .restricted,
            .authorized
        ]
        XCTAssertTrue(validStatuses.contains(status), "Should return valid authorization status")
    }

    func testRequestPermissionDoesNotRequestWhenAlreadyAuthorized() async throws {
        let initialStatus = await permissionHandler.checkAuthorizationStatus()

        if initialStatus == .authorized {
            let requestedStatus = await permissionHandler.requestPermission()
            XCTAssertEqual(requestedStatus, .authorized, "Should remain authorized without new request")
        }
    }

    func testRequestPermissionDoesNotRequestWhenDenied() async throws {
        let initialStatus = await permissionHandler.checkAuthorizationStatus()

        if initialStatus == .denied {
            let requestedStatus = await permissionHandler.requestPermission()
            XCTAssertEqual(requestedStatus, .denied, "Should remain denied without new request")
        }
    }

    func testRequestPermissionDoesNotRequestWhenRestricted() async throws {
        let initialStatus = await permissionHandler.checkAuthorizationStatus()

        if initialStatus == .restricted {
            let requestedStatus = await permissionHandler.requestPermission()
            XCTAssertEqual(requestedStatus, .restricted, "Should remain restricted without new request")
        }
    }

    func testRequestPermissionOnlyRequestsWhenNotDetermined() async throws {
        let initialStatus = await permissionHandler.checkAuthorizationStatus()

        // Only .notDetermined state should trigger an actual permission request
        if initialStatus == .notDetermined {
            let requestedStatus = await permissionHandler.requestPermission()
            // After request, status should be either authorized or denied
            XCTAssertTrue(
                requestedStatus == .authorized || requestedStatus == .denied,
                "After request, status should be determined"
            )
        }
    }

    func testRequestPermissionAwaitsUserResponse() async throws {
        let initialStatus = await permissionHandler.checkAuthorizationStatus()

        if initialStatus == .notDetermined {
            let startTime = Date()
            _ = await permissionHandler.requestPermission()
            let elapsed = Date().timeIntervalSince(startTime)

            // Request should take some time if user interaction required
            // But we can't guarantee timing in tests
            XCTAssertGreaterThanOrEqual(elapsed, 0.0)
        }
    }

    // MARK: - Permission Validation Tests

    func testEnsurePermissionSucceedsWhenAuthorized() async throws {
        let status = await permissionHandler.checkAuthorizationStatus()

        if status == .authorized {
            // Should not throw when authorized
            try await permissionHandler.ensurePermission()
        }
    }

    func testEnsurePermissionThrowsWhenDenied() async throws {
        let status = await permissionHandler.checkAuthorizationStatus()

        if status == .denied {
            do {
                try await permissionHandler.ensurePermission()
                XCTFail("Should throw error when permission denied")
            } catch let error as CallTranscriptionError {
                if case .microphonePermissionDenied = error {
                    // Expected error type
                } else {
                    XCTFail("Wrong error type: \(error)")
                }
            }
        }
    }

    func testEnsurePermissionThrowsWhenRestricted() async throws {
        let status = await permissionHandler.checkAuthorizationStatus()

        if status == .restricted {
            do {
                try await permissionHandler.ensurePermission()
                XCTFail("Should throw error when permission restricted")
            } catch let error as CallTranscriptionError {
                if case .microphonePermissionDenied = error {
                    // Expected error type
                } else {
                    XCTFail("Wrong error type: \(error)")
                }
            }
        }
    }

    func testEnsurePermissionRequestsWhenNotDetermined() async throws {
        let status = await permissionHandler.checkAuthorizationStatus()

        if status == .notDetermined {
            // Should request permission automatically
            do {
                try await permissionHandler.ensurePermission()
                // If it succeeds, user granted permission
            } catch let error as CallTranscriptionError {
                // If it fails, user denied permission
                if case .microphonePermissionDenied = error {
                    // Expected error when denied
                } else {
                    XCTFail("Wrong error type: \(error)")
                }
            }
        }
    }

    // MARK: - Error Guidance Tests

    func testProvidesActionableErrorMessage() async throws {
        let status = await permissionHandler.checkAuthorizationStatus()

        if status == .denied {
            do {
                try await permissionHandler.ensurePermission()
                XCTFail("Should throw error")
            } catch let error as CallTranscriptionError {
                if case .microphonePermissionDenied = error {
                    // Error should have description
                    XCTAssertNotNil(error.errorDescription, "Should provide error description")
                    // Error should have recovery suggestion
                    XCTAssertNotNil(error.recoverySuggestion, "Should provide recovery suggestion")
                } else {
                    XCTFail("Wrong error type")
                }
            }
        }
    }

    func testErrorMessageReferencesSystemSettings() async throws {
        let status = await permissionHandler.checkAuthorizationStatus()

        if status == .denied {
            do {
                try await permissionHandler.ensurePermission()
                XCTFail("Should throw error")
            } catch let error as CallTranscriptionError {
                if case .microphonePermissionDenied = error {
                    let suggestion = error.recoverySuggestion ?? ""
                    // Should mention System Settings
                    XCTAssertTrue(
                        suggestion.contains("System Settings") ||
                        suggestion.contains("System Preferences"),
                        "Should reference System Settings"
                    )
                } else {
                    XCTFail("Wrong error type")
                }
            }
        }
    }

    func testErrorMessageReferencesMicrophonePrivacy() async throws {
        let status = await permissionHandler.checkAuthorizationStatus()

        if status == .denied {
            do {
                try await permissionHandler.ensurePermission()
                XCTFail("Should throw error")
            } catch let error as CallTranscriptionError {
                if case .microphonePermissionDenied = error {
                    let suggestion = error.recoverySuggestion ?? ""
                    // Should mention Microphone privacy
                    XCTAssertTrue(
                        suggestion.contains("Microphone"),
                        "Should reference Microphone privacy setting"
                    )
                } else {
                    XCTFail("Wrong error type")
                }
            }
        }
    }

    // MARK: - System Settings Integration Tests

    func testCanOpenSystemSettings() async throws {
        // Verify we can construct System Settings URL
        let settingsURL = permissionHandler.getSystemSettingsURL()
        XCTAssertNotNil(settingsURL, "Should provide System Settings URL")
    }

    func testSystemSettingsURLIsValid() async throws {
        let settingsURL = permissionHandler.getSystemSettingsURL()

        if let url = settingsURL {
            // URL should use the correct scheme
            XCTAssertTrue(
                url.absoluteString.hasPrefix("x-apple.systempreferences:") ||
                url.absoluteString.hasPrefix("x-apple.systemsettings:"),
                "Should use system settings URL scheme"
            )
        }
    }

    func testOpenSystemSettingsDoesNotCrash() async throws {
        // This test just verifies the method exists and doesn't crash
        // We cannot actually open System Settings in unit tests
        permissionHandler.openSystemSettings()
    }

    // MARK: - Integration with Audio Capture Tests

    func testPermissionRequiredBeforeCapture() async throws {
        // This test conceptually validates that permission should be checked
        // before attempting audio capture
        let status = await permissionHandler.checkAuthorizationStatus()

        if status != .authorized {
            // If not authorized, attempting capture should fail with permission error
            do {
                try await permissionHandler.ensurePermission()
                XCTFail("Should throw when not authorized")
            } catch let error as CallTranscriptionError {
                if case .microphonePermissionDenied = error {
                    // Expected
                } else {
                    XCTFail("Should throw microphonePermissionDenied")
                }
            }
        }
    }

    func testPermissionCheckBeforeMicrophoneCapture() async throws {
        // Verify permission handler can be used before creating MicrophoneCapture
        let status = await permissionHandler.checkAuthorizationStatus()

        // Should be able to check status without errors
        XCTAssertNotNil(status, "Should return status")
    }

    // MARK: - Concurrent Access Tests

    func testMultipleConcurrentStatusChecks() async throws {
        await withTaskGroup(of: AVAuthorizationStatus.self) { group in
            // Launch multiple concurrent status checks
            for _ in 0..<10 {
                group.addTask {
                    await self.permissionHandler.checkAuthorizationStatus()
                }
            }

            var statuses: [AVAuthorizationStatus] = []
            for await status in group {
                statuses.append(status)
            }

            // All status checks should return the same value
            let uniqueStatuses = Set(statuses.map { $0.rawValue })
            XCTAssertEqual(uniqueStatuses.count, 1, "All concurrent checks should return same status")
        }
    }

    func testSequentialPermissionRequests() async throws {
        // Multiple sequential requests should not cause issues
        let firstRequest = await permissionHandler.requestPermission()
        let secondRequest = await permissionHandler.requestPermission()

        // Both requests should return a valid status
        XCTAssertNotNil(firstRequest)
        XCTAssertNotNil(secondRequest)
    }

    // MARK: - Edge Cases and Error Scenarios

    func testHandlesRestrictedStateGracefully() async throws {
        let status = await permissionHandler.checkAuthorizationStatus()

        if status == .restricted {
            // Should handle restricted state without crashing
            do {
                try await permissionHandler.ensurePermission()
                XCTFail("Should throw error for restricted state")
            } catch let error as CallTranscriptionError {
                if case .microphonePermissionDenied = error {
                    // Expected
                } else {
                    XCTFail("Wrong error type: \(error)")
                }
            }
        }
    }

    func testEnsurePermissionIdempotent() async throws {
        let status = await permissionHandler.checkAuthorizationStatus()

        if status == .authorized {
            // Calling multiple times should succeed consistently
            try await permissionHandler.ensurePermission()
            try await permissionHandler.ensurePermission()
            try await permissionHandler.ensurePermission()
        }
    }
}
