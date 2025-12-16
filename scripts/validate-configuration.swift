#!/usr/bin/env swift

import Foundation

// MARK: - Configuration Validator
// Validates project configuration at build time
// Fails the build if required configuration is missing or incorrect

struct ConfigurationValidator {
    let projectRoot: URL

    init() {
        // Build scripts run with CWD set to project root
        self.projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }

    func validate() throws {
        print("🔍 Validating project configuration...")

        try validateInfoPlist()
        try validateEntitlements()
        try validateBuildConfigurations()
        try validateDeploymentTarget()

        print("✅ All configuration validations passed")
    }

    // MARK: - Info.plist Validation

    private func validateInfoPlist() throws {
        print("  • Checking Info.plist...")

        let infoPlistPath = projectRoot
            .appendingPathComponent("MeetingRecorder/Info.plist")
            .path

        guard FileManager.default.fileExists(atPath: infoPlistPath) else {
            throw ValidationError.fileNotFound("Info.plist not found at: \(infoPlistPath)")
        }

        guard let infoPlistData = FileManager.default.contents(atPath: infoPlistPath) else {
            throw ValidationError.fileNotReadable("Could not read Info.plist")
        }

        guard let infoPlist = try PropertyListSerialization.propertyList(
            from: infoPlistData,
            options: [],
            format: nil
        ) as? [String: Any] else {
            throw ValidationError.invalidFormat("Info.plist has invalid format")
        }

        // Validate required privacy keys
        try validateKey("NSMicrophoneUsageDescription", in: infoPlist, description: "microphone usage")
        try validateKey("NSSpeechRecognitionUsageDescription", in: infoPlist, description: "speech recognition usage")
        try validateKey("NSScreenCaptureUsageDescription", in: infoPlist, description: "screen capture usage")

        print("    ✓ Info.plist contains all required privacy keys")
    }

    private func validateKey(_ key: String, in plist: [String: Any], description: String) throws {
        guard let value = plist[key] as? String, !value.isEmpty else {
            throw ValidationError.missingConfiguration("\(key) must exist and not be empty in Info.plist")
        }
    }

    // MARK: - Entitlements Validation

    private func validateEntitlements() throws {
        print("  • Checking entitlements...")

        let entitlementsPath = projectRoot
            .appendingPathComponent("MeetingRecorder/MeetingRecorder.entitlements")
            .path

        guard FileManager.default.fileExists(atPath: entitlementsPath) else {
            throw ValidationError.fileNotFound("Entitlements file not found at: \(entitlementsPath)")
        }

        guard let entitlementsData = FileManager.default.contents(atPath: entitlementsPath) else {
            throw ValidationError.fileNotReadable("Could not read entitlements file")
        }

        guard let entitlements = try PropertyListSerialization.propertyList(
            from: entitlementsData,
            options: [],
            format: nil
        ) as? [String: Any] else {
            throw ValidationError.invalidFormat("Entitlements file has invalid format")
        }

        // Validate required entitlements
        try validateEntitlement("com.apple.security.app-sandbox", in: entitlements, expectedValue: true, description: "App Sandbox")
        try validateEntitlement("com.apple.security.device.audio-input", in: entitlements, expectedValue: true, description: "Audio Input")
        try validateEntitlement("com.apple.security.files.user-selected.read-write", in: entitlements, expectedValue: true, description: "User Selected File Access")

        print("    ✓ Entitlements are properly configured")
    }

    private func validateEntitlement(_ key: String, in entitlements: [String: Any], expectedValue: Bool, description: String) throws {
        guard let value = entitlements[key] as? Bool else {
            throw ValidationError.missingConfiguration("\(key) must be present in entitlements")
        }

        guard value == expectedValue else {
            throw ValidationError.invalidConfiguration("\(key) must be \(expectedValue) (currently: \(value))")
        }
    }

    // MARK: - Build Configuration Validation

    private func validateBuildConfigurations() throws {
        print("  • Checking build configurations...")

        let projectPath = projectRoot
            .appendingPathComponent("MeetingRecorder.xcodeproj/project.pbxproj")
            .path

        guard FileManager.default.fileExists(atPath: projectPath) else {
            throw ValidationError.fileNotFound("project.pbxproj not found at: \(projectPath)")
        }

        guard let projectContent = try? String(contentsOfFile: projectPath, encoding: .utf8) else {
            throw ValidationError.fileNotReadable("Could not read project.pbxproj")
        }

        // Check for Debug configuration
        guard projectContent.contains("name = Debug;") else {
            throw ValidationError.missingConfiguration("Debug build configuration not found in project")
        }

        // Check for Release configuration
        guard projectContent.contains("name = Release;") else {
            throw ValidationError.missingConfiguration("Release build configuration not found in project")
        }

        print("    ✓ Debug and Release build configurations exist")
    }

    // MARK: - Deployment Target Validation

    private func validateDeploymentTarget() throws {
        print("  • Checking deployment target...")

        let projectPath = projectRoot
            .appendingPathComponent("MeetingRecorder.xcodeproj/project.pbxproj")
            .path

        guard let projectContent = try? String(contentsOfFile: projectPath, encoding: .utf8) else {
            throw ValidationError.fileNotReadable("Could not read project.pbxproj")
        }

        guard projectContent.contains("MACOSX_DEPLOYMENT_TARGET") else {
            throw ValidationError.missingConfiguration("macOS deployment target must be configured")
        }

        print("    ✓ Deployment target is configured")
    }
}

// MARK: - Validation Error

enum ValidationError: Error, CustomStringConvertible {
    case fileNotFound(String)
    case fileNotReadable(String)
    case invalidFormat(String)
    case missingConfiguration(String)
    case invalidConfiguration(String)

    var description: String {
        switch self {
        case .fileNotFound(let message):
            return "❌ File Not Found: \(message)"
        case .fileNotReadable(let message):
            return "❌ File Not Readable: \(message)"
        case .invalidFormat(let message):
            return "❌ Invalid Format: \(message)"
        case .missingConfiguration(let message):
            return "❌ Missing Configuration: \(message)"
        case .invalidConfiguration(let message):
            return "❌ Invalid Configuration: \(message)"
        }
    }
}

// MARK: - Main Execution

do {
    let validator = ConfigurationValidator()
    try validator.validate()
    exit(0)
} catch let error as ValidationError {
    print("\n" + error.description)
    print("\n⛔️ Build failed: Configuration validation error")
    exit(1)
} catch {
    print("\n❌ Unexpected error: \(error)")
    print("\n⛔️ Build failed: Configuration validation error")
    exit(1)
}
