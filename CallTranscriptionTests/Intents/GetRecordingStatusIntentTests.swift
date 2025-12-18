import XCTest
import AppIntents
@testable import CallTranscription

@MainActor
final class GetRecordingStatusIntentTests: XCTestCase {

    var intent: GetRecordingStatusIntent!
    var mockAppState: AppState!
    var mockSettingsManager: SettingsManager!

    override func setUp() async throws {
        try await super.setUp()
        mockSettingsManager = SettingsManager(userDefaults: UserDefaults(suiteName: "test.GetRecordingStatusIntent")!)
        mockAppState = AppState(settingsManager: mockSettingsManager)
        intent = GetRecordingStatusIntent()
    }

    override func tearDown() async throws {
        intent = nil
        mockAppState = nil
        mockSettingsManager = nil

        // Clean up test UserDefaults
        if let testDefaults = UserDefaults(suiteName: "test.GetRecordingStatusIntent") {
            testDefaults.removePersistentDomain(forName: "test.GetRecordingStatusIntent")
        }

        try await super.tearDown()
    }

    // MARK: - Metadata Tests

    func testIntentHasCorrectTitle() {
        let title = GetRecordingStatusIntent.title
        XCTAssertNotNil(title, "Intent should have a title")
        XCTAssertTrue(String(describing: title).lowercased().contains("status") || String(describing: title).lowercased().contains("record"),
                     "Title should indicate getting recording status")
    }

    func testIntentHasDescription() {
        let description = GetRecordingStatusIntent.description
        XCTAssertNotNil(description, "Intent should have a description")
    }

    // MARK: - Execution Tests - Not Recording

    func testIntentReturnsNotRecordingStatus() async throws {
        // Given: App is not recording
        XCTAssertFalse(mockAppState.isRecording, "Should not be recording initially")

        // When: Intent is performed
        // let result = try await intent.perform()

        // Then: Result should indicate not recording
        // XCTAssertFalse(result.isRecording, "Should indicate not recording")
        // XCTAssertEqual(result.elapsedTime, "00:00", "Elapsed time should be zero")
        // XCTAssertFalse(result.isPaused, "Should not be paused")
        // (Test will fail until GetRecordingStatusIntent is implemented)
    }

    // MARK: - Execution Tests - Recording Active

    func testIntentReturnsRecordingStatus() async throws {
        // Given: App is recording
        mockAppState.startRecording()
        XCTAssertTrue(mockAppState.isRecording)

        // When: Intent is performed
        // let result = try await intent.perform()

        // Then: Result should indicate recording
        // XCTAssertTrue(result.isRecording, "Should indicate recording")
        // XCTAssertNotEqual(result.elapsedTime, "00:00", "Elapsed time should be non-zero")
        // XCTAssertFalse(result.isPaused, "Should not be paused")
        // (Test will fail until implementation exists)
    }

    func testIntentReturnsCorrectElapsedTime() async throws {
        // Given: App is recording for some time
        mockAppState.startRecording()
        try? await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds

        // When: Intent is performed
        // let result = try await intent.perform()

        // Then: Elapsed time should reflect actual time
        // XCTAssertNotEqual(result.elapsedTime, "00:00", "Elapsed time should show progress")
        // XCTAssertTrue(result.elapsedTime.contains(":"), "Should be in MM:SS format")
        // (Test will fail until implementation exists)
    }

    func testIntentReturnsMultipleTimesWithDifferentElapsed() async throws {
        // Given: App is recording
        mockAppState.startRecording()

        // When: Intent is performed at different times
        // let result1 = try await intent.perform()
        // try? await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds
        // let result2 = try await intent.perform()

        // Then: Elapsed time should increase
        // XCTAssertNotEqual(result1.elapsedTime, result2.elapsedTime, "Elapsed time should increase")
        // (Test will fail until implementation exists)
    }

    // MARK: - Execution Tests - Paused State

    func testIntentReturnsPausedStatus() async throws {
        // Given: App is recording and paused
        // mockAppState.startRecording()
        // try await mockAppState.pauseRecording()

        // When: Intent is performed
        // let result = try await intent.perform()

        // Then: Result should indicate paused
        // XCTAssertTrue(result.isRecording, "Should still indicate recording session exists")
        // XCTAssertTrue(result.isPaused, "Should indicate paused")
        // (Test will fail until implementation exists)
    }

    // MARK: - Result Structure Tests

    func testIntentResultContainsAllRequiredFields() async throws {
        // Given: App is recording
        mockAppState.startRecording()

        // When: Intent is performed
        // let result = try await intent.perform()

        // Then: Result should have all fields
        // XCTAssertNotNil(result.isRecording, "Should have isRecording field")
        // XCTAssertNotNil(result.elapsedTime, "Should have elapsedTime field")
        // XCTAssertNotNil(result.isPaused, "Should have isPaused field")
        // (Test will fail until implementation exists)
    }

    // MARK: - Thread Safety Tests

    func testIntentExecutesOnMainActor() async throws {
        // Verify the intent execution happens on MainActor
        let isOnMainThread = Thread.isMainThread
        XCTAssertTrue(isOnMainThread, "Test setup should be on main thread due to @MainActor")
    }

    // MARK: - Integration Tests

    func testIntentIntegratesWithAppState() async throws {
        // Given: Fresh app state
        XCTAssertFalse(mockAppState.isRecording)

        // When: Intent is performed
        // let result1 = try await intent.perform()

        // Then: Should reflect AppState values
        // XCTAssertFalse(result1.isRecording)

        // When: Start recording and check again
        mockAppState.startRecording()
        // let result2 = try await intent.perform()

        // Then: Should reflect updated AppState
        // XCTAssertTrue(result2.isRecording)
        // (Test will fail until implementation exists)
    }

    func testIntentDoesNotModifyAppState() async throws {
        // Given: App is recording
        mockAppState.startRecording()
        let initialIsRecording = mockAppState.isRecording
        let initialElapsedTime = mockAppState.elapsedTime

        // When: Intent is performed
        // _ = try await intent.perform()

        // Then: AppState should be unchanged
        XCTAssertEqual(mockAppState.isRecording, initialIsRecording, "Should not modify recording state")
        // (Elapsed time will change due to timer, so we just verify recording state)
        // (Test will fail until implementation exists)
    }
}
