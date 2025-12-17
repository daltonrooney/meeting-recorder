import XCTest
import AVFoundation
@testable import CallTranscription

final class AudioLevelAnalyzerTests: XCTestCase {

    // MARK: - RMS Calculation Tests

    func testCalculateRMS_WithSilentBuffer_ReturnsZero() {
        // Given: A buffer filled with zeros (silence)
        let buffer = createTestBuffer(sampleCount: 1024, amplitude: 0.0)

        // When: Calculate RMS
        let rms = AudioLevelAnalyzer.calculateRMS(from: buffer)

        // Then: RMS should be zero
        XCTAssertEqual(rms, 0.0, accuracy: 0.0001,
                      "RMS of silent buffer should be zero")
    }

    func testCalculateRMS_WithConstantAmplitude_ReturnsExpectedValue() {
        // Given: A buffer with constant amplitude 0.5
        let amplitude: Float = 0.5
        let buffer = createTestBuffer(sampleCount: 1024, amplitude: amplitude)

        // When: Calculate RMS
        let rms = AudioLevelAnalyzer.calculateRMS(from: buffer)

        // Then: RMS should equal the amplitude (for constant signal)
        XCTAssertEqual(rms, amplitude, accuracy: 0.0001,
                      "RMS should equal amplitude for constant signal")
    }

    func testCalculateRMS_WithMaxAmplitude_ReturnsOne() {
        // Given: A buffer with maximum amplitude (1.0)
        let buffer = createTestBuffer(sampleCount: 1024, amplitude: 1.0)

        // When: Calculate RMS
        let rms = AudioLevelAnalyzer.calculateRMS(from: buffer)

        // Then: RMS should be 1.0
        XCTAssertEqual(rms, 1.0, accuracy: 0.0001,
                      "RMS of max amplitude should be 1.0")
    }

    func testCalculateRMS_WithSineWave_ReturnsCorrectValue() {
        // Given: A buffer with sine wave (peak amplitude 1.0)
        // RMS of sine wave = peak / sqrt(2) ≈ 0.707
        let buffer = createSineWaveBuffer(sampleCount: 1024, frequency: 440.0, sampleRate: 44100.0)

        // When: Calculate RMS
        let rms = AudioLevelAnalyzer.calculateRMS(from: buffer)

        // Then: RMS should be approximately 0.707
        let expectedRMS = 1.0 / sqrt(2.0)
        XCTAssertEqual(rms, expectedRMS, accuracy: 0.01,
                      "RMS of sine wave should be peak/sqrt(2)")
    }

    // MARK: - dB Conversion Tests

    func testConvertToDecibels_WithZeroRMS_ReturnsNegativeInfinity() {
        // Given: Zero RMS value
        let rms: Float = 0.0

        // When: Convert to dB
        let db = AudioLevelAnalyzer.convertToDecibels(rms: rms)

        // Then: Should return negative infinity
        XCTAssertTrue(db.isInfinite && db < 0,
                     "dB of zero RMS should be -∞")
    }

    func testConvertToDecibels_WithRMSOne_ReturnsZero() {
        // Given: RMS value of 1.0 (max)
        let rms: Float = 1.0

        // When: Convert to dB
        let db = AudioLevelAnalyzer.convertToDecibels(rms: rms)

        // Then: Should return 0 dB
        XCTAssertEqual(db, 0.0, accuracy: 0.0001,
                      "dB of RMS 1.0 should be 0 dB")
    }

    func testConvertToDecibels_WithRMSHalf_ReturnsNegative6dB() {
        // Given: RMS value of 0.5
        // Expected: 20 * log10(0.5) ≈ -6.02 dB
        let rms: Float = 0.5

        // When: Convert to dB
        let db = AudioLevelAnalyzer.convertToDecibels(rms: rms)

        // Then: Should return approximately -6 dB
        XCTAssertEqual(db, -6.02, accuracy: 0.1,
                      "dB of RMS 0.5 should be approximately -6 dB")
    }

    func testConvertToDecibels_WithVeryLowRMS_ReturnsVeryNegative() {
        // Given: Very low RMS value (0.001)
        // Expected: 20 * log10(0.001) = -60 dB
        let rms: Float = 0.001

        // When: Convert to dB
        let db = AudioLevelAnalyzer.convertToDecibels(rms: rms)

        // Then: Should return -60 dB
        XCTAssertEqual(db, -60.0, accuracy: 0.1,
                      "dB of RMS 0.001 should be -60 dB")
    }

    // MARK: - Silence Detection Tests

    func testIsSilent_WithSilentBuffer_ReturnsTrue() {
        // Given: A silent buffer (RMS = 0)
        let buffer = createTestBuffer(sampleCount: 1024, amplitude: 0.0)

        // When: Check if silent with -40dB threshold
        let isSilent = AudioLevelAnalyzer.isSilent(buffer, threshold: -40.0)

        // Then: Should be detected as silent
        XCTAssertTrue(isSilent,
                     "Silent buffer should be detected as silent")
    }

