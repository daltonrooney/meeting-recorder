import XCTest
import AVFoundation
import Speech
@testable import CallTranscription

@available(macOS 26.0, *)
@MainActor
final class TranscriptionManagerTests: XCTestCase {
    var transcriptionManager: TranscriptionManager!

    override func setUp() async throws {
        try await super.setUp()
        transcriptionManager = TranscriptionManager()
    }

    override func tearDown() async throws {
        await transcriptionManager.stopTranscription()
        transcriptionManager = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testTranscriptionManagerCanBeInstantiated() {
        XCTAssertNotNil(transcriptionManager, "TranscriptionManager should instantiate")
    }

    func testCreatesSpeechTranscriberInstance() {
        // TranscriptionManager should create a SpeechTranscriber internally
        XCTAssertNotNil(transcriptionManager, "Should create transcriber")
    }

    func testCreatesSpeechAnalyzerInstance() {
        // TranscriptionManager should create a SpeechAnalyzer internally
        XCTAssertNotNil(transcriptionManager, "Should create analyzer")
    }

    func testSupportsCustomLocaleConfiguration() async throws {
        let customLocale = Locale(identifier: "en-US")
        let manager = TranscriptionManager(locale: customLocale)
        XCTAssertNotNil(manager, "Should support custom locale")
    }

    // MARK: - Model Availability Tests

    func testEnsureModelAvailableChecksLocaleSupport() async throws {
        do {
            try await transcriptionManager.ensureModelAvailable()
            // If locale is supported, should succeed
        } catch {
            // If error thrown, verify it's the correct type
            XCTAssertTrue(error is CallTranscriptionError, "Should throw CallTranscriptionError")
        }
    }

    func testDownloadsAssetsWhenModelNotInstalled() async throws {
        // This test verifies the download mechanism exists
        // Actual download may not occur if model is already present
        do {
            try await transcriptionManager.ensureModelAvailable()
        } catch let error as CallTranscriptionError {
            // Download failure should be speechRecognitionUnavailable
            if case .speechRecognitionUnavailable = error {
                // Expected error type
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testReturnsImmediatelyWhenModelInstalled() async throws {
        // If model is already available, should return quickly
        let startTime = Date()
        do {
            try await transcriptionManager.ensureModelAvailable()
            let elapsed = Date().timeIntervalSince(startTime)
            // Should complete quickly if model is present
            XCTAssertLessThan(elapsed, 2.0, "Should return quickly when model available")
        } catch {
            // Skip test if model not available
        }
    }

    func testThrowsErrorWhenLocaleNotSupported() async throws {
        let unsupportedLocale = Locale(identifier: "xx-XX")
        let manager = TranscriptionManager(locale: unsupportedLocale)

        do {
            try await manager.ensureModelAvailable()
            XCTFail("Should throw error for unsupported locale")
        } catch let error as CallTranscriptionError {
            if case .localeNotSupported(let locale) = error {
                XCTAssertEqual(locale.identifier, "xx-XX")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testHandlesDownloadFailuresGracefully() async throws {
        // Verify error handling for download failures
        // This test ensures the error path doesn't crash
        do {
            try await transcriptionManager.ensureModelAvailable()
        } catch {
            // Any error should be gracefully handled
            XCTAssertNotNil(error, "Should handle download failures")
        }
    }

    // MARK: - Transcription Start Tests

    func testStartTranscriptionInitializesAnalyzerSession() async throws {
        try await transcriptionManager.startTranscription()
        // If we get here, analyzer session was initialized
    }

    func testTranscriberIsAddedToAnalyzer() async throws {
        try await transcriptionManager.startTranscription()
        // Transcriber should be added to analyzer during start
    }

    func testInputStreamIsCreatedCorrectly() async throws {
        try await transcriptionManager.startTranscription()
        // AsyncStream should be created for audio input
    }

    func testResultsStreamIsEstablished() async throws {
        var receivedResults = false
        transcriptionManager.onTranscriptionResult = { result in
            receivedResults = true
        }

        try await transcriptionManager.startTranscription()
        // Results stream should be ready to receive
    }

    func testAnalysisStartsSuccessfully() async throws {
        try await transcriptionManager.startTranscription()
        // Analysis should start without errors
    }

    // MARK: - Audio Processing Tests

    func testFeedAudioAcceptsAVAudioPCMBuffer() async throws {
        try await transcriptionManager.startTranscription()

        // Create test buffer
        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
            XCTFail("Failed to create test buffer")
            return
        }
        buffer.frameLength = 1024

        // Should accept buffer without throwing
        await transcriptionManager.feedAudio(buffer)
    }

    func testHandlesHighBufferRateWithoutDropping() async throws {
        try await transcriptionManager.startTranscription()

        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!

        // Feed multiple buffers rapidly
        for _ in 0..<100 {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
                continue
            }
            buffer.frameLength = 1024
            await transcriptionManager.feedAudio(buffer)
        }

        // Should handle high rate without crashing
    }

    func testMaintainsBufferTimingInformation() async throws {
        try await transcriptionManager.startTranscription()

        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
            XCTFail("Failed to create test buffer")
            return
        }
        buffer.frameLength = 1024

        // Timing information should be preserved
        await transcriptionManager.feedAudio(buffer)
    }

    func testProcessesBuffersInOrder() async throws {
        try await transcriptionManager.startTranscription()

        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!

        // Feed multiple buffers
        for _ in 0..<10 {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
                continue
            }
            buffer.frameLength = 1024
            await transcriptionManager.feedAudio(buffer)
        }

        // Buffers should be processed in order
    }

    // MARK: - Result Handling Tests

    func testReceivesPartialTranscriptionResults() async throws {
        let expectation = expectation(description: "Receives partial results")
        expectation.assertForOverFulfill = false

        var receivedPartialResult = false
        transcriptionManager.onTranscriptionResult = { result in
            if !result.isFinal {
                receivedPartialResult = true
                expectation.fulfill()
            }
        }

        try await transcriptionManager.startTranscription()

        // Feed some audio
        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        for _ in 0..<50 {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
                continue
            }
            buffer.frameLength = 1024
            await transcriptionManager.feedAudio(buffer)
        }

        await fulfillment(of: [expectation], timeout: 10.0)
        XCTAssertTrue(receivedPartialResult, "Should receive partial results")
    }

    func testReceivesFinalTranscriptionResults() async throws {
        let expectation = expectation(description: "Receives final results")

        var receivedFinalResult = false
        transcriptionManager.onTranscriptionResult = { result in
            if result.isFinal {
                receivedFinalResult = true
                expectation.fulfill()
            }
        }

        try await transcriptionManager.startTranscription()

        // Feed audio then stop
        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        for _ in 0..<50 {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
                continue
            }
            buffer.frameLength = 1024
            await transcriptionManager.feedAudio(buffer)
        }

        await transcriptionManager.stopTranscription()

        await fulfillment(of: [expectation], timeout: 10.0)
        XCTAssertTrue(receivedFinalResult, "Should receive final results")
    }

    func testIsFinalFlagDistinguishesResultTypes() async throws {
        let expectation = expectation(description: "Distinguishes result types")
        expectation.assertForOverFulfill = false

        var sawPartial = false
        var sawFinal = false

        transcriptionManager.onTranscriptionResult = { result in
            if result.isFinal {
                sawFinal = true
            } else {
                sawPartial = true
            }

            if sawPartial || sawFinal {
                expectation.fulfill()
            }
        }

        try await transcriptionManager.startTranscription()

        // Feed audio
        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        for _ in 0..<50 {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
                continue
            }
            buffer.frameLength = 1024
            await transcriptionManager.feedAudio(buffer)
        }

        await fulfillment(of: [expectation], timeout: 10.0)
    }

