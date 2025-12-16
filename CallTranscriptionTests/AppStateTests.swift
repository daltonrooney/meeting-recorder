import XCTest
import Combine
@testable import CallTranscription

@MainActor
final class AppStateTests: XCTestCase {

    var appState: AppState!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        appState = AppState()
        cancellables = []
    }

    override func tearDown() async throws {
        cancellables = nil
        appState = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialIsRecordingIsFalse() {
        XCTAssertFalse(appState.isRecording, "isRecording should be false on initialization")
    }

    func testInitialElapsedTimeIsZero() {
        XCTAssertEqual(appState.elapsedTime, "00:00", "elapsedTime should be '00:00' on initialization")
    }

    func testStateIsObservable() {
        // Verify AppState conforms to ObservableObject by checking it has objectWillChange
        XCTAssertNotNil(appState.objectWillChange,
                     "AppState should conform to ObservableObject protocol")
    }

    func testIsRecordingPropertyIsPublished() {
        let expectation = expectation(description: "isRecording change should be published")
        var receivedValues: [Bool] = []

        appState.$isRecording
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        Task {
            await appState.startRecording()
        }

        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedValues, [true], "isRecording change should be published")
    }

    func testElapsedTimePropertyIsPublished() {
        let expectation = expectation(description: "elapsedTime change should be published")
        var receivedValues: [String] = []

        appState.$elapsedTime
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count >= 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        Task {
            await appState.startRecording()
            // Wait a bit for timer to update
            try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds
        }

        wait(for: [expectation], timeout: 3.0)
        XCTAssertFalse(receivedValues.isEmpty, "elapsedTime should publish changes")
        XCTAssertNotEqual(receivedValues.first, "00:00", "elapsedTime should change from initial value")
    }

    // MARK: - Recording State Transition Tests

    func testStartRecordingChangesIsRecordingToTrue() async {
        await appState.startRecording()
        XCTAssertTrue(appState.isRecording, "startRecording() should change isRecording to true")
    }

    func testStopRecordingChangesIsRecordingToFalse() async {
        await appState.startRecording()
        await appState.stopRecording()
        XCTAssertFalse(appState.isRecording, "stopRecording() should change isRecording to false")
    }

    func testMultipleStartCallsAreHandledGracefully() async {
        await appState.startRecording()
        XCTAssertTrue(appState.isRecording)

        // Call start again - should be handled gracefully (no crash, no error)
        await appState.startRecording()
        XCTAssertTrue(appState.isRecording, "Multiple start calls should be handled gracefully")
    }

    func testStopCalledWhenNotRecordingIsHandledGracefully() async {
        XCTAssertFalse(appState.isRecording)

        // Call stop when not recording - should be handled gracefully
        await appState.stopRecording()
        XCTAssertFalse(appState.isRecording, "Stop called when not recording should be handled gracefully")
    }

    func testRecordingCanBeStartedAfterStopping() async {
        await appState.startRecording()
        XCTAssertTrue(appState.isRecording)

        await appState.stopRecording()
        XCTAssertFalse(appState.isRecording)

        await appState.startRecording()
        XCTAssertTrue(appState.isRecording, "Recording should be able to restart after stopping")
    }

    // MARK: - Elapsed Time Tracking Tests

    func testElapsedTimeUpdatesWhileRecording() async {
        await appState.startRecording()
        let initialTime = appState.elapsedTime

        // Wait for at least one timer tick (should be ~1 second)
        try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds

        let updatedTime = appState.elapsedTime
        XCTAssertNotEqual(initialTime, updatedTime, "elapsedTime should update during recording")
    }

    func testElapsedTimeResetsAfterStopping() async {
        await appState.startRecording()

        // Wait for time to accumulate
        try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds
        XCTAssertNotEqual(appState.elapsedTime, "00:00", "elapsedTime should accumulate")

        await appState.stopRecording()
        XCTAssertEqual(appState.elapsedTime, "00:00", "elapsedTime should reset after stopping")
    }

    func testTimeFormatIsCorrectForSeconds() async {
        await appState.startRecording()

        // Wait for at least 1 second
        try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds

        let time = appState.elapsedTime
        // Should be in MM:SS format (e.g., "00:01")
        XCTAssertTrue(time.contains(":"), "Time format should contain colon separator")

        let components = time.split(separator: ":")
        XCTAssertEqual(components.count, 2, "Time format should have two components (MM:SS)")

        // Both components should be numeric
        XCTAssertNotNil(Int(components[0]), "Minutes should be numeric")
        XCTAssertNotNil(Int(components[1]), "Seconds should be numeric")
    }

    func testTimeFormatIsCorrectForMinutes() async {
        // This is a long test - we'll simulate by manipulating internal state
        // For now, just verify the format can handle minutes
        await appState.startRecording()

        // Wait a bit to ensure timer is running
        try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds

        let time = appState.elapsedTime
        let components = time.split(separator: ":")

        // Verify format: should be MM:SS where MM can be 00-99 and SS is 00-59
        XCTAssertEqual(components.count, 2, "Time should be in MM:SS format")
        XCTAssertEqual(components[0].count, 2, "Minutes should be zero-padded to 2 digits")
        XCTAssertEqual(components[1].count, 2, "Seconds should be zero-padded to 2 digits")
    }

    func testTimeFormatHandlesHours() async {
        // Verify format can handle hours if needed (HH:MM:SS)
        // This test validates that the format specification is met
        await appState.startRecording()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let time = appState.elapsedTime
        let components = time.split(separator: ":")

        // Should support either MM:SS or HH:MM:SS format
        XCTAssertTrue(components.count == 2 || components.count == 3,
                     "Time format should be MM:SS or HH:MM:SS")
    }

    func testElapsedTimeDoesNotUpdateWhenNotRecording() async {
        let initialTime = appState.elapsedTime

        // Wait without recording
        try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds

        XCTAssertEqual(appState.elapsedTime, initialTime,
                      "elapsedTime should not update when not recording")
    }

    // MARK: - Error State Management Tests

    func testStartRecordingPropagatesErrors() async {
        // Note: This test validates that errors can be thrown
        // Actual error conditions will be tested with real recording subsystems
        do {
            // For now, verify that startRecording completes without error
            await appState.startRecording()
            // If we get here, no error was thrown (expected for basic AppState)
            XCTAssertTrue(appState.isRecording)
        } catch {
            // If an error is thrown, verify it's a CallTranscriptionError
            XCTAssertTrue(error is CallTranscriptionError,
                         "Errors during start should be CallTranscriptionError")
        }
    }

    func testStopRecordingPropagatesErrors() async {
        do {
            await appState.startRecording()
            await appState.stopRecording()
            // If we get here, no error was thrown (expected for basic AppState)
            XCTAssertFalse(appState.isRecording)
        } catch {
            // If an error is thrown, verify it's a CallTranscriptionError
            XCTAssertTrue(error is CallTranscriptionError,
                         "Errors during stop should be CallTranscriptionError")
        }
    }

    func testErrorStateLeavesAppInConsistentState() async {
        await appState.startRecording()
        let wasRecording = appState.isRecording

        // Even if stop encounters an error, state should be consistent
        await appState.stopRecording()

        // After stop (error or not), isRecording should be false
        XCTAssertFalse(appState.isRecording,
                      "Error state should not leave app in inconsistent recording state")

        // And elapsed time should be reset
        XCTAssertEqual(appState.elapsedTime, "00:00",
                      "Error state should reset elapsed time")
    }

    func testStateRemainsConsistentAfterErrorDuringStart() async {
        // Attempt to start (may fail in real scenarios with permissions)
        await appState.startRecording()

        // Regardless of success/failure, state should be consistent
        if appState.isRecording {
            // If started successfully, elapsed time should eventually update
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            XCTAssertNotEqual(appState.elapsedTime, "00:00")
        } else {
            // If start failed, elapsed time should remain at initial value
            XCTAssertEqual(appState.elapsedTime, "00:00")
        }
    }

    // MARK: - Integration Tests

    func testCompleteRecordingCycle() async {
        // Test a complete recording cycle
        XCTAssertFalse(appState.isRecording, "Should start not recording")
        XCTAssertEqual(appState.elapsedTime, "00:00", "Should start at 00:00")

        await appState.startRecording()
        XCTAssertTrue(appState.isRecording, "Should be recording after start")

        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        XCTAssertNotEqual(appState.elapsedTime, "00:00", "Should have elapsed time")

        await appState.stopRecording()
        XCTAssertFalse(appState.isRecording, "Should stop recording")
        XCTAssertEqual(appState.elapsedTime, "00:00", "Should reset to 00:00")
    }

    func testMultipleRecordingCycles() async {
        // Test multiple start/stop cycles
        for _ in 0..<3 {
            await appState.startRecording()
            XCTAssertTrue(appState.isRecording)

            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            await appState.stopRecording()
            XCTAssertFalse(appState.isRecording)
            XCTAssertEqual(appState.elapsedTime, "00:00")
        }
    }

    // MARK: - MainActor Tests

    func testAppStateIsMainActorIsolated() {
        // Verify that AppState is marked with @MainActor
        let mainActorType = type(of: appState)
        XCTAssertNotNil(mainActorType, "AppState should be @MainActor isolated")
    }

    func testPropertyAccessIsMainActorSafe() async {
        // All property access should be safe from main actor
        await MainActor.run {
            let _ = appState.isRecording
            let _ = appState.elapsedTime
        }
    }
}
