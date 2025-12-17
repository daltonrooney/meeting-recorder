import Foundation
import os.log

/// Manages output folder validation, creation, and permission checking.
///
/// This class provides utilities for:
/// - Validating and expanding file paths (including tilde expansion)
/// - Creating output directories with proper permissions
/// - Checking write permissions before attempting to write files
/// - Providing a default output folder location
///
/// All operations are Swift 6 concurrency-safe with @MainActor isolation.
@MainActor
public final class OutputFolderManager {
    private let fileManager = FileManager.default
    private let logger = Logger(subsystem: "com.olive.CallTranscription", category: "OutputFolderManager")

    public init() {}

    // MARK: - Path Validation and Preparation

    /// Validates a path and prepares it for use by creating the directory if needed.
    ///
    /// This method:
    /// 1. Expands tilde (~) to user home directory
    /// 2. Converts relative paths to absolute paths
    /// 3. Creates the directory if it doesn't exist
    /// 4. Verifies write permissions
    ///
    /// - Parameter path: The path to validate (can be absolute, relative, or contain ~)
    /// - Returns: A validated and prepared file URL
    /// - Throws: `CallTranscriptionError` if validation or creation fails
    public func validateAndPreparePath(_ path: String) async throws -> URL {
        logger.debug("Validating output path: \(path)")

        // Handle empty path - use default
        let pathToUse = path.isEmpty ? defaultOutputFolder().path : path

        // Expand tilde in path
        let expandedPath = (pathToUse as NSString).expandingTildeInPath

        // Convert to URL
        var url: URL
        if expandedPath.hasPrefix("/") {
            // Absolute path
            url = URL(fileURLWithPath: expandedPath)
        } else {
            // Relative path - make it relative to current directory
            let currentDir = fileManager.currentDirectoryPath
            url = URL(fileURLWithPath: currentDir).appendingPathComponent(expandedPath)
        }

        // Standardize path (removes .., ., //)
        url = url.standardizedFileURL

        // Check if directory exists
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)

        if exists {
            // Directory exists - verify it's actually a directory and is writable
            guard isDirectory.boolValue else {
                logger.error("Path exists but is not a directory: \(url.path)")
                throw CallTranscriptionError.outputFolderNotWritable(url)
            }

            // Check write permission
            guard fileManager.isWritableFile(atPath: url.path) else {
                logger.error("Directory is not writable: \(url.path)")
                throw CallTranscriptionError.outputFolderNotWritable(url)
            }

            logger.debug("Using existing directory: \(url.path)")
        } else {
            // Directory doesn't exist - need to create it
            // First check if parent directory is writable
            let parentURL = url.deletingLastPathComponent()
            if fileManager.fileExists(atPath: parentURL.path) {
                guard fileManager.isWritableFile(atPath: parentURL.path) else {
                    logger.error("Parent directory is not writable: \(parentURL.path)")
                    throw CallTranscriptionError.outputFolderNotWritable(url)
                }
            }

            // Create directory with intermediate directories
            do {
                try fileManager.createDirectory(
                    at: url,
                    withIntermediateDirectories: true,
                    attributes: [.posixPermissions: 0o755]
                )
                logger.info("Created output directory: \(url.path)")
            } catch {
                logger.error("Failed to create directory at \(url.path): \(error.localizedDescription)")
                throw CallTranscriptionError.outputFolderCreationFailed(url.path, error)
            }

            // Verify it was created successfully
            guard fileManager.fileExists(atPath: url.path) else {
                logger.error("Directory creation succeeded but path doesn't exist: \(url.path)")
                throw CallTranscriptionError.outputFolderNotWritable(url)
            }
        }

        return url
    }

    // MARK: - Default Folder

    /// Returns the default output folder location.
    ///
    /// The default is ~/Desktop/Transcripts, with a fallback to ~/Documents/Transcripts
    /// if the Desktop directory is not available.
    ///
    /// - Returns: URL for the default output folder
    public func defaultOutputFolder() -> URL {
        // Try Desktop first
        if let desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first {
            return desktopURL.appendingPathComponent("Transcripts", isDirectory: true)
        }

        // Fallback to Documents
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            logger.warning("Desktop directory not available, using Documents instead")
            return documentsURL.appendingPathComponent("Transcripts", isDirectory: true)
        }

        // Last resort fallback - should never happen
        logger.error("Neither Desktop nor Documents directory available, using home directory")
        return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Transcripts", isDirectory: true)
    }
}
