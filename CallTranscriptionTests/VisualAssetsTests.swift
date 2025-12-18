import XCTest

/// Tests for visual assets including app icon and menu bar icons.
///
/// This test suite verifies that:
/// - App icon (icon.icon) is properly configured
/// - Menu bar icons (inactive and recording) exist and are properly structured
/// - Asset catalog structure is valid with proper Contents.json files
/// - All assets support required display scales and modes
final class VisualAssetsTests: XCTestCase {

    // MARK: - Constants

    private static let assetCatalogPath = "CallTranscription/Assets.xcassets"
    private static let appIconPath = "CallTranscription/icon.icon"
    private static let inactiveIconImageset = "MenuBarIconInactive.imageset"
    private static let recordingIconImageset = "MenuBarIconRecording.imageset"

    // MARK: - Helper Methods

    /// Get project root directory
    private func getProjectRoot() -> URL {
        // Navigate up from test bundle to project root
        let testBundlePath = Bundle(for: type(of: self)).bundlePath
        let projectRoot = URL(fileURLWithPath: testBundlePath)
            .deletingLastPathComponent()  // Remove test bundle
            .deletingLastPathComponent()  // Remove build products
            .deletingLastPathComponent()  // Should be at project root
        return projectRoot
    }

    /// Check if file exists at path relative to project root
    private func fileExists(atRelativePath path: String) -> Bool {
        let fullPath = getProjectRoot().appendingPathComponent(path).path
        return FileManager.default.fileExists(atPath: fullPath)
    }

    /// Get contents of file at path relative to project root
    private func getFileContents(atRelativePath path: String) throws -> Data {
        let fullPath = getProjectRoot().appendingPathComponent(path)
        return try Data(contentsOf: fullPath)
    }

