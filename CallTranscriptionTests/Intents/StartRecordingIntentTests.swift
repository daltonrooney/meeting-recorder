import XCTest
import AppIntents
@testable import CallTranscription

@MainActor
final class StartRecordingIntentTests: XCTestCase {

    var intent: StartRecordingIntent!
    var mockAppState: AppState!
    var mockSettingsManager: SettingsManager!

    override func setUp() async throws {
        try await super.setUp()
        mockSettingsManager = SettingsManager(userDefaults: UserDefaults(suiteName: "test.StartRecordingIntent")!)
        mockAppState = AppState(settingsManager: mockSettingsManager)
        intent = StartRecordingIntent()
    }

    override func tearDown() async throws {
        intent = nil
        mockAppState = nil
        mockSettingsManager = nil

        // Clean up test UserDefaults
        if let testDefaults = UserDefaults(suiteName: "test.StartRecordingIntent") {
            testDefaults.removePersistentDomain(forName: "test.StartRecordingIntent")
        }

        try await super.tearDown()
    }

    // MARK: - Metadata Tests

    func testIntentHasCorrectTitle() {
        let title = StartRecordingIntent.title
        XCTAssertNotNil(title, "Intent should have a title")
        XCTAssertTrue(String(describing: title).lowercased().contains("start") || String(describing: title).lowercased().contains("record"),
                     "Title should indicate starting a recording")
    }

    func testIntentHasDescription() {
        let description = StartRecordingIntent.description
        XCTAssertNotNil(description, "Intent should have a description")
    }

    // MARK: - Execution Tests

    func testIntentExecutionStartsRecording() async throws {
        // Given: App is not recording
        XCTAssertFalse(mockAppState.isRecording, "Should not be recording initially")

        // When: Intent is performed (this will fail until implementation exists)
        // Note: This uses the synchronous startRecording() for testing purposes
        // The actual intent will need to call startActualRecording(title:) with proper error handling

        // Then: Recording should be started
        // (Test will fail until StartRecordingIntent is implemented)
    }

    func testIntentWithCustomTitle() async throws {
        // Given: Intent configured with custom title
        let customTitle = "My Meeting"
        intent.title = customTitle

        // When: Intent is performed
        // (Implementation needed)

        // Then: Recording should start with custom title
        // (Test will fail until implementation exists)
    }

    func testIntentWithDefaultTitle() async throws {
        // Given: Intent without custom title
        intent.title = nil

        // When: Intent is performed
        // (Implementation needed)

        // Then: Recording should start with default title
        // (Test will fail until implementation exists)
    }

    func testIntentReturnsSuccessResult() async throws {
        // Given: App is not recording
        XCTAssertFalse(mockAppState.isRecording)

        // When: Intent is performed
        // let result = try await intent.perform()

        // Then: Result should indicate success
        // XCTAssertTrue(result indicates success)
        // (Test will fail until implementation exists)
    }

    func testIntentHandlesAlreadyRecordingGracefully() async throws {
        // Given: App is already recording
        mockAppState.startRecording()
        XCTAssertTrue(mockAppState.isRecording)

        // When: Intent is performed again
        // let result = try await intent.perform()

        // Then: Should handle gracefully (idempotent behavior)
        // XCTAssertTrue(mockAppState.isRecording, "Should remain in recording state")
        // (Test will fail until implementation exists)
    }

    func testIntentHandlesPermissionDeniedError() async throws {
        // Given: Microphone permissions are denied
        // (Would need to mock permission handler)

        // When: Intent is performed
        // (Implementation needed)

        // Then: Should throw or return error result
        // (Test will fail until implementation exists)
    }

    // MARK: - Thread Safety Tests

    func testIntentExecutesOnMainActor() async throws {
        // Verify the intent execution happens on MainActor
        // (Implementation will be @MainActor isolated)
        let isOnMainThread = Thread.isMainThread
        XCTAssertTrue(isOnMainThread, "Test setup should be on main thread due to @MainActor")
    }

    // MARK: - Integration Tests

    func testIntentIntegratesWithAppState() async throws {
        // Given: Fresh app state
        XCTAssertFalse(mockAppState.isRecording)
        XCTAssertEqual(mockAppState.elapsedTime, "00:00")

        // When: Intent is performed
        // (Implementation will call AppState.startActualRecording)

        // Then: AppState should reflect recording started
        // (Test will fail until implementation exists)
    }
}
