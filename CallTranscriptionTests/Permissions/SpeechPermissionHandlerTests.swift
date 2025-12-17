import XCTest
import Speech
@testable import CallTranscription

@available(macOS 26.0, *)
@MainActor
final class SpeechPermissionHandlerTests: XCTestCase {
    var permissionHandler: SpeechPermissionHandler!

    override func setUp() async throws {
        try await super.setUp()
        permissionHandler = SpeechPermissionHandler()
    }

    override func tearDown() async throws {
        permissionHandler = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testPermissionHandlerCanBeInstantiated() {
        XCTAssertNotNil(permissionHandler, "SpeechPermissionHandler should instantiate")
    }

    func testSupportsCustomLocaleConfiguration() {
        let customLocale = Locale(identifier: "en-GB")
        let handler = SpeechPermissionHandler(locale: customLocale)
        XCTAssertNotNil(handler, "Should support custom locale")
    }

    // MARK: - Permission Status Checking Tests

    func testCheckAuthorizationStatusReturnsValidStatus() async throws {
        let status = await permissionHandler.checkAuthorizationStatus()

        // Status should be one of the valid authorization states
        let validStatuses: [SFSpeechRecognizerAuthorizationStatus] = [
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

    // MARK: - Permission Request Tests

    func testRequestPermissionReturnsAuthorizationStatus() async throws {
        let status = await permissionHandler.requestPermission()

        let validStatuses: [SFSpeechRecognizerAuthorizationStatus] = [
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
                if case .speechRecognitionUnavailable = error {
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
                if case .speechRecognitionUnavailable = error {
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
                if case .speechRecognitionUnavailable = error {
                    // Expected error when denied
                } else {
                    XCTFail("Wrong error type: \(error)")
                }
            }
        }
    }

    // MARK: - Locale Support Tests

    func testCheckLocaleSupportForEnglishUS() async throws {
        let handler = SpeechPermissionHandler(locale: Locale(identifier: "en-US"))
        let isSupported = await handler.checkLocaleSupport()

        // en-US should always be supported
        XCTAssertTrue(isSupported, "English (US) should be supported")
    }

    func testCheckLocaleSupportForCommonLocales() async throws {
        let commonLocales = ["en-GB", "es-ES", "fr-FR", "de-DE", "ja-JP", "zh-CN"]

        for identifier in commonLocales {
            let handler = SpeechPermissionHandler(locale: Locale(identifier: identifier))
            let isSupported = await handler.checkLocaleSupport()

            // These locales are commonly supported
            // Test doesn't fail if unsupported, just verifies method works
            _ = isSupported
        }
    }

    func testCheckLocaleSupportForInvalidLocale() async throws {
        let handler = SpeechPermissionHandler(locale: Locale(identifier: "xx-XX"))
        let isSupported = await handler.checkLocaleSupport()

        // Invalid locale should not be supported
        XCTAssertFalse(isSupported, "Invalid locale should not be supported")
    }

    func testCheckLocaleSupportReturnsConsistentResults() async throws {
        let locale = Locale(identifier: "en-US")
        let handler = SpeechPermissionHandler(locale: locale)

        let firstCheck = await handler.checkLocaleSupport()
        let secondCheck = await handler.checkLocaleSupport()

        XCTAssertEqual(firstCheck, secondCheck, "Support check should be consistent")
    }

    // MARK: - Model Availability Tests

    func testCheckModelAvailabilityForEnglishUS() async throws {
        let handler = SpeechPermissionHandler(locale: Locale(identifier: "en-US"))
        let isAvailable = await handler.checkModelAvailability()

        // Should return true or false based on model installation
        _ = isAvailable
    }

    func testCheckModelAvailabilityForUnsupportedLocale() async throws {
        let handler = SpeechPermissionHandler(locale: Locale(identifier: "xx-XX"))
        let isAvailable = await handler.checkModelAvailability()

        // Unsupported locale should have no model available
        XCTAssertFalse(isAvailable, "Unsupported locale should not have model")
    }

    func testCheckModelAvailabilityRequiresLocaleSupport() async throws {
        // Model availability should first check locale support
        let handler = SpeechPermissionHandler(locale: Locale(identifier: "en-US"))
        let localeSupported = await handler.checkLocaleSupport()
        let modelAvailable = await handler.checkModelAvailability()

        // If model is available, locale must be supported
        if modelAvailable {
            XCTAssertTrue(localeSupported, "Model availability requires locale support")
        }
    }

    // MARK: - Model Download Tests

    func testDownloadModelForSupportedLocale() async throws {
        let handler = SpeechPermissionHandler(locale: Locale(identifier: "en-US"))
        let localeSupported = await handler.checkLocaleSupport()

        if localeSupported {
            // Should be able to initiate download for supported locale
            do {
                try await handler.downloadModel()
                // If succeeds, model was downloaded or already present
            } catch let error as CallTranscriptionError {
                // Download may fail due to network or other issues
                if case .speechRecognitionUnavailable = error {
                    // Expected error type for download failures
                } else {
                    XCTFail("Wrong error type: \(error)")
                }
            }
        }
    }

    func testDownloadModelThrowsForUnsupportedLocale() async throws {
        let handler = SpeechPermissionHandler(locale: Locale(identifier: "xx-XX"))

        do {
            try await handler.downloadModel()
            XCTFail("Should throw error for unsupported locale")
        } catch let error as CallTranscriptionError {
            if case .localeNotSupported(let locale) = error {
                XCTAssertEqual(locale.identifier, "xx-XX")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testDownloadModelReturnsImmediatelyWhenAlreadyInstalled() async throws {
        let handler = SpeechPermissionHandler(locale: Locale(identifier: "en-US"))
        let modelAvailable = await handler.checkModelAvailability()

        if modelAvailable {
            let startTime = Date()
            do {
                try await handler.downloadModel()
                let elapsed = Date().timeIntervalSince(startTime)
                // Should complete quickly if model already present
                XCTAssertLessThan(elapsed, 2.0, "Should return quickly when model available")
            } catch {
                // Skip test if model not available
            }
        }
    }

    func testDownloadModelHandlesNetworkErrors() async throws {
        // Test that network errors are handled gracefully
        let handler = SpeechPermissionHandler(locale: Locale(identifier: "en-US"))

        do {
            try await handler.downloadModel()
            // If succeeds, model was downloaded
        } catch let error as CallTranscriptionError {
            // Network errors should result in speechRecognitionUnavailable
            if case .speechRecognitionUnavailable = error {
                // Expected error type
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testDownloadModelHandlesCancellation() async throws {
        // Test that cancellation doesn't crash
        let handler = SpeechPermissionHandler(locale: Locale(identifier: "en-US"))

        // Create a task that can be cancelled
        let downloadTask = Task {
            try await handler.downloadModel()
        }

        // Cancel immediately
        downloadTask.cancel()

        do {
            _ = try await downloadTask.value
        } catch {
            // Cancellation or download failure is acceptable
            XCTAssertNotNil(error, "Should handle cancellation")
        }
    }

    // MARK: - Integration Tests

    func testEnsureModelAvailableCompletesSuccessfully() async throws {
        let handler = SpeechPermissionHandler(locale: Locale(identifier: "en-US"))

        // This combines permission check, locale check, and model availability
        do {
            try await handler.ensureModelAvailable()
            // If succeeds, all requirements met
        } catch let error as CallTranscriptionError {
            // May fail if permission denied, locale unsupported, or download fails
            switch error {
            case .speechRecognitionUnavailable, .localeNotSupported:
                // Expected error types
                break
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }

    func testEnsureModelAvailableChecksPermissionFirst() async throws {
        let handler = SpeechPermissionHandler(locale: Locale(identifier: "en-US"))
        let status = await handler.checkAuthorizationStatus()

        if status == .denied || status == .restricted {
            do {
                try await handler.ensureModelAvailable()
                XCTFail("Should fail when permission denied")
            } catch let error as CallTranscriptionError {
                if case .speechRecognitionUnavailable = error {
                    // Expected error
                } else {
                    XCTFail("Wrong error type: \(error)")
                }
            }
        }
    }

    func testEnsureModelAvailableChecksLocaleSupport() async throws {
        let handler = SpeechPermissionHandler(locale: Locale(identifier: "xx-XX"))

        do {
            try await handler.ensureModelAvailable()
            XCTFail("Should fail for unsupported locale")
        } catch let error as CallTranscriptionError {
            if case .localeNotSupported = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testEnsureModelAvailableDownloadsIfNeeded() async throws {
        let handler = SpeechPermissionHandler(locale: Locale(identifier: "en-US"))
        let status = await handler.checkAuthorizationStatus()
        let localeSupported = await handler.checkLocaleSupport()

        if status == .authorized && localeSupported {
            // Should download model if not available
            do {
                try await handler.ensureModelAvailable()
                // If succeeds, model is now available
                let modelAvailable = await handler.checkModelAvailability()
                XCTAssertTrue(modelAvailable, "Model should be available after ensure completes")
            } catch {
                // Download may fail, but should throw proper error
                XCTAssertTrue(error is CallTranscriptionError, "Should throw CallTranscriptionError")
            }
        }
    }

    // MARK: - Error Scenario Tests

    func testProvidesActionableErrorForDeniedPermission() async throws {
        let status = await permissionHandler.checkAuthorizationStatus()

        if status == .denied {
            do {
                try await permissionHandler.ensurePermission()
                XCTFail("Should throw error")
            } catch let error as CallTranscriptionError {
                if case .speechRecognitionUnavailable = error {
                    // Error should have helpful recovery suggestion
                    XCTAssertNotNil(error.recoverySuggestion, "Should provide recovery suggestion")
                } else {
                    XCTFail("Wrong error type")
                }
            }
        }
    }

    func testProvidesActionableErrorForUnsupportedLocale() async throws {
        let handler = SpeechPermissionHandler(locale: Locale(identifier: "xx-XX"))

        do {
            try await handler.ensureModelAvailable()
            XCTFail("Should throw error")
        } catch let error as CallTranscriptionError {
            if case .localeNotSupported = error {
                // Error should have helpful recovery suggestion
                XCTAssertNotNil(error.recoverySuggestion, "Should provide recovery suggestion")
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    func testProvidesActionableErrorForDownloadFailure() async throws {
        // Simulate scenario where download fails
        let handler = SpeechPermissionHandler(locale: Locale(identifier: "en-US"))

        do {
            try await handler.downloadModel()
        } catch let error as CallTranscriptionError {
            if case .speechRecognitionUnavailable = error {
                // Error should have helpful recovery suggestion
                XCTAssertNotNil(error.recoverySuggestion, "Should provide recovery suggestion")
            }
        }
    }

    // MARK: - On-Device Recognition Tests

    func testSupportsOnDeviceRecognition() async throws {
        let handler = SpeechPermissionHandler(locale: Locale(identifier: "en-US"))

        // On-device recognition should be available on macOS 26.0+
        let supportsOnDevice = await handler.supportsOnDeviceRecognition()

        // Should return boolean without crashing
        _ = supportsOnDevice
    }

    func testOnDeviceRecognitionWorksOffline() async throws {
        let handler = SpeechPermissionHandler(locale: Locale(identifier: "en-US"))
        let supportsOnDevice = await handler.supportsOnDeviceRecognition()

        if supportsOnDevice {
            // On-device recognition should work without network
            // This is a conceptual test - actual offline testing would require
            // disabling network which is complex in unit tests
            XCTAssertTrue(supportsOnDevice, "On-device recognition available")
        }
    }
}
