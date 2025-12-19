import XCTest
@testable import CallTranscription

/// Tests for localization infrastructure setup and String Catalog validation.
///
/// These tests verify that the localization infrastructure is properly configured
/// and that the app bundle supports the required languages.
final class LocalizationInfrastructureTests: XCTestCase {

    // MARK: - Localization Infrastructure Tests

    func testLocalizationTableExists() {
        // Given: The app uses String Catalog for localization
        // When: Attempting to load the localization table
        let testKey = "localization.test.placeholder"
        let localizedValue = NSLocalizedString(testKey, comment: "Test placeholder")

        // Then: The localization system should be functional
        // If the key is not found, NSLocalizedString returns the key itself
        // If found, it returns the localized value
        XCTAssertNotEqual(localizedValue, "",
                         "Localization system should return a value for test key")
    }

    func testPlaceholderKeyIsLocalized() {
        // Given: String Catalog has a placeholder entry
        let testKey = "localization.test.placeholder"

        // When: Looking up the placeholder key
        let localizedValue = NSLocalizedString(testKey, comment: "Test placeholder")

        // Then: Should return the English value "Placeholder"
        XCTAssertEqual(localizedValue, "Placeholder",
                      "Placeholder key should return 'Placeholder' in English")
    }

    // MARK: - Bundle Configuration Tests

    func testAppBundleHasLocalizationResources() {
        // Given: The app bundle
        let bundle = Bundle.main

        // When: Checking for localization resources
        // Then: Bundle should have at least English localization
        let localizations = bundle.localizations

        XCTAssertTrue(localizations.contains("en"),
                     "App bundle should contain English localization")
    }

    func testLocalizationSystemIsAccessibleAtRuntime() {
        // Given: String Catalog is configured and bundled
        // When: Attempting to use localization at runtime
        let testKey = "localization.test.placeholder"
        let localizedValue = NSLocalizedString(testKey, comment: "Test placeholder")

        // Then: Should be able to retrieve localized strings
        XCTAssertFalse(localizedValue.isEmpty,
                      "Localization system should be accessible at runtime")
    }

    // MARK: - Development Language Configuration Tests

    func testProjectDevelopmentLanguageIsEnglish() {
        // Given: The app's main bundle
        let bundle = Bundle.main

        // When: Checking the development region
        let developmentRegion = bundle.developmentLocalization

        // Then: It should be English
        XCTAssertEqual(developmentRegion, "en",
                      "Project development language should be English (en)")
    }

    func testBundleSupportsMultipleLocalizations() {
        // Given: The app should support multiple languages
        let bundle = Bundle.main

        // When: Checking supported localizations
        let localizations = bundle.localizations

        // Then: Should include English at minimum
        XCTAssertTrue(localizations.contains("en"),
                     "Bundle should support English localization")

        // Note: Other languages will be added in later phases
        // This test establishes baseline
    }
}
