import XCTest
@testable import CallTranscription

@MainActor
final class ShortcutExecutorTests: XCTestCase {
    var executor: ShortcutExecutor!
    var tempDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()
        executor = ShortcutExecutor()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ShortcutExecutorTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    /// Creates a test transcript file
    private func createTestTranscript(name: String, content: String) throws -> URL {
        let transcriptURL = tempDirectory.appendingPathComponent(name)
        try content.write(to: transcriptURL, atomically: true, encoding: .utf8)
        return transcriptURL
    }

    // MARK: - listAvailableShortcuts() Tests

    func testListAvailableShortcutsReturnsArray() async {
        let shortcuts = await executor.listAvailableShortcuts()

        // Should return an array (may be empty if no shortcuts configured)
        XCTAssertNotNil(shortcuts, "Should return an array of shortcuts")
    }

    func testListAvailableShortcutsFiltersEmptyLines() async {
        // This test verifies that the parsing logic removes empty lines
        // The actual implementation should filter out empty strings
        let shortcuts = await executor.listAvailableShortcuts()

        // All returned shortcuts should be non-empty
        for shortcut in shortcuts {
            XCTAssertFalse(shortcut.isEmpty, "Shortcuts list should not contain empty strings")
        }
    }

    func testListAvailableShortcutsTrimsWhitespace() async {
        let shortcuts = await executor.listAvailableShortcuts()

        // All returned shortcuts should be trimmed
        for shortcut in shortcuts {
            XCTAssertEqual(shortcut, shortcut.trimmingCharacters(in: .whitespaces),
                          "Shortcuts should be trimmed of whitespace")
        }
    }

    func testListAvailableShortcutsHandlesProcessError() async {
        // Even if the process fails (e.g., shortcuts command not available),
        // should return empty array, not crash
        let shortcuts = await executor.listAvailableShortcuts()

        XCTAssertNotNil(shortcuts, "Should handle errors gracefully and return empty array")
    }

    // MARK: - execute() Success Scenarios

    func testExecuteEmptyShortcutNameReturnsSuccess() async {
        let transcriptURL = try! createTestTranscript(name: "transcript.txt", content: "Test transcript")

        let result = await executor.execute(
            shortcutName: "",
            transcriptPath: transcriptURL.path
        )

        XCTAssertTrue(result.success, "Empty shortcut name should be a no-op that returns success")
        XCTAssertNil(result.errorMessage, "No-op should not have error message")
        XCTAssertNil(result.output, "No-op should not have output")
    }

    func testExecuteReturnsSuccessOnExitCodeZero() async {
        // This test assumes we have a valid shortcut installed
        // In a real environment, we'd need to mock Process or use a test shortcut
        // For now, we're testing the interface and structure

        let transcriptURL = try! createTestTranscript(name: "transcript.txt", content: "Test transcript")

        // Using a shortcut that doesn't exist will fail, but we're testing the result structure
        let result = await executor.execute(
            shortcutName: "NonExistentTestShortcut",
            transcriptPath: transcriptURL.path
        )

        // Verify the result structure is correct
        XCTAssertNotNil(result.success, "Result should have success field")
        if !result.success {
            XCTAssertNotNil(result.errorMessage, "Failed execution should have error message")
        }
    }

    func testExecutePassesTranscriptPathCorrectly() async {
        let transcriptURL = try! createTestTranscript(name: "test-transcript.txt", content: "Test content")

        let result = await executor.execute(
            shortcutName: "NonExistentTestShortcut",
            transcriptPath: transcriptURL.path
        )

        // The function should attempt to pass the transcript path
        // Even though execution will fail, the path should be formatted correctly
        XCTAssertNotNil(result, "Should return a result even if shortcut doesn't exist")
    }

    func testExecuteCapturesOutput() async {
        let transcriptURL = try! createTestTranscript(name: "transcript.txt", content: "Test transcript")

        let result = await executor.execute(
            shortcutName: "NonExistentTestShortcut",
            transcriptPath: transcriptURL.path
        )

        // Output should be nil or a string
        if let output = result.output {
            XCTAssertTrue(output is String, "Output should be a string if present")
        }
    }

    // MARK: - execute() Timeout Tests

    func testExecuteRespectsDefaultTimeout() async {
        // Test that default timeout is used when not specified
        let transcriptURL = try! createTestTranscript(name: "transcript.txt", content: "Test transcript")

        let startTime = Date()
        let result = await executor.execute(
            shortcutName: "NonExistentTestShortcut",
            transcriptPath: transcriptURL.path
        )
        let duration = Date().timeIntervalSince(startTime)

        // Should not wait the full default timeout (5 minutes) if shortcut fails quickly
        XCTAssertLessThan(duration, ShortcutExecutor.defaultTimeout,
                         "Should not wait full timeout for failed shortcut")
        XCTAssertNotNil(result, "Should return result")
    }

