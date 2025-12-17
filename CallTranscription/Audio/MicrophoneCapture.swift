import Foundation
import AVFoundation

/// Captures microphone audio using AVAudioEngine and delivers PCM buffers via callback.
///
/// MicrophoneCapture provides a simple interface for capturing microphone input
/// with low latency (1024 buffer size). Audio buffers are delivered asynchronously
/// via the `audioBufferHandler` closure.
///
/// - Important: This class is only available on macOS. On other platforms, permission
///   checks will always return false and capture will not function.
///
/// Example usage:
/// ```swift
/// let capture = MicrophoneCapture()
/// capture.audioBufferHandler = { buffer in
///     // Process audio buffer
/// }
/// try await capture.startCapture()
/// // ... later ...
/// await capture.stopCapture()
/// ```
public final class MicrophoneCapture {

    // MARK: - Public Properties

    /// Callback handler for receiving audio buffers.
    /// Called on the audio rendering thread for each buffer.
    public var audioBufferHandler: ((AVAudioPCMBuffer) -> Void)?

    // MARK: - Private Properties

    private let audioEngine = AVAudioEngine()
    private var isCapturing = false
    private let bufferSize: AVAudioFrameCount = 1024

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

    /// Starts capturing microphone audio.
    ///
    /// - Throws: `CallTranscriptionError.microphonePermissionDenied` if permission not granted
    /// - Note: This method is idempotent - multiple calls are safe
    public func startCapture() async throws {
        // Handle multiple start calls gracefully
        guard !isCapturing else {
            return
        }

        // Check microphone permission
        let permission = await checkMicrophonePermission()
        guard permission else {
            throw CallTranscriptionError.microphonePermissionDenied
        }

        // Get input node and format
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        // Install tap with specified buffer size
        // Capture handler to avoid race conditions with main thread
        let handler = audioBufferHandler
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { buffer, time in
            handler?(buffer)
        }

        // Start the audio engine
        do {
            try audioEngine.start()
            isCapturing = true
        } catch {
            // Clean up tap if engine failed to start
            inputNode.removeTap(onBus: 0)
            throw error
        }
    }

    /// Stops capturing microphone audio and cleans up resources.
    ///
    /// - Note: This method is idempotent - multiple calls are safe
    public func stopCapture() async {
        guard isCapturing else {
            return
        }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isCapturing = false
    }

    /// Pauses microphone capture without stopping the audio engine.
    ///
    /// Removes the audio tap to stop buffer delivery while keeping the engine running.
    /// This allows for quick resume without restarting the engine.
    ///
    /// - Note: This method is idempotent - multiple calls are safe
    public func pauseCapture() async {
        guard isCapturing else {
            return
        }

        // Remove tap but keep engine running
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    /// Resumes microphone capture after being paused.
    ///
    /// Reinstalls the audio tap to resume buffer delivery.
    ///
    /// - Note: This method is idempotent - multiple calls are safe
    public func resumeCapture() async {
        guard isCapturing else {
            return
        }

        // Check if tap already installed (already resumed)
        // Note: AVAudioEngine will throw if tap is already installed
        // We rely on try? to handle this gracefully
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        let handler = audioBufferHandler

        // Reinstall tap - if already installed, this will fail silently
        try? inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { buffer, time in
            handler?(buffer)
        }
    }

    // MARK: - Private Methods

    private func checkMicrophonePermission() async -> Bool {
        #if os(macOS)
        // macOS 14+ permission handling
        let status = AVCaptureDevice.authorizationStatus(for: .audio)

        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
        #else
        return false
        #endif
    }
}
