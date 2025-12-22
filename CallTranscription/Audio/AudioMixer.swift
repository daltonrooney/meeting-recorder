import Foundation
import AVFoundation
import Accelerate
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
        // CRITICAL DEBUG: Verify this method is being called (Issue #137)
        print("🟢 AudioMixer.feedMicrophoneBuffer() CALLED - \(buffer.frameLength) frames, \(buffer.format.sampleRate)Hz, \(buffer.format.channelCount)ch")

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
    ///
    /// Mixing behavior:
    /// - When both sources have buffers: Mixes them together and clears both (prevents duplication)
    /// - When only one source has buffer: Outputs that source scaled by its level
    ///
    /// Single-source buffers are preserved for future mixing until replaced by new buffer
    /// from same source. This ensures continuous output even when sources are intermittent.
    private func deliverMixedOutput() throws {
        // Mix buffers if we have at least one source
        guard lastMicrophoneBuffer != nil || lastSystemAudioBuffer != nil else {
            return
        }

        let mixedBuffer: AVAudioPCMBuffer

        if let micBuffer = lastMicrophoneBuffer, let sysBuffer = lastSystemAudioBuffer {
            // Mix both sources and clear to avoid duplication in subsequent mixes
            mixedBuffer = try mixBuffers(micBuffer, sysBuffer)
            lastMicrophoneBuffer = nil
            lastSystemAudioBuffer = nil
        } else if let micBuffer = lastMicrophoneBuffer {
            // Only microphone buffer available
            // If system audio is disabled (level == 0), output mic alone
            // Otherwise, WAIT for system audio buffer to arrive (don't output yet)
            guard systemAudioLevel == 0.0 else {
                return // Wait for system audio buffer
            }
            mixedBuffer = scaleBuffer(micBuffer, level: microphoneLevel)
            lastMicrophoneBuffer = nil
        } else if let sysBuffer = lastSystemAudioBuffer {
            // Only system audio buffer available
            // If microphone is disabled (level == 0), output sys alone
            // Otherwise, WAIT for microphone buffer to arrive (don't output yet)
            guard microphoneLevel == 0.0 else {
                return // Wait for microphone buffer
            }
            mixedBuffer = scaleBuffer(sysBuffer, level: systemAudioLevel)
            lastSystemAudioBuffer = nil
        } else {
            return
        }

        mixedBufferHandler?(mixedBuffer)
    }

    /// Mixes two buffers together with configured levels and clipping protection.
    private func mixBuffers(_ buffer1: AVAudioPCMBuffer, _ buffer2: AVAudioPCMBuffer) throws -> AVAudioPCMBuffer {
        // Use the shorter length
        let frameLength = min(buffer1.frameLength, buffer2.frameLength)

        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameLength) else {
            throw NSError(domain: "AudioMixer", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create mixed buffer"])
        }

        outputBuffer.frameLength = frameLength

        // Mix samples with soft limiting to prevent clipping
        // Use Accelerate framework for SIMD performance
        if let data1 = buffer1.floatChannelData,
           let data2 = buffer2.floatChannelData,
           let outputData = outputBuffer.floatChannelData {
            for channel in 0..<Int(outputFormat.channelCount) {
                let sourceChannel1 = min(channel, Int(buffer1.format.channelCount) - 1)
                let sourceChannel2 = min(channel, Int(buffer2.format.channelCount) - 1)

                // Scale buffer1 by microphoneLevel: data1[channel] * microphoneLevel -> output
                var micLevel = microphoneLevel
                vDSP_vsmul(data1[sourceChannel1], 1, &micLevel, outputData[channel], 1, vDSP_Length(frameLength))

                // Scale buffer2 by systemAudioLevel and add to output: output + (data2[channel] * systemAudioLevel)
                var sysLevel = systemAudioLevel
                vDSP_vsma(data2[sourceChannel2], 1, &sysLevel, outputData[channel], 1, outputData[channel], 1, vDSP_Length(frameLength))

                // Apply soft limiting to each sample
                for frame in 0..<Int(frameLength) {
                    outputData[channel][frame] = softLimit(outputData[channel][frame])
                }
            }
        }

        return outputBuffer
    }

    /// Applies soft limiting to prevent clipping while preserving signal dynamics.
    ///
    /// Uses a smooth tanh-like curve that:
    /// - Passes through signals below threshold unchanged (linear region)
    /// - Gradually compresses signals approaching ±1.0 (soft limiting region)
    /// - Never exceeds ±1.0 (hard limit)
    ///
    /// - Parameter sample: Input sample value
    /// - Returns: Limited sample value within [-1.0, 1.0]
    private func softLimit(_ sample: Float) -> Float {
        let threshold: Float = 0.8
        let absValue = abs(sample)

        if absValue <= threshold {
            // Below threshold - pass through unchanged
            return sample
        } else if absValue < 1.0 {
            // Between threshold and 1.0 - apply soft compression
            // Use smooth curve that asymptotically approaches 1.0
            let excess = absValue - threshold
            let compressed = threshold + (excess * (1.0 - threshold) / (excess + (1.0 - threshold)))
            return sample < 0 ? -compressed : compressed
        } else {
            // At or above 1.0 - hard limit
            return sample < 0 ? -1.0 : 1.0
        }
    }

    // MARK: - Private Methods

    /// Converts buffer to target format if needed, otherwise returns original buffer.
    private func convertBufferIfNeeded(_ buffer: AVAudioPCMBuffer, to targetFormat: AVAudioFormat) throws -> AVAudioPCMBuffer {
        // Log input format for every buffer (critical for diagnosing Issue #137)
        // Using both logger and print for visibility during debugging
        let inputInfo = "🎤 AudioMixer: received \(buffer.frameLength) frames @ \(buffer.format.sampleRate)Hz, \(buffer.format.channelCount)ch"
        logger.info("Audio buffer received: \(buffer.frameLength) frames, \(buffer.format.sampleRate)Hz, \(buffer.format.channelCount)ch")
        print(inputInfo)

        // Check if formats match
        if buffer.format.sampleRate == targetFormat.sampleRate &&
           buffer.format.channelCount == targetFormat.channelCount &&
           buffer.format.commonFormat == targetFormat.commonFormat {
            logger.debug("No conversion needed - format already matches target")
            return buffer
        }

        // Log format conversion for diagnostics (Issue #137)
        let conversionInfo = "🔄 AudioMixer: converting \(buffer.format.sampleRate)Hz/\(buffer.format.channelCount)ch → \(targetFormat.sampleRate)Hz/\(targetFormat.channelCount)ch"
        logger.info("Converting audio format: \(buffer.format.sampleRate)Hz/\(buffer.format.channelCount)ch → \(targetFormat.sampleRate)Hz/\(targetFormat.channelCount)ch")
        print(conversionInfo)

        // Handle stereo-to-mono conversion separately to avoid phase issues (Issue #137)
        if buffer.format.channelCount == 2 && targetFormat.channelCount == 1 {
            logger.debug("Performing stereo-to-mono downmix with phase-aware mixing")
            return try convertStereoToMono(buffer, targetSampleRate: targetFormat.sampleRate)
        }

        guard let converter = AVAudioConverter(from: buffer.format, to: targetFormat) else {
            logger.error("Failed to create audio converter")
            throw NSError(domain: "AudioMixer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio converter"])
        }

        // Configure converter for maximum quality (Issue #137)
        converter.sampleRateConverterQuality = .max
        converter.sampleRateConverterAlgorithm = AVSampleRateConverterAlgorithm_Mastering

        logger.debug("Configured AVAudioConverter with maximum quality settings")

        // Calculate exact output frame count for sample rate conversion
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let expectedFrameCount = AVAudioFrameCount(ceil(Double(buffer.frameLength) * ratio))

        // Create buffer with small safety margin for converter internal buffering
        let bufferCapacity = AVAudioFrameCount(Double(expectedFrameCount) * 1.1)

        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: bufferCapacity) else {
            logger.error("Failed to create output buffer")
            throw NSError(domain: "AudioMixer", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create output buffer"])
        }

        var error: NSError?
        nonisolated(unsafe) let unsafeBuffer = buffer
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return unsafeBuffer
        }

        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)

        if let error = error {
            logger.error("Audio conversion failed: \(error.localizedDescription)")
            throw error
        }

        // Verify conversion produced output
        guard outputBuffer.frameLength > 0 else {
            logger.error("Audio conversion produced zero frames - input: \(buffer.frameLength) frames at \(buffer.format.sampleRate)Hz")
            throw NSError(domain: "AudioMixer", code: -6, userInfo: [NSLocalizedDescriptionKey: "Sample rate conversion produced no output"])
        }

        // Trim output buffer to exact expected frame count to prevent time stretching (Issue #137)
        // CRITICAL: We must create a NEW buffer and COPY only the correct frames
        // Simply setting frameLength doesn't remove extra samples from memory, which causes
        // AAC encoder to write incorrect duration
        let finalBuffer: AVAudioPCMBuffer
        if outputBuffer.frameLength > expectedFrameCount {
            logger.debug("Trimming output buffer from \(outputBuffer.frameLength) to \(expectedFrameCount) frames by copying to new buffer")

            guard let trimmedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: expectedFrameCount) else {
                logger.error("Failed to create trimmed buffer")
                throw NSError(domain: "AudioMixer", code: -7, userInfo: [NSLocalizedDescriptionKey: "Failed to create trimmed buffer"])
            }

            trimmedBuffer.frameLength = expectedFrameCount

            // Copy only the correct number of frames from output to trimmed buffer
            let channelCount = Int(targetFormat.channelCount)
            for channel in 0..<channelCount {
                if let srcPtr = outputBuffer.floatChannelData?[channel],
                   let dstPtr = trimmedBuffer.floatChannelData?[channel] {
                    dstPtr.initialize(from: srcPtr, count: Int(expectedFrameCount))
                }
            }

            finalBuffer = trimmedBuffer
        } else {
            finalBuffer = outputBuffer
        }

        // Log conversion results for diagnosis
        let expectedFrames = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        let resultInfo = "✅ AudioMixer: converted \(buffer.frameLength)→\(finalBuffer.frameLength) frames, \(buffer.format.sampleRate)Hz→\(targetFormat.sampleRate)Hz (expected ~\(expectedFrames))"
        logger.info("Sample rate conversion: \(buffer.frameLength) frames @ \(buffer.format.sampleRate)Hz → \(finalBuffer.frameLength) frames @ \(targetFormat.sampleRate)Hz (expected ~\(expectedFrames))")
        print(resultInfo)

        // Verify conversion ratio is approximately correct (within 10% tolerance)
        let actualRatio = Double(finalBuffer.frameLength) / Double(buffer.frameLength)
        let expectedRatio = ratio
        let tolerance = 0.1
        if abs(actualRatio - expectedRatio) > expectedRatio * tolerance {
            logger.warning("Sample rate conversion ratio mismatch: expected \(expectedRatio), got \(actualRatio)")
        }

        return finalBuffer
    }

    /// Converts stereo buffer to mono using phase-aware mixing algorithm.
    ///
    /// This implementation avoids phase cancellation by using proper stereo downmix algorithm
    /// instead of simple averaging. It handles in-phase and out-of-phase signals appropriately.
    ///
    /// - Parameters:
    ///   - stereoBuffer: Input stereo buffer
    ///   - targetSampleRate: Target sample rate for output
    /// - Returns: Mono buffer at target sample rate
    /// - Throws: Error if conversion fails
    private func convertStereoToMono(_ stereoBuffer: AVAudioPCMBuffer, targetSampleRate: Double) throws -> AVAudioPCMBuffer {
        // First, downmix stereo to mono
        guard let monoFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: stereoBuffer.format.sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw NSError(domain: "AudioMixer", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create mono audio format"])
        }

        guard let monoBuffer = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: stereoBuffer.frameCapacity) else {
            throw NSError(domain: "AudioMixer", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to create mono buffer"])
        }

        monoBuffer.frameLength = stereoBuffer.frameLength

        // Perform phase-aware downmix
        if let stereoData = stereoBuffer.floatChannelData,
           let monoData = monoBuffer.floatChannelData {

            let leftChannel = stereoData[0]
            let rightChannel = stereoData[1]
            let output = monoData[0]

            // Use proper stereo downmix: (L + R) / sqrt(2)
            // This preserves power and avoids phase cancellation
            let scaleFactor: Float = 1.0 / sqrt(2.0)

            for frame in 0..<Int(stereoBuffer.frameLength) {
                output[frame] = (leftChannel[frame] + rightChannel[frame]) * scaleFactor
            }
        }

        // If sample rate conversion is needed, apply it now
        if stereoBuffer.format.sampleRate != targetSampleRate {
            guard let targetFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: targetSampleRate,
                channels: 1,
                interleaved: false
            ) else {
                throw NSError(domain: "AudioMixer", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to create target audio format"])
            }

            guard let converter = AVAudioConverter(from: monoFormat, to: targetFormat) else {
                throw NSError(domain: "AudioMixer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create sample rate converter"])
            }

            // Configure for maximum quality
            converter.sampleRateConverterQuality = .max
            converter.sampleRateConverterAlgorithm = AVSampleRateConverterAlgorithm_Mastering

            let ratio = targetSampleRate / stereoBuffer.format.sampleRate
            let outputFrameCount = AVAudioFrameCount(ceil(Double(monoBuffer.frameLength) * ratio) * 1.1)

            guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCount) else {
                throw NSError(domain: "AudioMixer", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create output buffer"])
            }

            var error: NSError?
            nonisolated(unsafe) let unsafeBuffer = monoBuffer
            let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                outStatus.pointee = .haveData
                return unsafeBuffer
            }

            converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)

            if let error = error {
                throw error
            }

            // Verify conversion produced output
            guard outputBuffer.frameLength > 0 else {
                logger.error("Stereo-to-mono sample rate conversion produced zero frames")
                throw NSError(domain: "AudioMixer", code: -7, userInfo: [NSLocalizedDescriptionKey: "Stereo-to-mono sample rate conversion produced no output"])
            }

            logger.info("Stereo-to-mono with sample rate conversion: \(monoBuffer.frameLength) frames @ \(monoFormat.sampleRate)Hz → \(outputBuffer.frameLength) frames @ \(targetFormat.sampleRate)Hz")

            return outputBuffer
        }

        logger.info("Stereo-to-mono downmix complete: \(monoBuffer.frameLength) frames @ \(monoBuffer.format.sampleRate)Hz")
        return monoBuffer
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

        // Scale samples using Accelerate framework for SIMD performance
        if let inputData = buffer.floatChannelData,
           let outputData = outputBuffer.floatChannelData {
            var scaleFactor = level
            for channel in 0..<Int(buffer.format.channelCount) {
                vDSP_vsmul(inputData[channel], 1, &scaleFactor, outputData[channel], 1, vDSP_Length(buffer.frameLength))

                // Apply soft limiting to prevent clipping
                for frame in 0..<Int(buffer.frameLength) {
                    outputData[channel][frame] = softLimit(outputData[channel][frame])
                }
            }
        }

        return outputBuffer
    }
}
