import Foundation

/// Validates file paths to prevent security vulnerabilities.
///
/// PathValidator provides comprehensive validation of file paths to protect against:
/// - Path traversal attacks (e.g., `../../etc/passwd`)
/// - Symlink attacks (symlinks pointing outside allowed directories)
/// - Unauthorized file system access
/// - Malicious path inputs
///
/// This provides defense-in-depth alongside macOS sandbox protections.
///
/// Example usage:
/// ```swift
/// let validator = PathValidator()
/// let baseDir = FileManager.default.homeDirectoryForCurrentUser
/// let validatedURL = try validator.validate(
///     path: userProvidedPath,
///     againstBaseDirectories: [baseDir]
/// )
/// ```
@MainActor
public final class PathValidator {

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    /// Validates a path is within allowed base directories.
    ///
    /// This method performs comprehensive security checks:
    /// 1. Validates path is not empty
    /// 2. Converts relative paths to absolute
    /// 3. Standardizes path format
    /// 4. Resolves symlinks to final destination
    /// 5. Checks if resolved path is within allowed directories
    /// 6. Detects path traversal attempts
    ///
    /// - Parameters:
    ///   - path: The file path to validate
    ///   - baseDirectories: Array of allowed base directories
    /// - Returns: Validated and normalized URL
    /// - Throws: CallTranscriptionError if path is invalid or dangerous
    public func validate(path: String, againstBaseDirectories baseDirectories: [URL]) throws -> URL {
        // Validate input
        guard !path.isEmpty else {
            throw CallTranscriptionError.invalidPath(path, reason: "Path cannot be empty")
        }

        guard !baseDirectories.isEmpty else {
            throw CallTranscriptionError.invalidPath(path, reason: "No base directories provided for validation")
        }

        // Early check for obvious path traversal patterns
        if path.contains("../") || path.contains("..\\") {
            // We'll validate this more carefully below, but flag it
        }

        // Check if the original path string is relative (doesn't start with /)
        let isRelativePath = !path.hasPrefix("/")

        // Convert to URL
        let absoluteURL: URL
        if isRelativePath {
            // Relative path - make it relative to first base directory
            absoluteURL = baseDirectories[0].appendingPathComponent(path)
        } else {
            // Absolute path
            absoluteURL = URL(fileURLWithPath: path)
        }

        // Standardize the path (removes ./, //, etc.)
        let standardizedURL = absoluteURL.standardizedFileURL

        // Resolve symlinks to get the real destination
        let resolvedURL = standardizedURL.resolvingSymlinksInPath()

        // Check if the resolved path is within any allowed base directory
        var isWithinAllowedDirectory = false
        for baseDir in baseDirectories {
            let resolvedBaseDir = baseDir.standardizedFileURL.resolvingSymlinksInPath()

            // Check if resolved path starts with base directory path
            if resolvedURL.path.hasPrefix(resolvedBaseDir.path) {
                // Ensure it's actually a subdirectory, not just a prefix match
                // e.g., /home shouldn't match /homeother
                let relativePath = resolvedURL.path.dropFirst(resolvedBaseDir.path.count)
                if relativePath.isEmpty || relativePath.hasPrefix("/") {
                    isWithinAllowedDirectory = true
                    break
                }
            }
        }

        guard isWithinAllowedDirectory else {
            // Check if this was a path traversal attempt that escaped
            if path.contains("../") || path.contains("..\\") {
                throw CallTranscriptionError.pathTraversalDetected(
                    path,
                    reason: "Path contains '..' sequences that escape allowed directories"
                )
            }

            // Check if this is a symlink attack
            if standardizedURL.path != resolvedURL.path {
                throw CallTranscriptionError.symlinkAttackDetected(
                    standardizedURL.path,
                    resolvedPath: resolvedURL.path
                )
            }

            // Not a symlink, just outside allowed directories
            let allowedPaths = baseDirectories.map { $0.path }
            throw CallTranscriptionError.pathOutsideAllowedDirectories(
                path,
                allowedDirectories: allowedPaths
            )
        }

        return resolvedURL
    }

    /// Validates a URL is within allowed base directories.
    ///
    /// Convenience method that accepts a URL instead of a string path.
    ///
    /// - Parameters:
    ///   - url: The URL to validate
    ///   - baseDirectories: Array of allowed base directories
    /// - Returns: Validated and normalized URL
    /// - Throws: CallTranscriptionError if URL is invalid or dangerous
    public func validate(url: URL, againstBaseDirectories baseDirectories: [URL]) throws -> URL {
        return try validate(path: url.path, againstBaseDirectories: baseDirectories)
    }

    /// Validates a path for file output using default allowed directories.
    ///
    /// Default allowed directories include:
    /// - User's home directory
    /// - System temporary directory
    ///
    /// This is suitable for validating paths where users save transcript files.
    ///
    /// - Parameter path: The file path to validate
    /// - Returns: Validated and normalized URL
    /// - Throws: CallTranscriptionError if path is invalid or dangerous
    public func validateForFileOutput(path: String) throws -> URL {
        let allowedDirectories = [
            FileManager.default.homeDirectoryForCurrentUser,
            FileManager.default.temporaryDirectory
        ]
        return try validate(path: path, againstBaseDirectories: allowedDirectories)
    }

    /// Validates a path for script execution using restricted directories.
    ///
    /// More restrictive than file output validation. Only allows scripts in:
    /// - User's home directory
    ///
    /// This prevents execution of system scripts or scripts in unexpected locations.
    ///
    /// - Parameter path: The script path to validate
    /// - Returns: Validated and normalized URL
    /// - Throws: CallTranscriptionError if path is invalid or dangerous
    public func validateForScriptExecution(path: String) throws -> URL {
        let allowedDirectories = [
            FileManager.default.homeDirectoryForCurrentUser
        ]
        return try validate(path: path, againstBaseDirectories: allowedDirectories)
    }

    /// Normalizes a path without validation.
    ///
    /// Useful for display purposes or preparing paths before validation.
    /// Does NOT perform security checks - use validate() for security validation.
    ///
    /// - Parameter path: The path to normalize
    /// - Returns: Normalized URL
    public func normalize(path: String) -> URL {
        let url = URL(fileURLWithPath: path)
        return url.standardizedFileURL
    }

    /// Checks if a URL is within allowed base directories.
    ///
    /// This is a simpler check that doesn't throw errors.
    ///
    /// - Parameters:
    ///   - url: The URL to check
    ///   - baseDirectories: Array of allowed base directories
    /// - Returns: true if URL is within allowed directories
    public func isPathSafe(_ url: URL, againstBaseDirectories baseDirectories: [URL]) -> Bool {
        do {
            _ = try validate(url: url, againstBaseDirectories: baseDirectories)
            return true
        } catch {
            return false
        }
    }
}
