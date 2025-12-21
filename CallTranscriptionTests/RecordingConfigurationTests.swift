import XCTest
@testable import CallTranscription

/// Tests for RecordingConfiguration following TDD methodology.
/// Tests are written FIRST before implementation.
final class RecordingConfigurationTests: XCTestCase {

    // MARK: - saveOriginalAudio Field Tests

    func testRecordingConfigurationIncludesSaveOriginalAudioField() {
        let config = RecordingConfiguration(
            outputFolder: "/tmp/test",
            locale: Locale(identifier: "en-US"),
            saveOriginalAudio: true
        )

        XCTAssertTrue(config.saveOriginalAudio)
    }

    func testSaveOriginalAudioDefaultsToFalse() {
        let config = RecordingConfiguration(
            outputFolder: "/tmp/test",
            locale: Locale(identifier: "en-US")
        )

        XCTAssertFalse(config.saveOriginalAudio)
    }

    func testSaveOriginalAudioCanBeSetToTrue() {
        let config = RecordingConfiguration(
            outputFolder: "/tmp/test",
            locale: Locale(identifier: "en-US"),
            saveOriginalAudio: true
        )

        XCTAssertTrue(config.saveOriginalAudio)
    }

    func testSaveOriginalAudioCanBeSetToFalse() {
        let config = RecordingConfiguration(
            outputFolder: "/tmp/test",
            locale: Locale(identifier: "en-US"),
            saveOriginalAudio: false
        )

        XCTAssertFalse(config.saveOriginalAudio)
    }

    func testSaveOriginalAudioPreservedWithOtherParameters() {
        let config = RecordingConfiguration(
            outputFolder: "/tmp/test",
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true,
            systemAudioEnabled: true,
            postRecordingActionType: .doNothing,
            postRecordingScriptPath: nil,
            shortcutIdentifier: nil,
            silencePauseThreshold: .never,
            filenameTemplate: "transcript_{date}_{time}.txt",
            outputFolderBookmark: nil,
            postRecordingScriptBookmark: nil,
            saveOriginalAudio: true
        )

        XCTAssertTrue(config.saveOriginalAudio)
        XCTAssertEqual(config.outputFolder, "/tmp/test")
        XCTAssertEqual(config.locale.identifier, "en-US")
    }
}
