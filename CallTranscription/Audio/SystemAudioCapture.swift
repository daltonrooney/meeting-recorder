import Foundation
import AVFoundation
import CoreAudio
import OSLog

/// Captures audio input using AVAudioEngine (placeholder for future system audio capture).
///
/// **IMPORTANT LIMITATION**: This current implementation captures audio from the microphone
/// input (similar to MicrophoneCapture), NOT actual system audio output. True system audio
/// capture would require implementing Core Audio Process Taps using the
/// `AudioHardwareCreateProcessTap` API, which is not yet implemented.
///
/// This class provides the API surface and infrastructure for future system audio capture
/// functionality while currently serving as a microphone capture mechanism.
///
/// **TODO: CLASS NAMING ISSUE** - This class should either:
/// - Be renamed to reflect actual behavior (e.g., `MicrophoneCapturePlus`)
/// - Implement actual Core Audio Process Tap for system audio
/// - Be removed until proper implementation is ready
///
/// - Important: Requires macOS 14.2+ for future Core Audio tap support.
/// - Note: Process filtering parameters will throw an error if used (not implemented).
///
/// Example usage:
/// ```swift
/// let capture = SystemAudioCapture()
/// capture.audioBufferHandler = { buffer in
///     // Process audio buffer
/// }
/// try await capture.startCapture()
/// // ... later ...
/// await capture.stopCapture()
/// ```
@available(macOS 14.0, *)
public final class SystemAudioCapture {

    // MARK: - Public Properties

    /// Callback handler for receiving audio buffers.
    /// Called on the audio rendering thread for each buffer.
    public var audioBufferHandler: ((AVAudioPCMBuffer) -> Void)?

    /// Indicates whether audio capture is currently paused.
    /// `true` when pauseCapture() has been called, `false` when active or stopped.
    public private(set) var isPaused = false

    // MARK: - Private Properties

    private let audioEngine = AVAudioEngine()
    private var isCapturing = false
    private let bufferSize: AVAudioFrameCount = 1024  // Aligned with MicrophoneCapture
    private let logger = Logger(subsystem: "dev.rygn.CallTranscription", category: "SystemAudioCapture")

    // MARK: - Initialization

    public init() {
        // Engine created in property initializer
    }

    deinit {
        // Clean up synchronously if still capturing
        if isCapturing {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
    }

    // MARK: - Public Methods

    /// Starts capturing audio.
    ///
    /// **LIMITATION**: Currently captures microphone input, not system audio output.
    ///
    /// - Parameters:
    ///   - excludingProcesses: Process IDs to exclude (NOT IMPLEMENTED - throws error if non-empty)
    ///   - includingProcesses: Process IDs to include (NOT IMPLEMENTED - throws error if non-empty)
    /// - Throws: `CallTranscriptionError.featureNotImplemented` if process filtering requested,
    ///   `CallTranscriptionError.audioTapCreationFailed` if capture setup fails,
    ///   or `CallTranscriptionError.microphonePermissionDenied` if permission not granted
    /// - Note: This method is idempotent - multiple calls are safe
    public func startCapture(excludingProcesses: [pid_t] = [], includingProcesses: [pid_t] = []) async throws {
        // Handle multiple start calls gracefully
        guard !isCapturing else {
            return
        }

        // Reject process filtering (not yet implemented)
        if !excludingProcesses.isEmpty || !includingProcesses.isEmpty {
            logger.error("Process filtering requested but not implemented")
            throw CallTranscriptionError.featureNotImplemented("Process filtering")
        }

        // Check microphone permission using shared handler (since we're currently using inputNode)
        try await MicrophonePermissionHandler().ensurePermission()

        // Set up audio input tap
        // CURRENT BEHAVIOR: Uses inputNode (microphone)
        // FUTURE TODO: Should tap system audio output via Core Audio Process Tap
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        // Install tap with specified buffer size
        let handler = audioBufferHandler
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { buffer, time in
            handler?(buffer)
        }

        // Start the audio engine
        do {
            try audioEngine.start()
            isCapturing = true
        } catch {
            inputNode.removeTap(onBus: 0)
            // Preserve the actual OSStatus from AVAudioEngine
            let osStatus = (error as NSError).code
            throw CallTranscriptionError.audioTapCreationFailed(OSStatus(osStatus))
        }
    }

    /// Stops capturing audio and cleans up resources.
    ///
    /// - Note: This method is idempotent - multiple calls are safe
    public func stopCapture() async {
        guard isCapturing else {
            return
        }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isCapturing = false
        isPaused = false
    }

    /// Pauses audio capture without stopping the audio engine.
    ///
    /// Removes the audio tap to stop buffer delivery while keeping the engine running.
    /// This allows for quick resume without restarting the engine.
    ///
    /// - Note: This method is idempotent - multiple calls are safe
    public func pauseCapture() async {
        guard isCapturing else {
            return
        }

        logger.debug("Pausing audio capture")
        // Remove tap but keep engine running
        audioEngine.inputNode.removeTap(onBus: 0)
        isPaused = true
    }

    /// Resumes audio capture after being paused.
    ///
    /// Reinstalls the audio tap to resume buffer delivery.
    ///
    /// - Note: This method is idempotent - multiple calls are safe
    public func resumeCapture() async {
        guard isCapturing else {
            return
        }

        logger.debug("Resuming audio capture")

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        let handler = audioBufferHandler

        // User called resume, so mark as no longer paused regardless of tap installation success
        // This reflects user intent and avoids inconsistent state
        isPaused = false

        // Reinstall tap
        // Note: This may fail if tap is already installed (expected during idempotent calls)
        // or due to other issues (format mismatch, resource exhaustion) which we log
        do {
            try inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { buffer, time in
                handler?(buffer)
            }
        } catch {
            // Log the error but don't throw - this is a best-effort operation
            // Most common case: tap already installed (idempotent call)
            logger.debug("Failed to reinstall tap during resume: \(error.localizedDescription)")
        }
    }

}
