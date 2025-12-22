import XCTest
@testable import CallTranscription

@MainActor
final class URLSchemeHandlerIntegrationTests: XCTestCase {
    private var handler: URLSchemeHandler!
    private var mockAppState: MockAppStateForIntegration!
    private var mockSettingsManager: SettingsManager!
    private var mockWorkspace: MockNSWorkspaceForIntegration!
    private var tempDirectory: URL!

    override func setUp() async throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("URLSchemeHandlerIntegrationTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        mockAppState = MockAppStateForIntegration()

        let testSuiteName = "URLSchemeHandlerIntegrationTests-\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: testSuiteName)!
        mockSettingsManager = SettingsManager(userDefaults: testDefaults)
        mockSettingsManager.outputFolder = tempDirectory.path

        mockWorkspace = MockNSWorkspaceForIntegration()

        handler = URLSchemeHandler(
            appState: mockAppState,
            workspace: mockWorkspace
        )
    }

    override func tearDown() async throws {
        handler = nil
        mockAppState = nil
        mockSettingsManager = nil
        mockWorkspace = nil

        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
    }

    // MARK: - End-to-End Start Action

    func testHandleStartURLWithSuccessCallback() async throws {
        let url = URL(string: "olive://x-callback-url/start?title=Test&x-success=shortcuts://success")!

        await handler.handle(url)

        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        XCTAssertTrue(mockAppState.startRecordingCalled)
        XCTAssertEqual(mockAppState.lastRecordingTitle, "Test")
        XCTAssertEqual(mockWorkspace.lastOpenedURL?.absoluteString, "shortcuts://success")
    }

    func testHandleStartURLWithError() async throws {
        mockAppState.shouldFailStart = true
        let url = URL(string: "olive://x-callback-url/start?x-error=shortcuts://error")!

        await handler.handle(url)

        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        let opened = mockWorkspace.lastOpenedURL?.absoluteString ?? ""
        XCTAssertTrue(opened.starts(with: "shortcuts://error"))
        XCTAssertTrue(opened.contains("errorMessage="))
    }

    func testHandleStartURLWithAllParameters() async throws {
        let customFolder = tempDirectory.appendingPathComponent("custom").path
        try FileManager.default.createDirectory(atPath: customFolder, withIntermediateDirectories: true)

        let url = URL(string: "olive://x-callback-url/start?title=Meeting&outputFolder=\(customFolder.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&filenameTemplate=meeting_{date}.txt&x-success=shortcuts://")!

        await handler.handle(url)

        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        XCTAssertTrue(mockAppState.startRecordingCalled)
        XCTAssertEqual(mockAppState.lastRecordingTitle, "Meeting")
        // Settings should NOT be modified (overrides are used instead)
        XCTAssertNotEqual(mockSettingsManager.outputFolder, customFolder)
        XCTAssertNotEqual(mockSettingsManager.filenameTemplate, "meeting_{date}.txt")
        XCTAssertNotNil(mockWorkspace.lastOpenedURL)
    }

    // MARK: - End-to-End Stop Action

    func testHandleStopURLWithSuccessCallback() async throws {
        mockAppState.isRecording = true
        let transcriptURL = tempDirectory.appendingPathComponent("transcript.txt")
        try "Test".write(to: transcriptURL, atomically: true, encoding: .utf8)
        mockAppState.mockTranscriptURL = transcriptURL

        let url = URL(string: "olive://x-callback-url/stop?x-success=shortcuts://success")!

        await handler.handle(url)

        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        XCTAssertTrue(mockAppState.stopRecordingCalled)
        let opened = mockWorkspace.lastOpenedURL?.absoluteString ?? ""
        XCTAssertTrue(opened.contains("shortcuts://success"))
        XCTAssertTrue(opened.contains("transcriptURL="))
    }

    func testHandleStopURLWhenNotRecording() async throws {
        mockAppState.isRecording = false

        let url = URL(string: "olive://x-callback-url/stop?x-error=shortcuts://error")!

        await handler.handle(url)

        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        let opened = mockWorkspace.lastOpenedURL?.absoluteString ?? ""
        XCTAssertTrue(opened.contains("shortcuts://error"))
        XCTAssertTrue(opened.contains("errorMessage="))
    }

    // MARK: - End-to-End Pause/Resume Actions