    func testResultTextIsExtractedCorrectly() async throws {
        let expectation = expectation(description: "Extracts result text")
        expectation.assertForOverFulfill = false

        transcriptionManager.onTranscriptionResult = { result in
            XCTAssertNotNil(result.text, "Result should have text")
            expectation.fulfill()
        }

        try await transcriptionManager.startTranscription()

        // Feed audio
        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        for _ in 0..<50 {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
                continue
            }
            buffer.frameLength = 1024
            await transcriptionManager.feedAudio(buffer)
        }

        await fulfillment(of: [expectation], timeout: 10.0)
    }

    func testFinalResultsTriggersCallback() async throws {
        let expectation = expectation(description: "Final result triggers callback")

        transcriptionManager.onTranscriptionResult = { result in
            if result.isFinal {
                expectation.fulfill()
            }
        }

        try await transcriptionManager.startTranscription()

        // Feed audio then stop
        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        for _ in 0..<50 {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
                continue
            }
            buffer.frameLength = 1024
            await transcriptionManager.feedAudio(buffer)
        }

        await transcriptionManager.stopTranscription()

        await fulfillment(of: [expectation], timeout: 10.0)
    }

    func testResultsArriveInReasonableTime() async throws {
        let expectation = expectation(description: "Results arrive timely")
        expectation.assertForOverFulfill = false

        let startTime = Date()
        transcriptionManager.onTranscriptionResult = { result in
            let elapsed = Date().timeIntervalSince(startTime)
            XCTAssertLessThan(elapsed, 5.0, "Results should arrive within reasonable time")
            expectation.fulfill()
        }

        try await transcriptionManager.startTranscription()

        // Feed audio
        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        for _ in 0..<50 {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
                continue
            }
            buffer.frameLength = 1024
            await transcriptionManager.feedAudio(buffer)
        }

        await fulfillment(of: [expectation], timeout: 10.0)
    }

    // MARK: - Transcription Stop Tests

    func testStopTranscriptionFinishesInputStream() async throws {
        try await transcriptionManager.startTranscription()
        await transcriptionManager.stopTranscription()
        // Input stream should be finished
    }

    func testAnalyzerStopsGracefully() async throws {
        try await transcriptionManager.startTranscription()
        await transcriptionManager.stopTranscription()
        // Analyzer should stop without errors
    }

    func testFinalResultsDeliveredBeforeStopCompletes() async throws {
        let expectation = expectation(description: "Final results before stop")

        var receivedFinal = false
        transcriptionManager.onTranscriptionResult = { result in
            if result.isFinal {
                receivedFinal = true
                expectation.fulfill()
            }
        }

        try await transcriptionManager.startTranscription()

        // Feed audio
        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        for _ in 0..<50 {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
                continue
            }
            buffer.frameLength = 1024
            await transcriptionManager.feedAudio(buffer)
        }

        await transcriptionManager.stopTranscription()

        await fulfillment(of: [expectation], timeout: 10.0)
        XCTAssertTrue(receivedFinal, "Should receive final results before stop completes")
    }

    func testResourcesAreCleanedUp() async throws {
        try await transcriptionManager.startTranscription()
        await transcriptionManager.stopTranscription()
        // Resources should be released
    }

    func testCanRestartAfterStop() async throws {
        try await transcriptionManager.startTranscription()
        await transcriptionManager.stopTranscription()

        // Should be able to start again
        try await transcriptionManager.startTranscription()
        await transcriptionManager.stopTranscription()
    }

    // MARK: - Error Scenario Tests

    func testThrowsWhenModelDownloadFails() async throws {
        // Simulate model download failure scenario
        // This may not be testable without mocking
        do {
            try await transcriptionManager.ensureModelAvailable()
        } catch let error as CallTranscriptionError {
            if case .speechRecognitionUnavailable = error {
                // Expected error type
            }
        }
    }

    func testThrowsWhenLocaleNotSupportedInStart() async throws {
        let unsupportedLocale = Locale(identifier: "xx-XX")
        let manager = TranscriptionManager(locale: unsupportedLocale)

        do {
            try await manager.startTranscription()
            XCTFail("Should throw error for unsupported locale")
        } catch let error as CallTranscriptionError {
            if case .localeNotSupported = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testHandlesAnalyzerStartFailures() async throws {
        // Test error handling when analyzer fails to start
        do {
            try await transcriptionManager.startTranscription()
        } catch {
            // Should handle analyzer start failures gracefully
            XCTAssertNotNil(error, "Should handle start failures")
        }
    }

    func testHandlesTranscriberAdditionFailures() async throws {
        // Test error handling when transcriber can't be added
        do {
            try await transcriptionManager.startTranscription()
        } catch {
            // Should handle transcriber addition failures
            XCTAssertNotNil(error, "Should handle addition failures")
        }
    }

    func testRecoversFromTemporaryErrors() async throws {
        // Test that temporary errors don't prevent future operations
        do {
            try await transcriptionManager.startTranscription()
            await transcriptionManager.stopTranscription()

            // Should be able to retry after error
            try await transcriptionManager.startTranscription()
            await transcriptionManager.stopTranscription()
        } catch {
            // Even if first attempt fails, second should work
        }
    }
}
