import Foundation
import AVFoundation
import AppKit

/// Handles microphone permissions and system settings integration.
///
/// This class provides utilities for:
/// - Checking and requesting microphone authorization
/// - Validating permission status before audio capture
/// - Directing users to System Settings when permission denied
/// - Opening System Settings programmatically
///
/// **Thread Safety**: This class is marked `@MainActor` because permission
/// requests may trigger UI (permission dialogs) and System Settings opening
/// requires main thread access. All public methods must be called from the
/// main actor context.
@available(macOS 14.0, *)
@MainActor
public final class MicrophonePermissionHandler {

    /// Creates a microphone permission handler.
    public init() {}

    // MARK: - Authorization

    /// Checks the current microphone authorization status.
    ///
    /// - Returns: The current authorization status for audio capture.
    public func checkAuthorizationStatus() async -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .audio)
    }

    /// Requests microphone permission from the user.
    ///
    /// Only requests permission if the status is `.notDetermined`.
    /// For other states, returns the current status without requesting.
    ///
    /// - Returns: The authorization status after the request.
    public func requestPermission() async -> AVAuthorizationStatus {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .audio)

        // Only request if not determined
        guard currentStatus == .notDetermined else {
            return currentStatus
        }

        // Request permission and return the result
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        return granted ? .authorized : .denied
    }

    /// Ensures microphone permission is granted.
    ///
    /// Automatically requests permission if not yet determined.
    /// Throws an error if permission is denied or restricted.
    ///
    /// **Note**: The `.notDetermined` case is included in the error cases because after calling
    /// `requestPermission()`, the status should only be `.notDetermined` if the user dismissed
    /// the permission dialog without choosing. This is treated as a denial for app functionality.
    ///
    /// - Throws: `CallTranscriptionError.microphonePermissionDenied` if permission denied or restricted.
    public func ensurePermission() async throws {
        let status = await requestPermission()

        switch status {
        case .authorized:
            return
        case .denied, .restricted, .notDetermined:
            // .notDetermined should not occur after requestPermission(), but if it does,
            // treat it as denied since the user didn't explicitly grant permission
            throw CallTranscriptionError.microphonePermissionDenied
        @unknown default:
            throw CallTranscriptionError.microphonePermissionDenied
        }
    }

    // MARK: - System Settings Integration

    /// Gets the URL for opening System Settings to the Microphone privacy pane.
    ///
    /// - Returns: The URL to open System Settings, or `nil` if unavailable.
    public func getSystemSettingsURL() -> URL? {
        // macOS 13+ uses x-apple.systemsettings, earlier versions use x-apple.systempreferences
        // Privacy & Security > Microphone
        if #available(macOS 13.0, *) {
            return URL(string: "x-apple.systemsettings:com.apple.preference.security?Privacy_Microphone")
        } else {
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
        }
    }

    /// Opens System Settings to the Microphone privacy pane.
    ///
    /// This method attempts to open System Settings to the relevant privacy settings
    /// where the user can grant microphone access to the application.
    public func openSystemSettings() {
        guard let settingsURL = getSystemSettingsURL() else {
            return
        }

        NSWorkspace.shared.open(settingsURL)
    }
}
