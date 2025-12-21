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
    private let pathValidator = PathValidator()
    private let bookmarkManager = SecurityScopedBookmarkManager()

    public init() {}

    // MARK: - Path Validation and Preparation

    /// Validates a path and prepares it for use by creating the directory if needed.
    ///
    /// This method:
    /// 1. If bookmark is provided, resolves it to get the URL (enables sandbox access)
    /// 2. Expands tilde (~) to user home directory
    /// 3. Validates path for security (no path traversal, within allowed directories)
    /// 4. Creates the directory if it doesn't exist
    /// 5. Verifies write permissions
    ///
    /// - Parameters:
    ///   - path: The path to validate (can be absolute, relative, or contain ~)
    ///   - bookmark: Optional security-scoped bookmark data for sandboxed access
    /// - Returns: A validated and prepared file URL
    /// - Throws: `CallTranscriptionError` if validation or creation fails
    public func validateAndPreparePath(_ path: String, bookmark: Data? = nil) async throws -> URL {
        logger.debug("Validating output path: \(path), has bookmark: \(bookmark != nil)")

        // Handle empty path - use default
        let pathToUse = path.isEmpty ? defaultOutputFolder().path : path

        // Try to use bookmark first if available
        let url: URL
        let usingBookmark: Bool
        if let bookmarkData = bookmark {
            logger.debug("Attempting to resolve security-scoped bookmark")
            do {
                // Resolve bookmark to get URL
                // When using bookmark, skip PathValidator entirely
                // Security-scoped bookmarks already provide validated access from macOS
                url = try bookmarkManager.resolveBookmark(bookmarkData)
                logger.info("Successfully resolved bookmark to: \(url.path, privacy: .public)")
                usingBookmark = true
            } catch {
                logger.warning("Failed to resolve bookmark: \(error.localizedDescription), falling back to path validation")
                // Fall back to normal path validation if bookmark fails
                let expandedPath = (pathToUse as NSString).expandingTildeInPath
                url = try pathValidator.validateForFileOutput(path: expandedPath)
                usingBookmark = false
            }
        } else {
            // No bookmark - use normal path validation for sandbox-local paths
            logger.debug("No bookmark provided, using path validation")
            let expandedPath = (pathToUse as NSString).expandingTildeInPath
            url = try pathValidator.validateForFileOutput(path: expandedPath)
            usingBookmark = false
        }
        logger.debug("Using output path: \(url.path, privacy: .public), usingBookmark: \(usingBookmark)")

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
            // Directory doesn't exist - create it
            // Use user-only permissions (0o700) for security - transcripts may contain sensitive data
            do {
                try fileManager.createDirectory(
                    at: url,
                    withIntermediateDirectories: true,
                    attributes: [.posixPermissions: 0o700]
                )
                logger.info("Created output directory: \(url.path)")
            } catch {
                logger.error("Failed to create directory at \(url.path): \(error.localizedDescription)")
                throw CallTranscriptionError.outputFolderCreationFailed(url.path, error)
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
