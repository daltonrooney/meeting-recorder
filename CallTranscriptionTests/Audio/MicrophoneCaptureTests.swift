import XCTest
import AVFoundation
@testable import CallTranscription

final class MicrophoneCaptureTests: XCTestCase {
    var microphoneCapture: MicrophoneCapture!

    override func setUp() async throws {
        try await super.setUp()
        microphoneCapture = MicrophoneCapture()
    }

    override func tearDown() async throws {
        // Ensure cleanup even if tests fail
        await microphoneCapture.stopCapture()
        microphoneCapture = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testMicrophoneCaptureCanBeInstantiated() {
        XCTAssertNotNil(microphoneCapture, "MicrophoneCapture should instantiate")
    }

    func testAudioBufferHandlerIsNilByDefault() {
        XCTAssertNil(microphoneCapture.audioBufferHandler,
                     "audioBufferHandler should be nil by default")
    }

    // MARK: - Capture Start Tests

    func testStartCaptureSucceedsWithPermission() async throws {
        // Test that startCapture doesn't throw when permission is available
        // Note: This test requires microphone permission to be granted
        try await microphoneCapture.startCapture()
        // If we get here without throwing, success
    }

    func testMultipleStartCallsAreHandledGracefully() async throws {
        try await microphoneCapture.startCapture()
        // Second call should not throw or cause issues
        try await microphoneCapture.startCapture()
        // Should still be in valid state
    }

    // MARK: - Audio Buffer Delivery Tests

    func testAudioBufferHandlerReceivesBuffers() async throws {
        let expectation = expectation(description: "Buffer handler called")
        var receivedBuffer: AVAudioPCMBuffer?

        microphoneCapture.audioBufferHandler = { buffer in
            receivedBuffer = buffer
            expectation.fulfill()
        }

        try await microphoneCapture.startCapture()

        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertNotNil(receivedBuffer, "Should receive audio buffer")
    }

    func testBuffersAreAVAudioPCMBufferType() async throws {
        let expectation = expectation(description: "Buffer type verified")

        microphoneCapture.audioBufferHandler = { buffer in
            XCTAssertTrue(buffer is AVAudioPCMBuffer,
                         "Buffer should be AVAudioPCMBuffer type")
            expectation.fulfill()
        }

        try await microphoneCapture.startCapture()
        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func testBuffersContainValidAudioData() async throws {
        let expectation = expectation(description: "Buffer has valid data")

        microphoneCapture.audioBufferHandler = { buffer in
            XCTAssertNotNil(buffer.audioBufferList, "Buffer should have audioBufferList")
            XCTAssertGreaterThan(buffer.frameLength, 0, "Buffer should have frames")
            expectation.fulfill()
        }

        try await microphoneCapture.startCapture()
        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func testBuffersArriveAtExpectedRate() async throws {
        let expectation = expectation(description: "Multiple buffers received")
        expectation.expectedFulfillmentCount = 3

        microphoneCapture.audioBufferHandler = { _ in
            expectation.fulfill()
        }

        try await microphoneCapture.startCapture()
        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func testNilHandlerDuringCaptureDoesNotCrash() async throws {
        microphoneCapture.audioBufferHandler = nil
        try await microphoneCapture.startCapture()

        // Wait a bit to ensure buffers would be delivered
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Should not crash - if we get here, test passes
    }

    // MARK: - Capture Stop Tests

    func testStopCaptureCompletesSuccessfully() async throws {
        try await microphoneCapture.startCapture()
        await microphoneCapture.stopCapture()
        // Should complete without error
    }

    func testBuffersStopArrivingAfterStop() async throws {
        var bufferCountDuringCapture = 0
        var bufferCountAfterStop = 0
        var isStopped = false
        let expectation = expectation(description: "Buffers stop after stop")
        expectation.isInverted = true

        microphoneCapture.audioBufferHandler = { _ in
            if isStopped {
                bufferCountAfterStop += 1
                if bufferCountAfterStop == 1 {
                    // Only fulfill once if we receive buffers after stop
                    expectation.fulfill()
                }
            } else {
                bufferCountDuringCapture += 1
            }
        }

        try await microphoneCapture.startCapture()
        try await Task.sleep(nanoseconds: 500_000_000) // Let some buffers arrive
        await microphoneCapture.stopCapture()
        isStopped = true

        // After stop, no more buffers should arrive
        await fulfillment(of: [expectation], timeout: 2.0)

        // Verify we actually received buffers during capture
        XCTAssertGreaterThan(bufferCountDuringCapture, 0, "Should have received buffers during capture")
    }

    func testMultipleStopCallsAreSafe() async throws {
        try await microphoneCapture.startCapture()
        await microphoneCapture.stopCapture()
        await microphoneCapture.stopCapture()
        await microphoneCapture.stopCapture()
        // Should not crash - multiple stops are safe
    }

    func testStopWhenNotStartedIsSafe() async throws {
        await microphoneCapture.stopCapture()
        // Should not crash - stopping without starting is safe
    }

    // MARK: - Error Scenario Tests

    func testPermissionDeniedThrowsCorrectError() async {
        // Note: This test will pass if permission is granted
        // To properly test denied permission, would need to mock or manually deny
        // For now, we test that the error type is correct IF thrown
        do {
            try await microphoneCapture.startCapture()
            // If permission granted, this is fine
        } catch let error as CallTranscriptionError {
            // If error thrown, verify it's the correct type
            XCTAssertEqual(error, .microphonePermissionDenied,
                          "Should throw microphonePermissionDenied error")
        } catch {
            XCTFail("Should only throw CallTranscriptionError, got: \(error)")
        }
    }

    // MARK: - Integration Tests

    func testCompleteCaptureCycle() async throws {
        var bufferReceived = false

        microphoneCapture.audioBufferHandler = { _ in
            bufferReceived = true
        }

        try await microphoneCapture.startCapture()
        try await Task.sleep(nanoseconds: 1_000_000_000)
        await microphoneCapture.stopCapture()

        XCTAssertTrue(bufferReceived, "Should have received at least one buffer")
    }

    func testMultipleCaptureCycles() async throws {
        for _ in 0..<3 {
            var bufferReceived = false

            microphoneCapture.audioBufferHandler = { _ in
                bufferReceived = true
            }

            try await microphoneCapture.startCapture()
            try await Task.sleep(nanoseconds: 500_000_000)
            await microphoneCapture.stopCapture()

            XCTAssertTrue(bufferReceived, "Should receive buffer in each cycle")
        }
    }

    func testBufferFormatMatchesExpectations() async throws {
        let expectation = expectation(description: "Buffer format verified")

        microphoneCapture.audioBufferHandler = { buffer in
            // Verify format is reasonable for microphone input
            XCTAssertNotNil(buffer.format, "Buffer should have format")
            XCTAssertGreaterThan(buffer.format.sampleRate, 0, "Should have valid sample rate")
            XCTAssertGreaterThan(buffer.format.channelCount, 0, "Should have at least one channel")
            expectation.fulfill()
        }

        try await microphoneCapture.startCapture()
        await fulfillment(of: [expectation], timeout: 5.0)
    }
}