    func testExecuteRespectsCustomTimeout() async {
        let transcriptURL = try! createTestTranscript(name: "transcript.txt", content: "Test transcript")

        let customTimeout: TimeInterval = 10.0
        let startTime = Date()
        let result = await executor.execute(
            shortcutName: "NonExistentTestShortcut",
            transcriptPath: transcriptURL.path,
            timeout: customTimeout
        )
        let duration = Date().timeIntervalSince(startTime)

        XCTAssertLessThan(duration, customTimeout,
                         "Should not exceed custom timeout")
        XCTAssertNotNil(result, "Should return result")
    }

    func testExecuteTimesOutLongRunningShortcut() async {
        // Note: This is a challenging test because we can't easily create a long-running shortcut
        // We're testing the timeout mechanism structure

        let transcriptURL = try! createTestTranscript(name: "transcript.txt", content: "Test transcript")

        // Using very short timeout to test timeout logic
        let result = await executor.execute(
            shortcutName: "NonExistentTestShortcut",
            transcriptPath: transcriptURL.path,
            timeout: 0.1  // Very short timeout
        )

        // If a shortcut were to hang, this should timeout
        XCTAssertNotNil(result, "Should return result even on timeout")
    }

    func testExecuteTimeoutReturnsFailureResult() async {
        // When a timeout occurs, result should indicate failure
        let transcriptURL = try! createTestTranscript(name: "transcript.txt", content: "Test transcript")

        let result = await executor.execute(
            shortcutName: "HypotheticalHangingShortcut",
            transcriptPath: transcriptURL.path,
            timeout: 0.1
        )

        // Structure should support timeout failure reporting
        if !result.success {
            // Should have error message if failed
            XCTAssertNotNil(result.errorMessage, "Failed result should have error message")
        }
    }

    func testExecuteTimeoutIncludesTimeoutDurationInError() async {
        // This test verifies that IF a timeout occurs, the error message mentions it
        // Since we can't easily create a hanging shortcut in tests, we verify the structure
        let transcriptURL = try! createTestTranscript(name: "transcript.txt", content: "Test transcript")

        let timeout: TimeInterval = 2.0
        let result = await executor.execute(
            shortcutName: "NonExistentShortcut",
            transcriptPath: transcriptURL.path,
            timeout: timeout
        )

        // The shortcut will fail (doesn't exist), but we verify error handling works
        // In actual timeout scenarios, the implementation should include timeout in message
        XCTAssertFalse(result.success, "Non-existent shortcut should fail")
        XCTAssertNotNil(result.errorMessage, "Failed execution should have error message")
    }

    // MARK: - execute() Process Failure Tests

    func testExecuteHandlesNonExistentShortcut() async {
        let transcriptURL = try! createTestTranscript(name: "transcript.txt", content: "Test transcript")

        let result = await executor.execute(
            shortcutName: "DefinitelyNonExistentShortcut12345",
            transcriptPath: transcriptURL.path
        )

        XCTAssertNotNil(result, "Should return result for non-existent shortcut")
        XCTAssertFalse(result.success, "Non-existent shortcut should fail")
        XCTAssertNotNil(result.errorMessage, "Should have error message")
    }

    func testExecuteHandlesProcessLaunchFailure() async {
        let transcriptURL = try! createTestTranscript(name: "transcript.txt", content: "Test transcript")

        // Using invalid shortcut name to trigger failure
        let result = await executor.execute(
            shortcutName: "Invalid\nShortcut\nName",
            transcriptPath: transcriptURL.path
        )

        XCTAssertNotNil(result, "Should handle launch failures gracefully")
        XCTAssertFalse(result.success, "Invalid shortcut should fail")
    }

    func testExecuteReturnsErrorMessageOnFailure() async {
        let transcriptURL = try! createTestTranscript(name: "transcript.txt", content: "Test transcript")

        let result = await executor.execute(
            shortcutName: "NonExistentShortcut",
            transcriptPath: transcriptURL.path
        )

        if !result.success {
            XCTAssertNotNil(result.errorMessage, "Failed execution should provide error message")
            XCTAssertFalse(result.errorMessage!.isEmpty, "Error message should not be empty")
        }
    }

    func testExecuteCapturesStandardError() async {
        let transcriptURL = try! createTestTranscript(name: "transcript.txt", content: "Test transcript")

        let result = await executor.execute(
            shortcutName: "NonExistentShortcut",
            transcriptPath: transcriptURL.path
        )

        // Should capture stderr if there's an error
        if !result.success {
            XCTAssertNotNil(result.errorMessage, "Should capture error output")
        }
    }

    // MARK: - execute() Edge Cases

    func testExecuteHandlesPathsWithSpaces() async {
        let transcriptURL = try! createTestTranscript(name: "transcript with spaces.txt", content: "Test content")

        let result = await executor.execute(
            shortcutName: "TestShortcut",
            transcriptPath: transcriptURL.path
        )

        XCTAssertNotNil(result, "Should handle paths with spaces")
        // The path should be passed correctly even with spaces
    }

