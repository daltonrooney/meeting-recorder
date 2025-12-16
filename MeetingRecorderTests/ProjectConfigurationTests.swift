import XCTest

/// Tests for verifying Xcode project configuration
/// These tests ensure Info.plist, entitlements, and build settings are correctly configured
final class ProjectConfigurationTests: XCTestCase {

    // MARK: - Info.plist Tests

    func testInfoPlistContainsMicrophoneUsageDescription() throws {
        let infoPlist = try getInfoPlist()

        let microphoneDescription = infoPlist["NSMicrophoneUsageDescription"] as? String
        XCTAssertNotNil(microphoneDescription, "NSMicrophoneUsageDescription must exist in Info.plist")
        XCTAssertFalse(microphoneDescription?.isEmpty ?? true, "NSMicrophoneUsageDescription must not be empty")
    }

    func testInfoPlistContainsSpeechRecognitionUsageDescription() throws {
        let infoPlist = try getInfoPlist()

        let speechDescription = infoPlist["NSSpeechRecognitionUsageDescription"] as? String
        XCTAssertNotNil(speechDescription, "NSSpeechRecognitionUsageDescription must exist in Info.plist")
        XCTAssertFalse(speechDescription?.isEmpty ?? true, "NSSpeechRecognitionUsageDescription must not be empty")
    }

    func testInfoPlistContainsScreenCaptureUsageDescription() throws {
        let infoPlist = try getInfoPlist()

        let screenCaptureDescription = infoPlist["NSScreenCaptureUsageDescription"] as? String
        XCTAssertNotNil(screenCaptureDescription, "NSScreenCaptureUsageDescription must exist in Info.plist for fallback scenarios")
    }

    // MARK: - Entitlements Tests

    func testEntitlementsContainAppSandbox() throws {
        let entitlements = try getEntitlements()

        let appSandbox = entitlements["com.apple.security.app-sandbox"] as? Bool
        XCTAssertNotNil(appSandbox, "com.apple.security.app-sandbox must be present in entitlements")
        XCTAssertTrue(appSandbox ?? false, "com.apple.security.app-sandbox must be enabled (true)")
    }

    func testEntitlementsContainAudioInput() throws {
        let entitlements = try getEntitlements()

        let audioInput = entitlements["com.apple.security.device.audio-input"] as? Bool
        XCTAssertNotNil(audioInput, "com.apple.security.device.audio-input must be present in entitlements")
        XCTAssertTrue(audioInput ?? false, "com.apple.security.device.audio-input must be enabled (true)")
    }

    func testEntitlementsContainUserSelectedFileAccess() throws {
        let entitlements = try getEntitlements()

        let fileAccess = entitlements["com.apple.security.files.user-selected.read-write"] as? Bool
        XCTAssertNotNil(fileAccess, "com.apple.security.files.user-selected.read-write must be present in entitlements")
        XCTAssertTrue(fileAccess ?? false, "com.apple.security.files.user-selected.read-write must be enabled (true)")
    }

    func testEntitlementsContainTemporaryFileAccessException() throws {
        let entitlements = try getEntitlements()

        let tempException = entitlements["com.apple.security.temporary-exception.files.absolute-path.read-write"] as? [String]
        XCTAssertNotNil(tempException, "com.apple.security.temporary-exception.files.absolute-path.read-write must be configured")
        XCTAssertFalse(tempException?.isEmpty ?? true, "Temporary file access exception must include paths")
    }

    // MARK: - Build Configuration Tests

    func testDebugBuildConfigurationExists() throws {
        // This test verifies that the Debug build configuration is present
        // In a real Xcode project, we would parse project.pbxproj
        // For now, we'll verify the project file exists and contains Debug configuration

        let projectPath = try getProjectPath()
        XCTAssertTrue(FileManager.default.fileExists(atPath: projectPath), "Xcode project must exist")

        let projectContent = try String(contentsOfFile: projectPath, encoding: .utf8)
        XCTAssertTrue(projectContent.contains("Debug"), "Debug build configuration must exist")
    }

    func testReleaseBuildConfigurationExists() throws {
        let projectPath = try getProjectPath()
        XCTAssertTrue(FileManager.default.fileExists(atPath: projectPath), "Xcode project must exist")

        let projectContent = try String(contentsOfFile: projectPath, encoding: .utf8)
        XCTAssertTrue(projectContent.contains("Release"), "Release build configuration must exist")
    }

    func testMinimumDeploymentTargetIsConfigured() throws {
        let projectPath = try getProjectPath()
        let projectContent = try String(contentsOfFile: projectPath, encoding: .utf8)

        // Check for macOS deployment target (14.2 or higher)
        XCTAssertTrue(
            projectContent.contains("MACOSX_DEPLOYMENT_TARGET"),
            "macOS deployment target must be configured"
        )
    }

    // MARK: - Helper Methods

    private func getInfoPlist() throws -> [String: Any] {
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

    private func getEntitlements() throws -> [String: Any] {
        // Entitlements file path in the project structure
        let projectURL = try getProjectURL()
        let entitlementsPath = projectURL
            .deletingLastPathComponent()
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

    private func getProjectPath() throws -> String {
        let projectURL = try getProjectURL()
        return projectURL
            .deletingLastPathComponent()
            .appendingPathComponent("MeetingRecorder.xcodeproj/project.pbxproj")
            .path
    }

    private func getProjectURL() throws -> URL {
        // Get the project root directory
        guard let projectURL = Bundle(for: type(of: self)).bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent() as URL? else {
            throw TestError.projectNotFound
        }

        return projectURL
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
