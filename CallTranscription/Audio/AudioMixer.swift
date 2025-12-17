import Foundation
import AVFoundation
import os.log

/// Mixes audio buffers from microphone and system audio sources into a unified stream.
///
/// AudioMixer combines audio from two sources with configurable levels, handles format
/// mismatches, and delivers mixed output through a callback handler.
///
/// - Note: Thread-safe with @MainActor isolation for Swift 6 compliance
///
/// Example usage:
/// ```swift
/// let mixer = AudioMixer(microphoneLevel: 0.7, systemAudioLevel: 0.3)
/// mixer.mixedBufferHandler = { mixedBuffer in
///     // Process mixed audio
/// }
/// try await mixer.feedMicrophoneBuffer(micBuffer)
/// try await mixer.feedSystemAudioBuffer(sysBuffer)
/// ```
@MainActor
public final class AudioMixer {

    // MARK: - Public Properties

    /// Callback invoked when mixed audio buffer is ready
    public var mixedBufferHandler: ((AVAudioPCMBuffer) -> Void)?

    // MARK: - Private Properties

    private let microphoneLevel: Float
    private let systemAudioLevel: Float
    private let logger = Logger(subsystem: "dev.rygn.CallTranscription", category: "AudioMixer")

    // Target output format (48kHz, mono, float32)
    private lazy var outputFormat: AVAudioFormat = {
        AVAudioFormat(commonFormat: .pcmFormatFloat32,
                     sampleRate: 48000.0,
                     channels: 1,
                     interleaved: false)!
    }()

    // Recent buffers for mixing
    private var lastMicrophoneBuffer: AVAudioPCMBuffer?
    private var lastSystemAudioBuffer: AVAudioPCMBuffer?

    // MARK: - Initialization

    /// Creates a new audio mixer with configurable mixing levels.
    ///
    /// - Parameters:
    ///   - microphoneLevel: Level for microphone audio (0.0-1.0), defaults to 0.5
    ///   - systemAudioLevel: Level for system audio (0.0-1.0), defaults to 0.5
    public init(microphoneLevel: Float = 0.5, systemAudioLevel: Float = 0.5) {
        self.microphoneLevel = microphoneLevel
        self.systemAudioLevel = systemAudioLevel
        logger.debug("AudioMixer initialized with mic level: \(microphoneLevel), system level: \(systemAudioLevel)")
    }

    // MARK: - Buffer Feeding

    /// Feeds a microphone audio buffer for mixing.
    ///
    /// - Parameter buffer: Audio buffer from microphone source
    /// - Throws: Error if buffer processing fails
    public func feedMicrophoneBuffer(_ buffer: AVAudioPCMBuffer) async throws {
        guard buffer.frameLength > 0 else {
            logger.debug("Skipping empty microphone buffer")
            return
        }

        // Convert to output format if needed
        let convertedBuffer = try convertBufferIfNeeded(buffer, to: outputFormat)
        lastMicrophoneBuffer = convertedBuffer

        // Mix and deliver
        try deliverMixedOutput()
    }

    /// Feeds a system audio buffer for mixing.
    ///
    /// - Parameter buffer: Audio buffer from system audio source
    /// - Throws: Error if buffer processing fails
    public func feedSystemAudioBuffer(_ buffer: AVAudioPCMBuffer) async throws {
        guard buffer.frameLength > 0 else {
            logger.debug("Skipping empty system audio buffer")
            return
        }

        // Convert to output format if needed
        let convertedBuffer = try convertBufferIfNeeded(buffer, to: outputFormat)
        lastSystemAudioBuffer = convertedBuffer

        // Mix and deliver
        try deliverMixedOutput()
    }

