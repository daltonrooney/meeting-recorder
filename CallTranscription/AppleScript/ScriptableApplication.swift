import AppKit
import Foundation

/// Extension to NSApplication to provide AppleScript access to app properties.
///
/// This extension makes AppState properties accessible via AppleScript,
/// allowing scripts to query recording state, elapsed time, and settings.
extension NSApplication {

    // MARK: - Recording State Properties

    /// AppleScript accessor for isRecording property
    @objc var isRecording: Bool {
        var result = false
        DispatchQueue.main.sync {
            guard let appState = try? AppStateContainer.shared.requireAppState() else {
                return
            }
            result = appState.isRecording
        }
        return result
    }

    /// AppleScript accessor for elapsedTime property
    @objc var elapsedTime: String {
        var result = "00:00"
        DispatchQueue.main.sync {
            guard let appState = try? AppStateContainer.shared.requireAppState() else {
                return
            }
            result = appState.elapsedTime
        }
        return result
    }

    /// AppleScript accessor for isPaused property
    @objc var isPaused: Bool {
        var result = false
        DispatchQueue.main.sync {
            guard let appState = try? AppStateContainer.shared.requireAppState() else {
                return
            }
            result = appState.isPaused
        }
        return result
    }

    // MARK: - Settings Properties

    /// AppleScript accessor for outputFolder property
    @objc var outputFolder: String {
        get {
            var result = "~/Desktop/Transcripts"
            DispatchQueue.main.sync {
                guard let settingsManager = try? AppStateContainer.shared.requireSettingsManager() else {
                    return
                }
                result = settingsManager.outputFolder
            }
            return result
        }
        set {
            DispatchQueue.main.async {
                guard let settingsManager = try? AppStateContainer.shared.requireSettingsManager() else {
                    return
                }
                settingsManager.outputFolder = newValue
            }
        }
    }

    /// AppleScript accessor for captureMicrophone property
    @objc var captureMicrophone: Bool {
        get {
            var result = true
            DispatchQueue.main.sync {
                guard let settingsManager = try? AppStateContainer.shared.requireSettingsManager() else {
                    return
                }
                result = settingsManager.captureMicrophone
            }
            return result
        }
        set {
            DispatchQueue.main.async {
                guard let settingsManager = try? AppStateContainer.shared.requireSettingsManager() else {
                    return
                }
                settingsManager.captureMicrophone = newValue
            }
        }
    }

    /// AppleScript accessor for captureSystemAudio property
    @objc var captureSystemAudio: Bool {
        get {
            var result = true
            DispatchQueue.main.sync {
                guard let settingsManager = try? AppStateContainer.shared.requireSettingsManager() else {
                    return
                }
                result = settingsManager.captureSystemAudio
            }
            return result
        }
        set {
            DispatchQueue.main.async {
                guard let settingsManager = try? AppStateContainer.shared.requireSettingsManager() else {
                    return
                }
                settingsManager.captureSystemAudio = newValue
            }
        }
    }
}
