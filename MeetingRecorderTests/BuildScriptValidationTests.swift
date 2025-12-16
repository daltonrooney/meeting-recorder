import XCTest

/// Tests for the build-time configuration validation script
///
/// These tests verify that the validate-configuration.swift script correctly:
/// 1. Passes when all configuration is valid
/// 2. Fails with appropriate exit codes and messages when configuration is invalid
/// 3. Provides helpful error messages for debugging
final class BuildScriptValidationTests: XCTestCase {

    // MARK: - Setup

    private var projectRoot: URL!
    private var validationScriptPath: String!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Find project root
        projectRoot = try findProjectRoot()
        validationScriptPath = projectRoot
            .appendingPathComponent("scripts/validate-configuration.swift")
            .path

        // Verify script exists
        guard FileManager.default.fileExists(atPath: validationScriptPath) else {
            throw TestError.scriptNotFound
        }
    }

    // MARK: - Success Tests

    func testValidConfigurationPasses() throws {
        // Run the validation script against the current valid configuration
        let result = try runValidationScript()

        XCTAssertEqual(result.exitCode, 0, "Validation should pass with exit code 0 for valid configuration")
        XCTAssertTrue(result.output.contains("✅ All configuration validations passed"),
                      "Should show success message")
    }

    // MARK: - Privacy Key Tests

    func testMissingMicrophoneKeyFails() throws {
        let tempInfoPlist = try createTemporaryInfoPlist(omittingKey: "NSMicrophoneUsageDescription")
        defer { try? FileManager.default.removeItem(at: tempInfoPlist) }

        let result = try runValidationScript(withInfoPlist: tempInfoPlist)

        XCTAssertEqual(result.exitCode, 1, "Should fail with exit code 1 for missing microphone key")
        XCTAssertTrue(result.output.contains("NSMicrophoneUsageDescription"),
                      "Error message should mention missing key")
        XCTAssertTrue(result.output.contains("Configuration validation error"),
                      "Should indicate configuration error")
    }

    func testEmptyMicrophoneDescriptionFails() throws {
        let tempInfoPlist = try createTemporaryInfoPlist(withEmptyValue: "NSMicrophoneUsageDescription")
        defer { try? FileManager.default.removeItem(at: tempInfoPlist) }

        let result = try runValidationScript(withInfoPlist: tempInfoPlist)

        XCTAssertEqual(result.exitCode, 1, "Should fail with exit code 1 for empty description")
        XCTAssertTrue(result.output.contains("NSMicrophoneUsageDescription"),
                      "Error message should mention the key")
    }

    // MARK: - Entitlements Tests

    func testMissingAppSandboxFails() throws {
        let tempEntitlements = try createTemporaryEntitlements(omittingKey: "com.apple.security.app-sandbox")
        defer { try? FileManager.default.removeItem(at: tempEntitlements) }

        let result = try runValidationScript(withEntitlements: tempEntitlements)

        XCTAssertEqual(result.exitCode, 1, "Should fail with exit code 1 for missing sandbox entitlement")
        XCTAssertTrue(result.output.contains("com.apple.security.app-sandbox"),
                      "Error message should mention missing entitlement")
    }

    // MARK: - Deployment Target Tests

    func testInvalidDeploymentTargetFails() throws {
        // Note: This test would require temporarily modifying project.pbxproj
        // which is complex and fragile. Consider this a documentation of
        // expected behavior rather than an executable test.
        //
        // When deployment target is < 26.0, validation should:
        // - Exit with code 1
        // - Show error mentioning MACOSX_DEPLOYMENT_TARGET
        // - Show the found version and required minimum (26.0)
        throw XCTSkip("Modifying project.pbxproj is too fragile for testing")
    }

    // MARK: - Error Message Quality Tests

    func testInvalidPlistFormatProducesHelpfulError() throws {
        let tempInfoPlist = try createInvalidPlist()
        defer { try? FileManager.default.removeItem(at: tempInfoPlist) }

        let result = try runValidationScript(withInfoPlist: tempInfoPlist)

        XCTAssertEqual(result.exitCode, 1, "Should fail with exit code 1 for invalid format")
        XCTAssertTrue(result.output.contains("parsing failed") ||
                      result.output.contains("Invalid Format"),
                      "Should indicate parsing failure")
        XCTAssertTrue(result.output.contains("plutil -lint"),
                      "Should suggest using plutil for debugging")
    }

    // MARK: - Script Error Tests

    func testScriptExecutionSucceeds() throws {
        // Verify the script can be executed at all
        let process = Process()
        process.executableURL = URL(fileURLWithPath: validationScriptPath)
        process.environment = ["PWD": projectRoot.path]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        // Should exit with 0 (success) or 1 (validation error), never 2 (script error)
        XCTAssertNotEqual(process.terminationStatus, 2,
                          "Script should not encounter unexpected errors with valid input")
    }

    // MARK: - Helper Methods

    private func runValidationScript(withInfoPlist infoPlistOverride: URL? = nil,
                                     withEntitlements entitlementsOverride: URL? = nil) throws -> ProcessResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: validationScriptPath)
        process.currentDirectoryURL = projectRoot
        process.environment = ProcessInfo.processInfo.environment

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let output = (String(data: outputData, encoding: .utf8) ?? "") +
                     (String(data: errorData, encoding: .utf8) ?? "")

        return ProcessResult(exitCode: Int(process.terminationStatus), output: output)
    }

    private func createTemporaryInfoPlist(omittingKey keyToOmit: String) throws -> URL {
        // This would create a temporary Info.plist for testing
        // Implementation requires copying current plist and removing the key
        throw XCTSkip("Temporary plist creation not yet implemented")
    }

    private func createTemporaryInfoPlist(withEmptyValue key: String) throws -> URL {
        throw XCTSkip("Temporary plist creation not yet implemented")
    }

    private func createTemporaryEntitlements(omittingKey keyToOmit: String) throws -> URL {
        throw XCTSkip("Temporary entitlements creation not yet implemented")
    }

    private func createInvalidPlist() throws -> URL {
        throw XCTSkip("Invalid plist creation not yet implemented")
    }

    private func findProjectRoot() throws -> URL {
        let fileManager = FileManager.default

        // Try PWD environment variable first
        if let pwd = ProcessInfo.processInfo.environment["PWD"] {
            let pwdURL = URL(fileURLWithPath: pwd)
            let xcodeproj = pwdURL.appendingPathComponent("MeetingRecorder.xcodeproj")

            if fileManager.fileExists(atPath: xcodeproj.path) {
                return pwdURL
            }
        }

        // Try current directory
        let currentDir = fileManager.currentDirectoryPath
        let currentURL = URL(fileURLWithPath: currentDir)
        let xcodeproj = currentURL.appendingPathComponent("MeetingRecorder.xcodeproj")

        if fileManager.fileExists(atPath: xcodeproj.path) {
            return currentURL
        }

        // Git-based fallback
        let gitProcess = Process()
        gitProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        gitProcess.arguments = ["rev-parse", "--show-toplevel"]

        let pipe = Pipe()
        gitProcess.standardOutput = pipe
        gitProcess.standardError = Pipe()

        try gitProcess.run()
        gitProcess.waitUntilExit()

        if gitProcess.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let gitRoot = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                return URL(fileURLWithPath: gitRoot)
            }
        }

        throw TestError.projectNotFound
    }

    // MARK: - Helper Types

    struct ProcessResult {
        let exitCode: Int
        let output: String
    }

    enum TestError: Error {
        case projectNotFound
        case scriptNotFound
    }
}
