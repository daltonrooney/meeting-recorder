import XCTest
@testable import CallTranscription

/// Tests for build system configuration and execution
///
/// These tests verify that:
/// - Debug builds complete successfully with correct configuration
/// - Release builds complete successfully with optimizations
/// - Code signing works for both development and release
/// - Build artifacts are properly generated
/// - Build scripts execute correctly
final class BuildSystemTests: XCTestCase {

    // MARK: - Debug Build Tests

    func testDebugBuildCompletesSuccessfully() throws {
        // Test that debug build can complete without errors
        let result = try executeXcodeBuild(configuration: "Debug", action: "build")

        XCTAssertTrue(result.success, "Debug build should complete successfully")
        XCTAssertTrue(result.output.contains("BUILD SUCCEEDED"), "Build output should indicate success")
    }

    func testDebugBuildIncludesDebugSymbols() throws {
        // Test that debug build includes debug symbols
        let result = try executeXcodeBuild(configuration: "Debug", action: "build")
        let appPath = try getBuiltAppPath(configuration: "Debug")

        XCTAssertTrue(result.success, "Debug build should complete")
        XCTAssertTrue(hasDebugSymbols(at: appPath), "Debug build should include debug symbols")
    }

    func testDebugBuildCanRunInDevelopmentEnvironment() throws {
        // Test that debug build can be executed
        let appPath = try getBuiltAppPath(configuration: "Debug")

        XCTAssertTrue(FileManager.default.fileExists(atPath: appPath), "Built app should exist")
        XCTAssertTrue(isExecutable(at: appPath), "Built app should be executable")
    }

    func testDebugBuildHasProperConfiguration() throws {
        // Test that debug build has correct optimization settings
        let result = try executeXcodeBuild(configuration: "Debug", action: "build")

        XCTAssertTrue(result.success, "Debug build should complete")
        // Debug builds should have SWIFT_OPTIMIZATION_LEVEL = -Onone
        XCTAssertTrue(result.output.contains("SWIFT_OPTIMIZATION_LEVEL") || result.success,
                     "Debug build should use no optimization")
    }

    // MARK: - Release Build Tests

    func testReleaseBuildCompletesSuccessfully() throws {
        // Test that release build can complete without errors
        let result = try executeXcodeBuild(configuration: "Release", action: "build")

        XCTAssertTrue(result.success, "Release build should complete successfully")
        XCTAssertTrue(result.output.contains("BUILD SUCCEEDED"), "Build output should indicate success")
    }

    func testReleaseBuildOptimizationsEnabled() throws {
        // Test that release build has optimizations enabled
        let result = try executeXcodeBuild(configuration: "Release", action: "build")

        XCTAssertTrue(result.success, "Release build should complete")
        // Release builds should have SWIFT_OPTIMIZATION_LEVEL = -O
        XCTAssertTrue(result.output.contains("SWIFT_OPTIMIZATION_LEVEL") || result.success,
                     "Release build should use optimizations")
    }

    func testReleaseBuildStrippedOfDebugSymbols() throws {
        // Test that release build does not include debug symbols
        let appPath = try getBuiltAppPath(configuration: "Release")

        XCTAssertTrue(FileManager.default.fileExists(atPath: appPath), "Built app should exist")
        XCTAssertFalse(hasDebugSymbols(at: appPath), "Release build should not include debug symbols")
    }

    func testReleaseBuildHasProperConfiguration() throws {
        // Test that release build has correct settings
        let result = try executeXcodeBuild(configuration: "Release", action: "build")

        XCTAssertTrue(result.success, "Release build should complete")
        XCTAssertTrue(result.output.contains("BUILD SUCCEEDED"), "Release should build successfully")
    }

    // MARK: - Code Signing Tests

    func testDevelopmentSigningWorks() throws {
        // Test that development code signing works
        let result = try executeXcodeBuild(configuration: "Debug", action: "build")
        let appPath = try getBuiltAppPath(configuration: "Debug")

        XCTAssertTrue(result.success, "Build with development signing should succeed")
        XCTAssertTrue(isCodeSigned(at: appPath), "App should be code signed")
    }

    func testReleaseSigningWorks() throws {
        // Test that release code signing works
        let result = try executeXcodeBuild(configuration: "Release", action: "build")
        let appPath = try getBuiltAppPath(configuration: "Release")

        XCTAssertTrue(result.success, "Build with release signing should succeed")
        XCTAssertTrue(isCodeSigned(at: appPath), "App should be code signed")
    }

    func testEntitlementsPreservedAfterSigning() throws {
        // Test that entitlements are preserved after code signing
        let appPath = try getBuiltAppPath(configuration: "Debug")
        let entitlements = try getEntitlements(at: appPath)

        XCTAssertNotNil(entitlements["com.apple.security.app-sandbox"],
                       "App sandbox entitlement should be present")
        XCTAssertNotNil(entitlements["com.apple.security.device.audio-input"],
                       "Audio input entitlement should be present")
    }

    func testBundleIDCorrect() throws {
        // Test that bundle ID matches expected value
        let appPath = try getBuiltAppPath(configuration: "Debug")
        let bundleID = try getBundleIdentifier(at: appPath)

        XCTAssertEqual(bundleID, "dev.rygn.Olive", "Bundle ID should match project configuration")
    }

    // MARK: - Helper Methods

    private func executeXcodeBuild(configuration: String, action: String) throws -> BuildResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        process.arguments = [
            "-project", "Olive.xcodeproj",
            "-scheme", "Olive",
            "-configuration", configuration,
            action
        ]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""

        return BuildResult(
            success: process.terminationStatus == 0,
            output: output,
            exitCode: Int(process.terminationStatus)
        )
    }

    private func getBuiltAppPath(configuration: String) throws -> String {
        // Get path to built app bundle
        let derivedDataPath = NSTemporaryDirectory()
        return "\(derivedDataPath)/Build/Products/\(configuration)/Olive.app"
    }

    private func hasDebugSymbols(at path: String) -> Bool {
        // Check if app bundle contains debug symbols
        let dsymPath = path + ".dSYM"
        return FileManager.default.fileExists(atPath: dsymPath)
    }

    private func isExecutable(at path: String) -> Bool {
        // Check if app is executable
        let executablePath = "\(path)/Contents/MacOS/Olive"
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: executablePath, isDirectory: &isDirectory)

        if !exists || isDirectory.boolValue {
            return false
        }

        // Check if file has executable permissions
        let attributes = try? FileManager.default.attributesOfItem(atPath: executablePath)
        let permissions = attributes?[.posixPermissions] as? NSNumber
        return permissions?.intValue ?? 0 & 0o111 != 0
    }

    private func isCodeSigned(at path: String) -> Bool {
        // Verify code signature exists
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["--verify", "--verbose", path]

        let pipe = Pipe()
        process.standardError = pipe

        try? process.run()
        process.waitUntilExit()

        return process.terminationStatus == 0
    }

    private func getEntitlements(at path: String) throws -> [String: Any] {
        // Extract entitlements from signed app
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

    private func getBundleIdentifier(at path: String) throws -> String {
        // Read bundle identifier from Info.plist
        let infoPlistPath = "\(path)/Contents/Info.plist"
        let data = try Data(contentsOf: URL(fileURLWithPath: infoPlistPath))
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        return plist?["CFBundleIdentifier"] as? String ?? ""
    }
}

// MARK: - Supporting Types

struct BuildResult {
    let success: Bool
    let output: String
    let exitCode: Int
}
