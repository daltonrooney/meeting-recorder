import Foundation
import OSLog

private let logger = Logger(subsystem: "dev.rygn.CallTranscription", category: "ShortcutExecutor")

/// Result of a shortcut execution.
public struct ShortcutExecutionResult {
    /// Whether the shortcut executed successfully.
    public let success: Bool

    /// Error message if execution failed.
    public let errorMessage: String?

    /// Output from the shortcut, if any.
    public let output: String?
}

/// Executes macOS Shortcuts for post-recording automation.
///
/// This class provides functionality to enumerate available shortcuts and execute them
/// after recording completes, passing the transcript file path as input.
@MainActor
public final class ShortcutExecutor {

    /// Default timeout for shortcut execution (5 minutes).
    public static let defaultTimeout: TimeInterval = 300.0

    public init() {}

    /// Retrieves a list of available shortcut names from the system.
    ///
    /// - Returns: Array of shortcut names that can be executed.
    ///
    /// - Note: Uses the `shortcuts` command-line tool available in macOS 12+.
    public func listAvailableShortcuts() async -> [String] {
        logger.debug("Listing available shortcuts")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["list"]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            // Parse shortcut names (one per line)
            let shortcuts = output
                .split(separator: "\n")
                .map { String($0).trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            logger.info("Found \(shortcuts.count) shortcuts")
            return shortcuts
        } catch {
            logger.error("Failed to list shortcuts: \(error.localizedDescription)")
            return []
        }
    }

    /// Executes a macOS shortcut with the given transcript path as input.
    ///
    /// - Parameters:
    ///   - shortcutName: Name of the shortcut to execute.
    ///   - transcriptPath: Path to the transcript file to pass as input.
    ///   - timeout: Maximum time to wait for shortcut completion. Defaults to 5 minutes.
    ///
    /// - Returns: Result containing success status and any output or errors.
    ///
    /// - Note: If shortcut name is empty, this is a no-op that returns success.
    public func execute(
        shortcutName: String,
        transcriptPath: String,
        timeout: TimeInterval = defaultTimeout
    ) async -> ShortcutExecutionResult {

        // Handle empty shortcut name as no-op
        if shortcutName.isEmpty {
            logger.info("No shortcut configured, skipping")
            return ShortcutExecutionResult(
                success: true,
                errorMessage: nil,
                output: nil
            )
        }

        logger.info("Executing shortcut: \(shortcutName)")
        logger.debug("Transcript path input: \(transcriptPath)")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["run", shortcutName, "--input-path", transcriptPath]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()

            // Wait for completion with timeout
            let startTime = Date()
            var timedOut = false

            while process.isRunning {
                if Date().timeIntervalSince(startTime) > timeout {
                    timedOut = true
                    process.terminate()

                    // Give it a moment to terminate gracefully
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

                    if process.isRunning {
                        process.interrupt()
                    }
                    break
                }

                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }

            if timedOut {
                logger.error("Shortcut exceeded timeout of \(timeout) seconds")
                return ShortcutExecutionResult(
                    success: false,
                    errorMessage: "Shortcut timed out after \(timeout) seconds",
                    output: nil
                )
            }

            // Read output
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            let output = outputData.isEmpty ? nil : String(data: outputData, encoding: .utf8)
            let errorOutput = errorData.isEmpty ? nil : String(data: errorData, encoding: .utf8)

            let exitCode = process.terminationStatus
            let success = exitCode == 0

            if success {
                logger.info("Shortcut completed successfully")
            } else {
                logger.warning("Shortcut exited with code \(exitCode)")
                if let errorOutput = errorOutput {
                    logger.warning("Shortcut error: \(errorOutput)")
                }
            }

            return ShortcutExecutionResult(
                success: success,
                errorMessage: success ? nil : (errorOutput ?? "Unknown error"),
                output: output
            )
        } catch {
            logger.error("Failed to execute shortcut: \(error.localizedDescription)")
            return ShortcutExecutionResult(
                success: false,
                errorMessage: error.localizedDescription,
                output: nil
            )
        }
    }
}
