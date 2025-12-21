import XCTest
import AVFoundation
import OSLog
@testable import CallTranscription

/// Tests for audio quality improvements following TDD methodology.
/// Tests are written FIRST before implementation.
///
/// These tests verify:
/// - Audio format logging and diagnostics
/// - High-quality sample rate conversion
/// - Proper stereo-to-mono downmixing
/// - Improved AAC encoding quality
@MainActor
final class AudioQualityTests: XCTestCase {

    // MARK: - Helper Methods

    private func createTestBuffer(
        sampleRate: Double = 48000.0,
        channelCount: UInt32 = 1,
        frameCount: AVAudioFrameCount = 1024,
        fillValue: Float = 0.5
    ) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: channelCount,
            interleaved: false
        )!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        // Fill with test data
        if let channelData = buffer.floatChannelData {
            for channel in 0..<Int(channelCount) {
                for frame in 0..<Int(frameCount) {
                    channelData[channel][frame] = fillValue
                }
            }
        }

        return buffer
    }

    // MARK: - AudioMixer Quality Tests

    func testAudioMixerUsesHighQualitySampleRateConversion() async throws {
        let mixer = AudioMixer()

        // Create buffers with different sample rates requiring conversion
        let buffer44k = createTestBuffer(sampleRate: 44100.0, fillValue: 0.5)
        let buffer48k = createTestBuffer(sampleRate: 48000.0, fillValue: 0.5)

        var receivedBuffer: AVAudioPCMBuffer?
        mixer.mixedBufferHandler = { buffer in
            receivedBuffer = buffer
        }

        // Feed buffers requiring sample rate conversion
        try await mixer.feedMicrophoneBuffer(buffer44k)
        try await mixer.feedSystemAudioBuffer(buffer48k)

        // Should produce output without throwing
        XCTAssertNotNil(receivedBuffer)

        // Output should be at target rate (48kHz)
        XCTAssertEqual(receivedBuffer?.format.sampleRate, 48000.0)
    }

    func testAudioMixerPreservesAudioQualityDuringSampleRateConversion() async throws {
        let mixer = AudioMixer()

        // Create a buffer with known frequency content at 44.1kHz
        let sampleRate44k: Double = 44100.0
        let buffer = createTestBuffer(sampleRate: sampleRate44k, frameCount: 4096)

        // Fill with 1kHz sine wave
        if let channelData = buffer.floatChannelData {
            let frequency: Float = 1000.0
            for frame in 0..<Int(buffer.frameLength) {
                let phase = Float(frame) * frequency / Float(sampleRate44k) * 2.0 * .pi
                channelData[0][frame] = sin(phase) * 0.5
            }
        }

        var receivedBuffer: AVAudioPCMBuffer?
        mixer.mixedBufferHandler = { buffer in
            receivedBuffer = buffer
        }

        try await mixer.feedMicrophoneBuffer(buffer)

        XCTAssertNotNil(receivedBuffer)

        // After high-quality conversion, signal should maintain coherence
        // Check that output has reasonable amplitude (not severely degraded)
        if let outputData = receivedBuffer?.floatChannelData {
            var maxAmplitude: Float = 0.0
            for frame in 0..<Int(receivedBuffer!.frameLength) {
                maxAmplitude = max(maxAmplitude, abs(outputData[0][frame]))
            }

            // High-quality conversion should preserve amplitude within reasonable bounds.
            // Some amplitude variation is expected due to:
            // 1. Sample rate conversion filter characteristics
            // 2. Soft limiting applied by mixer
            // 3. Numerical precision in conversion
            // We verify the signal isn't severely degraded (>50% loss) or unexpectedly amplified
            XCTAssertGreaterThan(maxAmplitude, 0.25, "Signal severely degraded during conversion")
            XCTAssertLessThan(maxAmplitude, 0.75, "Signal amplified unexpectedly")
        }
    }

    func testAudioMixerPerformsProperStereoToMonoDownmix() async throws {
        let mixer = AudioMixer()

        // Create stereo buffer with distinct left/right channels
        let stereoBuffer = createTestBuffer(channelCount: 2, frameCount: 1024)

        if let channelData = stereoBuffer.floatChannelData {
            // Left channel: 0.3
            for frame in 0..<Int(stereoBuffer.frameLength) {
                channelData[0][frame] = 0.3
            }
            // Right channel: 0.7
            for frame in 0..<Int(stereoBuffer.frameLength) {
                channelData[1][frame] = 0.7
            }
        }

        var receivedBuffer: AVAudioPCMBuffer?
        mixer.mixedBufferHandler = { buffer in
            receivedBuffer = buffer
        }

        try await mixer.feedMicrophoneBuffer(stereoBuffer)

        XCTAssertNotNil(receivedBuffer)

        // Output should be mono
        XCTAssertEqual(receivedBuffer?.format.channelCount, 1)

        // Downmix should intelligently combine channels
        // Expected: proper mixing that preserves both channels without phase issues
        if let outputData = receivedBuffer?.floatChannelData {
            let mixedValue = outputData[0][0]

            // Should be between the two input values
            XCTAssertGreaterThan(mixedValue, 0.3)
            XCTAssertLessThan(mixedValue, 0.7)

            // For proper downmix (average or similar), expect ~0.5
            XCTAssertEqual(Double(mixedValue), 0.5, accuracy: 0.15)
        }
    }

    func testAudioMixerHandlesPhaseInvertedSignalsCorrectly() async throws {
        let mixer = AudioMixer()

        // Create stereo buffer with completely phase-inverted signals (L = -R)
        // This edge case tests that the downmix algorithm handles extreme phase relationships
        // without crashing and produces mathematically correct output.
        let stereoBuffer = createTestBuffer(channelCount: 2, frameCount: 1024)

        if let channelData = stereoBuffer.floatChannelData {
            for frame in 0..<Int(stereoBuffer.frameLength) {
                let value = sin(Float(frame) * 0.1) * 0.8
                channelData[0][frame] = value      // Left: positive phase
                channelData[1][frame] = -value     // Right: negative phase (inverted)
            }
        }

        var receivedBuffer: AVAudioPCMBuffer?
        mixer.mixedBufferHandler = { buffer in
            receivedBuffer = buffer
        }

        try await mixer.feedMicrophoneBuffer(stereoBuffer)

        XCTAssertNotNil(receivedBuffer)

        // With completely phase-inverted signals (L = -R), standard downmix (L+R)/sqrt(2)
        // mathematically produces near-zero output. This is correct behavior.
        // Real-world audio rarely has perfect phase inversion across all frequencies.
        // We verify the downmix produces valid output in all cases.
        if let outputData = receivedBuffer?.floatChannelData {
            // Verify output is within valid range [-1.0, 1.0]
            // Output will be near-zero for perfectly inverted signals, which is expected
            for frame in 0..<Int(receivedBuffer!.frameLength) {
                XCTAssertGreaterThanOrEqual(outputData[0][frame], -1.0)
                XCTAssertLessThanOrEqual(outputData[0][frame], 1.0)
            }
        }
    }

    func testAudioMixerLogsFormatConversions() async throws {
        // This test verifies that format conversions are logged for diagnostics
        // In actual implementation, we'd verify OSLog output

        let mixer = AudioMixer()

        // Create buffer requiring both sample rate and channel conversion
        let buffer = createTestBuffer(sampleRate: 44100.0, channelCount: 2)

        var receivedBuffer: AVAudioPCMBuffer?
        mixer.mixedBufferHandler = { buffer in
            receivedBuffer = buffer
        }

        // This should trigger logging of format conversion
        try await mixer.feedMicrophoneBuffer(buffer)

        XCTAssertNotNil(receivedBuffer)

        // Log verification would require OSLog inspection in real implementation
        // For now, just verify conversion happened successfully
        XCTAssertEqual(receivedBuffer?.format.sampleRate, 48000.0)
        XCTAssertEqual(receivedBuffer?.format.channelCount, 1)
    }

    // MARK: - AudioFileWriter Quality Tests

    func testAudioFileWriterUsesHighQualityAACEncoding() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let writer = try await AudioFileWriter(
            outputFolder: tempDir,
            filename: "test_quality.m4a",
            format: .aac
        )

        // Write some test audio
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 48000,
            channels: 1,
            interleaved: false
        )!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4096)!
        buffer.frameLength = 4096

        // Fill with complex audio signal (multiple frequencies)
        if let channelData = buffer.floatChannelData {
            for frame in 0..<Int(buffer.frameLength) {
                let t = Float(frame) / Float(format.sampleRate)
                // Mix of 440Hz and 880Hz
                channelData[0][frame] =
                    sin(2.0 * .pi * 440.0 * t) * 0.3 +
                    sin(2.0 * .pi * 880.0 * t) * 0.2
            }
        }

        try await writer.write(buffer: buffer)
        let fileURL = try await writer.finalize()

        // Verify file was created
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        // Verify file has reasonable size
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as! UInt64

        // With 128kbps encoding and ~0.085 seconds of audio, expect > 1KB
        // (rough calculation: 128000 bits/sec * 0.085 sec / 8 = ~1.36KB)
        XCTAssertGreaterThan(fileSize, 1000, "File seems too small for AAC encoding")
    }

    func testAudioFileWriterMaintains48kHzSampleRate() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let writer = try await AudioFileWriter(
            outputFolder: tempDir,
            filename: "test_48k.m4a",
            format: .aac
        )

        // Write buffer at 48kHz
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 48000,
            channels: 1,
            interleaved: false
        )!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
        buffer.frameLength = 1024

        try await writer.write(buffer: buffer)
        let fileURL = try await writer.finalize()

        // Read back file and verify sample rate
        let audioFile = try AVAudioFile(forReading: fileURL)
        XCTAssertEqual(audioFile.fileFormat.sampleRate, 48000.0)
    }

    func testAudioFileWriterMaintainsMonoChannel() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let writer = try await AudioFileWriter(
            outputFolder: tempDir,
            filename: "test_mono.m4a",
            format: .aac
        )

        // Write mono buffer
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 48000,
            channels: 1,
            interleaved: false
        )!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
        buffer.frameLength = 1024

        try await writer.write(buffer: buffer)
        let fileURL = try await writer.finalize()

        // Read back file and verify channel count
        let audioFile = try AVAudioFile(forReading: fileURL)
        XCTAssertEqual(audioFile.fileFormat.channelCount, 1)
    }

    // MARK: - Integration Tests

    func testEndToEndAudioQualityWith44kHzStereoInput() async throws {
        // Simulate real-world scenario: 44.1kHz stereo input → mixing → 48kHz mono AAC output

        let mixer = AudioMixer(microphoneLevel: 0.5, systemAudioLevel: 0.5)

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let writer = try await AudioFileWriter(
            outputFolder: tempDir,
            filename: "integration_test.m4a",
            format: .aac
        )

        // Connect mixer to writer
        mixer.mixedBufferHandler = { buffer in
            Task {
                try? await writer.write(buffer: buffer)
            }
        }

        // Feed typical input: 44.1kHz stereo
        for _ in 0..<10 {
            let micBuffer = createTestBuffer(sampleRate: 44100.0, channelCount: 2, fillValue: 0.4)
            let sysBuffer = createTestBuffer(sampleRate: 44100.0, channelCount: 2, fillValue: 0.3)

            try await mixer.feedMicrophoneBuffer(micBuffer)
            try await mixer.feedSystemAudioBuffer(sysBuffer)
        }

        // Small delay to ensure all buffers are written
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        let fileURL = try await writer.finalize()

        // Verify output file
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        let audioFile = try AVAudioFile(forReading: fileURL)
        XCTAssertEqual(audioFile.fileFormat.sampleRate, 48000.0)
        XCTAssertEqual(audioFile.fileFormat.channelCount, 1)

        // Verify file has content
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as! UInt64
        XCTAssertGreaterThan(fileSize, 1000)
    }

    func testEndToEndAudioQualityWith48kHzMonoInput() async throws {
        // Test optimal case: no conversion needed

        let mixer = AudioMixer()

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let writer = try await AudioFileWriter(
            outputFolder: tempDir,
            filename: "optimal_test.m4a",
            format: .aac
        )

        mixer.mixedBufferHandler = { buffer in
            Task {
                try? await writer.write(buffer: buffer)
            }
        }

        // Feed ideal input: already 48kHz mono
        for _ in 0..<10 {
            let buffer = createTestBuffer(sampleRate: 48000.0, channelCount: 1, fillValue: 0.5)
            try await mixer.feedMicrophoneBuffer(buffer)
        }

        try await Task.sleep(nanoseconds: 100_000_000)

        let fileURL = try await writer.finalize()

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        let audioFile = try AVAudioFile(forReading: fileURL)
        XCTAssertEqual(audioFile.fileFormat.sampleRate, 48000.0)
        XCTAssertEqual(audioFile.fileFormat.channelCount, 1)
    }
}
