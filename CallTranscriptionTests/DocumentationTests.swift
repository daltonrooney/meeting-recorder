import XCTest
import Foundation

/// Tests that verify comprehensive documentation exists and is complete
final class DocumentationTests: XCTestCase {

    // MARK: - README Completeness Tests

    func testREADMEExists() throws {
        let readmePath = projectRoot.appendingPathComponent("README.md")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: readmePath.path),
            "README.md must exist in repository root"
        )
    }

    func testREADMEIncludesProjectDescription() throws {
        let readmeContent = try readREADME()
        XCTAssertTrue(
            readmeContent.contains("Olive") || readmeContent.lowercased().contains("call transcription"),
            "README must include project description"
        )
    }

    func testREADMEIncludesRequirements() throws {
        let readmeContent = try readREADME()
        XCTAssertTrue(
            readmeContent.lowercased().contains("requirement") || readmeContent.lowercased().contains("macos"),
            "README must include system requirements (macOS version)"
        )
    }

    func testREADMEIncludesBuildInstructions() throws {
        let readmeContent = try readREADME()
        XCTAssertTrue(
            readmeContent.lowercased().contains("build") || readmeContent.lowercased().contains("xcode"),
            "README must include build instructions"
        )
    }

    func testREADMEIncludesUsageInstructions() throws {
        let readmeContent = try readREADME()
        XCTAssertTrue(
            readmeContent.lowercased().contains("usage") || readmeContent.lowercased().contains("how to"),
            "README must include usage instructions"
        )
    }

    // MARK: - User Documentation Tests

    func testUserDocumentationExplainsInstallation() throws {
        let readmeContent = try readREADME()
        XCTAssertTrue(
            readmeContent.lowercased().contains("install") || readmeContent.lowercased().contains("setup"),
            "Documentation must explain installation process"
        )
    }

    func testUserDocumentationExplainsPermissions() throws {
        let readmeContent = try readREADME()
        XCTAssertTrue(
            readmeContent.lowercased().contains("permission") || readmeContent.lowercased().contains("privacy"),
            "Documentation must explain required permissions"
        )
    }

    func testUserDocumentationExplainsFeatures() throws {
        let readmeContent = try readREADME()
        let hasRecording = readmeContent.lowercased().contains("record")
        let hasTranscription = readmeContent.lowercased().contains("transcri")
        XCTAssertTrue(
            hasRecording && hasTranscription,
            "Documentation must explain core features (recording, transcription)"
        )
    }

    func testUserDocumentationExplainsSettings() throws {
        let readmeContent = try readREADME()
        XCTAssertTrue(
            readmeContent.lowercased().contains("setting") || readmeContent.lowercased().contains("configuration"),
            "Documentation must explain available settings"
        )
    }

    func testUserDocumentationIncludesTroubleshooting() throws {
        let readmeContent = try readREADME()
        XCTAssertTrue(
            readmeContent.lowercased().contains("troubleshoot") || readmeContent.lowercased().contains("common") && readmeContent.lowercased().contains("error"),
            "Documentation must include troubleshooting section"
        )
    }

    // MARK: - Developer Documentation Tests

    func testDeveloperDocumentationExplainsArchitecture() throws {
        let readmeContent = try readREADME()
        XCTAssertTrue(
            readmeContent.lowercased().contains("architecture"),
            "Developer documentation must explain or reference architecture"
        )
    }

    func testDeveloperDocumentationExplainsHowToBuild() throws {
        let readmeContent = try readREADME()
        XCTAssertTrue(
            readmeContent.lowercased().contains("build") || readmeContent.lowercased().contains("compile"),
            "Developer documentation must explain build process"
        )
    }

    func testDeveloperDocumentationExplainsHowToTest() throws {
        let readmeContent = try readREADME()
        XCTAssertTrue(
            readmeContent.lowercased().contains("test") || readmeContent.lowercased().contains("tdd"),
            "Developer documentation must explain testing approach"
        )
    }

    func testDeveloperDocumentationExplainsHowToContribute() throws {
        let readmeContent = try readREADME()
        XCTAssertTrue(
            readmeContent.lowercased().contains("contribut") || readmeContent.lowercased().contains("development"),
            "Developer documentation must explain contribution process"
        )
    }

    func testDeveloperDocumentationReferencesArchitectureMd() throws {
        let readmeContent = try readREADME()
        XCTAssertTrue(
            readmeContent.contains("architecture.md"),
            "Developer documentation must reference architecture.md"
        )
    }

    // MARK: - Troubleshooting Guide Tests

    func testTroubleshootingCoversCommonErrors() throws {
        let readmeContent = try readREADME()
        // Check for troubleshooting section with error-related content
        let hasTroubleshooting = readmeContent.lowercased().contains("troubleshoot")
        let hasErrors = readmeContent.lowercased().contains("error") || readmeContent.lowercased().contains("problem")
        XCTAssertTrue(
            hasTroubleshooting && hasErrors,
            "Troubleshooting guide must cover common errors"
        )
    }

    func testTroubleshootingCoversPermissionIssues() throws {
        let readmeContent = try readREADME()
        let hasTroubleshooting = readmeContent.lowercased().contains("troubleshoot")
        let hasPermissions = readmeContent.lowercased().contains("permission")
        XCTAssertTrue(
            hasTroubleshooting && hasPermissions,
            "Troubleshooting guide must cover permission issues"
        )
    }

    func testTroubleshootingCoversAudioCaptureIssues() throws {
        let readmeContent = try readREADME()
        let hasTroubleshooting = readmeContent.lowercased().contains("troubleshoot")
        let hasAudio = readmeContent.lowercased().contains("audio") || readmeContent.lowercased().contains("recording")
        XCTAssertTrue(
            hasTroubleshooting && hasAudio,
            "Troubleshooting guide must cover audio capture issues"
        )
    }

    // MARK: - Helper Methods

    private var projectRoot: URL {
        // Use source file path (#file) to locate project root
        // This works reliably in Xcode and command-line builds
        let sourceFile = #filePath
        var url = URL(fileURLWithPath: sourceFile)

        // Navigate up from CallTranscriptionTests/DocumentationTests.swift to project root
        url.deleteLastPathComponent() // Remove DocumentationTests.swift
        url.deleteLastPathComponent() // Remove CallTranscriptionTests directory

        return url
    }

    private func readREADME() throws -> String {
        let readmePath = projectRoot.appendingPathComponent("README.md")
        return try String(contentsOf: readmePath, encoding: .utf8)
    }
}
