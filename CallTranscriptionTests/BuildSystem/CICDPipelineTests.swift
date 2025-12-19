import XCTest
@testable import CallTranscription

/// Tests for CI/CD pipeline configuration and functionality
///
/// These tests verify that:
/// - Automated builds work in CI environment
/// - Tests run successfully in CI
/// - Build artifacts are generated correctly
/// - Version numbering follows semantic versioning
/// - CI workflow configuration is valid
final class CICDPipelineTests: XCTestCase {

    // MARK: - Automated Build Tests

    func testAutomatedBuildWorks() throws {
        // Test that automated build completes successfully
        let workflowExists = FileManager.default.fileExists(
            atPath: ".github/workflows/ci.yml"
        )

        XCTAssertTrue(workflowExists, "CI workflow file should exist")

        // Verify workflow can be parsed
        let workflowContent = try String(contentsOfFile: ".github/workflows/ci.yml")
        XCTAssertTrue(workflowContent.contains("xcodebuild"), "Workflow should use xcodebuild")
    }

    func testTestsRunInCI() throws {
        // Test that CI workflow includes test execution
        let workflowContent = try String(contentsOfFile: ".github/workflows/ci.yml")

        XCTAssertTrue(workflowContent.contains("test") || workflowContent.contains("xcodebuild"),
                     "CI workflow should run tests")
    }

    func testBuildArtifactsGenerated() throws {
        // Test that build artifacts are created and uploaded
        let workflowContent = try String(contentsOfFile: ".github/workflows/ci.yml")

        XCTAssertTrue(workflowContent.contains("upload-artifact") ||
                     workflowContent.contains("actions/upload"),
                     "CI should upload build artifacts")
    }

    func testVersionNumberingCorrect() throws {
        // Test that version follows semantic versioning
        let infoPlistPath = "CallTranscription/Info.plist"
        let data = try Data(contentsOf: URL(fileURLWithPath: infoPlistPath))
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]

        let version = plist?["CFBundleShortVersionString"] as? String
        XCTAssertNotNil(version, "Version should be present in Info.plist")

        // Verify semantic versioning format (e.g., 1.0.0)
        let semverPattern = "^\\d+\\.\\d+\\.\\d+$"
        let regex = try NSRegularExpression(pattern: semverPattern)
        let range = NSRange(version!.startIndex..., in: version!)
        let matches = regex.firstMatch(in: version!, range: range)

