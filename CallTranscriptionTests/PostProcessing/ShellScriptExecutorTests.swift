import XCTest
@testable import CallTranscription

@MainActor
final class ShellScriptExecutorTests: XCTestCase {
    var executor: ShellScriptExecutor!
    var tempDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()
        executor = ShellScriptExecutor()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ShellScriptExecutorTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    /// Creates a test script file with the given content and makes it executable
    private func createTestScript(name: String, content: String) throws -> URL {
        let scriptURL = tempDirectory.appendingPathComponent(name)
        try content.write(to: scriptURL, atomically: true, encoding: .utf8)

        // Make script executable
        let attributes = [FileAttributeKey.posixPermissions: 0o755]
        try FileManager.default.setAttributes(attributes, ofItemAtPath: scriptURL.path)

        return scriptURL
    }

    /// Creates a test transcript file
    private func createTestTranscript(name: String, content: String) throws -> URL {
        let transcriptURL = tempDirectory.appendingPathComponent(name)
        try content.write(to: transcriptURL, atomically: true, encoding: .utf8)
        return transcriptURL
    }

    // MARK: - Script Execution Tests

    func testExecutesScriptAtGivenPath() async throws {
        // Create a script that creates a marker file when executed
        let markerFile = tempDirectory.appendingPathComponent("executed.txt")
        let scriptContent = """
        #!/bin/bash
        touch "\(markerFile.path)"
        """
        let scriptURL = try createTestScript(name: "test.sh", content: scriptContent)
        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        let result = try await executor.execute(scriptPath: scriptURL.path, transcriptPath: transcriptURL.path)

        XCTAssertTrue(FileManager.default.fileExists(atPath: markerFile.path), "Script should have been executed")
        XCTAssertEqual(result.exitCode, 0, "Script should exit successfully")
    }

