import XCTest
@testable import CallTranscription

/// Tests for notarization process (macOS distribution requirement)
///
/// These tests verify that:
/// - App can be notarized for distribution
/// - Notarization process completes successfully
/// - Notarized app runs on clean systems
/// - Gatekeeper allows execution of notarized app
final class NotarizationTests: XCTestCase {

    // MARK: - Notarization Tests

    func testAppCanBeNotarized() throws {
        // Test that app structure supports notarization
        let appPath = try getBuiltAppPath(configuration: "Release")

        XCTAssertTrue(FileManager.default.fileExists(atPath: appPath),
                     "App should exist for notarization")
        XCTAssertTrue(isCodeSigned(at: appPath),
                     "App must be code signed before notarization")
        XCTAssertTrue(hasHardenedRuntime(at: appPath),
                     "App should have hardened runtime for notarization")
    }

    func testNotarizationConfigurationExists() throws {
        // Test that notarization configuration is present
        let notarizeScriptExists = FileManager.default.fileExists(
            atPath: "scripts/notarize.sh"
        )

        XCTAssertTrue(notarizeScriptExists,
                     "Notarization script should exist at scripts/notarize.sh")
    }

    func testNotarizationScriptHasRequiredParameters() throws {
        // Test that notarization script handles required parameters
        let scriptContent = try String(contentsOfFile: "scripts/notarize.sh")

        XCTAssertTrue(scriptContent.contains("notarytool") || scriptContent.contains("xcrun"),
                     "Script should use notarytool for notarization")
        XCTAssertTrue(scriptContent.contains("apple-id") || scriptContent.contains("APPLE_ID"),
                     "Script should handle Apple ID parameter")
    }

    func testNotarizedAppHasSecureTimestamp() throws {
        // Test that notarized app has secure timestamp
        let appPath = try getBuiltAppPath(configuration: "Release")

        // Check code signature includes secure timestamp
        let hasTimestamp = verifySecureTimestamp(at: appPath)
        XCTAssertTrue(hasTimestamp,
                     "Notarized app should have secure timestamp in signature")
    }

    func testNotarizedAppPassesGatekeeper() throws {
        // Test that Gatekeeper validation passes
        let appPath = try getBuiltAppPath(configuration: "Release")

        let gatekeeperResult = assessGatekeeper(at: appPath)
        XCTAssertTrue(gatekeeperResult.allowed,
                     "Gatekeeper should allow notarized app to execute")
    }

    func testNotarizationIncludesAllComponents() throws {
        // Test that all app components are included in notarization
        let appPath = try getBuiltAppPath(configuration: "Release")

        // All dylibs and frameworks should be signed
        let components = try findExecutableComponents(at: appPath)
        for component in components {
            XCTAssertTrue(isCodeSigned(at: component),
                         "Component \(component) should be code signed")
        }
    }

    // MARK: - Hardened Runtime Tests

    func testHardenedRuntimeEnabled() throws {
        // Test that hardened runtime is enabled
        let appPath = try getBuiltAppPath(configuration: "Release")

        XCTAssertTrue(hasHardenedRuntime(at: appPath),
                     "App should have hardened runtime enabled")
    }

    func testHardenedRuntimeEntitlements() throws {
        // Test that required entitlements are present for hardened runtime
        let appPath = try getBuiltAppPath(configuration: "Release")
        let entitlements = try getEntitlements(at: appPath)

        // Verify sandbox entitlement
        XCTAssertNotNil(entitlements["com.apple.security.app-sandbox"],
                       "Hardened runtime should include app sandbox")

        // Verify audio input entitlement
        XCTAssertNotNil(entitlements["com.apple.security.device.audio-input"],
                       "Hardened runtime should include audio input entitlement")
    }

    // MARK: - Distribution Package Tests

    func testCanCreateNotarizedPackage() throws {
        // Test that notarized package can be created
        let packageScriptExists = FileManager.default.fileExists(
            atPath: "scripts/package.sh"
        )

        XCTAssertTrue(packageScriptExists,
                     "Package script should exist for creating notarized distribution")
    }

    func testNotarizedPackageIncludesStapling() throws {
        // Test that notarization ticket is stapled to package
        let scriptContent = try String(contentsOfFile: "scripts/notarize.sh")

        XCTAssertTrue(scriptContent.contains("stapler") || scriptContent.contains("staple"),
                     "Notarization script should staple ticket to app")
    }

    // MARK: - Helper Methods

    private func getBuiltAppPath(configuration: String) throws -> String {
        let derivedDataPath = NSTemporaryDirectory()
        return "\(derivedDataPath)/Build/Products/\(configuration)/Olive.app"
    }

    private func isCodeSigned(at path: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["--verify", "--verbose", path]

        let pipe = Pipe()
        process.standardError = pipe

        try? process.run()
        process.waitUntilExit()

        return process.terminationStatus == 0
    }

    private func hasHardenedRuntime(at path: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["--display", "--verbose", path]

        let pipe = Pipe()
        process.standardError = pipe

        try? process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        return output.contains("runtime")
    }

    private func getEntitlements(at path: String) throws -> [String: Any] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["--display", "--entitlements", "-", path]

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        return plist as? [String: Any] ?? [:]
    }

    private func verifySecureTimestamp(at path: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["--display", "--verbose=4", path]

        let pipe = Pipe()
        process.standardError = pipe

        try? process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        return output.contains("timestamp")
    }

    private func assessGatekeeper(at path: String) -> GatekeeperResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/spctl")
        process.arguments = ["--assess", "--verbose", "--type", "execute", path]

        let pipe = Pipe()
        process.standardError = pipe

        try? process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        return GatekeeperResult(
            allowed: process.terminationStatus == 0,
            output: output
        )
    }

    private func findExecutableComponents(at path: String) throws -> [String] {
        var components: [String] = []
        let fileManager = FileManager.default

        // Find all executable files in the app bundle
        let enumerator = fileManager.enumerator(atPath: path)
        while let file = enumerator?.nextObject() as? String {
            let fullPath = "\(path)/\(file)"
            var isDirectory: ObjCBool = false

            if fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory),
               !isDirectory.boolValue {
                // Check if file is executable
                let attributes = try? fileManager.attributesOfItem(atPath: fullPath)
                let permissions = attributes?[.posixPermissions] as? NSNumber
                if (permissions?.intValue ?? 0) & 0o111 != 0 {
                    components.append(fullPath)
                }
            }
        }

        return components
    }
}

// MARK: - Supporting Types

struct GatekeeperResult {
    let allowed: Bool
    let output: String
}
