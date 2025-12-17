import Foundation
import os.log

/// Manages transcript file creation, appending timestamped text, and file finalization.
///
/// This class provides utilities for:
/// - Creating transcript files with formatted headers
/// - Appending timestamped text entries
/// - Managing file handles safely
/// - Finalizing and closing transcript files
///
/// All operations are Swift 6 concurrency-safe with @MainActor isolation.
@MainActor
public final class TranscriptWriter {
    private let fileURL: URL
    private var fileHandle: FileHandle?
    private var isFinalized = false
    private let logger = Logger(subsystem: "com.olive.CallTranscription", category: "TranscriptWriter")

    // MARK: - Initialization

    /// Creates a new transcript writer with optional filename and title.
    ///
    /// - Parameters:
    ///   - outputFolder: The folder where the transcript file will be created
    ///   - filename: Optional filename (generates ISO 8601 timestamp-based name if not provided)
    ///   - title: Optional title to include in the header
    /// - Throws: `CallTranscriptionError` if the folder is not writable or file creation fails
    public init(outputFolder: URL, filename: String? = nil, title: String? = nil) async throws {
        logger.debug("Initializing TranscriptWriter in folder: \(outputFolder.path)")

        // Validate output folder is writable
        guard FileManager.default.isWritableFile(atPath: outputFolder.path) else {
            logger.error("Output folder is not writable: \(outputFolder.path)")
            throw CallTranscriptionError.outputFolderNotWritable(outputFolder)
        }

        // Generate filename if not provided
        let actualFilename: String
        if let filename = filename {
            actualFilename = filename
        } else {
            // Generate ISO 8601 timestamp-based filename
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withYear, .withMonth, .withDay, .withTime, .withColonSeparatorInTime]
            let timestamp = dateFormatter.string(from: Date()).replacingOccurrences(of: ":", with: "_")
            actualFilename = "transcript_\(timestamp).txt"
        }

        self.fileURL = outputFolder.appendingPathComponent(actualFilename)

        // Create file with header
        do {
            let header = Self.generateHeader(title: title, date: Date())
            try header.write(to: fileURL, atomically: true, encoding: .utf8)
            logger.info("Created transcript file: \(self.fileURL.path)")
        } catch {
            logger.error("Failed to create transcript file: \(error.localizedDescription)")
            // Clean up any partial file
            try? FileManager.default.removeItem(at: fileURL)
            throw CallTranscriptionError.outputFolderNotWritable(outputFolder)
        }

        // Open file handle for appending
        do {
            self.fileHandle = try FileHandle(forWritingTo: fileURL)
            try self.fileHandle?.seekToEnd()
        } catch {
            logger.error("Failed to open file handle: \(error.localizedDescription)")
            // Clean up file
            try? FileManager.default.removeItem(at: fileURL)
            throw CallTranscriptionError.outputFolderNotWritable(outputFolder)
        }
    }

    // MARK: - Header Generation

    /// Generates a formatted header for the transcript file.
    private static func generateHeader(title: String?, date: Date) -> String {
        var header = "Olive - Call Transcription Transcript\n"

        // Add date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        header += "Date: \(dateFormatter.string(from: date))\n"

        // Add title if provided
        if let title = title, !title.isEmpty {
            header += "Title: \(title)\n"
        }

        // Add separator
        header += "================================================================================\n\n"

        return header
    }

    // MARK: - Text Appending

    /// Appends text to the transcript with a formatted timestamp.
    ///
    /// - Parameters:
    ///   - text: The text to append
    ///   - timestamp: The timestamp in seconds from start of recording
    /// - Throws: Error if the file handle is closed or writing fails
    public func append(_ text: String, timestamp: TimeInterval) async throws {
        guard !isFinalized else {
            logger.error("Cannot append after finalization")
            throw CallTranscriptionError.transcriptAlreadyFinalized
        }

        guard let fileHandle = fileHandle else {
            logger.error("File handle is nil")
            throw CallTranscriptionError.transcriptAlreadyFinalized
        }

        // Format timestamp
        let formattedTimestamp = Self.formatTimestamp(timestamp)

        // Create line with timestamp and text
        let line = "[\(formattedTimestamp)] \(text)\n"

        // Write to file
        if let data = line.data(using: .utf8) {
            try fileHandle.write(contentsOf: data)
            logger.debug("Appended text with timestamp \(formattedTimestamp)")
        }
    }

    // MARK: - Timestamp Formatting

    /// Formats a timestamp in seconds to [MM:SS] or [HH:MM:SS] format.
    private static func formatTimestamp(_ seconds: TimeInterval) -> String {
        // Handle negative timestamps
        let safeSeconds = max(0, seconds)

        let totalSeconds = Int(safeSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            // Format as HH:MM:SS
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            // Format as MM:SS
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    // MARK: - Finalization

    /// Finalizes the transcript file by closing the file handle.
    ///
    /// - Returns: The URL of the completed transcript file
    /// - Throws: Error if closing the file handle fails
    @discardableResult
    public func finalize() async throws -> URL {
        guard !isFinalized else {
            logger.warning("Transcript already finalized")
            return fileURL
        }

        // Close file handle
        if let fileHandle = fileHandle {
            do {
                try fileHandle.close()
                logger.info("Finalized transcript: \(self.fileURL.path)")
            } catch {
                logger.error("Error closing file handle: \(error.localizedDescription)")
                throw error
            }
        }

        isFinalized = true
        self.fileHandle = nil

        return fileURL
    }

    // MARK: - Cleanup

    deinit {
        // Ensure file handle is closed
        if let fileHandle = fileHandle, !isFinalized {
            try? fileHandle.close()
            logger.warning("File handle closed in deinit (should finalize explicitly)")
        }
    }
}
