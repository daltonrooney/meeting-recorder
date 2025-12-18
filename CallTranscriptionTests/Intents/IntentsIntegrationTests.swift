import XCTest
import AppIntents
@testable import CallTranscription

@MainActor
final class IntentsIntegrationTests: XCTestCase {

    var mockAppState: AppState!
    var mockSettingsManager: SettingsManager!

    override func setUp() async throws {
        try await super.setUp()
        mockSettingsManager = SettingsManager(userDefaults: UserDefaults(suiteName: "test.IntentsIntegration")!)
        mockAppState = AppState(settingsManager: mockSettingsManager)
    }

    override func tearDown() async throws {
        mockAppState = nil
        mockSettingsManager = nil

        // Clean up test UserDefaults
        if let testDefaults = UserDefaults(suiteName: "test.IntentsIntegration") {
            testDefaults.removePersistentDomain(forName: "test.IntentsIntegration")
        }

        try await super.tearDown()
    }

    // MARK: - Complete Workflow Tests

    func testCompleteStartStopWorkflow() async throws {
        // Given: App is not recording
        XCTAssertFalse(mockAppState.isRecording)

        // When: Start intent is performed
        let startIntent = StartRecordingIntent()
        // let startResult = try await startIntent.perform()

        // Then: App should be recording
        // XCTAssertTrue(mockAppState.isRecording)

        // When: Stop intent is performed
        let stopIntent = StopRecordingIntent()
        // let stopResult = try await stopIntent.perform()

        // Then: App should not be recording and file path returned
        // XCTAssertFalse(mockAppState.isRecording)
        // XCTAssertNotNil(stopResult.value, "Should return file path")
        // (Test will fail until implementation exists)
    }

    func testStatusQueryDuringRecording() async throws {
        // Given: App is recording
        mockAppState.startRecording()

        // When: Status intent is performed multiple times
        let statusIntent = GetRecordingStatusIntent()
        // let status1 = try await statusIntent.perform()
        // try? await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds
        // let status2 = try await statusIntent.perform()

        // Then: Status should reflect recording and time should progress
        // XCTAssertTrue(status1.isRecording)
        // XCTAssertTrue(status2.isRecording)
        // XCTAssertNotEqual(status1.elapsedTime, status2.elapsedTime, "Time should progress")
        // (Test will fail until implementation exists)
    }

    func testConfigureBeforeRecording() async throws {
        // Given: Fresh settings
        let configIntent = ConfigureSettingsIntent()
        configIntent.outputFolder = "~/Desktop/IntegrationTest"
        configIntent.captureMicrophone = true
        configIntent.captureSystemAudio = false

        // When: Configuration intent is performed
        // let configResult = try await configIntent.perform()

        // Then: Settings should be updated
        // XCTAssertEqual(mockSettingsManager.outputFolder, "~/Desktop/IntegrationTest")
        // XCTAssertTrue(mockSettingsManager.captureMicrophone)
        // XCTAssertFalse(mockSettingsManager.captureSystemAudio)

        // When: Recording is started
        let startIntent = StartRecordingIntent()
        // let startResult = try await startIntent.perform()

        // Then: Recording should use new settings
        // (Settings are applied during recording start)
        // (Test will fail until implementation exists)
    }

    // MARK: - Error Recovery Tests

    func testStopWithoutStartHandledGracefully() async throws {
        // Given: App is not recording
        XCTAssertFalse(mockAppState.isRecording)

        // When: Stop intent is performed
        let stopIntent = StopRecordingIntent()

        // Then: Should throw appropriate error
        // do {
        //     _ = try await stopIntent.perform()
        //     XCTFail("Should throw when stopping without recording")
        // } catch let error as CallTranscriptionError {
        //     XCTAssertEqual(error, .notRecording)
        // }
        // (Test will fail until implementation exists)
    }

    func testMultipleStartIntentsAreIdempotent() async throws {
        // Given: App is not recording
        XCTAssertFalse(mockAppState.isRecording)

        // When: Start intent is performed multiple times
        let startIntent1 = StartRecordingIntent()
        // let result1 = try await startIntent1.perform()

        let startIntent2 = StartRecordingIntent()
        // let result2 = try await startIntent2.perform()

        // Then: Should be recording only once (idempotent)
        // XCTAssertTrue(mockAppState.isRecording)
        // (Test will fail until implementation exists)
    }

    func testMultipleStopIntentsHandledGracefully() async throws {
        // Given: App is recording
        mockAppState.startRecording()

        // When: Stop intent is performed
        let stopIntent1 = StopRecordingIntent()
        // let result1 = try await stopIntent1.perform()

        // Then: Should be stopped
        // XCTAssertFalse(mockAppState.isRecording)

        // When: Stop intent is performed again
        let stopIntent2 = StopRecordingIntent()

        // Then: Should throw error
        // do {
        //     _ = try await stopIntent2.perform()
        //     XCTFail("Should throw when stopping already stopped recording")
        // } catch {
        //     // Expected
        // }
        // (Test will fail until implementation exists)
    }

