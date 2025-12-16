import XCTest

/// DEPRECATED: Configuration validation has been moved to build-time script
///
/// These XCTests cannot run reliably in a sandboxed macOS app environment because they require
/// access to source files (Info.plist, entitlements, project.pbxproj) which are outside the
/// app's sandbox container.
///
/// Configuration validation is now performed by scripts/validate-configuration.swift which runs
/// as a pre-build script phase. This approach:
/// 1. Has full filesystem access (no sandbox limitations)
/// 2. Catches configuration errors immediately at build time (fail-fast)
/// 3. Follows industry standard practice for build configuration validation
///
/// These tests served their TDD purpose - they drove the initial implementation and verified
/// the configuration was correct. The validation logic has been preserved in the build script.
final class ProjectConfigurationTests: XCTestCase {
    override func setUpWithError() throws {
        throw XCTSkip("Configuration validation moved to build-time script at scripts/validate-configuration.swift")
    }
}