    /// Mixes available buffers and delivers output.
    private func deliverMixedOutput() throws {
        // Mix buffers if we have at least one source
        guard lastMicrophoneBuffer != nil || lastSystemAudioBuffer != nil else {
            return
        }

        let mixedBuffer: AVAudioPCMBuffer

        if let micBuffer = lastMicrophoneBuffer, let sysBuffer = lastSystemAudioBuffer {
            // Mix both sources
            mixedBuffer = try mixBuffers(micBuffer, sysBuffer)
        } else if let micBuffer = lastMicrophoneBuffer {
            // Only microphone
            mixedBuffer = scaleBuffer(micBuffer, level: microphoneLevel)
        } else if let sysBuffer = lastSystemAudioBuffer {
            // Only system audio
            mixedBuffer = scaleBuffer(sysBuffer, level: systemAudioLevel)
        } else {
            return
        }

        mixedBufferHandler?(mixedBuffer)
    }

    /// Mixes two buffers together with configured levels.
    private func mixBuffers(_ buffer1: AVAudioPCMBuffer, _ buffer2: AVAudioPCMBuffer) throws -> AVAudioPCMBuffer {
        // Use the shorter length
        let frameLength = min(buffer1.frameLength, buffer2.frameLength)

        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameLength) else {
            throw NSError(domain: "AudioMixer", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create mixed buffer"])
        }

        outputBuffer.frameLength = frameLength

        // Mix samples
        if let data1 = buffer1.floatChannelData,
           let data2 = buffer2.floatChannelData,
           let outputData = outputBuffer.floatChannelData {
            for channel in 0..<Int(outputFormat.channelCount) {
                for frame in 0..<Int(frameLength) {
                    let sample1 = data1[min(channel, Int(buffer1.format.channelCount) - 1)][frame]
                    let sample2 = data2[min(channel, Int(buffer2.format.channelCount) - 1)][frame]
                    outputData[channel][frame] = (sample1 * microphoneLevel) + (sample2 * systemAudioLevel)
                }
            }
        }

        return outputBuffer
    }

    // MARK: - Private Methods

    /// Converts buffer to target format if needed, otherwise returns original buffer.
    private func convertBufferIfNeeded(_ buffer: AVAudioPCMBuffer, to targetFormat: AVAudioFormat) throws -> AVAudioPCMBuffer {
        // Check if formats match
        if buffer.format.sampleRate == targetFormat.sampleRate &&
           buffer.format.channelCount == targetFormat.channelCount &&
           buffer.format.commonFormat == targetFormat.commonFormat {
            return buffer
        }

        logger.debug("Converting buffer from \(buffer.format.sampleRate)Hz/\(buffer.format.channelCount)ch to \(targetFormat.sampleRate)Hz/\(targetFormat.channelCount)ch")

        guard let converter = AVAudioConverter(from: buffer.format, to: targetFormat) else {
            logger.error("Failed to create audio converter")
            throw NSError(domain: "AudioMixer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio converter"])
        }

        // Calculate output frame count based on sample rate ratio
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * ratio)

        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCount) else {
            logger.error("Failed to create output buffer")
            throw NSError(domain: "AudioMixer", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create output buffer"])
        }

        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)

        if let error = error {
            logger.error("Audio conversion failed: \(error.localizedDescription)")
            throw error
        }

        return outputBuffer
    }

    /// Scales buffer samples by the specified level.
    private func scaleBuffer(_ buffer: AVAudioPCMBuffer, level: Float) -> AVAudioPCMBuffer {
        guard level != 1.0 else {
            return buffer
        }

        // Create output buffer with same format
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameCapacity) else {
            logger.error("Failed to create scaled buffer")
            return buffer
        }

        outputBuffer.frameLength = buffer.frameLength

        // Scale samples
        if let inputData = buffer.floatChannelData,
           let outputData = outputBuffer.floatChannelData {
            for channel in 0..<Int(buffer.format.channelCount) {
                for frame in 0..<Int(buffer.frameLength) {
                    outputData[channel][frame] = inputData[channel][frame] * level
                }
            }
        }

        return outputBuffer
    }
}
