import XCTest
@testable import CallTranscription

@MainActor
final class URLSchemeActionDispatcherTests: XCTestCase {
    private var dispatcher: URLSchemeActionDispatcher!
    private var mockAppState: MockAppState!
    private var mockSettingsManager: SettingsManager!
    private var tempDirectory: URL!

    override func setUp() async throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("URLSchemeActionDispatcherTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        mockAppState = MockAppState()

        let testSuiteName = "URLSchemeActionDispatcherTests-\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: testSuiteName)!
        mockSettingsManager = SettingsManager(userDefaults: testDefaults)
        mockSettingsManager.outputFolder = tempDirectory.path

        dispatcher = URLSchemeActionDispatcher(appState: mockAppState)
    }

    override func tearDown() async throws {
        dispatcher = nil
        mockAppState = nil
        mockSettingsManager = nil

        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
    }

    // MARK: - Start Action

    func testDispatchStartActionWithoutParameters() async throws {
        let request = URLSchemeRequest(
            action: .start,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        let result = try await dispatcher.dispatch(request)

        XCTAssertTrue(mockAppState.startRecordingCalled)
        // When no title is provided, a default localized title is used
        XCTAssertEqual(mockAppState.lastRecordingTitle, NSLocalizedString("url.recording.defaultTitle", comment: "Default recording title from URL scheme"))
        // When no folder/template provided, overrides should be nil
        XCTAssertNil(mockAppState.lastSessionOverrides)
        XCTAssertNil(result.transcriptURL)
    }

    func testDispatchStartActionWithTitle() async throws {
        let request = URLSchemeRequest(
            action: .start,
            title: "Team Meeting",
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        let result = try await dispatcher.dispatch(request)

        XCTAssertTrue(mockAppState.startRecordingCalled)
        XCTAssertEqual(mockAppState.lastRecordingTitle, "Team Meeting")
        // When no folder/template provided, overrides should be nil
        XCTAssertNil(mockAppState.lastSessionOverrides)
        XCTAssertNil(result.transcriptURL)
    }

    func testDispatchStartActionWithOutputFolder() async throws {
        let customFolder = tempDirectory.appendingPathComponent("custom").path
        try FileManager.default.createDirectory(atPath: customFolder, withIntermediateDirectories: true)

        let request = URLSchemeRequest(
            action: .start,
            title: nil,
            outputFolder: customFolder,
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        _ = try await dispatcher.dispatch(request)

        XCTAssertTrue(mockAppState.startRecordingCalled)
        // Verify session overrides were provided (NOT that settings were modified)
        XCTAssertNotNil(mockAppState.lastSessionOverrides)
        XCTAssertEqual(mockAppState.lastSessionOverrides?.outputFolder, customFolder)
        XCTAssertNil(mockAppState.lastSessionOverrides?.filenameTemplate)
        // Verify settings were NOT modified
        XCTAssertNotEqual(mockSettingsManager.outputFolder, customFolder)
    }

    func testDispatchStartActionWithFilenameTemplate() async throws {
        let request = URLSchemeRequest(
            action: .start,
            title: nil,
            outputFolder: nil,
            filenameTemplate: "meeting_{date}.txt",
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        _ = try await dispatcher.dispatch(request)

        XCTAssertTrue(mockAppState.startRecordingCalled)
        // Verify session overrides were provided (NOT that settings were modified)
        XCTAssertNotNil(mockAppState.lastSessionOverrides)
        XCTAssertEqual(mockAppState.lastSessionOverrides?.filenameTemplate, "meeting_{date}.txt")
        XCTAssertNil(mockAppState.lastSessionOverrides?.outputFolder)
        // Verify settings were NOT modified
        XCTAssertNotEqual(mockSettingsManager.filenameTemplate, "meeting_{date}.txt")
    }

    func testDispatchStartActionWithAllParameters() async throws {
        let customFolder = tempDirectory.appendingPathComponent("custom").path
        try FileManager.default.createDirectory(atPath: customFolder, withIntermediateDirectories: true)

        let request = URLSchemeRequest(
            action: .start,
            title: "Daily Standup",
            outputFolder: customFolder,
            filenameTemplate: "standup_{date}.txt",
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        _ = try await dispatcher.dispatch(request)

        XCTAssertTrue(mockAppState.startRecordingCalled)
        XCTAssertEqual(mockAppState.lastRecordingTitle, "Daily Standup")
        // Verify session overrides were provided (NOT that settings were modified)
        XCTAssertNotNil(mockAppState.lastSessionOverrides)
        XCTAssertEqual(mockAppState.lastSessionOverrides?.outputFolder, customFolder)
        XCTAssertEqual(mockAppState.lastSessionOverrides?.filenameTemplate, "standup_{date}.txt")
        // Verify settings were NOT modified
        XCTAssertNotEqual(mockSettingsManager.outputFolder, customFolder)
        XCTAssertNotEqual(mockSettingsManager.filenameTemplate, "standup_{date}.txt")
    }

    func testDispatchStartActionWhenAlreadyRecording() async throws {
        mockAppState.isRecording = true

        let request = URLSchemeRequest(
            action: .start,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        await XCTAssertThrowsErrorAsync({ try await dispatcher.dispatch(request) }) { error in
            guard case CallTranscriptionError.alreadyRecording = error else {
                XCTFail("Expected alreadyRecording error, got \(error)")
                return
            }
        }
    }

    // MARK: - Stop Action

    func testDispatchStopAction() async throws {
        mockAppState.isRecording = true
        let mockTranscriptURL = tempDirectory.appendingPathComponent("transcript.txt")
        try "Test transcript".write(to: mockTranscriptURL, atomically: true, encoding: .utf8)
        mockAppState.mockTranscriptURL = mockTranscriptURL

        let request = URLSchemeRequest(
            action: .stop,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        let result = try await dispatcher.dispatch(request)

        XCTAssertTrue(mockAppState.stopRecordingCalled)
        XCTAssertEqual(result.transcriptURL, mockTranscriptURL)
    }

    func testDispatchStopActionWhenNotRecording() async throws {
        mockAppState.isRecording = false

        let request = URLSchemeRequest(
            action: .stop,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        await XCTAssertThrowsErrorAsync({ try await dispatcher.dispatch(request) }) { error in
            guard case CallTranscriptionError.notRecording = error else {
                XCTFail("Expected notRecording error, got \(error)")
                return
            }
        }
    }

    // MARK: - Pause Action

    func testDispatchPauseAction() async throws {
        mockAppState.isRecording = true
        mockAppState.isPaused = false

        let request = URLSchemeRequest(
            action: .pause,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        _ = try await dispatcher.dispatch(request)

        XCTAssertTrue(mockAppState.pauseRecordingCalled)
    }

    func testDispatchPauseActionWhenNotRecording() async throws {
        mockAppState.isRecording = false

        let request = URLSchemeRequest(
            action: .pause,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        await XCTAssertThrowsErrorAsync({ try await dispatcher.dispatch(request) }) { error in
            guard case CallTranscriptionError.notRecording = error else {
                XCTFail("Expected notRecording error, got \(error)")
                return
            }
        }
    }

    func testDispatchPauseActionWhenAlreadyPaused() async throws {
        mockAppState.isRecording = true
        mockAppState.isPaused = true

        let request = URLSchemeRequest(
            action: .pause,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        await XCTAssertThrowsErrorAsync({ try await dispatcher.dispatch(request) }) { error in
            guard case CallTranscriptionError.alreadyPaused = error else {
                XCTFail("Expected alreadyPaused error, got \(error)")
                return
            }
        }
    }

    // MARK: - Resume Action

    func testDispatchResumeAction() async throws {
        mockAppState.isRecording = true
        mockAppState.isPaused = true

        let request = URLSchemeRequest(
            action: .resume,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        _ = try await dispatcher.dispatch(request)

        XCTAssertTrue(mockAppState.resumeRecordingCalled)
    }

    func testDispatchResumeActionWhenNotRecording() async throws {
        mockAppState.isRecording = false

        let request = URLSchemeRequest(
            action: .resume,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        await XCTAssertThrowsErrorAsync({ try await dispatcher.dispatch(request) }) { error in
            guard case CallTranscriptionError.notRecording = error else {
                XCTFail("Expected notRecording error, got \(error)")
                return
            }
        }
    }

    func testDispatchResumeActionWhenNotPaused() async throws {
        mockAppState.isRecording = true
        mockAppState.isPaused = false

        let request = URLSchemeRequest(
            action: .resume,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        await XCTAssertThrowsErrorAsync({ try await dispatcher.dispatch(request) }) { error in
            guard case CallTranscriptionError.notPaused = error else {
                XCTFail("Expected notPaused error, got \(error)")
                return
            }
        }
    }

    // MARK: - Path Validation

    func testDispatchStartWithInvalidOutputFolder() async throws {
        let request = URLSchemeRequest(
            action: .start,
            title: nil,
            outputFolder: "/etc/passwd",
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        await XCTAssertThrowsErrorAsync({ try await dispatcher.dispatch(request) }) { error in
            guard case CallTranscriptionError.pathOutsideAllowedDirectories = error else {
                XCTFail("Expected pathOutsideAllowedDirectories error, got \(error)")
                return
            }
        }
    }

    func testDispatchStartWithPathTraversal() async throws {
        let request = URLSchemeRequest(
            action: .start,
            title: nil,
            outputFolder: tempDirectory.path + "/../../../etc",
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        await XCTAssertThrowsErrorAsync({ try await dispatcher.dispatch(request) }) { error in
            // PathValidator now throws pathTraversalDetected for .. sequences
            guard case CallTranscriptionError.pathTraversalDetected = error else {
                XCTFail("Expected pathTraversalDetected error, got \(error)")
                return
            }
        }
    }

    // MARK: - Template Validation

    func testDispatchStartWithInvalidTemplate() async throws {
        let request = URLSchemeRequest(
            action: .start,
            title: nil,
            outputFolder: nil,
            filenameTemplate: "../evil.txt",
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        await XCTAssertThrowsErrorAsync({ try await dispatcher.dispatch(request) }) { error in
            guard case CallTranscriptionError.invalidFilenameTemplate = error else {
                XCTFail("Expected invalidFilenameTemplate error, got \(error)")
                return
            }
        }
    }

    func testDispatchStartWithTemplateContainingSlash() async throws {
        let request = URLSchemeRequest(
            action: .start,
            title: nil,
            outputFolder: nil,
            filenameTemplate: "folder/file.txt",
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        await XCTAssertThrowsErrorAsync({ try await dispatcher.dispatch(request) }) { error in
            guard case CallTranscriptionError.invalidFilenameTemplate = error else {
                XCTFail("Expected invalidFilenameTemplate error, got \(error)")
                return
            }
        }
    }
}

// MARK: - Mock AppState

@MainActor
private class MockAppState: RecordingActionHandler {
    var isRecording = false
    var isPaused = false

    var startRecordingCalled = false
    var stopRecordingCalled = false
    var pauseRecordingCalled = false
    var resumeRecordingCalled = false
    var lastRecordingTitle: String?
    var mockTranscriptURL: URL?

    var lastSessionOverrides: RecordingSessionOverrides?

    func startActualRecording(title: String, overrides: RecordingSessionOverrides?) async throws {
        startRecordingCalled = true
        lastRecordingTitle = title
        lastSessionOverrides = overrides
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

// MARK: - XCTest Async Error Assertion Helper

@MainActor
func XCTAssertThrowsErrorAsync<T>(
    _ expression: () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (_ error: Error) -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        XCTFail(message(), file: file, line: line)
    } catch {
        errorHandler(error)
    }
}