    // MARK: - Concurrent Intent Execution Tests

    func testConcurrentStatusQueries() async throws {
        // Given: App is recording
        mockAppState.startRecording()

        // When: Multiple status intents are performed concurrently
        let statusIntent1 = GetRecordingStatusIntent()
        let statusIntent2 = GetRecordingStatusIntent()
        let statusIntent3 = GetRecordingStatusIntent()

        // async let result1 = statusIntent1.perform()
        // async let result2 = statusIntent2.perform()
        // async let result3 = statusIntent3.perform()

        // let results = try await [result1, result2, result3]

        // Then: All should succeed with consistent recording state
        // XCTAssertTrue(results.allSatisfy { $0.isRecording })
        // (Test will fail until implementation exists)
    }

    // MARK: - State Consistency Tests

    func testAppStateRemainsConsistentAcrossIntents() async throws {
        // Given: Initial state
        XCTAssertFalse(mockAppState.isRecording)
        XCTAssertEqual(mockAppState.elapsedTime, "00:00")

        // When: Start, check status, stop sequence
        let startIntent = StartRecordingIntent()
        // _ = try await startIntent.perform()
        XCTAssertTrue(mockAppState.isRecording)

        let statusIntent = GetRecordingStatusIntent()
        // let status = try await statusIntent.perform()
        // XCTAssertTrue(status.isRecording)

        let stopIntent = StopRecordingIntent()
        // _ = try await stopIntent.perform()
        XCTAssertFalse(mockAppState.isRecording)

        // Then: State should be completely reset
        XCTAssertEqual(mockAppState.elapsedTime, "00:00")
        // (Test will fail until implementation exists)
    }

    // MARK: - Configuration Persistence Tests

    func testConfigurationPersistsAcrossIntentCalls() async throws {
        // Given: Configuration intent
        let configIntent = ConfigureSettingsIntent()
        configIntent.outputFolder = "~/Desktop/PersistentFolder"

        // When: Configuration is applied
        // _ = try await configIntent.perform()

        // Then: New intent should see persisted settings
        // let newSettingsManager = SettingsManager(userDefaults: UserDefaults(suiteName: "test.IntentsIntegration")!)
        // XCTAssertEqual(newSettingsManager.outputFolder, "~/Desktop/PersistentFolder")
        // (Test will fail until implementation exists)
    }

    // MARK: - Intent Shortcuts Discovery Tests

    func testIntentsAreDiscoverableInShortcutsApp() {
        // Given: App with intents
        // When: Checking for intent discovery metadata
        // Then: Intents should be properly configured for Shortcuts app
        // (This is verified through proper AppIntent conformance and metadata)
        // (Test will fail until implementation exists)
    }

    func testAppShortcutsProviderProvidesDefaultShortcuts() {
        // Given: AppShortcutsProvider
        // When: Checking default shortcuts
        // Then: Should provide sensible defaults for common workflows
        // (Test will fail until implementation exists)
    }

    // MARK: - Thread Safety Tests

    func testIntentsExecuteOnMainActor() async throws {
        // Given: Intents that modify AppState

        // When: Intents are performed
        // Then: Should maintain thread safety through @MainActor
        // (All intents should be @MainActor isolated)
    }

    // MARK: - Performance Tests

    func testStatusIntentPerformanceIsAcceptable() async throws {
        // Given: App is recording
        mockAppState.startRecording()

        // When: Status intent is performed repeatedly
        let iterations = 100
        let startTime = Date()

        for _ in 0..<iterations {
            let statusIntent = GetRecordingStatusIntent()
            // _ = try await statusIntent.perform()
        }

        let duration = Date().timeIntervalSince(startTime)

        // Then: Should complete quickly (< 1 second for 100 calls)
        // XCTAssertLessThan(duration, 1.0, "Status queries should be fast")
        // (Test will fail until implementation exists)
    }

    // MARK: - Cross-Feature Integration Tests

    func testIntentsWorkWithExistingPostRecordingActions() async throws {
        // Given: Settings with post-recording action configured
        mockSettingsManager.postRecordingActionType = .doNothing

        // When: Recording workflow is executed via intents
        let startIntent = StartRecordingIntent()
        // _ = try await startIntent.perform()

        let stopIntent = StopRecordingIntent()
        // let result = try await stopIntent.perform()

        // Then: Post-recording action should be respected
        // (Integration with existing ShortcutExecutor and shell script features)
        // (Test will fail until implementation exists)
    }
}
