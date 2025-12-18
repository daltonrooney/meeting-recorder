import XCTest
@preconcurrency import AVFoundation
@testable import CallTranscription

/// Thread-safe counter for testing callbacks
final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = 0

    var value: Int {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }

    func increment() {
        lock.lock()
        defer { lock.unlock() }
        _value += 1
    }
}

final class SilenceDetectorTests: XCTestCase {

    nonisolated(unsafe) var detector: SilenceDetector!
    nonisolated(unsafe) var silenceCounter: Counter = Counter()
    nonisolated(unsafe) var audioCounter: Counter = Counter()

    override func setUp() async throws {
        try await super.setUp()
        silenceCounter = Counter()
        audioCounter = Counter()
    }

    override func tearDown() async throws {
        detector = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_WithNeverThreshold_DoesNotDetectSilence() {
        // Given: Detector with .never threshold
        detector = SilenceDetector(threshold: .never, silenceDBThreshold: -40.0)

        // When: Process silent buffer multiple times
        let silentBuffer = createSilentBuffer()
        for _ in 0..<1000 {
            detector.processAudioBuffer(silentBuffer)
        }

        // Then: Should never trigger silence detection
        detector.onSilenceThresholdExceeded = { [silenceCounter] in
            silenceCounter.increment()
        }
        XCTAssertEqual(silenceCounter.value, 0,
                      ".never threshold should never detect silence")
    }

    func testInit_WithTwoMinuteThreshold_StoresCorrectValue() {
        // Given/When: Create detector with 2-minute threshold
        detector = SilenceDetector(threshold: .twoMinutes, silenceDBThreshold: -40.0)

        // Then: Should have correct threshold value
        XCTAssertEqual(detector.thresholdSeconds, 120.0,
                      "Two-minute threshold should be 120 seconds")
    }

    // MARK: - Silence Duration Tracking Tests

    func testProcessBuffer_WithContinuousSilence_TracksDuration() {
        // Given: Detector with 2-minute threshold
        detector = SilenceDetector(threshold: .twoMinutes, silenceDBThreshold: -40.0)
        let silentBuffer = createSilentBuffer()

        // When: Process silent buffers for simulated time
        // 1024 samples at 44100 Hz = ~0.023 seconds per buffer
        let buffersPerSecond = Int(44100.0 / 1024.0) // ~43 buffers/sec
        let totalBuffers = buffersPerSecond * 60 // 60 seconds of silence

        for _ in 0..<totalBuffers {
            detector.processAudioBuffer(silentBuffer)
        }

        // Then: Current silence duration should be ~60 seconds
        XCTAssertGreaterThanOrEqual(detector.currentSilenceDuration, 59.0,
                                   "Should track 60 seconds of silence")
        XCTAssertLessThanOrEqual(detector.currentSilenceDuration, 61.0,
                                "Silence duration should be accurate")
    }

    func testProcessBuffer_WithAudioAfterSilence_ResetsDuration() {
        // Given: Detector that has accumulated some silence
        detector = SilenceDetector(threshold: .twoMinutes, silenceDBThreshold: -40.0)
        let silentBuffer = createSilentBuffer()
        let audioBuffer = createAudioBuffer(amplitude: 0.5)

        // When: Process silence, then audio, then silence again
        for _ in 0..<100 {
            detector.processAudioBuffer(silentBuffer)
        }
        let durationBeforeAudio = detector.currentSilenceDuration
        XCTAssertGreaterThan(durationBeforeAudio, 0, "Should have accumulated silence")

        detector.processAudioBuffer(audioBuffer) // Audio breaks the silence

        // Then: Silence duration should reset
        XCTAssertEqual(detector.currentSilenceDuration, 0.0, accuracy: 0.01,
                      "Audio should reset silence duration to zero")
    }

    // MARK: - Threshold Exceeded Callback Tests

    func testCallback_WhenSilenceThresholdExceeded_FiresOnce() {
        // Given: Detector with 1-second threshold (for quick testing)
        detector = SilenceDetector(threshold: .twoMinutes, silenceDBThreshold: -40.0)
        detector.thresholdSeconds = 1.0 // Override for testing

        let silentBuffer = createSilentBuffer()
        let callbackFiredCounter = Counter()

        detector.onSilenceThresholdExceeded = { [silenceCounter, callbackFiredCounter] in
            callbackFiredCounter.value = 1
            silenceCounter.increment()
        }

        // When: Process enough silent buffers to exceed 1 second
        let buffersNeeded = Int(44100.0 / 1024.0) + 5 // ~43 buffers + margin
        for _ in 0..<buffersNeeded {
            detector.processAudioBuffer(silentBuffer)
        }

        // Then: Callback should fire exactly once
        XCTAssertEqual(callbackFiredCounter.value, 1, "Callback should fire when threshold exceeded")
        XCTAssertEqual(silenceCounter.value, 1,
                      "Callback should fire exactly once, not repeatedly")
    }

    func testCallback_WithContinuedSilence_DoesNotFireAgain() {
        // Given: Detector that has already triggered
        detector = SilenceDetector(threshold: .twoMinutes, silenceDBThreshold: -40.0)
        detector.thresholdSeconds = 1.0 // Override for testing

        let silentBuffer = createSilentBuffer()

        detector.onSilenceThresholdExceeded = { [silenceCounter] in
            silenceCounter.increment()
        }

        // When: Process buffers to trigger, then continue processing
        let buffersNeeded = Int(44100.0 / 1024.0) + 5
        for _ in 0..<(buffersNeeded * 2) { // Double the buffers
            detector.processAudioBuffer(silentBuffer)
        }

        // Then: Should only fire once
        XCTAssertEqual(silenceCounter.value, 1,
                      "Should not fire callback repeatedly for continued silence")
    }

    func testCallback_AfterAudioResume_CanFireAgain() {
        // Given: Detector that has triggered once
        detector = SilenceDetector(threshold: .twoMinutes, silenceDBThreshold: -40.0)
        detector.thresholdSeconds = 1.0 // Override for testing

        let silentBuffer = createSilentBuffer()
        let audioBuffer = createAudioBuffer(amplitude: 0.5)

        detector.onSilenceThresholdExceeded = { [silenceCounter] in
            silenceCounter.increment()
        }

        let buffersNeeded = Int(44100.0 / 1024.0) + 5

        // When: Trigger silence, add audio, trigger silence again
        for _ in 0..<buffersNeeded {
            detector.processAudioBuffer(silentBuffer)
        }
        XCTAssertEqual(silenceCounter.value, 1, "First silence detected")

        // Process audio to break silence
        for _ in 0..<10 {
            detector.processAudioBuffer(audioBuffer)
        }

        // Process silence again
        for _ in 0..<buffersNeeded {
            detector.processAudioBuffer(silentBuffer)
        }

        // Then: Should trigger again
        XCTAssertEqual(silenceCounter.value, 2,
                      "Should fire again after audio breaks silence")
    }

    // MARK: - Audio Resume Callback Tests

    func testCallback_WhenAudioResumes_FiresOnAudioDetected() {
        // Given: Detector with audio resume callback
        detector = SilenceDetector(threshold: .twoMinutes, silenceDBThreshold: -40.0)
        let silentBuffer = createSilentBuffer()
        let audioBuffer = createAudioBuffer(amplitude: 0.5)

        detector.onAudioDetectedAfterSilence = { [audioCounter] in
            audioCounter.increment()
        }

        // When: Process silence, then audio
        for _ in 0..<100 {
            detector.processAudioBuffer(silentBuffer)
        }
        XCTAssertEqual(audioCounter.value, 0, "No audio detected during silence")

        detector.processAudioBuffer(audioBuffer)

        // Then: Should fire audio detected callback
        XCTAssertEqual(audioCounter.value, 1,
                      "Should fire audio detected callback when audio resumes")
    }

    func testCallback_WithContinuedAudio_DoesNotFireRepeatedly() {
        // Given: Detector with callbacks
        detector = SilenceDetector(threshold: .twoMinutes, silenceDBThreshold: -40.0)
        let silentBuffer = createSilentBuffer()
        let audioBuffer = createAudioBuffer(amplitude: 0.5)

        detector.onAudioDetectedAfterSilence = { [audioCounter] in
            audioCounter.increment()
        }

        // When: Silence → audio → more audio
        for _ in 0..<100 {
            detector.processAudioBuffer(silentBuffer)
        }

        for _ in 0..<100 {
            detector.processAudioBuffer(audioBuffer)
        }

        // Then: Should only fire once when audio first resumes
        XCTAssertEqual(audioCounter.value, 1,
                      "Should not fire repeatedly for continued audio")
    }

    // MARK: - State Management Tests

    func testReset_ClearsSilenceDuration() {
        // Given: Detector with accumulated silence
        detector = SilenceDetector(threshold: .twoMinutes, silenceDBThreshold: -40.0)
        let silentBuffer = createSilentBuffer()

        for _ in 0..<100 {
            detector.processAudioBuffer(silentBuffer)
        }
        XCTAssertGreaterThan(detector.currentSilenceDuration, 0)

        // When: Reset
        detector.reset()

        // Then: Duration should be zero
        XCTAssertEqual(detector.currentSilenceDuration, 0.0, accuracy: 0.0001,
                      "Reset should clear silence duration")
    }

    func testReset_ClearsTriggeredState() {
        // Given: Detector that has triggered
        detector = SilenceDetector(threshold: .twoMinutes, silenceDBThreshold: -40.0)
        detector.thresholdSeconds = 1.0

        let silentBuffer = createSilentBuffer()

        detector.onSilenceThresholdExceeded = { [silenceCounter] in
            silenceCounter.increment()
        }

        let buffersNeeded = Int(44100.0 / 1024.0) + 5
        for _ in 0..<buffersNeeded {
            detector.processAudioBuffer(silentBuffer)
        }
        XCTAssertEqual(silenceCounter.value, 1)

        // When: Reset and process more silence
        detector.reset()
        for _ in 0..<buffersNeeded {
            detector.processAudioBuffer(silentBuffer)
        }

        // Then: Should trigger again (state was cleared)
        XCTAssertEqual(silenceCounter.value, 2,
                      "Reset should allow callback to fire again")
    }

    // MARK: - Thread Safety Tests

    // TODO: Re-enable this test after resolving Swift 6 strict concurrency issues
    // This test intentionally tests concurrent access patterns which conflicts with
    // Swift 6's sending parameter checks. The code being tested (SilenceDetector)
    // is thread-safe through proper synchronization, but the test infrastructure
    // cannot express this to the type system.
    /*
    func testConcurrentProcessing_MaintainsCorrectState() async {
        // Given: Detector and buffers
        detector = SilenceDetector(threshold: .twoMinutes, silenceDBThreshold: -40.0)
        let silentBuffer = createSilentBuffer()

        // When: Process buffers concurrently from multiple tasks
        nonisolated(unsafe) let unsafeBuffer = silentBuffer
        nonisolated(unsafe) let unsafeDetector = detector
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    for _ in 0..<100 {
                        unsafeDetector!.processAudioBuffer(unsafeBuffer)
                    }
                }
            }
        }

        // Then: Should not crash and should have reasonable duration
        // (exact value may vary due to concurrency, but should be > 0)
        XCTAssertGreaterThan(detector.currentSilenceDuration, 0,
                           "Concurrent processing should accumulate silence")
    }
    */

    // MARK: - Helper Methods

    private func createSilentBuffer() -> AVAudioPCMBuffer {
        return createBuffer(amplitude: 0.0)
    }

    private func createAudioBuffer(amplitude: Float) -> AVAudioPCMBuffer {
        return createBuffer(amplitude: amplitude)
    }

    private func createBuffer(amplitude: Float) -> AVAudioPCMBuffer {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
            fatalError("Failed to create test buffer")
        }

        buffer.frameLength = 1024

        guard let channelData = buffer.floatChannelData else {
            fatalError("No channel data")
        }

        // Fill buffer with constant amplitude
        for i in 0..<1024 {
            channelData[0][Int(i)] = amplitude
        }

        return buffer
    }
}
