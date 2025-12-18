import AppKit
import Foundation

/// Helper function to safely execute code on main thread, avoiding deadlock.
/// If already on main thread, uses MainActor.assumeIsolated. Otherwise uses DispatchQueue.main.sync.
private func executeOnMainThread<T: Sendable>(_ block: @MainActor () -> T) -> T {
    if Thread.isMainThread {
        return MainActor.assumeIsolated(block)
    } else {
        return DispatchQueue.main.sync {
            MainActor.assumeIsolated(block)
        }
    }
}

/// Extension to NSApplication to provide AppleScript access to app properties.
///
/// This extension makes AppState properties accessible via AppleScript,
/// allowing scripts to query recording state, elapsed time, and settings.
extension NSApplication {

    // MARK: - Recording State Properties

    /// AppleScript accessor for isRecording property
    @objc var isRecording: Bool {
        final class ResultBox { var value = false }
        let box = ResultBox()
        executeOnMainThread {
            guard let appState = try? AppStateContainer.shared.requireAppState() else {
                return
            }
            box.value = appState.isRecording
        }
        return box.value
    }

    /// AppleScript accessor for elapsedTime property
    @objc var elapsedTime: String {
        final class ResultBox { var value = "00:00" }
        let box = ResultBox()
        executeOnMainThread {
            guard let appState = try? AppStateContainer.shared.requireAppState() else {
                return
            }
            box.value = appState.elapsedTime
        }
        return box.value
    }

    /// AppleScript accessor for isPaused property
    @objc var isPaused: Bool {
        final class ResultBox { var value = false }
        let box = ResultBox()
        executeOnMainThread {
            guard let appState = try? AppStateContainer.shared.requireAppState() else {
                return
            }
            box.value = appState.isPaused
        }
        return box.value
    }

    // MARK: - Settings Properties

    /// AppleScript accessor for outputFolder property
    @objc var outputFolder: String {
        get {
            final class ResultBox { var value = "~/Desktop/Transcripts" }
            let box = ResultBox()
            executeOnMainThread {
                guard let settingsManager = try? AppStateContainer.shared.requireSettingsManager() else {
                    return
                }
                box.value = settingsManager.outputFolder
            }
            return box.value
        }
        set {
            executeOnMainThread {
                guard let settingsManager = try? AppStateContainer.shared.requireSettingsManager() else {
                    NSLog("AppleScript: Failed to set outputFolder - SettingsManager not available")
                    return
                }
                settingsManager.outputFolder = newValue
            }
        }
    }

    /// AppleScript accessor for captureMicrophone property
    @objc var captureMicrophone: Bool {
        get {
            final class ResultBox { var value = true }
            let box = ResultBox()
            executeOnMainThread {
                guard let settingsManager = try? AppStateContainer.shared.requireSettingsManager() else {
                    return
                }
                box.value = settingsManager.captureMicrophone
            }
            return box.value
        }
        set {
            executeOnMainThread {
                guard let settingsManager = try? AppStateContainer.shared.requireSettingsManager() else {
                    NSLog("AppleScript: Failed to set captureMicrophone - SettingsManager not available")
                    return
                }
                settingsManager.captureMicrophone = newValue
            }
        }
    }

    /// AppleScript accessor for captureSystemAudio property
    @objc var captureSystemAudio: Bool {
        get {
            final class ResultBox { var value = true }
            let box = ResultBox()
            executeOnMainThread {
                guard let settingsManager = try? AppStateContainer.shared.requireSettingsManager() else {
                    return
                }
                box.value = settingsManager.captureSystemAudio
            }
            return box.value
        }
        set {
            executeOnMainThread {
                guard let settingsManager = try? AppStateContainer.shared.requireSettingsManager() else {
                    NSLog("AppleScript: Failed to set captureSystemAudio - SettingsManager not available")
                    return
                }
                settingsManager.captureSystemAudio = newValue
            }
        }
    }
}
