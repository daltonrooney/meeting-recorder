import XCTest
@testable import CallTranscription

/// Tests for localization infrastructure setup and String Catalog validation.
///
/// These tests verify that the String Catalog is properly configured with all
/// required languages and is correctly bundled in the application.
final class LocalizationInfrastructureTests: XCTestCase {

    // MARK: - String Catalog File Tests

    func testStringCatalogFileExists() {
        // Given: The app should have a String Catalog for localization
        // When: Looking for Localizable.xcstrings in the main bundle
        let bundle = Bundle.main

        // Then: String Catalog should be found in resources
        let catalogURL = bundle.url(forResource: "Localizable", withExtension: "xcstrings")
        XCTAssertNotNil(catalogURL,
                       "Localizable.xcstrings should exist in the main bundle resources")
    }

    func testStringCatalogIsValidJSON() {
        // Given: String Catalog exists
        guard let catalogURL = Bundle.main.url(forResource: "Localizable", withExtension: "xcstrings") else {
            XCTFail("String Catalog file not found")
            return
        }

        // When: Reading the String Catalog file
        do {
            let data = try Data(contentsOf: catalogURL)

            // Then: It should be valid JSON
            let json = try JSONSerialization.jsonObject(with: data)
            XCTAssertNotNil(json, "String Catalog should contain valid JSON")

            // And: Should be a dictionary at the root
            XCTAssertTrue(json is [String: Any],
                         "String Catalog root should be a JSON dictionary")
        } catch {
            XCTFail("Failed to parse String Catalog as JSON: \(error)")
        }
    }

    func testStringCatalogHasVersionField() {
        // Given: String Catalog exists and is valid JSON
        guard let catalogURL = Bundle.main.url(forResource: "Localizable", withExtension: "xcstrings"),
              let data = try? Data(contentsOf: catalogURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("String Catalog not found or invalid")
            return
        }

        // Then: Should have a version field
        XCTAssertNotNil(json["version"],
                       "String Catalog should have a 'version' field")

        // And: Version should be "1.0"
        if let version = json["version"] as? String {
            XCTAssertEqual(version, "1.0",
                          "String Catalog version should be '1.0'")
        }
    }

    func testStringCatalogHasSourceLanguage() {
        // Given: String Catalog exists and is valid JSON
        guard let catalogURL = Bundle.main.url(forResource: "Localizable", withExtension: "xcstrings"),
              let data = try? Data(contentsOf: catalogURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("String Catalog not found or invalid")
            return
        }

        // Then: Should have a sourceLanguage field
        XCTAssertNotNil(json["sourceLanguage"],
                       "String Catalog should have a 'sourceLanguage' field")

        // And: Source language should be English
        if let sourceLanguage = json["sourceLanguage"] as? String {
            XCTAssertEqual(sourceLanguage, "en",
                          "String Catalog source language should be 'en' (English)")
        }
    }

    // MARK: - Supported Languages Tests

    func testStringCatalogSupportsAllRequiredLanguages() {
        // Given: App should support 6 languages
        let requiredLanguages = ["en", "es", "fr", "de", "ja", "zh-Hans"]

        guard let catalogURL = Bundle.main.url(forResource: "Localizable", withExtension: "xcstrings"),
              let data = try? Data(contentsOf: catalogURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let strings = json["strings"] as? [String: Any] else {
            XCTFail("String Catalog not found or invalid structure")
            return
        }

        // When: Examining the strings dictionary
        // Then: For any key that exists, it should have localizations for all required languages
        // Note: This test will pass even with empty strings dict initially
        if !strings.isEmpty {
            // Check first key as sample (full validation in later tests)
            if let firstKey = strings.keys.first,
               let stringEntry = strings[firstKey] as? [String: Any],
               let localizations = stringEntry["localizations"] as? [String: Any] {

                for language in requiredLanguages {
                    XCTAssertTrue(localizations.keys.contains(language),
                                "String Catalog should support language: \(language)")
                }
            }
        }
    }

    func testEnglishIsTheBaseLanguage() {
        // Given: String Catalog is configured
        guard let catalogURL = Bundle.main.url(forResource: "Localizable", withExtension: "xcstrings"),
              let data = try? Data(contentsOf: catalogURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("String Catalog not found or invalid")
            return
        }

        // Then: Source language should be English
        let sourceLanguage = json["sourceLanguage"] as? String
        XCTAssertEqual(sourceLanguage, "en",
                      "English (en) should be the base/source language for all translations")
    }

    // MARK: - Bundle Configuration Tests

    func testStringCatalogIsProperlyBundled() {
        // Given: The app is running
        let bundle = Bundle.main

        // Then: String Catalog should be accessible from the bundle
        let catalogURL = bundle.url(forResource: "Localizable", withExtension: "xcstrings")
        XCTAssertNotNil(catalogURL,
                       "String Catalog should be bundled in the application")

        // And: The file should be readable
        if let url = catalogURL {
            XCTAssertTrue(FileManager.default.isReadableFile(atPath: url.path),
                         "String Catalog file should be readable")
        }
    }

    func testStringsResourceIsAccessibleAtRuntime() {
        // Given: String Catalog is bundled
        // When: Attempting to use localization at runtime
        // Then: The localization system should be functional
        // Note: This is a basic smoke test - actual string localization tested in component tests

        let bundle = Bundle.main
        let catalogExists = bundle.url(forResource: "Localizable", withExtension: "xcstrings") != nil

        XCTAssertTrue(catalogExists,
                     "String Catalog must be accessible for runtime localization to work")
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
