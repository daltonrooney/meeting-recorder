import Foundation
import os.log

/// Manages security-scoped bookmarks for sandboxed file access.
///
/// Security-scoped bookmarks allow a sandboxed app to access user-selected files and folders
/// across launches. This is essential for:
/// - Saving transcripts to user-selected output folders
/// - Accessing custom scripts outside the app container
/// - Maintaining permissions after app restart
///
/// Example usage:
/// ```swift
/// let manager = SecurityScopedBookmarkManager()
///
/// // User selects folder with NSOpenPanel
/// let bookmarkData = try manager.createBookmark(for: selectedURL)
/// UserDefaults.standard.set(bookmarkData, forKey: "outputFolderBookmark")
///
/// // Later, access the folder
/// let result = try await manager.accessResource(bookmarkData: bookmarkData) { url in
///     // Write files to url
///     try "content".write(to: url.appendingPathComponent("file.txt"), atomically: true, encoding: .utf8)
///     return url
/// }
/// ```
@MainActor
public final class SecurityScopedBookmarkManager {
    private let logger = Logger(subsystem: "com.olive.CallTranscription", category: "SecurityScopedBookmarkManager")

    public init() {}

    // MARK: - Bookmark Creation

    /// Creates a security-scoped bookmark for the specified URL.
    ///
    /// The URL must point to an existing directory. The bookmark can be saved to UserDefaults
    /// and used across app launches to regain access to the folder.
    ///
    /// - Parameter url: The directory URL to create a bookmark for
    /// - Returns: Bookmark data that can be saved and later resolved
    /// - Throws: `CallTranscriptionError.bookmarkCreationFailed` if bookmark creation fails
    public func createBookmark(for url: URL) throws -> Data {
        logger.debug("Creating bookmark for: \(url.path)")

        // Verify URL exists and is a directory
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            logger.error("Cannot create bookmark: path is not a directory or doesn't exist: \(url.path)")
            throw CallTranscriptionError.bookmarkCreationFailed(url.path, reason: "Path must be an existing directory")
        }

        do {
            // Create security-scoped bookmark with read-write access
            let bookmarkData = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            logger.info("Successfully created bookmark for: \(url.path)")
            return bookmarkData
        } catch {
            logger.error("Failed to create bookmark: \(error.localizedDescription)")
            throw CallTranscriptionError.bookmarkCreationFailed(url.path, reason: error.localizedDescription)
        }
    }

    // MARK: - Bookmark Resolution

    /// Resolves a security-scoped bookmark to a URL.
    ///
    /// The resolved URL can be used with `startAccessingSecurityScopedResource()` to access
    /// the bookmarked folder. Remember to call `stopAccessingSecurityScopedResource()` when done.
    ///
    /// - Parameter bookmarkData: The bookmark data created by `createBookmark(for:)`
    /// - Returns: The resolved URL
    /// - Throws: `CallTranscriptionError.bookmarkResolutionFailed` if resolution fails
    public func resolveBookmark(_ bookmarkData: Data) throws -> URL {
        logger.debug("Resolving bookmark...")

        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope, .withoutUI],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                logger.warning("Bookmark is stale but resolved: \(url.path)")
            }

            // Verify the resolved URL still exists
            guard FileManager.default.fileExists(atPath: url.path) else {
                logger.error("Resolved bookmark points to non-existent path: \(url.path)")
                throw CallTranscriptionError.bookmarkResolutionFailed(reason: "Bookmarked folder no longer exists")
            }

            logger.debug("Successfully resolved bookmark to: \(url.path)")
            return url
        } catch {
            logger.error("Failed to resolve bookmark: \(error.localizedDescription)")
            throw CallTranscriptionError.bookmarkResolutionFailed(reason: error.localizedDescription)
        }
    }

    // MARK: - Security-Scoped Access

    /// Accesses a bookmarked resource within a closure.
    ///
    /// This method handles the full lifecycle:
    /// 1. Resolves the bookmark to a URL
    /// 2. Starts accessing the security-scoped resource
    /// 3. Executes your closure with the URL
    /// 4. Stops accessing the security-scoped resource
    ///
    /// This is the recommended way to access bookmarked folders as it ensures proper cleanup.
    ///
    /// - Parameters:
    ///   - bookmarkData: The bookmark data to access
    ///   - operation: Closure to execute with access to the URL
    /// - Returns: The value returned by the operation closure
    /// - Throws: Rethrows any errors from the operation closure
    public func accessResource<T>(bookmarkData: Data, operation: (URL) throws -> T) async throws -> T {
        // Resolve bookmark
        let url = try resolveBookmark(bookmarkData)

        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            logger.error("Failed to start accessing security-scoped resource: \(url.path)")
            throw CallTranscriptionError.securityScopedAccessFailed(url.path)
        }

        // Ensure we stop accessing on all exit paths
        defer {
            url.stopAccessingSecurityScopedResource()
            logger.debug("Stopped accessing security-scoped resource: \(url.path)")
        }

        // Execute operation
        logger.debug("Started accessing security-scoped resource: \(url.path)")
        return try operation(url)
    }

    /// Accesses a bookmarked resource within an async closure.
    ///
    /// Async version of `accessResource(bookmarkData:operation:)`.
    ///
    /// - Parameters:
    ///   - bookmarkData: The bookmark data to access
    ///   - operation: Async closure to execute with access to the URL
    /// - Returns: The value returned by the operation closure
    /// - Throws: Rethrows any errors from the operation closure
    public func accessResource<T>(bookmarkData: Data, operation: (URL) async throws -> T) async throws -> T {
        // Resolve bookmark
        let url = try resolveBookmark(bookmarkData)

        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            logger.error("Failed to start accessing security-scoped resource: \(url.path)")
            throw CallTranscriptionError.securityScopedAccessFailed(url.path)
        }

        // Ensure we stop accessing on all exit paths
        defer {
            url.stopAccessingSecurityScopedResource()
            logger.debug("Stopped accessing security-scoped resource: \(url.path)")
        }

        // Execute operation
        logger.debug("Started accessing security-scoped resource: \(url.path)")
        return try await operation(url)
    }
}
