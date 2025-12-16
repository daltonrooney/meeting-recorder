import XCTest

/// Tests for verifying Xcode project configuration
/// These tests ensure Info.plist, entitlements, and build settings are correctly configured
final class ProjectConfigurationTests: XCTestCase {

    // MARK: - Cached Properties

    /// Lazy-loaded Info.plist to avoid redundant file reads
    private lazy var cachedInfoPlist: [String: Any]? = {
        return try? loadInfoPlist()
    }()

    /// Lazy-loaded entitlements to avoid redundant file reads
    private lazy var cachedEntitlements: [String: Any]? = {
        return try? loadEntitlements()
    }()

    /// Lazy-loaded project content to avoid redundant file reads
    private lazy var cachedProjectContent: String? = {
        guard let projectPath = try? getProjectPath() else { return nil }
        return try? String(contentsOfFile: projectPath, encoding: .utf8)
    }()

    // MARK: - Info.plist Tests

    func testInfoPlistContainsMicrophoneUsageDescription() throws {
        guard let infoPlist = cachedInfoPlist else {
            XCTFail("Failed to load Info.plist")
            return
        }

        let microphoneDescription = infoPlist["NSMicrophoneUsageDescription"] as? String
        XCTAssertNotNil(microphoneDescription, "NSMicrophoneUsageDescription must exist in Info.plist")
        XCTAssertFalse(microphoneDescription?.isEmpty ?? true, "NSMicrophoneUsageDescription must not be empty")
    }

    func testInfoPlistContainsSpeechRecognitionUsageDescription() throws {
        guard let infoPlist = cachedInfoPlist else {
            XCTFail("Failed to load Info.plist")
            return
        }

        let speechDescription = infoPlist["NSSpeechRecognitionUsageDescription"] as? String
        XCTAssertNotNil(speechDescription, "NSSpeechRecognitionUsageDescription must exist in Info.plist")
        XCTAssertFalse(speechDescription?.isEmpty ?? true, "NSSpeechRecognitionUsageDescription must not be empty")
    }

    func testInfoPlistContainsScreenCaptureUsageDescription() throws {
        guard let infoPlist = cachedInfoPlist else {
            XCTFail("Failed to load Info.plist")
            return
        }

        let screenCaptureDescription = infoPlist["NSScreenCaptureUsageDescription"] as? String
        XCTAssertNotNil(screenCaptureDescription, "NSScreenCaptureUsageDescription must exist in Info.plist for fallback scenarios")
    }

    // MARK: - Entitlements Tests

    func testEntitlementsContainAppSandbox() throws {
        guard let entitlements = cachedEntitlements else {
            XCTFail("Failed to load entitlements")
            return
        }

        let appSandbox = entitlements["com.apple.security.app-sandbox"] as? Bool
        XCTAssertNotNil(appSandbox, "com.apple.security.app-sandbox must be present in entitlements")
        XCTAssertTrue(appSandbox ?? false, "com.apple.security.app-sandbox must be enabled (true)")
    }

    func testEntitlementsContainAudioInput() throws {
        guard let entitlements = cachedEntitlements else {
            XCTFail("Failed to load entitlements")
            return
        }

        let audioInput = entitlements["com.apple.security.device.audio-input"] as? Bool
        XCTAssertNotNil(audioInput, "com.apple.security.device.audio-input must be present in entitlements")
        XCTAssertTrue(audioInput ?? false, "com.apple.security.device.audio-input must be enabled (true)")
    }

    func testEntitlementsContainUserSelectedFileAccess() throws {
        guard let entitlements = cachedEntitlements else {
            XCTFail("Failed to load entitlements")
            return
        }

        let fileAccess = entitlements["com.apple.security.files.user-selected.read-write"] as? Bool
        XCTAssertNotNil(fileAccess, "com.apple.security.files.user-selected.read-write must be present in entitlements")
        XCTAssertTrue(fileAccess ?? false, "com.apple.security.files.user-selected.read-write must be enabled (true)")
    }

    // MARK: - Build Configuration Tests

