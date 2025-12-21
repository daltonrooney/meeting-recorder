import XCTest
import AVFoundation
@testable import CallTranscription

/// Tests for AudioFileWriter following TDD methodology.
/// Tests are written FIRST before implementation.
final class AudioFileWriterTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()

        // Create temp directory for testing
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        // Clean up temp directory
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        try await super.tearDown()
    }

    // MARK: - File Creation Tests

    func testCreatesAudioFileAtSpecifiedPath() async throws {
        let writer = try await AudioFileWriter(
            outputFolder: tempDirectory,
            filename: "test_audio.m4a",
            format: .aac
        )
        try await writer.finalize()

        let expectedPath = tempDirectory.appendingPathComponent("test_audio.m4a")
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedPath.path))
    }

    func testGeneratesFilenameWhenNotProvided() async throws {
        let writer = try await AudioFileWriter(
            outputFolder: tempDirectory,
            format: .aac
        )
        let fileURL = try await writer.finalize()

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertTrue(fileURL.lastPathComponent.hasSuffix(".m4a"))
    }

    func testFilenameIncludesISO8601Timestamp() async throws {
        let writer = try await AudioFileWriter(
            outputFolder: tempDirectory,
            format: .aac
        )
        let fileURL = try await writer.finalize()

        let filename = fileURL.lastPathComponent
        // Should contain date in format like "2025-12-17"
        XCTAssertTrue(filename.contains("-"))

        // Should contain time components
        let components = filename.components(separatedBy: CharacterSet(charactersIn: "T_-."))
        XCTAssertGreaterThan(components.count, 3)
    }

    // MARK: - Format Tests

    func testSupportsAACFormat() async throws {
        let writer = try await AudioFileWriter(
            outputFolder: tempDirectory,
            filename: "test.m4a",
            format: .aac
        )
        try await writer.finalize()

        let fileURL = tempDirectory.appendingPathComponent("test.m4a")
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testSupportsWAVFormat() async throws {
        let writer = try await AudioFileWriter(
            outputFolder: tempDirectory,
            filename: "test.wav",
            format: .wav
        )
        try await writer.finalize()

        let fileURL = tempDirectory.appendingPathComponent("test.wav")
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testDefaultFormatIsAAC() async throws {
        let writer = try await AudioFileWriter(
            outputFolder: tempDirectory,
            filename: "test_default.m4a"
        )
        try await writer.finalize()

        let fileURL = tempDirectory.appendingPathComponent("test_default.m4a")
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    // MARK: - Audio Writing Tests

    func testWritesAudioBuffers() async throws {
        let writer = try await AudioFileWriter(
            outputFolder: tempDirectory,
            filename: "test_with_audio.m4a",
            format: .aac
        )

        // Create a test audio buffer (48kHz mono, 1024 frames)
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 48000,
            channels: 1,
            interleaved: false
        )!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
        buffer.frameLength = 1024

        // Fill with test data (sine wave)
        let floatChannelData = buffer.floatChannelData!
        for i in 0..<Int(buffer.frameLength) {
            floatChannelData[0][i] = sin(Float(i) * 0.1)
        }

        try await writer.write(buffer: buffer)
        let fileURL = try await writer.finalize()

        // Verify file exists and has content
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as! UInt64
        XCTAssertGreaterThan(fileSize, 0, "Audio file should have content")
    }

    func testWritesMultipleBuffers() async throws {
        let writer = try await AudioFileWriter(
            outputFolder: tempDirectory,
            filename: "test_multiple_buffers.m4a",
            format: .aac
        )

        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 48000,
            channels: 1,
            interleaved: false
        )!

        // Write 3 buffers
        for _ in 0..<3 {
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
            buffer.frameLength = 1024
            let floatChannelData = buffer.floatChannelData!
            for i in 0..<Int(buffer.frameLength) {
                floatChannelData[0][i] = sin(Float(i) * 0.1)
            }
            try await writer.write(buffer: buffer)
        }

        let fileURL = try await writer.finalize()
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as! UInt64
        XCTAssertGreaterThan(fileSize, 0)
    }

    // MARK: - Error Handling Tests

    func testThrowsWhenFolderNotWritable() async throws {
        let readOnlyFolder = tempDirectory.appendingPathComponent("readonly")
        try FileManager.default.createDirectory(at: readOnlyFolder, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o444], ofItemAtPath: readOnlyFolder.path)

        do {
            _ = try await AudioFileWriter(
                outputFolder: readOnlyFolder,
                filename: "test.m4a",
                format: .aac
            )
            XCTFail("Expected error for read-only folder")
        } catch CallTranscriptionError.outputFolderNotWritable {
            // Expected
        } catch {
            XCTFail("Expected outputFolderNotWritable error, got \(error)")
        }

        // Restore permissions for cleanup
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: readOnlyFolder.path)
    }

    func testThrowsWhenWritingAfterFinalize() async throws {
        let writer = try await AudioFileWriter(
            outputFolder: tempDirectory,
            filename: "test.m4a",
            format: .aac
        )

        try await writer.finalize()

        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 48000,
            channels: 1,
            interleaved: false
        )!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
        buffer.frameLength = 1024

        do {
            try await writer.write(buffer: buffer)
            XCTFail("Expected error when writing after finalize")
        } catch {
            // Expected - should throw some error
            XCTAssertTrue(true)
        }
    }

    // MARK: - Thread Safety Tests

    func testConcurrentWritesDoNotCrash() async throws {
        let writer = try await AudioFileWriter(
            outputFolder: tempDirectory,
            filename: "test_concurrent.m4a",
            format: .aac
        )

        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 48000,
            channels: 1,
            interleaved: false
        )!

        // Write from multiple tasks concurrently
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
                    buffer.frameLength = 1024
                    let floatChannelData = buffer.floatChannelData!
                    for i in 0..<Int(buffer.frameLength) {
                        floatChannelData[0][i] = sin(Float(i) * 0.1)
                    }
                    try? await writer.write(buffer: buffer)
                }
            }
        }

        try await writer.finalize()
    }

    // MARK: - File Naming Tests

    func testGeneratesM4AExtensionForAAC() async throws {
        let writer = try await AudioFileWriter(
            outputFolder: tempDirectory,
            format: .aac
        )
        let fileURL = try await writer.finalize()

        XCTAssertTrue(fileURL.lastPathComponent.hasSuffix(".m4a"))
    }

    func testGeneratesWAVExtensionForWAV() async throws {
        let writer = try await AudioFileWriter(
            outputFolder: tempDirectory,
            format: .wav
        )
        let fileURL = try await writer.finalize()

        XCTAssertTrue(fileURL.lastPathComponent.hasSuffix(".wav"))
    }

    func testCustomFilenamePreserved() async throws {
        let writer = try await AudioFileWriter(
            outputFolder: tempDirectory,
            filename: "my_recording.m4a",
            format: .aac
        )
        let fileURL = try await writer.finalize()

        XCTAssertEqual(fileURL.lastPathComponent, "my_recording.m4a")
    }
}
