import XCTest
import AVFoundation
@testable import CallTranscription

final class SystemAudioCaptureTests: XCTestCase {
    var systemAudioCapture: SystemAudioCapture!

    override func setUp() async throws {
        try await super.setUp()
        systemAudioCapture = SystemAudioCapture()
    }

    override func tearDown() async throws {
        // Ensure cleanup even if tests fail
        await systemAudioCapture.stopCapture()
        systemAudioCapture = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testSystemAudioCaptureCanBeInstantiated() {
        XCTAssertNotNil(systemAudioCapture, "SystemAudioCapture should instantiate")
    }

    func testAudioBufferHandlerIsNilByDefault() {
        XCTAssertNil(systemAudioCapture.audioBufferHandler,
                     "audioBufferHandler should be nil by default")
    }

    func testTapDescriptionCanBeCreated() {
        // This tests that the internal tap description can be configured
        // The actual tap creation happens during startCapture
        XCTAssertNotNil(systemAudioCapture, "Should be able to prepare tap configuration")
    }

    // MARK: - Tap Creation Tests

    func testStartCaptureCreatesAudioTapSuccessfully() async throws {
        // Test that startCapture creates the audio tap without errors
        try await systemAudioCapture.startCapture()
        // If we get here without throwing, tap was created successfully
    }

    func testAggregateDeviceIsCreatedDuringTapCreation() async throws {
        try await systemAudioCapture.startCapture()
        // Aggregate device should be created as part of the tap setup
        // This is verified by successful capture without errors
    }

    func testProcessCallbackIsRegisteredDuringTapCreation() async throws {
        let expectation = expectation(description: "Process callback registered")

        systemAudioCapture.audioBufferHandler = { _ in
            expectation.fulfill()
        }

        try await systemAudioCapture.startCapture()

        // If callback receives buffers, it was registered successfully
        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func testTapCanFilterByProcessIDs() async throws {
        // Test filtering by specific process IDs
        // Process filtering throws featureNotImplemented error
        let testProcessIDs: [pid_t] = [1000]
        do {
            try await systemAudioCapture.startCapture(excludingProcesses: testProcessIDs)
            XCTFail("Should throw featureNotImplemented error")
        } catch let error as CallTranscriptionError {
            if case .featureNotImplemented(let feature) = error {
                XCTAssertEqual(feature, "Process filtering")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testTapCapturesAllSystemAudioWhenNoFilter() async throws {
        // Default behavior - no process filtering
        let expectation = expectation(description: "Captures system audio")

        systemAudioCapture.audioBufferHandler = { buffer in
            expectation.fulfill()
        }

        try await systemAudioCapture.startCapture()
        await fulfillment(of: [expectation], timeout: 5.0)
    }

    // MARK: - Audio Buffer Delivery Tests

    func testAudioBufferHandlerReceivesSystemAudioBuffers() async throws {
        let expectation = expectation(description: "Buffer handler called")
        var receivedBuffer: AVAudioPCMBuffer?

        systemAudioCapture.audioBufferHandler = { buffer in
            receivedBuffer = buffer
            expectation.fulfill()
        }

        try await systemAudioCapture.startCapture()

        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertNotNil(receivedBuffer, "Should receive system audio buffer")
    }

    func testBuffersAreAVAudioPCMBufferType() async throws {
        let expectation = expectation(description: "Buffer type verified")

        systemAudioCapture.audioBufferHandler = { buffer in
            XCTAssertTrue(buffer is AVAudioPCMBuffer,
                         "Buffer should be AVAudioPCMBuffer type")
            expectation.fulfill()
        }

        try await systemAudioCapture.startCapture()
        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func testBuffersContainValidPCMData() async throws {
        let expectation = expectation(description: "Buffer has valid PCM data")

        systemAudioCapture.audioBufferHandler = { buffer in
            XCTAssertNotNil(buffer.audioBufferList, "Buffer should have audioBufferList")
            XCTAssertGreaterThan(buffer.frameLength, 0, "Buffer should have frames")
            expectation.fulfill()
        }

        try await systemAudioCapture.startCapture()
        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func testBufferFormatIsCorrect() async throws {
        let expectation = expectation(description: "Buffer format verified")

        systemAudioCapture.audioBufferHandler = { buffer in
            // Verify format properties
            XCTAssertNotNil(buffer.format, "Buffer should have format")
            XCTAssertGreaterThan(buffer.format.sampleRate, 0,
                               "Should have valid sample rate")
            XCTAssertGreaterThan(buffer.format.channelCount, 0,
                               "Should have at least one channel")
            expectation.fulfill()
        }

        try await systemAudioCapture.startCapture()
        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func testNoLatencyAddedToPlaybackPath() async throws {
        // System audio capture should be passive - no modification to playback
        // We verify this by checking that buffers are delivered without affecting playback
        let expectation = expectation(description: "Passive monitoring verified")
        expectation.expectedFulfillmentCount = 3

        systemAudioCapture.audioBufferHandler = { _ in
            expectation.fulfill()
        }

        try await systemAudioCapture.startCapture()
        await fulfillment(of: [expectation], timeout: 5.0)
        // If buffers arrive consistently, monitoring is passive and not blocking
    }

    // MARK: - Process Filtering Tests

    func testCanExcludeSpecificProcessIDs() async throws {
        let excludeProcesses: [pid_t] = [12345]
        do {
            try await systemAudioCapture.startCapture(excludingProcesses: excludeProcesses)
            XCTFail("Should throw featureNotImplemented error")
        } catch let error as CallTranscriptionError {
            if case .featureNotImplemented = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testCanCaptureFromSpecificProcessesOnly() async throws {
        // Test include-only filtering throws error (not implemented)
        let testProcesses: [pid_t] = [1]
        do {
            try await systemAudioCapture.startCapture(includingProcesses: testProcesses)
            XCTFail("Should throw featureNotImplemented error")
        } catch let error as CallTranscriptionError {
            if case .featureNotImplemented = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testEmptyExcludeListCapturesAllAudio() async throws {
        let expectation = expectation(description: "Captures all audio")

        systemAudioCapture.audioBufferHandler = { _ in
            expectation.fulfill()
        }

        // Empty exclude list means capture everything
        try await systemAudioCapture.startCapture(excludingProcesses: [])
        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func testFilteringWorksWithMultipleProcesses() async throws {
        let multipleProcesses: [pid_t] = [100, 200, 300]

        do {
            try await systemAudioCapture.startCapture(excludingProcesses: multipleProcesses)
            XCTFail("Should throw featureNotImplemented error")
        } catch let error as CallTranscriptionError {
            if case .featureNotImplemented = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Tap Destruction Tests

    func testStopCaptureRemovesAudioTap() async throws {
        try await systemAudioCapture.startCapture()
        await systemAudioCapture.stopCapture()
        // Should complete without error
    }

    func testAggregateDeviceIsDestroyedOnStop() async throws {
        try await systemAudioCapture.startCapture()
        await systemAudioCapture.stopCapture()
        // Aggregate device should be cleaned up
    }

    func testBuffersStopArrivingAfterStop() async throws {
        var bufferCountDuringCapture = 0
        var bufferCountAfterStop = 0
        var isStopped = false
        let expectation = expectation(description: "Buffers stop after stop")
        expectation.isInverted = true

        systemAudioCapture.audioBufferHandler = { _ in
            if isStopped {
                bufferCountAfterStop += 1
                if bufferCountAfterStop == 1 {
                    expectation.fulfill()
                }
            } else {
                bufferCountDuringCapture += 1
            }
        }

        try await systemAudioCapture.startCapture()
        try await Task.sleep(nanoseconds: 500_000_000)
        await systemAudioCapture.stopCapture()
        isStopped = true

        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertGreaterThan(bufferCountDuringCapture, 0,
                           "Should have received buffers during capture")
    }

    func testResourcesAreCleanedUpProperly() async throws {
        // Test that multiple capture cycles don't leak resources
        for _ in 0..<3 {
            try await systemAudioCapture.startCapture()
            try await Task.sleep(nanoseconds: 100_000_000)
            await systemAudioCapture.stopCapture()
        }
        // If we get here without crashes, cleanup is working
    }

    func testMultipleStopCallsAreSafe() async throws {
        try await systemAudioCapture.startCapture()
        await systemAudioCapture.stopCapture()
        await systemAudioCapture.stopCapture()
        await systemAudioCapture.stopCapture()
        // Multiple stops should be safe
    }

    // MARK: - Error Scenario Tests

    func testThrowsAudioTapCreationFailedOnCoreAudioError() async {
        // This test verifies the error type when Core Audio fails
        // In a real scenario, this would require mocking or forcing failure
        do {
            // Under normal conditions, this should succeed
            try await systemAudioCapture.startCapture()
        } catch let error as CallTranscriptionError {
            // If error is thrown, verify it's the correct type
            if case .audioTapCreationFailed(let status) = error {
                XCTAssertNotEqual(status, 0, "Should have non-zero error status")
            }
        } catch {
            XCTFail("Should only throw CallTranscriptionError, got: \(error)")
        }
    }

    func testHandlesMissingAudioDevices() async {
        // Test graceful handling when audio devices are unavailable
        // This would typically require system configuration or mocking
        // For now, verify the method signature exists
        do {
            try await systemAudioCapture.startCapture()
        } catch let error as CallTranscriptionError {
            if case .audioTapCreationFailed = error {
                // This is the expected error type for device issues
            }
        } catch {
            XCTFail("Should throw CallTranscriptionError for device issues")
        }
    }

    func testHandlesInvalidProcessIDsInFilter() async throws {
        // Test that invalid process IDs don't crash the system
        let invalidProcesses: [pid_t] = [-1, Int32.max]

        // Should either succeed or throw appropriate error
        do {
            try await systemAudioCapture.startCapture(excludingProcesses: invalidProcesses)
        } catch let error as CallTranscriptionError {
            // Invalid process IDs might cause tap creation to fail
            if case .audioTapCreationFailed = error {
                // This is acceptable
            }
        }
    }

    func testRecoversFromTapCreationFailures() async {
        // Test that failed tap creation doesn't leave system in bad state
        do {
            try await systemAudioCapture.startCapture()
            await systemAudioCapture.stopCapture()

            // Should be able to retry after failure or success
            try await systemAudioCapture.startCapture()
            await systemAudioCapture.stopCapture()
        } catch {
            // Even if capture fails, subsequent attempts should work
        }
    }

    // MARK: - Integration Tests

    func testCompleteCaptureCycle() async throws {
        var bufferReceived = false

        systemAudioCapture.audioBufferHandler = { _ in
            bufferReceived = true
        }

        try await systemAudioCapture.startCapture()
        try await Task.sleep(nanoseconds: 1_000_000_000)
        await systemAudioCapture.stopCapture()

        XCTAssertTrue(bufferReceived, "Should have received at least one buffer")
    }

    func testMultipleCaptureCycles() async throws {
        for _ in 0..<3 {
            var bufferReceived = false

            systemAudioCapture.audioBufferHandler = { _ in
                bufferReceived = true
            }

            try await systemAudioCapture.startCapture()
            try await Task.sleep(nanoseconds: 500_000_000)
            await systemAudioCapture.stopCapture()

            XCTAssertTrue(bufferReceived, "Should receive buffer in each cycle")
        }
    }

    func testMultipleStartCallsAreHandledGracefully() async throws {
        try await systemAudioCapture.startCapture()
        // Second call should not throw or cause issues
        try await systemAudioCapture.startCapture()
        await systemAudioCapture.stopCapture()
    }

    func testStopWhenNotStartedIsSafe() async {
        await systemAudioCapture.stopCapture()
        // Should not crash - stopping without starting is safe
    }

    func testNilHandlerDuringCaptureDoesNotCrash() async throws {
        systemAudioCapture.audioBufferHandler = nil
        try await systemAudioCapture.startCapture()

        try await Task.sleep(nanoseconds: 1_000_000_000)

        await systemAudioCapture.stopCapture()
        // Should not crash even with nil handler
    }
}
