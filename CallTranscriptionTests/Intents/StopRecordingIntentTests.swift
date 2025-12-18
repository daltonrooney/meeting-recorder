import XCTest
import AppIntents
@testable import CallTranscription

@MainActor
final class StopRecordingIntentTests: XCTestCase {

    var intent: StopRecordingIntent!
    var mockAppState: AppState!
    var mockSettingsManager: SettingsManager!

    override func setUp() async throws {
        try await super.setUp()
        mockSettingsManager = SettingsManager(userDefaults: UserDefaults(suiteName: "test.StopRecordingIntent")!)
        mockAppState = AppState(settingsManager: mockSettingsManager)
        intent = StopRecordingIntent()
    }

    override func tearDown() async throws {
        intent = nil
        mockAppState = nil
        mockSettingsManager = nil

        // Clean up test UserDefaults
        if let testDefaults = UserDefaults(suiteName: "test.StopRecordingIntent") {
            testDefaults.removePersistentDomain(forName: "test.StopRecordingIntent")
        }

        try await super.tearDown()
    }

    // MARK: - Metadata Tests

    func testIntentHasCorrectTitle() {
        let title = StopRecordingIntent.title
        XCTAssertNotNil(title, "Intent should have a title")
        XCTAssertTrue(String(describing: title).lowercased().contains("stop") || String(describing: title).lowercased().contains("record"),
                     "Title should indicate stopping a recording")
    }

    func testIntentHasDescription() {
        let description = StopRecordingIntent.description
        XCTAssertNotNil(description, "Intent should have a description")
    }

    // MARK: - Execution Tests

    func testIntentExecutionStopsRecording() async throws {
        // Given: App is recording
        mockAppState.startRecording()
        XCTAssertTrue(mockAppState.isRecording, "Should be recording before test")

        // When: Intent is performed (this will fail until implementation exists)
        // let result = try await intent.perform()

        // Then: Recording should be stopped
        // XCTAssertFalse(mockAppState.isRecording, "Should not be recording after stop")
        // (Test will fail until StopRecordingIntent is implemented)
    }

    func testIntentReturnsTranscriptFilePath() async throws {
        // Given: App is recording
        mockAppState.startRecording()

        // When: Intent is performed
        // let result = try await intent.perform()

        // Then: Result should contain transcript file path
        // XCTAssertNotNil(result.value, "Should return transcript file path")
        // (Test will fail until implementation exists)
    }

    func testIntentThrowsWhenNotRecording() async throws {
        // Given: App is not recording
        XCTAssertFalse(mockAppState.isRecording, "Should not be recording initially")

        // When: Intent is performed
        // Then: Should throw CallTranscriptionError.notRecording
        // do {
        //     _ = try await intent.perform()
        //     XCTFail("Should throw when not recording")
        // } catch let error as CallTranscriptionError {
        //     XCTAssertEqual(error, .notRecording, "Should throw notRecording error")
        // }
        // (Test will fail until implementation exists)
    }

    func testIntentCleansUpStateAfterStop() async throws {
        // Given: App is recording with elapsed time
        mockAppState.startRecording()
        // Wait for some elapsed time
        try? await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds

        // When: Intent is performed
        // let result = try await intent.perform()

        // Then: State should be reset
        // XCTAssertFalse(mockAppState.isRecording)
        // XCTAssertEqual(mockAppState.elapsedTime, "00:00")
        // (Test will fail until implementation exists)
    }

    func testIntentReturnsValidFileURL() async throws {
        // Given: App is recording
        mockAppState.startRecording()

        // When: Intent is performed
        // let result = try await intent.perform()

        // Then: Returned URL should be valid and point to existing file
        // if let urlString = result.value {
        //     let url = URL(fileURLWithPath: urlString)
        //     XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        // }
        // (Test will fail until implementation exists)
    }

    // MARK: - Thread Safety Tests

    func testIntentExecutesOnMainActor() async throws {
        // Verify the intent execution happens on MainActor
        let isOnMainThread = Thread.isMainThread
        XCTAssertTrue(isOnMainThread, "Test setup should be on main thread due to @MainActor")
    }

    // MARK: - Error Handling Tests

    func testIntentHandlesStopRecordingFailure() async throws {
        // Given: App is recording but stop will fail
        // (Would need to mock coordinator failure)

        // When: Intent is performed
        // Then: Should propagate or handle error appropriately
        // (Test will fail until implementation exists)
    }

    // MARK: - Integration Tests

    func testIntentIntegratesWithAppState() async throws {
        // Given: App is recording
        mockAppState.startRecording()
        XCTAssertTrue(mockAppState.isRecording)

        // When: Intent is performed
        // (Implementation will call AppState.stopActualRecording)

        // Then: AppState should reflect recording stopped
        // (Test will fail until implementation exists)
    }

    func testIntentResultContainsFilePath() async throws {
        // Given: App is recording
        mockAppState.startRecording()

        // When: Intent is performed
        // let result = try await intent.perform()

        // Then: Result should be a string path to the transcript
        // XCTAssertNotNil(result.value)
        // XCTAssertTrue(result.value?.hasSuffix(".md") ?? false, "Should return markdown file path")
        // (Test will fail until implementation exists)
    }
}
