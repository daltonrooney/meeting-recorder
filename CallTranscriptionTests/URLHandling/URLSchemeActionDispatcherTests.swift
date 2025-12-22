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
        mockSettingsManager = SettingsManager(defaults: testDefaults)
        mockSettingsManager.outputFolder = tempDirectory.path

        dispatcher = URLSchemeActionDispatcher(
            appState: mockAppState,
            settingsManager: mockSettingsManager
        )
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
        XCTAssertNil(mockAppState.lastRecordingTitle)
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
        XCTAssertEqual(mockSettingsManager.outputFolder, customFolder)
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
        XCTAssertEqual(mockSettingsManager.filenameTemplate, "meeting_{date}.txt")
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
        XCTAssertEqual(mockSettingsManager.outputFolder, customFolder)
        XCTAssertEqual(mockSettingsManager.filenameTemplate, "standup_{date}.txt")
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

        await XCTAssertThrowsErrorAsync(try await dispatcher.dispatch(request)) { error in
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

        await XCTAssertThrowsErrorAsync(try await dispatcher.dispatch(request)) { error in
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

        await XCTAssertThrowsErrorAsync(try await dispatcher.dispatch(request)) { error in
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

        await XCTAssertThrowsErrorAsync(try await dispatcher.dispatch(request)) { error in
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

        await XCTAssertThrowsErrorAsync(try await dispatcher.dispatch(request)) { error in
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

        await XCTAssertThrowsErrorAsync(try await dispatcher.dispatch(request)) { error in
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

        await XCTAssertThrowsErrorAsync(try await dispatcher.dispatch(request)) { error in
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

        await XCTAssertThrowsErrorAsync(try await dispatcher.dispatch(request)) { error in
            guard case CallTranscriptionError.pathOutsideAllowedDirectories = error else {
                XCTFail("Expected pathOutsideAllowedDirectories error, got \(error)")
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

        await XCTAssertThrowsErrorAsync(try await dispatcher.dispatch(request)) { error in
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

        await XCTAssertThrowsErrorAsync(try await dispatcher.dispatch(request)) { error in
            guard case CallTranscriptionError.invalidFilenameTemplate = error else {
                XCTFail("Expected invalidFilenameTemplate error, got \(error)")
                return
            }
        }
    }
}

// MARK: - Mock AppState

@MainActor
private class MockAppState: AppState {
    var startRecordingCalled = false
    var stopRecordingCalled = false
    var pauseRecordingCalled = false
    var resumeRecordingCalled = false
    var lastRecordingTitle: String?
    var mockTranscriptURL: URL?

    override func startActualRecording(title: String?) async throws {
        startRecordingCalled = true
        lastRecordingTitle = title
        isRecording = true
    }

    override func stopActualRecording() async throws -> URL {
        stopRecordingCalled = true
        isRecording = false
        guard let url = mockTranscriptURL else {
            throw CallTranscriptionError.notRecording
        }
        return url
    }

    override func pauseRecording() async throws {
        pauseRecordingCalled = true
        isPaused = true
    }

    override func resumeRecording() async throws {
        resumeRecordingCalled = true
        isPaused = false
    }
}

// MARK: - XCTest Async Error Assertion Helper

func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
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
