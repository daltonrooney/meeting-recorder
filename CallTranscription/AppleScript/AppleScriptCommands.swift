import AppKit
import Foundation

/// NSScriptCommand subclass for starting a recording.
@preconcurrency @objc(StartRecordingCommand)
final class StartRecordingCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        // Extract title parameter if provided
        let titleParam = evaluatedArguments?["title"] as? String
        let title = titleParam ?? "Untitled Recording"

        // Execute on main thread synchronously
        DispatchQueue.main.sync {
            do {
                let appState = try AppStateContainer.shared.requireAppState()

                // Start recording asynchronously but don't wait for completion
                Task { @MainActor in
                    do {
                        try await appState.startActualRecording(title: title)
                    } catch {
                        print("AppleScript start recording error: \(error.localizedDescription)")
                    }
                }
            } catch {
                self.scriptErrorNumber = -1743 // errOSACantAccess
                self.scriptErrorString = error.localizedDescription
            }
        }

        return true
    }
}

/// NSScriptCommand subclass for stopping a recording.
@preconcurrency @objc(StopRecordingCommand)
final class StopRecordingCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        var result: String?
        var errorToSet: Error?

        let semaphore = DispatchSemaphore(value: 0)

        // Execute on main thread
        DispatchQueue.main.async {
            do {
                let appState = try AppStateContainer.shared.requireAppState()

                Task { @MainActor in
                    do {
                        let transcriptURL = try await appState.stopActualRecording()
                        result = transcriptURL.path
                    } catch {
                        errorToSet = error
                    }
                    semaphore.signal()
                }
            } catch {
                errorToSet = error
                semaphore.signal()
            }
        }

        // Wait for async operation (timeout after 5 seconds)
        _ = semaphore.wait(timeout: .now() + 5.0)

        if let error = errorToSet {
            if let transcriptionError = error as? CallTranscriptionError, transcriptionError == .notRecording {
                self.scriptErrorNumber = -1728 // errAENoSuchObject
                self.scriptErrorString = "No recording session is currently active"
            } else {
                self.scriptErrorNumber = -1743 // errOSACantAccess
                self.scriptErrorString = error.localizedDescription
            }
            return nil
        }

        return result
    }
}

/// NSScriptCommand subclass for getting recording status.
@preconcurrency @objc(GetStatusCommand)
final class GetStatusCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        var status: NSDictionary?

        // Execute on main thread synchronously
        DispatchQueue.main.sync {
            do {
                let appState = try AppStateContainer.shared.requireAppState()

                status = [
                    "isRecording": appState.isRecording,
                    "elapsedTime": appState.elapsedTime,
                    "isPaused": appState.isPaused
                ]
            } catch {
                self.scriptErrorNumber = -1743 // errOSACantAccess
                self.scriptErrorString = error.localizedDescription
            }
        }

        return status
    }
}