    func testDebugBuildConfigurationExists() throws {
        guard let projectContent = cachedProjectContent else {
            XCTFail("Failed to load project file")
            return
        }

        // Look for more specific pattern: buildConfiguration with name "Debug"
        let debugPattern = #"buildConfiguration.*name\s*=\s*"?Debug"?"#
        XCTAssertTrue(
            projectContent.range(of: debugPattern, options: .regularExpression) != nil,
            "Debug build configuration must exist in project"
        )
    }

    func testReleaseBuildConfigurationExists() throws {
        guard let projectContent = cachedProjectContent else {
            XCTFail("Failed to load project file")
            return
        }

        // Look for more specific pattern: buildConfiguration with name "Release"
        let releasePattern = #"buildConfiguration.*name\s*=\s*"?Release"?"#
        XCTAssertTrue(
            projectContent.range(of: releasePattern, options: .regularExpression) != nil,
            "Release build configuration must exist in project"
        )
    }

    func testMinimumDeploymentTargetIsConfigured() throws {
        guard let projectContent = cachedProjectContent else {
            XCTFail("Failed to load project file")
            return
        }

        // Check for macOS deployment target (14.2 or higher)
        XCTAssertTrue(
            projectContent.contains("MACOSX_DEPLOYMENT_TARGET"),
            "macOS deployment target must be configured"
        )
    }

    // MARK: - Helper Methods

    /// Loads Info.plist from the main bundle
    private func loadInfoPlist() throws -> [String: Any] {
        guard let infoPlistPath = Bundle.main.path(forResource: "Info", ofType: "plist") else {
            throw TestError.infoPlistNotFound
        }

        guard let infoPlistData = FileManager.default.contents(atPath: infoPlistPath) else {
            throw TestError.infoPlistNotReadable
        }

        guard let infoPlist = try PropertyListSerialization.propertyList(
            from: infoPlistData,
            options: [],
            format: nil
        ) as? [String: Any] else {
            throw TestError.infoPlistInvalidFormat
        }

        return infoPlist
    }

    /// Loads entitlements from the project structure
    private func loadEntitlements() throws -> [String: Any] {
        let projectRoot = try findProjectRoot()
        let entitlementsPath = projectRoot
            .appendingPathComponent("MeetingRecorder/MeetingRecorder.entitlements")
            .path

        guard FileManager.default.fileExists(atPath: entitlementsPath) else {
            throw TestError.entitlementsNotFound
        }

        guard let entitlementsData = FileManager.default.contents(atPath: entitlementsPath) else {
            throw TestError.entitlementsNotReadable
        }

        guard let entitlements = try PropertyListSerialization.propertyList(
            from: entitlementsData,
            options: [],
            format: nil
        ) as? [String: Any] else {
            throw TestError.entitlementsInvalidFormat
        }

        return entitlements
    }

    /// Gets the path to project.pbxproj file
    private func getProjectPath() throws -> String {
        let projectRoot = try findProjectRoot()
        return projectRoot
            .appendingPathComponent("MeetingRecorder.xcodeproj/project.pbxproj")
            .path
    }

    /// Finds the project root directory by searching upward for marker files
    /// This is more robust than assuming a specific bundle structure
    private func findProjectRoot() throws -> URL {
        var currentURL = Bundle(for: type(of: self)).bundleURL

        // Search upward for the project root (contains .xcodeproj or project.yml)
        for _ in 0..<10 { // Limit search depth to prevent infinite loops
            let xcodeproj = currentURL.appendingPathComponent("MeetingRecorder.xcodeproj")
            let projectYml = currentURL.appendingPathComponent("project.yml")

            if FileManager.default.fileExists(atPath: xcodeproj.path) ||
               FileManager.default.fileExists(atPath: projectYml.path) {
                return currentURL
            }

            let parentURL = currentURL.deletingLastPathComponent()
            if parentURL == currentURL {
                // Reached filesystem root without finding project
                break
            }
            currentURL = parentURL
        }

        throw TestError.projectNotFound
    }

    enum TestError: Error {
        case infoPlistNotFound
        case infoPlistNotReadable
        case infoPlistInvalidFormat
        case entitlementsNotFound
        case entitlementsNotReadable
        case entitlementsInvalidFormat
        case projectNotFound
    }
}
