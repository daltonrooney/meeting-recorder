import Foundation
import OSLog

private let logger = Logger(subsystem: "dev.rygn.CallTranscription", category: "ShellScriptExecutor")

/// Result of a shell script execution.
public struct ShellScriptExecutionResult {
    /// The exit code returned by the script.
    public let exitCode: Int32

    /// Standard output captured from the script.
    public let standardOutput: String?

    /// Standard error captured from the script.
    public let standardError: String?

    /// Whether the script executed successfully (exit code 0).
    public var success: Bool {
        return exitCode == 0
    }
}

/// Executes user-defined shell scripts for post-recording automation.
///
/// This class provides functionality to execute bash scripts after recording completes,
/// passing the transcript file path as the first argument. It handles path expansion,
/// validation, timeout management, and captures script output.
@MainActor
public final class ShellScriptExecutor {

    /// Default timeout for script execution (5 minutes).
    public static let defaultTimeout: TimeInterval = 300.0

    public init() {}

    /// Executes a shell script with the given transcript path as argument.
    ///
    /// - Parameters:
    ///   - scriptPath: Path to the shell script to execute. Can use tilde (~) for home directory.
    ///                 If empty, this is a no-op that returns success.
    ///   - transcriptPath: Path to the transcript file to pass as first argument ($1).
    ///   - timeout: Maximum time to wait for script completion. Defaults to 5 minutes.
    ///
    /// - Returns: Result containing exit code and output from the script.
    ///
    /// - Throws:
    ///   - `CallTranscriptionError.postRecordingScriptNotFound` if script doesn't exist
    ///   - `CallTranscriptionError.postRecordingScriptNotExecutable` if script lacks execute permission
    ///   - `CallTranscriptionError.postRecordingScriptTimeout` if script exceeds timeout
    ///
    /// - Note: This method waits for the script to complete. Non-zero exit codes are logged
    ///         but do not throw - they return a result with the exit code for the caller to handle.
    public func execute(
        scriptPath: String,
        transcriptPath: String,
        timeout: TimeInterval = defaultTimeout
    ) async throws -> ShellScriptExecutionResult {

        // Handle empty script path as no-op
        if scriptPath.isEmpty {
            logger.info("No post-recording script configured, skipping")
            return ShellScriptExecutionResult(
                exitCode: 0,
                standardOutput: nil,
                standardError: nil
            )
        }

        // Expand tilde in script path
        let expandedScriptPath = NSString(string: scriptPath).expandingTildeInPath

        // Validate script exists
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: expandedScriptPath) else {
            logger.error("Post-recording script not found at path: \(expandedScriptPath)")
            throw CallTranscriptionError.postRecordingScriptNotFound(expandedScriptPath)
        }

        // Validate script is executable
        guard fileManager.isExecutableFile(atPath: expandedScriptPath) else {
            logger.error("Post-recording script is not executable: \(expandedScriptPath)")
            throw CallTranscriptionError.postRecordingScriptNotExecutable(expandedScriptPath)
        }

        logger.info("Executing post-recording script: \(expandedScriptPath)")
        logger.debug("Transcript path argument: \(transcriptPath)")

        // Create process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [expandedScriptPath, transcriptPath]

        // Set up pipes for capturing output
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        // Start the process
        do {
            try process.run()
        } catch {
            logger.error("Failed to start post-recording script: \(error.localizedDescription)")
            throw error
        }

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
                    // Force kill if still running
                    process.interrupt()
                }
                break
            }

            // Sleep briefly to avoid busy-waiting
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }

        if timedOut {
            logger.error("Post-recording script exceeded timeout of \(timeout) seconds")
            throw CallTranscriptionError.postRecordingScriptTimeout(timeout)
        }

        // Read output data
        let stdoutData = (try? stdoutPipe.fileHandleForReading.readToEnd()) ?? Data()
        let stderrData = (try? stderrPipe.fileHandleForReading.readToEnd()) ?? Data()

        // Get exit code
        let exitCode = process.terminationStatus

        // Convert output to strings
        let stdout = stdoutData.isEmpty ? nil : String(data: stdoutData, encoding: .utf8)
        let stderr = stderrData.isEmpty ? nil : String(data: stderrData, encoding: .utf8)

        // Log result
        if exitCode == 0 {
            logger.info("Post-recording script completed successfully")
        } else {
            logger.warning("Post-recording script exited with code \(exitCode)")
            if let stderr = stderr, !stderr.isEmpty {
                logger.warning("Script stderr: \(stderr)")
            }
        }

        return ShellScriptExecutionResult(
            exitCode: exitCode,
            standardOutput: stdout,
            standardError: stderr
        )
    }
}
