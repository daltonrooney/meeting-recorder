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
        print("  📁 Project root: \(projectRoot.path)")

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
            .appendingPathComponent("CallTranscription/Info.plist")
            .path

        guard FileManager.default.fileExists(atPath: infoPlistPath) else {
            throw ValidationError.fileNotFound("Info.plist not found at: \(infoPlistPath)")
        }

        guard let infoPlistData = FileManager.default.contents(atPath: infoPlistPath) else {
            throw ValidationError.fileNotReadable("Could not read Info.plist")
        }

        let plistObject: Any
        do {
            plistObject = try PropertyListSerialization.propertyList(
                from: infoPlistData,
                options: [],
                format: nil
            )
        } catch {
            var errorDetails = "Info.plist parsing failed at path: \(infoPlistPath)\n"
            errorDetails += "    Parse error: \(error.localizedDescription)"
            if let nsError = error as NSError? {
                errorDetails += "\n    Domain: \(nsError.domain), Code: \(nsError.code)"
            }
            errorDetails += "\n    Hint: Check that the file is valid XML plist format. Try: plutil -lint \(infoPlistPath)"
            throw ValidationError.invalidFormat(errorDetails)
        }

        guard let infoPlist = plistObject as? [String: Any] else {
            throw ValidationError.invalidFormat("Info.plist must be a dictionary, found: \(type(of: plistObject))")
        }

        // Validate required privacy keys
        try validateKey("NSMicrophoneUsageDescription", in: infoPlist, description: "microphone usage")
        try validateKey("NSSpeechRecognitionUsageDescription", in: infoPlist, description: "speech recognition usage")

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
            .appendingPathComponent("CallTranscription/CallTranscription.entitlements")
            .path

        guard FileManager.default.fileExists(atPath: entitlementsPath) else {
            throw ValidationError.fileNotFound("Entitlements file not found at: \(entitlementsPath)")
        }

        guard let entitlementsData = FileManager.default.contents(atPath: entitlementsPath) else {
            throw ValidationError.fileNotReadable("Could not read entitlements file")
        }

        let entitlementsObject: Any
        do {
            entitlementsObject = try PropertyListSerialization.propertyList(
                from: entitlementsData,
                options: [],
                format: nil
            )
        } catch {
            var errorDetails = "Entitlements parsing failed at path: \(entitlementsPath)\n"
            errorDetails += "    Parse error: \(error.localizedDescription)"
            if let nsError = error as NSError? {
                errorDetails += "\n    Domain: \(nsError.domain), Code: \(nsError.code)"
            }
            errorDetails += "\n    Hint: Check that the file is valid XML plist format. Try: plutil -lint \(entitlementsPath)"
            throw ValidationError.invalidFormat(errorDetails)
        }

        guard let entitlements = entitlementsObject as? [String: Any] else {
            throw ValidationError.invalidFormat("Entitlements must be a dictionary, found: \(type(of: entitlementsObject))")
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
            .appendingPathComponent("Olive.xcodeproj/project.pbxproj")
            .path

        guard FileManager.default.fileExists(atPath: projectPath) else {
            throw ValidationError.fileNotFound("project.pbxproj not found at: \(projectPath)")
        }

        let projectContent: String
        do {
            projectContent = try String(contentsOfFile: projectPath, encoding: .utf8)
        } catch {
            throw ValidationError.fileNotReadable("Could not read project.pbxproj: \(error.localizedDescription)")
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
            .appendingPathComponent("Olive.xcodeproj/project.pbxproj")
            .path

        let projectContent: String
        do {
            projectContent = try String(contentsOfFile: projectPath, encoding: .utf8)
        } catch {
            throw ValidationError.fileNotReadable("Could not read project.pbxproj: \(error.localizedDescription)")
        }

        guard projectContent.contains("MACOSX_DEPLOYMENT_TARGET") else {
            throw ValidationError.missingConfiguration("macOS deployment target must be configured")
        }

        // Extract and validate the actual version
        let pattern = #"MACOSX_DEPLOYMENT_TARGET\s*=\s*"?([0-9]+\.[0-9]+)"?;"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: projectContent, range: NSRange(projectContent.startIndex..., in: projectContent)),
              let versionRange = Range(match.range(at: 1), in: projectContent) else {
            throw ValidationError.invalidConfiguration("Could not parse MACOSX_DEPLOYMENT_TARGET version")
        }

        let versionString = String(projectContent[versionRange])
        let components = versionString.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 2 else {
            throw ValidationError.invalidConfiguration("Invalid MACOSX_DEPLOYMENT_TARGET format: \(versionString)")
        }

        let major = components[0]
        let minor = components[1]

        // Validate minimum 26.0 (as per architecture.md - requires SpeechTranscriber API)
        if major < 26 {
            throw ValidationError.invalidConfiguration(
                "MACOSX_DEPLOYMENT_TARGET must be at least 26.0 (found: \(versionString))"
            )
        }

        print("    ✓ Deployment target is \(versionString) (minimum 26.0)")
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
    print("Fix the configuration issues above and rebuild.")
    exit(1)
} catch {
    print("\n❌ UNEXPECTED ERROR: The validation script itself encountered an error")
    print("Error: \(error)")
    print("Error type: \(type(of: error))")
    print("\n⛔️ Build failed: Validation script error (not a configuration issue)")
    print("This is likely a bug in the validation script. Please report this error.")
    if let localizedError = error as? LocalizedError {
        print("Details: \(localizedError.localizedDescription)")
        if let reason = localizedError.failureReason {
            print("Reason: \(reason)")
        }
    }
    exit(2)  // Different exit code for script errors vs config errors
}
