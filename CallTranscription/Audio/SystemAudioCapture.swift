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
/// - Important: Requires macOS 14.2+ for future Core Audio tap support.
/// - Note: Process filtering parameters are accepted but not currently functional.
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
public final class SystemAudioCapture {

    // MARK: - Public Properties

    /// Callback handler for receiving audio buffers.
    /// Called on the audio rendering thread for each buffer.
    public var audioBufferHandler: ((AVAudioPCMBuffer) -> Void)?

    // MARK: - Private Properties

    private let audioEngine = AVAudioEngine()
    private var isCapturing = false
    private let bufferSize: AVAudioFrameCount = 1024  // Aligned with MicrophoneCapture
    private var aggregateDeviceID: AudioDeviceID?
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
        if let deviceID = aggregateDeviceID {
            destroyAggregateDevice(deviceID)
        }
    }

    // MARK: - Public Methods

    /// Starts capturing audio.
    ///
    /// **LIMITATION**: Currently captures microphone input, not system audio output.
    /// Process filtering is not yet implemented.
    ///
    /// - Parameters:
    ///   - excludingProcesses: Process IDs to exclude (NOT IMPLEMENTED - parameter ignored)
    ///   - includingProcesses: Process IDs to include (NOT IMPLEMENTED - parameter ignored)
    /// - Throws: `CallTranscriptionError.audioTapCreationFailed` if capture setup fails
    ///   or `CallTranscriptionError.microphonePermissionDenied` if permission not granted
    /// - Note: This method is idempotent - multiple calls are safe
    ///
    /// - Warning: Process filtering parameters are currently ignored. Providing these
    ///   parameters will log a warning but will not affect capture behavior.
    public func startCapture(excludingProcesses: [pid_t] = [], includingProcesses: [pid_t] = []) async throws {
        // Handle multiple start calls gracefully
        guard !isCapturing else {
            return
        }

        // Log warning if process filtering is requested (not yet implemented)
        if !excludingProcesses.isEmpty || !includingProcesses.isEmpty {
            logger.warning("Process filtering requested but not implemented. Parameters will be ignored.")
            logger.warning("excludingProcesses: \(excludingProcesses), includingProcesses: \(includingProcesses)")
        }

        // Check microphone permission (since we're currently using inputNode)
        let permission = await checkMicrophonePermission()
        guard permission else {
            throw CallTranscriptionError.microphonePermissionDenied
        }

        // Create aggregate device for audio capture
        // TODO: Replace with actual system audio tap implementation
        do {
            aggregateDeviceID = try createAggregateDevice()
        } catch let error as CallTranscriptionError {
            throw error
        } catch {
            let osStatus = (error as NSError).code
            throw CallTranscriptionError.audioTapCreationFailed(OSStatus(osStatus))
        }

        // Configure audio engine
        guard let deviceID = aggregateDeviceID else {
            throw CallTranscriptionError.audioTapCreationFailed(-2)
        }

        // Set up audio input tap
        // CURRENT BEHAVIOR: Uses inputNode (microphone)
        // FUTURE: Should tap system audio output via Core Audio Process Tap
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

        // Clean up aggregate device
        if let deviceID = aggregateDeviceID {
            destroyAggregateDevice(deviceID)
            aggregateDeviceID = nil
        }
    }

    // MARK: - Private Methods

    /// Checks microphone permission status.
    ///
    /// - Returns: `true` if permission is granted, `false` otherwise
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

    /// Creates or identifies an audio device for capture.
    ///
    /// - Returns: AudioDeviceID for the capture device
    /// - Throws: `CallTranscriptionError.audioTapCreationFailed` if device setup fails
    ///
    /// **CURRENT IMPLEMENTATION**: Returns default output device
    /// **FUTURE TODO**: Create actual aggregate device combining system output with loopback
    private func createAggregateDevice() throws -> AudioDeviceID {
        // Get default output device
        var deviceID = AudioDeviceID()
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)

        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceID
        )

        guard status == noErr else {
            throw CallTranscriptionError.audioTapCreationFailed(status)
        }

        // NOTE: This returns the default output device but doesn't actually
        // create an aggregate device or set up system audio tapping.
        // A complete implementation would:
        // 1. Create an aggregate device via Audio HAL
        // 2. Configure it to tap system audio output
        // 3. Set it as the audioEngine's input device
        // For now, audioEngine will use the default microphone input.

        return deviceID
    }

    /// Cleans up aggregate device resources.
    ///
    /// - Parameter deviceID: The device to clean up
    ///
    /// **FUTURE TODO**: Implement actual aggregate device destruction
    private func destroyAggregateDevice(_ deviceID: AudioDeviceID) {
        // Cleanup of aggregate device
        // Currently a no-op since we're using the default device
        // Future implementation should destroy the aggregate device via Audio HAL
    }
}