    func testIsSilent_WithLoudBuffer_ReturnsFalse() {
        // Given: A loud buffer (RMS = 0.5, -6 dB)
        let buffer = createTestBuffer(sampleCount: 1024, amplitude: 0.5)

        // When: Check if silent with -40dB threshold
        let isSilent = AudioLevelAnalyzer.isSilent(buffer, threshold: -40.0)

        // Then: Should NOT be detected as silent
        XCTAssertFalse(isSilent,
                      "Loud buffer should not be detected as silent")
    }

    func testIsSilent_WithBorderlineBuffer_DetectsCorrectly() {
        // Given: Buffer at exactly -40dB
        // -40dB means RMS = 10^(-40/20) = 0.01
        let rms: Float = 0.01
        let buffer = createTestBuffer(sampleCount: 1024, amplitude: rms)

        // When: Check with -40dB threshold
        let isSilent = AudioLevelAnalyzer.isSilent(buffer, threshold: -40.0)

        // Then: Should be on the boundary (implementation choice: >= threshold is silent)
        // We'll test both sides of the boundary
        let justAbove = createTestBuffer(sampleCount: 1024, amplitude: rms * 1.1)
        let justBelow = createTestBuffer(sampleCount: 1024, amplitude: rms * 0.9)

        XCTAssertFalse(AudioLevelAnalyzer.isSilent(justAbove, threshold: -40.0),
                      "Buffer just above threshold should not be silent")
        XCTAssertTrue(AudioLevelAnalyzer.isSilent(justBelow, threshold: -40.0),
                     "Buffer just below threshold should be silent")
    }

    func testIsSilent_WithDifferentThresholds_DetectsCorrectly() {
        // Given: Buffer with -30dB RMS (0.0316)
        let rms: Float = 0.0316
        let buffer = createTestBuffer(sampleCount: 1024, amplitude: rms)

        // When/Then: Test with different thresholds
        XCTAssertFalse(AudioLevelAnalyzer.isSilent(buffer, threshold: -40.0),
                      "Should not be silent with -40dB threshold")
        XCTAssertTrue(AudioLevelAnalyzer.isSilent(buffer, threshold: -20.0),
                     "Should be silent with -20dB threshold")
    }

    // MARK: - Integration Tests

    func testAnalyzeBuffer_ReturnsCorrectRMSAndDB() {
        // Given: A buffer with known amplitude
        let amplitude: Float = 0.1
        let buffer = createTestBuffer(sampleCount: 1024, amplitude: amplitude)

        // When: Analyze the buffer
        let result = AudioLevelAnalyzer.analyze(buffer)

        // Then: Should return correct RMS and dB
        XCTAssertEqual(result.rms, amplitude, accuracy: 0.0001,
                      "RMS should match buffer amplitude")
        let expectedDB = 20.0 * log10(amplitude)
        XCTAssertEqual(result.db, expectedDB, accuracy: 0.1,
                      "dB should be calculated correctly from RMS")
        XCTAssertEqual(result.isSilent, amplitude < 0.01, // -40dB threshold
                      "Silence detection should match expected value")
    }

    // MARK: - Edge Case Tests

    func testCalculateRMS_WithEmptyBuffer_ReturnsZero() {
        // Given: An empty buffer (no frames)
        let buffer = createTestBuffer(sampleCount: 0, amplitude: 0.5)

        // When: Calculate RMS
        let rms = AudioLevelAnalyzer.calculateRMS(from: buffer)

        // Then: Should return zero (or handle gracefully)
        XCTAssertEqual(rms, 0.0, accuracy: 0.0001,
                      "RMS of empty buffer should be zero")
    }

    func testCalculateRMS_WithNilChannelData_ReturnsZero() {
        // Given: A buffer with nil channel data
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024) else {
            XCTFail("Failed to create buffer")
            return
        }
        buffer.frameLength = 0 // No actual frames

        // When: Calculate RMS
        let rms = AudioLevelAnalyzer.calculateRMS(from: buffer)

        // Then: Should return zero
        XCTAssertEqual(rms, 0.0, accuracy: 0.0001,
                      "RMS of buffer with no frames should be zero")
    }

    // MARK: - Helper Methods

    private func createTestBuffer(sampleCount: Int, amplitude: Float) -> AVAudioPCMBuffer {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount)) else {
            fatalError("Failed to create test buffer")
        }

        buffer.frameLength = AVAudioFrameCount(sampleCount)

        guard let channelData = buffer.floatChannelData else {
            fatalError("No channel data")
        }

        // Fill buffer with constant amplitude
        for i in 0..<sampleCount {
            channelData[0][i] = amplitude
        }

        return buffer
    }

    private func createSineWaveBuffer(sampleCount: Int, frequency: Float, sampleRate: Float) -> AVAudioPCMBuffer {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount)) else {
            fatalError("Failed to create test buffer")
        }

        buffer.frameLength = AVAudioFrameCount(sampleCount)

        guard let channelData = buffer.floatChannelData else {
            fatalError("No channel data")
        }

        // Generate sine wave
        for i in 0..<sampleCount {
            let phase = 2.0 * Float.pi * frequency * Float(i) / sampleRate
            channelData[0][i] = sin(phase)
        }

        return buffer
    }
}