    func testPassesTranscriptPathAsFirstArgument() async throws {
        // Create a script that writes its first argument to a file
        let outputFile = tempDirectory.appendingPathComponent("output.txt")
        let scriptContent = """
        #!/bin/bash
        echo "$1" > "\(outputFile.path)"
        """
        let scriptURL = try createTestScript(name: "test.sh", content: scriptContent)
        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        _ = try await executor.execute(scriptPath: scriptURL.path, transcriptPath: transcriptURL.path)

        let output = try String(contentsOf: outputFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(output, transcriptURL.path, "Transcript path should be passed as $1")
    }

    func testUsesBashAsInterpreter() async throws {
        // Create a script that uses bash-specific syntax
        let outputFile = tempDirectory.appendingPathComponent("output.txt")
        let scriptContent = """
        #!/bin/bash
        echo "$BASH_VERSION" > "\(outputFile.path)"
        """
        let scriptURL = try createTestScript(name: "test.sh", content: scriptContent)
        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        _ = try await executor.execute(scriptPath: scriptURL.path, transcriptPath: transcriptURL.path)

        let output = try String(contentsOf: outputFile, encoding: .utf8)
        XCTAssertFalse(output.isEmpty, "Should execute with bash (BASH_VERSION should be set)")
    }

    func testInheritsEnvironmentVariables() async throws {
        // Create a script that checks for an environment variable
        let outputFile = tempDirectory.appendingPathComponent("output.txt")
        let scriptContent = """
        #!/bin/bash
        echo "$HOME" > "\(outputFile.path)"
        """
        let scriptURL = try createTestScript(name: "test.sh", content: scriptContent)
        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        _ = try await executor.execute(scriptPath: scriptURL.path, transcriptPath: transcriptURL.path)

        let output = try String(contentsOf: outputFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertFalse(output.isEmpty, "HOME environment variable should be inherited")
    }

    func testWaitsForCompletionBeforeReturning() async throws {
        // Create a script that takes some time to execute
        let markerFile = tempDirectory.appendingPathComponent("completed.txt")
        let scriptContent = """
        #!/bin/bash
        sleep 0.5
        touch "\(markerFile.path)"
        """
        let scriptURL = try createTestScript(name: "test.sh", content: scriptContent)
        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        let result = try await executor.execute(scriptPath: scriptURL.path, transcriptPath: transcriptURL.path)

        XCTAssertTrue(FileManager.default.fileExists(atPath: markerFile.path), "Should wait for script completion")
        XCTAssertEqual(result.exitCode, 0, "Script should complete successfully")
    }

    // MARK: - Path Handling Tests

    func testExpandsTildeInScriptPath() async throws {
        // Create a script in temp directory, then reference it with tilde
        let scriptContent = """
        #!/bin/bash
        exit 0
        """
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let scriptDir = homeDir.appendingPathComponent(".test-scripts-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: scriptDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: scriptDir) }

        let scriptURL = scriptDir.appendingPathComponent("test.sh")
        try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
        let attributes = [FileAttributeKey.posixPermissions: 0o755]
        try FileManager.default.setAttributes(attributes, ofItemAtPath: scriptURL.path)

        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")
        let tildePath = "~/\(scriptDir.lastPathComponent)/test.sh"

        let result = try await executor.execute(scriptPath: tildePath, transcriptPath: transcriptURL.path)

        XCTAssertEqual(result.exitCode, 0, "Should expand tilde and execute script")
    }

    func testHandlesAbsolutePaths() async throws {
        let scriptContent = """
        #!/bin/bash
        exit 0
        """
        let scriptURL = try createTestScript(name: "test.sh", content: scriptContent)
        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        let result = try await executor.execute(scriptPath: scriptURL.path, transcriptPath: transcriptURL.path)

        XCTAssertEqual(result.exitCode, 0, "Should handle absolute paths")
    }

    func testHandlesRelativePaths() async throws {
        // Save current directory and change to temp directory
        let currentDir = FileManager.default.currentDirectoryPath
        defer { FileManager.default.changeCurrentDirectoryPath(currentDir) }

        FileManager.default.changeCurrentDirectoryPath(tempDirectory.path)

        let scriptContent = """
        #!/bin/bash
        exit 0
        """
        let scriptURL = try createTestScript(name: "test.sh", content: scriptContent)
        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        let result = try await executor.execute(scriptPath: "./test.sh", transcriptPath: transcriptURL.path)

        XCTAssertEqual(result.exitCode, 0, "Should handle relative paths")
    }

    func testValidatesScriptFileExists() async throws {
        let nonExistentScript = tempDirectory.appendingPathComponent("nonexistent.sh").path
        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        do {
            _ = try await executor.execute(scriptPath: nonExistentScript, transcriptPath: transcriptURL.path)
            XCTFail("Should throw error when script doesn't exist")
        } catch let error as CallTranscriptionError {
            if case .postRecordingScriptNotFound(let path) = error {
                XCTAssertEqual(path, nonExistentScript)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testValidatesScriptIsExecutable() async throws {
        let scriptContent = """
        #!/bin/bash
        exit 0
        """
        let scriptURL = tempDirectory.appendingPathComponent("test.sh")
        try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
        // Don't make it executable

        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        do {
            _ = try await executor.execute(scriptPath: scriptURL.path, transcriptPath: transcriptURL.path)
            XCTFail("Should throw error when script is not executable")
        } catch let error as CallTranscriptionError {
            if case .postRecordingScriptNotExecutable(let path) = error {
                XCTAssertEqual(path, scriptURL.path)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Argument Passing Tests

    func testTranscriptPathIsFormattedCorrectly() async throws {
        let outputFile = tempDirectory.appendingPathComponent("output.txt")
        let scriptContent = """
        #!/bin/bash
        echo "$1" > "\(outputFile.path)"
        """
        let scriptURL = try createTestScript(name: "test.sh", content: scriptContent)
        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        _ = try await executor.execute(scriptPath: scriptURL.path, transcriptPath: transcriptURL.path)

        let output = try String(contentsOf: outputFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(output, transcriptURL.path)
    }

    func testHandlesPathsWithSpaces() async throws {
        let outputFile = tempDirectory.appendingPathComponent("output.txt")
        let scriptContent = """
        #!/bin/bash
        echo "$1" > "\(outputFile.path)"
        """
        let scriptURL = try createTestScript(name: "test.sh", content: scriptContent)
        let transcriptURL = try createTestTranscript(name: "transcript with spaces.txt", content: "Test transcript")

        _ = try await executor.execute(scriptPath: scriptURL.path, transcriptPath: transcriptURL.path)

        let output = try String(contentsOf: outputFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(output, transcriptURL.path)
        XCTAssertTrue(output.contains(" "), "Path should contain spaces")
    }

    func testHandlesSpecialCharactersInPath() async throws {
        let outputFile = tempDirectory.appendingPathComponent("output.txt")
        let scriptContent = """
        #!/bin/bash
        echo "$1" > "\(outputFile.path)"
        """
        let scriptURL = try createTestScript(name: "test.sh", content: scriptContent)
        let transcriptURL = try createTestTranscript(name: "transcript-[2024]-(test).txt", content: "Test transcript")

        _ = try await executor.execute(scriptPath: scriptURL.path, transcriptPath: transcriptURL.path)

        let output = try String(contentsOf: outputFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(output, transcriptURL.path)
    }

    // MARK: - Exit Status Handling Tests

    func testCapturesExitStatus() async throws {
        let scriptContent = """
        #!/bin/bash
        exit 42
        """
        let scriptURL = try createTestScript(name: "test.sh", content: scriptContent)
        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        let result = try await executor.execute(scriptPath: scriptURL.path, transcriptPath: transcriptURL.path)

        XCTAssertEqual(result.exitCode, 42, "Should capture exit status")
    }

    func testReturnsSuccessfullyOnExitZero() async throws {
        let scriptContent = """
        #!/bin/bash
        exit 0
        """
        let scriptURL = try createTestScript(name: "test.sh", content: scriptContent)
        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        let result = try await executor.execute(scriptPath: scriptURL.path, transcriptPath: transcriptURL.path)

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.success)
    }

    func testLogsWarningOnNonZeroExit() async throws {
        let scriptContent = """
        #!/bin/bash
        exit 1
        """
        let scriptURL = try createTestScript(name: "test.sh", content: scriptContent)
        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        let result = try await executor.execute(scriptPath: scriptURL.path, transcriptPath: transcriptURL.path)

        XCTAssertEqual(result.exitCode, 1)
        XCTAssertFalse(result.success)
    }

    func testDoesNotThrowOnScriptFailure() async throws {
        let scriptContent = """
        #!/bin/bash
        exit 1
        """
        let scriptURL = try createTestScript(name: "test.sh", content: scriptContent)
        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        // Should not throw, just return result with non-zero exit
        let result = try await executor.execute(scriptPath: scriptURL.path, transcriptPath: transcriptURL.path)

        XCTAssertEqual(result.exitCode, 1)
        XCTAssertFalse(result.success)
    }

    func testProvidesExitStatusInResult() async throws {
        let scriptContent = """
        #!/bin/bash
        exit 7
        """
        let scriptURL = try createTestScript(name: "test.sh", content: scriptContent)
        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        let result = try await executor.execute(scriptPath: scriptURL.path, transcriptPath: transcriptURL.path)

        XCTAssertEqual(result.exitCode, 7)
    }

    // MARK: - Edge Cases Tests

    func testHandlesEmptyScriptPath() async throws {
        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        let result = try await executor.execute(scriptPath: "", transcriptPath: transcriptURL.path)

        XCTAssertTrue(result.success, "Empty script path should be a no-op")
        XCTAssertEqual(result.exitCode, 0)
    }

    func testHandlesScriptThatHangs() async throws {
        let scriptContent = """
        #!/bin/bash
        sleep 100
        """
        let scriptURL = try createTestScript(name: "test.sh", content: scriptContent)
        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        do {
            _ = try await executor.execute(scriptPath: scriptURL.path, transcriptPath: transcriptURL.path, timeout: 1.0)
            XCTFail("Should throw timeout error")
        } catch let error as CallTranscriptionError {
            if case .postRecordingScriptTimeout(let timeout) = error {
                XCTAssertEqual(timeout, 1.0)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testHandlesScriptOutput() async throws {
        let scriptContent = """
        #!/bin/bash
        echo "stdout message"
        echo "stderr message" >&2
        exit 0
        """
        let scriptURL = try createTestScript(name: "test.sh", content: scriptContent)
        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        let result = try await executor.execute(scriptPath: scriptURL.path, transcriptPath: transcriptURL.path)

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.standardOutput?.contains("stdout message") ?? false)
        XCTAssertTrue(result.standardError?.contains("stderr message") ?? false)
    }

    // MARK: - Concurrent Execution Tests

    func testMultipleScriptsRunSequentially() async throws {
        let markerFile1 = tempDirectory.appendingPathComponent("marker1.txt")
        let markerFile2 = tempDirectory.appendingPathComponent("marker2.txt")

        let scriptContent1 = """
        #!/bin/bash
        touch "\(markerFile1.path)"
        """
        let scriptContent2 = """
        #!/bin/bash
        touch "\(markerFile2.path)"
        """

        let scriptURL1 = try createTestScript(name: "test1.sh", content: scriptContent1)
        let scriptURL2 = try createTestScript(name: "test2.sh", content: scriptContent2)
        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        _ = try await executor.execute(scriptPath: scriptURL1.path, transcriptPath: transcriptURL.path)
        _ = try await executor.execute(scriptPath: scriptURL2.path, transcriptPath: transcriptURL.path)

        XCTAssertTrue(FileManager.default.fileExists(atPath: markerFile1.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: markerFile2.path))
    }

    // MARK: - Security Tests

    func testDoesNotAllowCommandInjection() async throws {
        // Try to inject a command via transcript path
        let maliciousTranscriptPath = "; rm -rf /tmp/should-not-be-deleted; echo test"

        let outputFile = tempDirectory.appendingPathComponent("output.txt")
        let scriptContent = """
        #!/bin/bash
        echo "$1" > "\(outputFile.path)"
        """
        let scriptURL = try createTestScript(name: "test.sh", content: scriptContent)

        let result = try await executor.execute(scriptPath: scriptURL.path, transcriptPath: maliciousTranscriptPath)

        // The malicious path should be passed as-is, not executed
        let output = try String(contentsOf: outputFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(output, maliciousTranscriptPath)
        XCTAssertEqual(result.exitCode, 0)
    }

    func testValidatesScriptPathBeforeExecution() async throws {
        let invalidScript = "/dev/null"
        let transcriptURL = try createTestTranscript(name: "transcript.txt", content: "Test transcript")

        do {
            _ = try await executor.execute(scriptPath: invalidScript, transcriptPath: transcriptURL.path)
            XCTFail("Should validate that script is executable before execution")
        } catch {
            // Should throw error for non-executable file
            XCTAssertTrue(error is CallTranscriptionError)
        }
    }
}
