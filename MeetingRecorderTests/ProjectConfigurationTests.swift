import XCTest

/// Runtime configuration tests that verify the BUILT app bundle has correct settings.
///
/// These tests complement the build-time validation script (scripts/validate-configuration.swift):
/// - Build script: Prevents bad builds by validating source files at build time
/// - These tests: Verify the built app bundle has correct runtime configuration
///
/// This follows best practices: build-time validation for fail-fast, runtime tests for verification.
final class ProjectConfigurationTests: XCTestCase {

    // MARK: - Privacy Keys Tests

    func testInfoPlistContainsRequiredPrivacyKeys() throws {
        let bundle = Bundle(for: type(of: self))

        // Test microphone usage description
        let microphoneDesc = bundle.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") as? String
        XCTAssertNotNil(microphoneDesc, "NSMicrophoneUsageDescription must be present")
        XCTAssertFalse(microphoneDesc?.isEmpty ?? true, "NSMicrophoneUsageDescription must not be empty")
        XCTAssertTrue(microphoneDesc?.contains("microphone") ?? false,
                      "Microphone description should mention 'microphone'")

        // Test speech recognition usage description
        let speechDesc = bundle.object(forInfoDictionaryKey: "NSSpeechRecognitionUsageDescription") as? String
        XCTAssertNotNil(speechDesc, "NSSpeechRecognitionUsageDescription must be present")
        XCTAssertFalse(speechDesc?.isEmpty ?? true, "NSSpeechRecognitionUsageDescription must not be empty")
        XCTAssertTrue(speechDesc?.contains("speech") ?? false,
                      "Speech recognition description should mention 'speech'")
    }

    func testPrivacyDescriptionsAreUserFriendly() throws {
        let bundle = Bundle(for: type(of: self))

        let microphoneDesc = bundle.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") as? String
        let speechDesc = bundle.object(forInfoDictionaryKey: "NSSpeechRecognitionUsageDescription") as? String

        // Privacy descriptions should be meaningful, not just placeholders
        XCTAssertTrue((microphoneDesc?.count ?? 0) > 20,
                      "Microphone description should be descriptive (>20 chars)")
        XCTAssertTrue((speechDesc?.count ?? 0) > 20,
                      "Speech description should be descriptive (>20 chars)")

        // Should not contain placeholder text
        XCTAssertFalse(microphoneDesc?.contains("TODO") ?? false)
        XCTAssertFalse(speechDesc?.contains("TODO") ?? false)
        XCTAssertFalse(microphoneDesc?.contains("placeholder") ?? false)
        XCTAssertFalse(speechDesc?.contains("placeholder") ?? false)
    }

    // MARK: - Bundle Configuration Tests

    func testBundleIdentifierIsCorrect() throws {
        let bundle = Bundle(for: type(of: self))
        let bundleId = bundle.bundleIdentifier

        XCTAssertNotNil(bundleId, "Bundle identifier must be set")
        XCTAssertTrue(bundleId?.hasPrefix("com.daltonrooney.") ?? false,
                      "Bundle ID should use correct prefix")
    }

    func testBundleVersionsAreSet() throws {
        // Test the main app bundle, not the test bundle
        guard let appBundle = Bundle.allBundles.first(where: { $0.bundleIdentifier == "com.daltonrooney.MeetingRecorder" }) else {
            XCTFail("Could not find main app bundle")
            return
        }

        let version = appBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = appBundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        XCTAssertNotNil(version, "CFBundleShortVersionString must be set")
        XCTAssertNotNil(build, "CFBundleVersion must be set")
        XCTAssertFalse(version?.isEmpty ?? true, "Version string must not be empty")
        XCTAssertFalse(build?.isEmpty ?? true, "Build string must not be empty")
    }

    // MARK: - Deployment Target Tests

    func testMinimumSystemVersionIsCorrect() throws {
        // Test the main app bundle, not the test bundle
        guard let appBundle = Bundle.allBundles.first(where: { $0.bundleIdentifier == "com.daltonrooney.MeetingRecorder" }) else {
            XCTFail("Could not find main app bundle")
            return
        }

        // The minimum macOS version should be set to 26.0 or higher
        let minimumVersion = appBundle.object(forInfoDictionaryKey: "LSMinimumSystemVersion") as? String

        XCTAssertNotNil(minimumVersion, "LSMinimumSystemVersion must be set")

        if let versionString = minimumVersion {
            // Parse version string (e.g., "26.0")
            let components = versionString.split(separator: ".").compactMap { Int($0) }
            XCTAssertGreaterThanOrEqual(components.first ?? 0, 26,
                                       "Minimum system version should be macOS 26.0 or higher")
        }
    }
}
