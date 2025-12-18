import Foundation
import AVFoundation

/// Detects periods of silence in audio streams and triggers callbacks when thresholds are exceeded.
///
/// SilenceDetector processes audio buffers continuously and tracks:
/// - Duration of continuous silence
/// - When silence threshold from settings is exceeded
/// - When audio resumes after silence
///
/// The detector is stateful and maintains silence duration across buffer calls.
/// It triggers callbacks only on state transitions (not repeatedly).
///
/// Example usage:
/// ```swift
/// let detector = SilenceDetector(threshold: .twoMinutes, silenceDBThreshold: -40.0)
///
/// detector.onSilenceThresholdExceeded = {
///     // Trigger auto-pause
/// }
///
/// detector.onAudioDetectedAfterSilence = {
///     // Trigger auto-resume
/// }
///
/// // In audio callback:
/// detector.processAudioBuffer(buffer)
/// ```
public final class SilenceDetector {

    // MARK: - Public Properties

    /// Current duration of continuous silence in seconds.
    public private(set) var currentSilenceDuration: TimeInterval = 0.0

    /// Threshold duration in seconds (nil for .never).
    public var thresholdSeconds: TimeInterval?

    /// Callback fired once when silence threshold is exceeded.
    public var onSilenceThresholdExceeded: (@Sendable () -> Void)?

    /// Callback fired once when audio is detected after a period of silence.
    public var onAudioDetectedAfterSilence: (@Sendable () -> Void)?

    // MARK: - Private Properties

    private let silenceDBThreshold: Float
    private var hasTriggeredSilenceCallback = false
    private var wasInSilence = false
    private let lock = NSLock()

    // MARK: - Initialization

    /// Creates a new silence detector.
    ///
    /// - Parameters:
    ///   - threshold: Silence pause threshold from settings
    ///   - silenceDBThreshold: dB level below which audio is considered silent (default: -40.0)
    ///     -40 dB is industry standard for room silence detection
    public init(threshold: SilencePauseThreshold, silenceDBThreshold: Float = -40.0) {
        self.thresholdSeconds = threshold.timeInterval
        self.silenceDBThreshold = silenceDBThreshold
    }

    // MARK: - Public Methods

    /// Processes an audio buffer and updates silence detection state.
    ///
    /// This method should be called for each audio buffer in the stream.
    /// It updates silence duration and fires callbacks on state transitions.
    ///
    /// - Parameter buffer: The audio buffer to analyze
    public func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        defer { lock.unlock() }

        // Analyze buffer
        let isSilent = AudioLevelAnalyzer.isSilent(buffer, threshold: silenceDBThreshold)

        // Calculate buffer duration from actual sample rate
        // Extract sample rate from buffer format instead of hardcoding
        let bufferDuration = Double(buffer.frameLength) / buffer.format.sampleRate

        if isSilent {
            // Accumulate silence duration
            currentSilenceDuration += bufferDuration

            // Check if we've exceeded the threshold
            if let thresholdSecs = thresholdSeconds,
               currentSilenceDuration >= thresholdSecs,
               !hasTriggeredSilenceCallback {
                hasTriggeredSilenceCallback = true
                // Fire callback asynchronously to avoid blocking audio thread
                let callback = onSilenceThresholdExceeded
                DispatchQueue.main.async {
                    callback?()
                }
            }

            wasInSilence = true
        } else {
            // Audio detected
            let hadSilence = wasInSilence && currentSilenceDuration > 0

            // Reset silence tracking
            currentSilenceDuration = 0.0
            hasTriggeredSilenceCallback = false
            wasInSilence = false

            // Fire audio detected callback if we were in silence
            if hadSilence {
                let callback = onAudioDetectedAfterSilence
                DispatchQueue.main.async {
                    callback?()
                }
            }
        }
    }

    /// Resets the detector state.
    ///
    /// Clears accumulated silence duration and callback trigger state.
    /// Use this when starting a new recording session or when manually pausing.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }

        currentSilenceDuration = 0.0
        hasTriggeredSilenceCallback = false
        wasInSilence = false
    }
}
