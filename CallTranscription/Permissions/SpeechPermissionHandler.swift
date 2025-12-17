import Foundation
import Speech

/// Handles speech recognition permissions and model management.
///
/// This class provides utilities for:
/// - Checking and requesting speech recognition authorization
/// - Verifying locale support for speech recognition
/// - Checking model availability and initiating downloads
/// - Ensuring all requirements are met before transcription
///
/// **Thread Safety**: This class is marked `@MainActor` because `SFSpeechRecognizer`
/// requires main thread access for authorization requests and some configuration operations.
/// All public methods must be called from the main actor context.
@available(macOS 26.0, *)
@MainActor
public final class SpeechPermissionHandler {
    private let locale: Locale
    private var speechRecognizer: SFSpeechRecognizer?

    /// Creates a speech permission handler with the specified locale.
    ///
    /// - Parameter locale: The locale for speech recognition. Defaults to current locale.
    public init(locale: Locale = .current) {
        self.locale = locale
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    // MARK: - Authorization

    /// Checks the current speech recognition authorization status.
    ///
    /// - Returns: The current authorization status.
    public func checkAuthorizationStatus() async -> SFSpeechRecognizerAuthorizationStatus {
        return SFSpeechRecognizer.authorizationStatus()
    }

    /// Requests speech recognition permission from the user.
    ///
    /// Only requests permission if the status is `.notDetermined`.
    /// For other states, returns the current status without requesting.
    ///
    /// - Returns: The authorization status after the request.
    public func requestPermission() async -> SFSpeechRecognizerAuthorizationStatus {
        let currentStatus = SFSpeechRecognizer.authorizationStatus()

        // Only request if not determined
        guard currentStatus == .notDetermined else {
            return currentStatus
        }

        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    /// Ensures speech recognition permission is granted.
    ///
    /// Automatically requests permission if not yet determined.
    /// Throws an error if permission is denied or restricted.
    ///
    /// - Throws: `CallTranscriptionError.speechRecognitionUnavailable` if permission denied or restricted.
    public func ensurePermission() async throws {
        let status = await requestPermission()

        switch status {
        case .authorized:
            return
        case .denied, .restricted, .notDetermined:
            throw CallTranscriptionError.speechRecognitionUnavailable
        @unknown default:
            throw CallTranscriptionError.speechRecognitionUnavailable
        }
    }

    // MARK: - Locale Support

    /// Checks if the configured locale is supported for speech recognition.
    ///
    /// - Returns: `true` if the locale is supported, `false` otherwise.
    public func checkLocaleSupport() async -> Bool {
        guard let recognizer = speechRecognizer else {
            return false
        }
        return recognizer.isAvailable
    }

    // MARK: - Model Availability

    /// Checks if the speech recognition model is available for the configured locale.
    ///
    /// - Returns: `true` if the model is installed and available, `false` otherwise.
    public func checkModelAvailability() async -> Bool {
        // First verify locale is supported
        guard await checkLocaleSupport() else {
            return false
        }

        guard let recognizer = speechRecognizer else {
            return false
        }

        // Check if recognizer is available (implies model is present)
        return recognizer.isAvailable
    }

    /// Waits for the speech recognition model to become available for the configured locale.
    ///
    /// Returns immediately if the model is already available.
    /// Waits up to 5 seconds for the model to become available.
    ///
    /// **Note**: On macOS 26.0+, speech recognition models are downloaded automatically by the system
    /// when first needed. This method cannot programmatically trigger downloads; it only waits for
    /// availability. If the model is not available after the timeout, users must download it manually
    /// via System Settings > General > Keyboard > Dictation, or by using any system speech recognition
    /// feature for the first time.
    ///
    /// - Throws: `CallTranscriptionError.localeNotSupported` if locale is not supported.
    /// - Throws: `CallTranscriptionError.speechRecognitionUnavailable` if model unavailable after timeout.
    public func downloadModel() async throws {
        // Check if locale is supported
        guard await checkLocaleSupport() else {
            throw CallTranscriptionError.localeNotSupported(locale)
        }

        // Check if model is already available
        if await checkModelAvailability() {
            return
        }

        guard let recognizer = speechRecognizer else {
            throw CallTranscriptionError.localeNotSupported(locale)
        }

        // Wait up to 5 seconds for the recognizer to become available
        // The system may be downloading the model in the background
        let maxAttempts = 50  // 50 attempts × 100ms = 5 seconds total
        for _ in 0..<maxAttempts {
            if recognizer.isAvailable {
                return
            }
            try await Task.sleep(for: .milliseconds(100))
        }

        // If still not available after 5 seconds, the model needs manual download
        throw CallTranscriptionError.speechRecognitionUnavailable
    }

    /// Ensures the speech recognition model is available for the configured locale.
    ///
    /// This is a convenience method that combines permission check, locale verification,
    /// and model availability check.
    ///
    /// - Throws: `CallTranscriptionError.speechRecognitionUnavailable` if permission denied.
    /// - Throws: `CallTranscriptionError.localeNotSupported` if locale not supported.
    /// - Throws: `CallTranscriptionError.speechRecognitionUnavailable` if model unavailable.
    public func ensureModelAvailable() async throws {
        // First ensure we have permission
        try await ensurePermission()

        // Check locale support
        guard await checkLocaleSupport() else {
            throw CallTranscriptionError.localeNotSupported(locale)
        }

        // Ensure model is available
        try await downloadModel()
    }

    // MARK: - On-Device Recognition

    /// Checks if on-device speech recognition is supported for the configured locale.
    ///
    /// - Returns: `true` if on-device recognition is available, `false` otherwise.
    public func supportsOnDeviceRecognition() async -> Bool {
        guard let recognizer = speechRecognizer else {
            return false
        }

        // On macOS 26.0+, check if recognizer supports on-device recognition
        return recognizer.supportsOnDeviceRecognition
    }
}
