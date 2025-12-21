import Foundation
import AVFoundation

/// Audio format for file output
public enum AudioFileFormat {
    case aac
    case wav
}

/// Writes audio buffers to a file during recording.
///
/// Handles creation and writing of audio files in various formats (AAC, WAV).
/// Designed to work alongside TranscriptWriter for complete recording session capture.
///
/// Usage:
/// ```swift
/// let writer = try await AudioFileWriter(outputFolder: url, format: .aac)
/// // During recording:
/// try await writer.write(buffer: audioBuffer)
/// // When done:
/// let fileURL = try await writer.finalize()
/// ```
@MainActor
public final class AudioFileWriter {
    private let fileURL: URL
    private let format: AudioFileFormat
    private var audioFile: AVAudioFile?
    private var isFinalized = false

    /// Creates a new audio file writer.
    ///
    /// - Parameters:
    ///   - outputFolder: URL to output folder (must be writable)
    ///   - filename: Optional custom filename (generated if nil)
    ///   - format: Audio file format (default: .aac)
    /// - Throws: CallTranscriptionError if folder is not writable or file creation fails
    public init(
        outputFolder: URL,
        filename: String? = nil,
        format: AudioFileFormat = .aac
    ) async throws {
        self.format = format

        // Verify folder is writable
        let isWritable = FileManager.default.isWritableFile(atPath: outputFolder.path)
        if !isWritable {
            throw CallTranscriptionError.outputFolderNotWritable(outputFolder)
        }

        // Generate filename if not provided
        let finalFilename: String
        if let filename = filename {
            finalFilename = filename
        } else {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let ext = format == .aac ? "m4a" : "wav"
            finalFilename = "transcript_\(timestamp).\(ext)"
        }

        self.fileURL = outputFolder.appendingPathComponent(finalFilename)

        // Create audio file with appropriate format
        let audioFormat: AVAudioFormat
        if format == .aac {
            // AAC format: 48kHz, mono, for CoreAudio Process Tap compatibility
            audioFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 48000,
                channels: 1,
                interleaved: false
            )!
        } else {
            // WAV format: 48kHz, mono, PCM
            audioFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 48000,
                channels: 1,
                interleaved: false
            )!
        }

        // Create file for writing
        do {
            if format == .aac {
                // For M4A, we need to use kAudioFileM4AType
                let settings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVSampleRateKey: 48000,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderBitRateKey: 128000
                ]

                // Create the audio file
                self.audioFile = try AVAudioFile(
                    forWriting: fileURL,
                    settings: settings,
                    commonFormat: .pcmFormatFloat32,
                    interleaved: false
                )
            } else {
                // For WAV files
                self.audioFile = try AVAudioFile(
                    forWriting: fileURL,
                    settings: audioFormat.settings
                )
            }
        } catch {
            throw CallTranscriptionError.outputFolderNotWritable(outputFolder)
        }
    }

    /// Writes an audio buffer to the file.
    ///
    /// - Parameter buffer: Audio buffer to write (will be converted to file format if needed)
    /// - Throws: Error if writing fails or file is already finalized
    public func write(buffer: AVAudioPCMBuffer) async throws {
        guard !isFinalized else {
            throw CallTranscriptionError.transcriptAlreadyFinalized
        }

        guard let audioFile = audioFile else {
            throw CallTranscriptionError.transcriptAlreadyFinalized
        }

        // Write buffer to file
        // AVAudioFile handles format conversion automatically
        try audioFile.write(from: buffer)
    }

    /// Finalizes the audio file and returns its URL.
    ///
    /// After calling finalize, no more writes are accepted.
    ///
    /// - Returns: URL of the completed audio file
    /// - Throws: Error if file operations fail
    public func finalize() async throws -> URL {
        isFinalized = true
        audioFile = nil
        return fileURL
    }

    /// Cleans up the audio file if recording is cancelled.
    ///
    /// Removes the partially written file from disk.
    public func cleanup() async {
        isFinalized = true
        audioFile = nil
        try? FileManager.default.removeItem(at: fileURL)
    }
}