    func testHandlePauseURL() async throws {
        mockAppState.isRecording = true
        mockAppState.isPaused = false

        let url = URL(string: "olive://x-callback-url/pause?x-success=shortcuts://")!

        await handler.handle(url)

        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        XCTAssertTrue(mockAppState.pauseRecordingCalled)
        XCTAssertNotNil(mockWorkspace.lastOpenedURL)
    }

    func testHandleResumeURL() async throws {
        mockAppState.isRecording = true
        mockAppState.isPaused = true

        let url = URL(string: "olive://x-callback-url/resume?x-success=shortcuts://")!

        await handler.handle(url)

        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        XCTAssertTrue(mockAppState.resumeRecordingCalled)
        XCTAssertNotNil(mockWorkspace.lastOpenedURL)
    }

    // MARK: - Error Handling

    func testHandleInvalidSchemeURL() async throws {
        let url = URL(string: "http://x-callback-url/start?x-error=shortcuts://error")!

        await handler.handle(url)

        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // When URL scheme is invalid, parsing fails and we cannot extract error callback
        // So no callback should be invoked (error is just logged)
        XCTAssertNil(mockWorkspace.lastOpenedURL)
    }

    func testHandleInvalidActionURL() async throws {
        let url = URL(string: "olive://x-callback-url/invalid?x-error=shortcuts://error")!

        await handler.handle(url)

        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // When action is invalid, parsing fails and we cannot extract error callback
        // So no callback should be invoked (error is just logged)
        XCTAssertNil(mockWorkspace.lastOpenedURL)
    }

    func testHandleSecurityViolation() async throws {
        let url = URL(string: "olive://x-callback-url/start?outputFolder=/etc/passwd&x-error=shortcuts://error")!

        await handler.handle(url)

        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        let opened = mockWorkspace.lastOpenedURL?.absoluteString ?? ""
        XCTAssertTrue(opened.contains("shortcuts://error"))
        XCTAssertTrue(opened.contains("errorMessage="))
    }

    // MARK: - Complex Scenarios

    func testHandleMultipleURLsInSequence() async throws {
        // Start recording
        let startURL = URL(string: "olive://x-callback-url/start?title=Test")!
        await handler.handle(startURL)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(mockAppState.startRecordingCalled)

        // Pause recording
        mockAppState.isRecording = true
        let pauseURL = URL(string: "olive://x-callback-url/pause")!
        await handler.handle(pauseURL)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(mockAppState.pauseRecordingCalled)

        // Resume recording
        mockAppState.isPaused = true
        let resumeURL = URL(string: "olive://x-callback-url/resume")!
        await handler.handle(resumeURL)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(mockAppState.resumeRecordingCalled)

        // Stop recording
        let transcriptURL = tempDirectory.appendingPathComponent("transcript.txt")
        try "Test".write(to: transcriptURL, atomically: true, encoding: .utf8)
        mockAppState.mockTranscriptURL = transcriptURL
        mockAppState.isPaused = false

        let stopURL = URL(string: "olive://x-callback-url/stop")!
        await handler.handle(stopURL)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(mockAppState.stopRecordingCalled)
    }
}

// MARK: - Mock AppState for Integration

@MainActor
private class MockAppStateForIntegration: RecordingActionHandler {
    var isRecording = false
    var isPaused = false

    var startRecordingCalled = false
    var stopRecordingCalled = false
    var pauseRecordingCalled = false
    var resumeRecordingCalled = false
    var lastRecordingTitle: String?
    var mockTranscriptURL: URL?
    var shouldFailStart = false

    func startActualRecording(title: String, overrides: RecordingSessionOverrides?) async throws {
        if shouldFailStart {
            throw CallTranscriptionError.alreadyRecording
        }
        startRecordingCalled = true
        lastRecordingTitle = title
        isRecording = true
    }

    func stopActualRecording() async throws -> URL {
        stopRecordingCalled = true
        isRecording = false
        guard let url = mockTranscriptURL else {
            throw CallTranscriptionError.notRecording
        }
        return url
    }

    func pauseRecording() async throws {
        pauseRecordingCalled = true
        isPaused = true
    }

    func resumeRecording() async throws {
        resumeRecordingCalled = true
        isPaused = false
    }
}

// MARK: - Mock NSWorkspace for Integration

@MainActor
private class MockNSWorkspaceForIntegration: NSWorkspaceProtocol {
    var lastOpenedURL: URL?

    func open(_ url: URL) -> Bool {
        lastOpenedURL = url
        return true
    }
}