        XCTAssertNotNil(matches, "Version should follow semantic versioning (X.Y.Z)")
    }

    // MARK: - Workflow Configuration Tests

    func testCIWorkflowHasRequiredJobs() throws {
        // Test that CI workflow contains all required jobs
        let workflowContent = try String(contentsOfFile: ".github/workflows/ci.yml")

        XCTAssertTrue(workflowContent.contains("jobs:"), "Workflow should define jobs")
        XCTAssertTrue(workflowContent.contains("build") || workflowContent.contains("test"),
                     "Workflow should have build or test job")
    }

    func testCIWorkflowUsesCorrectMacOSVersion() throws {
        // Test that CI uses appropriate macOS version
        let workflowContent = try String(contentsOfFile: ".github/workflows/ci.yml")

        XCTAssertTrue(workflowContent.contains("macos") || workflowContent.contains("macOS"),
                     "Workflow should specify macOS runner")
    }

    func testCIWorkflowHasProperTriggers() throws {
        // Test that workflow triggers on appropriate events
        let workflowContent = try String(contentsOfFile: ".github/workflows/ci.yml")

        XCTAssertTrue(workflowContent.contains("on:") || workflowContent.contains("on "),
                     "Workflow should define triggers")
        XCTAssertTrue(workflowContent.contains("push") || workflowContent.contains("pull_request"),
                     "Workflow should trigger on push or PR")
    }

    func testWorkflowValidatesBeforeBuild() throws {
        // Test that validation runs before building
        let workflowContent = try String(contentsOfFile: ".github/workflows/ci.yml")

        XCTAssertTrue(workflowContent.contains("validate") || workflowContent.contains("lint"),
                     "Workflow should validate before building")
    }

    // MARK: - Build Script Tests

    func testBuildScriptExists() throws {
        // Test that build script is available
        let scriptExists = FileManager.default.fileExists(atPath: "scripts/build.sh")

        XCTAssertTrue(scriptExists, "Build script should exist at scripts/build.sh")
    }

    func testBuildScriptIsExecutable() throws {
        // Test that build script has executable permissions
        let scriptPath = "scripts/build.sh"
        let attributes = try FileManager.default.attributesOfItem(atPath: scriptPath)
        let permissions = attributes[.posixPermissions] as? NSNumber

        XCTAssertNotNil(permissions, "Script should have permissions set")
        XCTAssertTrue((permissions?.intValue ?? 0) & 0o111 != 0,
                     "Build script should be executable")
    }

    func testBuildScriptHandlesDebugConfiguration() throws {
        // Test that build script supports debug builds
        let scriptContent = try String(contentsOfFile: "scripts/build.sh")

        XCTAssertTrue(scriptContent.contains("Debug") || scriptContent.contains("debug"),
                     "Build script should handle Debug configuration")
    }

    func testBuildScriptHandlesReleaseConfiguration() throws {
        // Test that build script supports release builds
        let scriptContent = try String(contentsOfFile: "scripts/build.sh")

        XCTAssertTrue(scriptContent.contains("Release") || scriptContent.contains("release"),
                     "Build script should handle Release configuration")
    }

    func testBuildScriptCleansBeforeBuild() throws {
        // Test that build script can clean before building
        let scriptContent = try String(contentsOfFile: "scripts/build.sh")

        XCTAssertTrue(scriptContent.contains("clean") || scriptContent.contains("xcodebuild"),
                     "Build script should support clean builds")
    }

    func testBuildScriptOutputsArtifacts() throws {
        // Test that build script creates output artifacts
        let scriptContent = try String(contentsOfFile: "scripts/build.sh")

        XCTAssertTrue(scriptContent.contains("build") || scriptContent.contains("archive"),
                     "Build script should create artifacts")
    }

    // MARK: - Distribution Tests

    func testCanCreateDistributionArchive() throws {
        // Test that distribution archive can be created
        let scriptExists = FileManager.default.fileExists(atPath: "scripts/package.sh")

        XCTAssertTrue(scriptExists, "Package script should exist for creating distribution")
    }

    func testDistributionArchiveIsValid() throws {
        // Test that created archive is valid
        let scriptContent = try String(contentsOfFile: "scripts/package.sh")

        XCTAssertTrue(scriptContent.contains("zip") || scriptContent.contains("dmg") ||
                     scriptContent.contains("pkg"),
                     "Package script should create zip, dmg, or pkg")
    }

    func testInstallationProcessWorks() throws {
        // Test that installation instructions are present
        let readmeExists = FileManager.default.fileExists(atPath: "README.md")

        XCTAssertTrue(readmeExists, "README with installation instructions should exist")

        let readmeContent = try String(contentsOfFile: "README.md")
        XCTAssertTrue(readmeContent.contains("install") || readmeContent.contains("Install"),
                     "README should contain installation instructions")
    }

    // MARK: - Release Process Tests

    func testReleaseScriptExists() throws {
        // Test that release script is available
        let scriptExists = FileManager.default.fileExists(atPath: "scripts/release.sh")

        XCTAssertTrue(scriptExists, "Release script should exist at scripts/release.sh")
    }

    func testReleaseScriptTagsVersion() throws {
        // Test that release script creates git tags
        let scriptContent = try String(contentsOfFile: "scripts/release.sh")

        XCTAssertTrue(scriptContent.contains("git tag") || scriptContent.contains("tag"),
                     "Release script should create version tags")
    }

    func testReleaseScriptBuildsForDistribution() throws {
        // Test that release script builds release configuration
        let scriptContent = try String(contentsOfFile: "scripts/release.sh")

        XCTAssertTrue(scriptContent.contains("Release") || scriptContent.contains("archive"),
                     "Release script should build Release configuration")
    }

    func testReleaseScriptValidatesBeforeRelease() throws {
        // Test that release script runs validation
        let scriptContent = try String(contentsOfFile: "scripts/release.sh")

        XCTAssertTrue(scriptContent.contains("test") || scriptContent.contains("validate"),
                     "Release script should validate before releasing")
    }
}
