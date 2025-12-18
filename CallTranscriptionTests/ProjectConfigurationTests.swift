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

    private static let expectedBundleIdentifier = "dev.rygn.Olive"
    private static let expectedProductName = "Olive"
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
        let appPath = (testBundlePath as NSString).deletingLastPathComponent + "/Olive.app"
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
        XCTAssertEqual(bundleId, Self.expectedBundleIdentifier,
                      "Bundle identifier should be '\(Self.expectedBundleIdentifier)'")
        XCTAssertTrue(bundleId?.hasPrefix("dev.rygn.") ?? false,
                      "Bundle ID should use correct prefix")
    }

    func testProductNameIsOlive() throws {
        let bundle = try getMainAppBundle()
        let productName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String

        XCTAssertNotNil(productName, "Product name (CFBundleName) must be set")
        XCTAssertEqual(productName, Self.expectedProductName,
                      "Product name should be '\(Self.expectedProductName)' for Activity Monitor and menu bar")
    }

    func testExecutableNameIsOlive() throws {
        let bundle = try getMainAppBundle()
        let executableName = bundle.object(forInfoDictionaryKey: "CFBundleExecutable") as? String

        XCTAssertNotNil(executableName, "Executable name must be set")
        XCTAssertEqual(executableName, Self.expectedProductName,
                      "Executable name should be '\(Self.expectedProductName)'")
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

    // MARK: - AppleScript Configuration Tests (Issue #44)

    func testInfoPlistContainsAppleScriptEnabled() throws {
        let bundle = try getMainAppBundle()

        let appleScriptEnabled = bundle.object(forInfoDictionaryKey: "NSAppleScriptEnabled") as? Bool
        XCTAssertNotNil(appleScriptEnabled, "NSAppleScriptEnabled must be present for AppleScript support")
        XCTAssertTrue(appleScriptEnabled ?? false, "NSAppleScriptEnabled must be true to enable AppleScript")
    }

    func testInfoPlistContainsScriptingDefinition() throws {
        let bundle = try getMainAppBundle()

        let scriptingDefinition = bundle.object(forInfoDictionaryKey: "OSAScriptingDefinition") as? String
        XCTAssertNotNil(scriptingDefinition, "OSAScriptingDefinition must be present for AppleScript support")
        XCTAssertEqual(scriptingDefinition, "Olive.sdef", "OSAScriptingDefinition should point to Olive.sdef")
    }

    func testScriptingDefinitionFileExists() throws {
        let bundle = try getMainAppBundle()

        let sdefPath = bundle.path(forResource: "Olive", ofType: "sdef")
        XCTAssertNotNil(sdefPath, "Olive.sdef file must exist in app bundle resources")

        guard let path = sdefPath else {
            XCTFail("Olive.sdef path is nil")
            return
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: path),
                     "Olive.sdef file must exist at path: \(path)")
    }

    func testScriptingDefinitionIsValidXML() throws {
        let bundle = try getMainAppBundle()

        guard let sdefPath = bundle.path(forResource: "Olive", ofType: "sdef") else {
            XCTFail("Olive.sdef file not found in bundle")
            return
        }

        let sdefData = try Data(contentsOf: URL(fileURLWithPath: sdefPath))
        XCTAssertGreaterThan(sdefData.count, 0, "Olive.sdef file must not be empty")

        // Verify it's valid XML
        let xmlParser = XMLParser(data: sdefData)
        XCTAssertTrue(xmlParser.parse(), "Olive.sdef must be valid XML")
    }

    // MARK: - App Intents Configuration Tests (Issue #44)

    func testAppIntentsTargetMembership() throws {
        // Verify that intent files are included in the app target
        // This is tested by attempting to instantiate the intent types
        // If they're not in the target, this will fail at compile time

        // Test that intent types exist and are accessible
        let _ = StartRecordingIntent.self
        let _ = StopRecordingIntent.self
        let _ = GetRecordingStatusIntent.self
        let _ = ConfigureSettingsIntent.self

        // If we get here, the types are available, meaning they're in the target
        XCTAssertTrue(true, "Intent types should be accessible from test target")
    }

    func testAppSupportsBackgroundModes() throws {
        let bundle = try getMainAppBundle()

        // Verify termination settings are appropriate for automation
        let supportsAutoTermination = bundle.object(forInfoDictionaryKey: "NSSupportsAutomaticTermination") as? Bool
        let supportsSuddenTermination = bundle.object(forInfoDictionaryKey: "NSSupportsSuddenTermination") as? Bool

        // For automation support, automatic termination should be disabled
        // to prevent the app from being terminated while handling intents/scripts
        XCTAssertNotNil(supportsAutoTermination, "NSSupportsAutomaticTermination should be set")
        XCTAssertNotNil(supportsSuddenTermination, "NSSupportsSuddenTermination should be set")

        // Both should be false to ensure app stays alive for automation
        XCTAssertFalse(supportsAutoTermination ?? true,
                      "NSSupportsAutomaticTermination should be false for automation support")
        XCTAssertFalse(supportsSuddenTermination ?? true,
                      "NSSupportsSuddenTermination should be false for automation support")
    }

    // MARK: - Error Types

    enum TestError: Error {
        case appBundleNotFound
    }
}