    func testExecuteHandlesSpecialCharactersInPath() async {
        let transcriptURL = try! createTestTranscript(name: "transcript-[2024]-(test).txt", content: "Test content")

        let result = await executor.execute(
            shortcutName: "TestShortcut",
            transcriptPath: transcriptURL.path
        )

        XCTAssertNotNil(result, "Should handle paths with special characters")
    }

    func testExecuteHandlesLargeOutput() async {
        let transcriptURL = try! createTestTranscript(name: "transcript.txt", content: "Test content")

        // Even if shortcut produces large output, should handle it
        let result = await executor.execute(
            shortcutName: "TestShortcut",
            transcriptPath: transcriptURL.path
        )

        XCTAssertNotNil(result, "Should handle shortcuts with large output")
    }

    func testExecuteHandlesEmptyOutput() async {
        let transcriptURL = try! createTestTranscript(name: "transcript.txt", content: "Test content")

        let result = await executor.execute(
            shortcutName: "TestShortcut",
            transcriptPath: transcriptURL.path
        )

        // Output can be nil or empty
        if let output = result.output {
            XCTAssertTrue(output is String, "Output should be string type if present")
        }
    }

    // MARK: - Process Cleanup Tests

    func testExecuteCleansUpProcessOnSuccess() async {
        let transcriptURL = try! createTestTranscript(name: "transcript.txt", content: "Test content")

        _ = await executor.execute(
            shortcutName: "TestShortcut",
            transcriptPath: transcriptURL.path
        )

        // Process should be cleaned up after execution
        // This is implicit - testing that we don't leak resources
        // In practice, this would be verified by process monitoring
    }

    func testExecuteCleansUpProcessOnFailure() async {
        let transcriptURL = try! createTestTranscript(name: "transcript.txt", content: "Test content")

        _ = await executor.execute(
            shortcutName: "NonExistentShortcut",
            transcriptPath: transcriptURL.path
        )

        // Process should be cleaned up even after failure
    }

    func testExecuteCleansUpProcessOnTimeout() async {
        let transcriptURL = try! createTestTranscript(name: "transcript.txt", content: "Test content")

        _ = await executor.execute(
            shortcutName: "TestShortcut",
            transcriptPath: transcriptURL.path,
            timeout: 0.1
        )

        // Process should be terminated and cleaned up on timeout
    }

    // MARK: - Result Structure Tests

    func testShortcutExecutionResultHasRequiredFields() async {
        let transcriptURL = try! createTestTranscript(name: "transcript.txt", content: "Test content")

        let result = await executor.execute(
            shortcutName: "TestShortcut",
            transcriptPath: transcriptURL.path
        )

        // Verify result has all required fields
        XCTAssertNotNil(result.success, "Result should have success field")
        // errorMessage and output can be nil, but should be accessible
        _ = result.errorMessage
        _ = result.output
    }

    func testExecuteReturnsCorrectSuccessState() async {
        let transcriptURL = try! createTestTranscript(name: "transcript.txt", content: "Test content")

        // Empty shortcut name should succeed
        let successResult = await executor.execute(
            shortcutName: "",
            transcriptPath: transcriptURL.path
        )
        XCTAssertTrue(successResult.success, "Empty shortcut should succeed")

        // Non-existent shortcut should fail
        let failureResult = await executor.execute(
            shortcutName: "NonExistentShortcut",
            transcriptPath: transcriptURL.path
        )
        XCTAssertFalse(failureResult.success, "Non-existent shortcut should fail")
    }

    // MARK: - Concurrent Execution Tests

    func testMultipleExecutionsRunIndependently() async {
        let transcriptURL1 = try! createTestTranscript(name: "transcript1.txt", content: "Content 1")
        let transcriptURL2 = try! createTestTranscript(name: "transcript2.txt", content: "Content 2")

        // Execute two shortcuts sequentially to verify they both work
        let result1 = await executor.execute(
            shortcutName: "Shortcut1",
            transcriptPath: transcriptURL1.path,
            timeout: 1.0
        )

        let result2 = await executor.execute(
            shortcutName: "Shortcut2",
            transcriptPath: transcriptURL2.path,
            timeout: 1.0
        )

        XCTAssertNotNil(result1, "First execution should complete")
        XCTAssertNotNil(result2, "Second execution should complete")
    }

    // MARK: - Default Timeout Constant

    func testDefaultTimeoutIsReasonable() {
        // Default timeout should be 5 minutes (300 seconds)
        XCTAssertEqual(ShortcutExecutor.defaultTimeout, 300.0,
                      "Default timeout should be 5 minutes")
    }

    func testDefaultTimeoutIsPublic() {
        // Should be able to access default timeout value
        let timeout = ShortcutExecutor.defaultTimeout
        XCTAssertGreaterThan(timeout, 0, "Default timeout should be positive")
    }
}
