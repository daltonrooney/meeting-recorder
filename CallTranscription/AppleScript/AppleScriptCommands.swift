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

/// NSScriptCommand subclass for starting a recording.
@preconcurrency @objc(StartRecordingCommand)
final class StartRecordingCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        // Extract title parameter if provided
        let titleParam = evaluatedArguments?["title"] as? String
        let title = titleParam ?? "Untitled Recording"

        // Use semaphore to wait for async operation to complete
        let semaphore = DispatchSemaphore(value: 0)

        final class ResultBox: @unchecked Sendable {
            var success = false
            var error: Error?
        }
        let resultBox = ResultBox()

        // Execute on main thread safely
        executeOnMainThread {
            do {
                let appState = try AppStateContainer.shared.requireAppState()

                // Start recording and wait for completion
                Task { @MainActor in
                    do {
                        try await appState.startActualRecording(title: title)
                        resultBox.success = true
                    } catch {
                        resultBox.error = error
                    }
                    semaphore.signal()
                }
            } catch {
                resultBox.error = error
                semaphore.signal()
            }
        }

        // Wait for async operation (timeout after 10 seconds)
        _ = semaphore.wait(timeout: .now() + 10.0)

        if let error = resultBox.error {
            self.scriptErrorNumber = -1743 // errOSACantAccess
            self.scriptErrorString = error.localizedDescription
            return false
        }

        return resultBox.success
    }
}

/// NSScriptCommand subclass for stopping a recording.
@preconcurrency @objc(StopRecordingCommand)
final class StopRecordingCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        // Use a semaphore to safely bridge async/await with synchronous return
        let semaphore = DispatchSemaphore(value: 0)

        final class ResultBox: @unchecked Sendable {
            var path: String?
            var error: Error?
        }
        let resultBox = ResultBox()

        // Execute on main thread safely
        executeOnMainThread {
            do {
                let appState = try AppStateContainer.shared.requireAppState()

                Task { @MainActor in
                    do {
                        let transcriptURL = try await appState.stopActualRecording()
                        resultBox.path = transcriptURL.path
                    } catch {
                        resultBox.error = error
                    }
                    semaphore.signal()
                }
            } catch {
                resultBox.error = error
                semaphore.signal()
            }
        }

        // Wait for async operation (timeout after 10 seconds for transcription processing)
        _ = semaphore.wait(timeout: .now() + 10.0)

        if let error = resultBox.error {
            if let transcriptionError = error as? CallTranscriptionError, transcriptionError == .notRecording {
                self.scriptErrorNumber = -1728 // errAENoSuchObject
                self.scriptErrorString = "No recording session is currently active"
            } else {
                self.scriptErrorNumber = -1743 // errOSACantAccess
                self.scriptErrorString = error.localizedDescription
            }
            return nil
        }

        return resultBox.path
    }
}

/// NSScriptCommand subclass for getting recording status.
@preconcurrency @objc(GetStatusCommand)
final class GetStatusCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        final class ResultBox: @unchecked Sendable {
            var status: NSDictionary?
            var error: Error?
        }
        let resultBox = ResultBox()

        // Execute on main thread safely
        executeOnMainThread {
            do {
                let appState = try AppStateContainer.shared.requireAppState()

                resultBox.status = [
                    "isRecording": appState.isRecording,
                    "elapsedTime": appState.elapsedTime,
                    "isPaused": appState.isPaused
                ]
            } catch {
                resultBox.error = error
            }
        }

        if let error = resultBox.error {
            self.scriptErrorNumber = -1743 // errOSACantAccess
            self.scriptErrorString = error.localizedDescription
            return nil
        }

        return resultBox.status
    }
}
