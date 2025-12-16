import XCTest

/// Runtime configuration tests that verify the BUILT app bundle has correct settings.
///
/// These tests complement the build-time validation script (scripts/validate-configuration.swift):
/// - Build script: Prevents bad builds by validating source files at build time
/// - These tests: Verify the built app bundle has correct runtime configuration
///
/// This follows best practices: build-time validation for fail-fast, runtime tests for verification.
final class ProjectConfigurationTests: XCTestCase {

    // MARK: - Constants

    private static let expectedBundleIdentifier = "dev.rygn.CallTranscription"
    private static let minimumMacOSVersion = 26

    // MARK: - Helper Methods

    /// Get the main application bundle using a reliable fallback approach.
    /// Tries multiple methods to ensure we get the correct bundle across different test environments.
    private func getMainAppBundle() throws -> Bundle {
        // Method 1: Try to find bundle by identifier in loaded bundles
        // This works when the app is loaded in the test process
        if let bundle = Bundle.allBundles.first(where: { $0.bundleIdentifier == Self.expectedBundleIdentifier }) {
            return bundle
        }

        // Method 2: Try Bundle.main (works in some test configurations)
        if Bundle.main.bundleIdentifier == Self.expectedBundleIdentifier {
            return Bundle.main
        }

        // Method 3: Look for the app bundle in the test bundle's path
        // The built app should be in the same directory as the test bundle
        let testBundlePath = Bundle(for: type(of: self)).bundlePath
        let appPath = (testBundlePath as NSString).deletingLastPathComponent + "/CallTranscription.app"
        if let bundle = Bundle(path: appPath), bundle.bundleIdentifier == Self.expectedBundleIdentifier {
            return bundle
        }

        throw TestError.appBundleNotFound
    }

    // MARK: - Privacy Keys Tests

    func testInfoPlistContainsRequiredPrivacyKeys() throws {
        let bundle = try getMainAppBundle()

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
        let bundle = try getMainAppBundle()

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
        let bundle = try getMainAppBundle()
        let bundleId = bundle.bundleIdentifier

        XCTAssertNotNil(bundleId, "Bundle identifier must be set")
        XCTAssertTrue(bundleId?.hasPrefix("dev.rygn.") ?? false,
                      "Bundle ID should use correct prefix")
    }

    func testBundleVersionsAreSet() throws {
        let appBundle = try getMainAppBundle()

        let version = appBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = appBundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        XCTAssertNotNil(version, "CFBundleShortVersionString must be set")
        XCTAssertNotNil(build, "CFBundleVersion must be set")
        XCTAssertFalse(version?.isEmpty ?? true, "Version string must not be empty")
        XCTAssertFalse(build?.isEmpty ?? true, "Build string must not be empty")
    }

    // MARK: - Deployment Target Tests

    func testMinimumSystemVersionIsCorrect() throws {
        let appBundle = try getMainAppBundle()

        // The minimum macOS version should be set to 26.0 or higher
        let minimumVersion = appBundle.object(forInfoDictionaryKey: "LSMinimumSystemVersion") as? String

        XCTAssertNotNil(minimumVersion, "LSMinimumSystemVersion must be set")

        guard let versionString = minimumVersion else {
            XCTFail("LSMinimumSystemVersion is nil")
            return
        }

        // Parse version string (e.g., "26.0")
        let components = versionString.split(separator: ".").compactMap { Int($0) }

        guard let majorVersion = components.first else {
            XCTFail("Could not parse major version from '\(versionString)'")
            return
        }

        XCTAssertGreaterThanOrEqual(majorVersion, Self.minimumMacOSVersion,
                                   "Minimum system version should be macOS \(Self.minimumMacOSVersion).0 or higher, but found \(versionString)")
    }

    // MARK: - Error Types

    enum TestError: Error {
        case appBundleNotFound
    }
}
