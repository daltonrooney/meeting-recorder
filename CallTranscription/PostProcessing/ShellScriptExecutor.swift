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

    private let pathValidator = PathValidator()
    private let bookmarkManager = SecurityScopedBookmarkManager()

    public init() {}

    /// Executes a shell script with the given transcript path as argument.
    ///
    /// - Parameters:
    ///   - scriptPath: Path to the shell script to execute. Can use tilde (~) for home directory.
    ///                 If empty, this is a no-op that returns success.
    ///   - transcriptPath: Path to the transcript file to pass as first argument ($1).
    ///   - scriptBookmark: Optional security-scoped bookmark for script directory access.
    ///                     If provided, enables sandboxed access to scripts outside app container.
    ///                     Falls back to normal path validation if bookmark resolution fails.
    ///   - timeout: Maximum time to wait for script completion. Defaults to 5 minutes.
    ///
    /// - Returns: Result containing exit code and output from the script.
    ///
    /// - Throws:
    ///   - `CallTranscriptionError.postRecordingScriptNotFound` if script doesn't exist
    ///   - `CallTranscriptionError.postRecordingScriptNotExecutable` if script lacks execute permission
    ///   - `CallTranscriptionError.postRecordingScriptTimeout` if script exceeds timeout
    ///   - Security errors if script path is outside allowed directories or contains traversal attacks
    ///
    /// - Note: This method waits for the script to complete. Non-zero exit codes are logged
    ///         but do not throw - they return a result with the exit code for the caller to handle.
    public func execute(
        scriptPath: String,
        transcriptPath: String,
        scriptBookmark: Data? = nil,
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

        // Try to use security-scoped bookmark if provided
        var securityScopedURL: URL?
        if let bookmarkData = scriptBookmark {
            do {
                let url = try bookmarkManager.resolveBookmark(bookmarkData)
                guard url.startAccessingSecurityScopedResource() else {
                    logger.warning("Failed to start accessing security-scoped resource for script, falling back to path validation")
                    throw CallTranscriptionError.securityScopedAccessFailed(url.path)
                }
                securityScopedURL = url
                logger.debug("Using security-scoped bookmark for script access")
            } catch {
                logger.warning("Failed to resolve script bookmark, falling back to path validation: \(error.localizedDescription)")
                // Continue with normal path validation as fallback
            }
        }

        // Clean up security-scoped resource on function exit
        defer {
            if let url = securityScopedURL {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // Validate script path for security
        // Ensures script is within allowed directories (user home) and prevents path traversal/symlink attacks
        let validatedScriptURL = try pathValidator.validateForScriptExecution(path: expandedScriptPath)
        let validatedScriptPath = validatedScriptURL.path
        logger.debug("Script path validated: \(validatedScriptPath)")

        // Validate script exists
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: validatedScriptPath) else {
            logger.error("Post-recording script not found at path: \(validatedScriptPath)")
            throw CallTranscriptionError.postRecordingScriptNotFound(validatedScriptPath)
        }

        // Validate script is executable
        guard fileManager.isExecutableFile(atPath: validatedScriptPath) else {
            logger.error("Post-recording script is not executable: \(validatedScriptPath)")
            throw CallTranscriptionError.postRecordingScriptNotExecutable(validatedScriptPath)
        }

        logger.info("Executing post-recording script: \(validatedScriptPath)")
        logger.debug("Transcript path argument: \(transcriptPath)")

        // Create process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [validatedScriptPath, transcriptPath]

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