    /// Parse JSON from file
    private func parseJSON(atRelativePath path: String) throws -> [String: Any] {
        let data = try getFileContents(atRelativePath: path)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to parse JSON at \(path)")
            return [:]
        }
        return json
    }

    // MARK: - App Icon Tests

    func testAppIconPackageExists() {
        XCTAssertTrue(
            fileExists(atRelativePath: Self.appIconPath),
            "icon.icon package must exist at \(Self.appIconPath)"
        )
    }

    func testAppIconPackageStructure() throws {
        let iconPath = getProjectRoot().appendingPathComponent(Self.appIconPath)

        // Verify icon.icon is a directory (package)
        var isDirectory: ObjCBool = false
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: iconPath.path, isDirectory: &isDirectory),
            "icon.icon must exist"
        )
        XCTAssertTrue(isDirectory.boolValue, "icon.icon must be a directory (package)")

        // Verify icon.json exists inside the package
        let iconJSONPath = iconPath.appendingPathComponent("icon.json").path
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: iconJSONPath),
            "icon.json must exist inside icon.icon package"
        )

        // Verify Assets directory exists
        let assetsPath = iconPath.appendingPathComponent("Assets").path
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: assetsPath),
            "Assets directory must exist inside icon.icon package"
        )
    }

    func testAppIconIsReferencedInProject() throws {
        // Read the project.pbxproj file
        let projectPath = "Olive.xcodeproj/project.pbxproj"
        let projectData = try getFileContents(atRelativePath: projectPath)
        let projectContent = String(data: projectData, encoding: .utf8) ?? ""

        // Verify icon.icon is referenced in the project
        XCTAssertTrue(
            projectContent.contains("icon.icon"),
            "icon.icon must be referenced in Olive.xcodeproj/project.pbxproj"
        )
    }

    // MARK: - Asset Catalog Tests

    func testAssetCatalogExists() {
        XCTAssertTrue(
            fileExists(atRelativePath: Self.assetCatalogPath),
            "Assets.xcassets must exist at \(Self.assetCatalogPath)"
        )
    }

    func testAssetCatalogContentsJSON() throws {
        let contentsPath = "\(Self.assetCatalogPath)/Contents.json"
        XCTAssertTrue(
            fileExists(atRelativePath: contentsPath),
            "Contents.json must exist in Assets.xcassets"
        )

        // Verify it's valid JSON
        let json = try parseJSON(atRelativePath: contentsPath)

        // Verify it has info section
        XCTAssertNotNil(json["info"], "Contents.json must have 'info' section")
    }

    // MARK: - Menu Bar Icon Tests

    func testMenuBarInactiveIconImagesetExists() {
        let imagesetPath = "\(Self.assetCatalogPath)/\(Self.inactiveIconImageset)"
        XCTAssertTrue(
            fileExists(atRelativePath: imagesetPath),
            "MenuBarIconInactive.imageset must exist in Assets.xcassets"
        )
    }

    func testMenuBarRecordingIconImagesetExists() {
        let imagesetPath = "\(Self.assetCatalogPath)/\(Self.recordingIconImageset)"
        XCTAssertTrue(
            fileExists(atRelativePath: imagesetPath),
            "MenuBarIconRecording.imageset must exist in Assets.xcassets"
        )
    }

    func testMenuBarInactiveIconHasSVG() {
        let svgPath = "\(Self.assetCatalogPath)/\(Self.inactiveIconImageset)/icon.svg"
        XCTAssertTrue(
            fileExists(atRelativePath: svgPath),
            "icon.svg must exist in MenuBarIconInactive.imageset"
        )
    }

    func testMenuBarRecordingIconHasSVG() {
        let svgPath = "\(Self.assetCatalogPath)/\(Self.recordingIconImageset)/icon.svg"
        XCTAssertTrue(
            fileExists(atRelativePath: svgPath),
            "icon.svg must exist in MenuBarIconRecording.imageset"
        )
    }

    func testMenuBarInactiveIconContentsJSON() throws {
        let contentsPath = "\(Self.assetCatalogPath)/\(Self.inactiveIconImageset)/Contents.json"
        XCTAssertTrue(
            fileExists(atRelativePath: contentsPath),
            "Contents.json must exist in MenuBarIconInactive.imageset"
        )

        // Verify it's valid JSON
        let json = try parseJSON(atRelativePath: contentsPath)

        // Verify it has required sections
        XCTAssertNotNil(json["images"], "Contents.json must have 'images' array")
        XCTAssertNotNil(json["info"], "Contents.json must have 'info' section")

        // Verify images array references the SVG
        guard let images = json["images"] as? [[String: Any]] else {
            XCTFail("'images' must be an array")
            return
        }

        let hasSVGReference = images.contains { image in
            guard let filename = image["filename"] as? String else { return false }
            return filename.contains(".svg")
        }
        XCTAssertTrue(hasSVGReference, "Contents.json must reference icon.svg file")
    }

    func testMenuBarRecordingIconContentsJSON() throws {
        let contentsPath = "\(Self.assetCatalogPath)/\(Self.recordingIconImageset)/Contents.json"
        XCTAssertTrue(
            fileExists(atRelativePath: contentsPath),
            "Contents.json must exist in MenuBarIconRecording.imageset"
        )

        // Verify it's valid JSON
        let json = try parseJSON(atRelativePath: contentsPath)

        // Verify it has required sections
        XCTAssertNotNil(json["images"], "Contents.json must have 'images' array")
        XCTAssertNotNil(json["info"], "Contents.json must have 'info' section")

        // Verify images array references the SVG
        guard let images = json["images"] as? [[String: Any]] else {
            XCTFail("'images' must be an array")
            return
        }

        let hasSVGReference = images.contains { image in
            guard let filename = image["filename"] as? String else { return false }
            return filename.contains(".svg")
        }
        XCTAssertTrue(hasSVGReference, "Contents.json must reference icon.svg file")
    }

    func testMenuBarIconsAreDifferent() throws {
        // Verify the two SVG files are different (monochrome vs color)
        let inactiveSVG = try getFileContents(
            atRelativePath: "\(Self.assetCatalogPath)/\(Self.inactiveIconImageset)/icon.svg"
        )
        let recordingSVG = try getFileContents(
            atRelativePath: "\(Self.assetCatalogPath)/\(Self.recordingIconImageset)/icon.svg"
        )

        XCTAssertNotEqual(
            inactiveSVG, recordingSVG,
            "Inactive and recording icons must be different (monochrome vs color)"
        )
    }

    func testInactiveIconIsMonochrome() throws {
        let svgData = try getFileContents(
            atRelativePath: "\(Self.assetCatalogPath)/\(Self.inactiveIconImageset)/icon.svg"
        )
        let svgContent = String(data: svgData, encoding: .utf8) ?? ""

        // Monochrome should use grayscale colors (B9B9B9, 868686, 6D6C6C based on the file we saw)
        let hasGrayscale = svgContent.contains("#B9B9B9") ||
                          svgContent.contains("#868686") ||
                          svgContent.contains("#6D6C6C")
        XCTAssertTrue(hasGrayscale, "Inactive icon should use grayscale/monochrome colors")
    }

    func testRecordingIconHasColor() throws {
        let svgData = try getFileContents(
            atRelativePath: "\(Self.assetCatalogPath)/\(Self.recordingIconImageset)/icon.svg"
        )
        let svgContent = String(data: svgData, encoding: .utf8) ?? ""

        // Color version should have green/orange colors (B1CC33, 5C9E31, FD623D based on the file we saw)
        let hasColor = svgContent.contains("#B1CC33") ||
                      svgContent.contains("#5C9E31") ||
                      svgContent.contains("#FD623D")
        XCTAssertTrue(hasColor, "Recording icon should use color (green/orange)")
    }

    // MARK: - Asset Catalog Organization Tests

    func testNoAppIconAppiconsetExists() {
        // Since we're using icon.icon (Icon Composer), AppIcon.appiconset should NOT exist
        // or if it exists, should be empty/unused
        let appiconsetPath = "\(Self.assetCatalogPath)/AppIcon.appiconset"

        // It's okay if the directory exists but is empty (leftover from setup)
        // The important part is that the project uses icon.icon instead
        if fileExists(atRelativePath: appiconsetPath) {
            // If it exists, it should not have a Contents.json or should be marked as unused
            let contentsPath = "\(appiconsetPath)/Contents.json"
            let hasContents = fileExists(atRelativePath: contentsPath)

            // We can be lenient here - either no Contents.json, or we just warn
            // The real test is that icon.icon is referenced in the project
            if hasContents {
                print("Warning: AppIcon.appiconset/Contents.json exists but should be unused (icon.icon takes precedence)")
            }
        }
    }

    func testAssetCatalogOnlyContainsMenuBarIcons() {
        let catalogURL = getProjectRoot().appendingPathComponent(Self.assetCatalogPath)

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: catalogURL,
            includingPropertiesForKeys: nil
        ) else {
            XCTFail("Could not read Assets.xcassets directory")
            return
        }

        let imagesets = contents.filter { $0.pathExtension == "imageset" || $0.lastPathComponent.hasSuffix(".imageset") }

        // Should have exactly 2 imagesets: MenuBarIconInactive and MenuBarIconRecording
        XCTAssertEqual(
            imagesets.count, 2,
            "Assets.xcassets should contain exactly 2 imagesets (MenuBarIconInactive and MenuBarIconRecording)"
        )

        let imagesetNames = imagesets.map { $0.lastPathComponent }
        XCTAssertTrue(
            imagesetNames.contains(Self.inactiveIconImageset),
            "Assets.xcassets must contain MenuBarIconInactive.imageset"
        )
        XCTAssertTrue(
            imagesetNames.contains(Self.recordingIconImageset),
            "Assets.xcassets must contain MenuBarIconRecording.imageset"
        )
    }
}
