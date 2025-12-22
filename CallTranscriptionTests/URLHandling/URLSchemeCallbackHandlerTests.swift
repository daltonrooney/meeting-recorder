import XCTest
@testable import CallTranscription

@MainActor
final class URLSchemeCallbackHandlerTests: XCTestCase {
    private var handler: URLSchemeCallbackHandler!
    private var mockWorkspace: MockNSWorkspace!

    override func setUp() async throws {
        mockWorkspace = MockNSWorkspace()
        handler = URLSchemeCallbackHandler(workspace: mockWorkspace)
    }

    override func tearDown() async throws {
        handler = nil
        mockWorkspace = nil
    }

    // MARK: - Success Callbacks

    func testInvokeSuccessCallbackWithoutURL() async {
        let request = URLSchemeRequest(
            action: .start,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        let result = URLSchemeActionResult(transcriptURL: nil)

        await handler.invokeCallback(for: request, result: result, error: nil)

        XCTAssertNil(mockWorkspace.lastOpenedURL)
    }

    func testInvokeSuccessCallbackWithSimpleURL() async {
        let successURL = URL(string: "shortcuts://")!
        let request = URLSchemeRequest(
            action: .start,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: successURL,
            errorCallback: nil,
            cancelCallback: nil
        )

        let result = URLSchemeActionResult(transcriptURL: nil)

        await handler.invokeCallback(for: request, result: result, error: nil)

        XCTAssertEqual(mockWorkspace.lastOpenedURL?.absoluteString, "shortcuts://")
    }

    func testInvokeSuccessCallbackWithTranscriptURL() async {
        let transcriptURL = URL(fileURLWithPath: "/Users/test/transcript.txt")
        let successURL = URL(string: "shortcuts://callback")!
        let request = URLSchemeRequest(
            action: .stop,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: successURL,
            errorCallback: nil,
            cancelCallback: nil
        )

        let result = URLSchemeActionResult(transcriptURL: transcriptURL)

        await handler.invokeCallback(for: request, result: result, error: nil)

        let opened = mockWorkspace.lastOpenedURL?.absoluteString ?? ""
        XCTAssertTrue(opened.starts(with: "shortcuts://callback"))
        XCTAssertTrue(opened.contains("transcriptURL="))
        XCTAssertTrue(opened.contains(transcriptURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!))
    }

    func testInvokeSuccessCallbackWithExistingQueryParameters() async {
        let transcriptURL = URL(fileURLWithPath: "/Users/test/transcript.txt")
        let successURL = URL(string: "shortcuts://run-shortcut?name=AfterRecording")!
        let request = URLSchemeRequest(
            action: .stop,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: successURL,
            errorCallback: nil,
            cancelCallback: nil
        )

        let result = URLSchemeActionResult(transcriptURL: transcriptURL)

        await handler.invokeCallback(for: request, result: result, error: nil)

        let opened = mockWorkspace.lastOpenedURL?.absoluteString ?? ""
        XCTAssertTrue(opened.starts(with: "shortcuts://run-shortcut"))
        XCTAssertTrue(opened.contains("name=AfterRecording"))
        XCTAssertTrue(opened.contains("transcriptURL="))
    }

    // MARK: - Error Callbacks

    func testInvokeErrorCallbackWithoutURL() async {
        let request = URLSchemeRequest(
            action: .start,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        let error = CallTranscriptionError.alreadyRecording

        await handler.invokeCallback(for: request, result: nil, error: error)

        XCTAssertNil(mockWorkspace.lastOpenedURL)
    }

    func testInvokeErrorCallbackWithURL() async {
        let errorURL = URL(string: "shortcuts://error")!
        let request = URLSchemeRequest(
            action: .start,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: errorURL,
            cancelCallback: nil
        )

        let error = CallTranscriptionError.alreadyRecording

        await handler.invokeCallback(for: request, result: nil, error: error)

        let opened = mockWorkspace.lastOpenedURL?.absoluteString ?? ""
        XCTAssertTrue(opened.starts(with: "shortcuts://error"))
        XCTAssertTrue(opened.contains("errorMessage="))
    }

    func testInvokeErrorCallbackWithCustomError() async {
        let errorURL = URL(string: "shortcuts://error")!
        let request = URLSchemeRequest(
            action: .stop,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: errorURL,
            cancelCallback: nil
        )

        let error = CallTranscriptionError.notRecording

        await handler.invokeCallback(for: request, result: nil, error: error)

        let opened = mockWorkspace.lastOpenedURL?.absoluteString ?? ""
        XCTAssertTrue(opened.contains("errorMessage="))
        // Check for "recording" which appears in "No recording session is currently active."
        XCTAssertTrue(opened.contains("recording".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!))
    }

    func testInvokeErrorCallbackWithPathError() async {
        let errorURL = URL(string: "shortcuts://error")!
        let request = URLSchemeRequest(
            action: .start,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: errorURL,
            cancelCallback: nil
        )

        let error = CallTranscriptionError.pathOutsideAllowedDirectories(
            "/etc/passwd",
            allowedDirectories: ["/Users/test"]
        )

        await handler.invokeCallback(for: request, result: nil, error: error)

        let opened = mockWorkspace.lastOpenedURL?.absoluteString ?? ""
        XCTAssertTrue(opened.contains("errorMessage="))
    }

    // MARK: - Cancel Callbacks

    func testInvokeCancelCallback() async {
        let cancelURL = URL(string: "shortcuts://cancel")!
        let request = URLSchemeRequest(
            action: .pause,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: cancelURL
        )

        await handler.invokeCancel(for: request)

        XCTAssertEqual(mockWorkspace.lastOpenedURL?.absoluteString, "shortcuts://cancel")
    }

    func testInvokeCancelCallbackWithoutURL() async {
        let request = URLSchemeRequest(
            action: .pause,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: nil,
            errorCallback: nil,
            cancelCallback: nil
        )

        await handler.invokeCancel(for: request)

        XCTAssertNil(mockWorkspace.lastOpenedURL)
    }

    // MARK: - Error Handling

    func testHandleFailedCallbackOpening() async {
        mockWorkspace.shouldFailOpen = true

        let successURL = URL(string: "shortcuts://")!
        let request = URLSchemeRequest(
            action: .start,
            title: nil,
            outputFolder: nil,
            filenameTemplate: nil,
            successCallback: successURL,
            errorCallback: nil,
            cancelCallback: nil
        )

        let result = URLSchemeActionResult(transcriptURL: nil)

        await handler.invokeCallback(for: request, result: result, error: nil)

        XCTAssertEqual(mockWorkspace.lastOpenedURL?.absoluteString, "shortcuts://")
        XCTAssertTrue(mockWorkspace.openCalled)
    }

    // MARK: - URL Building

    func testBuildCallbackURLWithNoParameters() {
        let baseURL = URL(string: "shortcuts://callback")!
        let result = handler.buildCallbackURL(base: baseURL, parameters: [:])

        XCTAssertEqual(result.absoluteString, "shortcuts://callback")
    }

    func testBuildCallbackURLWithSingleParameter() {
        let baseURL = URL(string: "shortcuts://callback")!
        let result = handler.buildCallbackURL(base: baseURL, parameters: ["key": "value"])

        XCTAssertEqual(result.absoluteString, "shortcuts://callback?key=value")
    }

    func testBuildCallbackURLWithMultipleParameters() {
        let baseURL = URL(string: "shortcuts://callback")!
        let result = handler.buildCallbackURL(
            base: baseURL,
            parameters: ["key1": "value1", "key2": "value2"]
        )

        let urlString = result.absoluteString
        XCTAssertTrue(urlString.starts(with: "shortcuts://callback?"))
        XCTAssertTrue(urlString.contains("key1=value1"))
        XCTAssertTrue(urlString.contains("key2=value2"))
    }

    func testBuildCallbackURLWithSpecialCharacters() {
        let baseURL = URL(string: "shortcuts://callback")!
        let result = handler.buildCallbackURL(
            base: baseURL,
            parameters: ["message": "Hello World!"]
        )

        XCTAssertTrue(result.absoluteString.contains("message=Hello%20World"))
    }

    func testBuildCallbackURLWithExistingQuery() {
        let baseURL = URL(string: "shortcuts://callback?existing=param")!
        let result = handler.buildCallbackURL(
            base: baseURL,
            parameters: ["new": "value"]
        )

        let urlString = result.absoluteString
        XCTAssertTrue(urlString.contains("existing=param"))
        XCTAssertTrue(urlString.contains("new=value"))
    }
}

// MARK: - Mock NSWorkspace

@MainActor
private class MockNSWorkspace: NSWorkspaceProtocol {
    var lastOpenedURL: URL?
    var openCalled = false
    var shouldFailOpen = false

    func open(_ url: URL) -> Bool {
        openCalled = true
        lastOpenedURL = url
        return !shouldFailOpen
    }
}
