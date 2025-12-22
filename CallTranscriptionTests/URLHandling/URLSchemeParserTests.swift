import XCTest
@testable import CallTranscription

@MainActor
final class URLSchemeParserTests: XCTestCase {

    // MARK: - Basic URL Parsing

    func testParseValidStartAction() throws {
        let url = URL(string: "olive://x-callback-url/start")!
        let result = try URLSchemeParser.parse(url)

        XCTAssertEqual(result.action, .start)
        XCTAssertNil(result.title)
        XCTAssertNil(result.outputFolder)
        XCTAssertNil(result.filenameTemplate)
        XCTAssertNil(result.successCallback)
        XCTAssertNil(result.errorCallback)
    }

    func testParseValidStopAction() throws {
        let url = URL(string: "olive://x-callback-url/stop")!
        let result = try URLSchemeParser.parse(url)

        XCTAssertEqual(result.action, .stop)
    }

    func testParseValidPauseAction() throws {
        let url = URL(string: "olive://x-callback-url/pause")!
        let result = try URLSchemeParser.parse(url)

        XCTAssertEqual(result.action, .pause)
    }

    func testParseValidResumeAction() throws {
        let url = URL(string: "olive://x-callback-url/resume")!
        let result = try URLSchemeParser.parse(url)

        XCTAssertEqual(result.action, .resume)
    }

    // MARK: - URL with Parameters

    func testParseStartWithTitle() throws {
        let url = URL(string: "olive://x-callback-url/start?title=Team%20Meeting")!
        let result = try URLSchemeParser.parse(url)

        XCTAssertEqual(result.action, .start)
        XCTAssertEqual(result.title, "Team Meeting")
    }

    func testParseStartWithOutputFolder() throws {
        let url = URL(string: "olive://x-callback-url/start?outputFolder=%2FUsers%2Fname%2FMeetings")!
        let result = try URLSchemeParser.parse(url)

        XCTAssertEqual(result.action, .start)
        XCTAssertEqual(result.outputFolder, "/Users/name/Meetings")
    }

    func testParseStartWithFilenameTemplate() throws {
        let url = URL(string: "olive://x-callback-url/start?filenameTemplate=meeting_{date}.txt")!
        let result = try URLSchemeParser.parse(url)

        XCTAssertEqual(result.action, .start)
        XCTAssertEqual(result.filenameTemplate, "meeting_{date}.txt")
    }

    func testParseStartWithAllParameters() throws {
        let url = URL(string: "olive://x-callback-url/start?title=Daily%20Standup&outputFolder=%2FUsers%2Fname%2FMeetings&filenameTemplate=meeting_{date}.txt")!
        let result = try URLSchemeParser.parse(url)

        XCTAssertEqual(result.action, .start)
        XCTAssertEqual(result.title, "Daily Standup")
        XCTAssertEqual(result.outputFolder, "/Users/name/Meetings")
        XCTAssertEqual(result.filenameTemplate, "meeting_{date}.txt")
    }

    // MARK: - x-callback-url Callbacks

    func testParseWithSuccessCallback() throws {
        let url = URL(string: "olive://x-callback-url/start?x-success=shortcuts://")!
        let result = try URLSchemeParser.parse(url)

        XCTAssertEqual(result.action, .start)
        XCTAssertEqual(result.successCallback?.absoluteString, "shortcuts://")
    }

    func testParseWithErrorCallback() throws {
        let url = URL(string: "olive://x-callback-url/stop?x-error=shortcuts://error")!
        let result = try URLSchemeParser.parse(url)

        XCTAssertEqual(result.action, .stop)
        XCTAssertEqual(result.errorCallback?.absoluteString, "shortcuts://error")
    }

    func testParseWithCancelCallback() throws {
        let url = URL(string: "olive://x-callback-url/pause?x-cancel=shortcuts://cancel")!
        let result = try URLSchemeParser.parse(url)

        XCTAssertEqual(result.action, .pause)
        XCTAssertEqual(result.cancelCallback?.absoluteString, "shortcuts://cancel")
    }

    func testParseWithAllCallbacks() throws {
        let url = URL(string: "olive://x-callback-url/start?x-success=shortcuts://success&x-error=shortcuts://error&x-cancel=shortcuts://cancel")!
        let result = try URLSchemeParser.parse(url)

        XCTAssertEqual(result.action, .start)
        XCTAssertEqual(result.successCallback?.absoluteString, "shortcuts://success")
        XCTAssertEqual(result.errorCallback?.absoluteString, "shortcuts://error")
        XCTAssertEqual(result.cancelCallback?.absoluteString, "shortcuts://cancel")
    }

    // MARK: - Complex URL Examples

    func testParseComplexStartURL() throws {
        let url = URL(string: "olive://x-callback-url/start?title=Daily%20Standup&x-success=shortcuts://run-shortcut?name=AfterRecording")!
        let result = try URLSchemeParser.parse(url)

        XCTAssertEqual(result.action, .start)
        XCTAssertEqual(result.title, "Daily Standup")
        XCTAssertEqual(result.successCallback?.absoluteString, "shortcuts://run-shortcut?name=AfterRecording")
    }

    func testParseComplexStopURL() throws {
        let url = URL(string: "olive://x-callback-url/stop?x-success=shortcuts://&x-error=shortcuts://error")!
        let result = try URLSchemeParser.parse(url)

        XCTAssertEqual(result.action, .stop)
        XCTAssertEqual(result.successCallback?.absoluteString, "shortcuts://")
        XCTAssertEqual(result.errorCallback?.absoluteString, "shortcuts://error")
    }

    // MARK: - Invalid URLs

    func testParseInvalidScheme() {
        let url = URL(string: "http://x-callback-url/start")!

        XCTAssertThrowsError(try URLSchemeParser.parse(url)) { error in
            guard case CallTranscriptionError.invalidURLScheme(let scheme) = error else {
                XCTFail("Expected invalidURLScheme error, got \(error)")
                return
            }
            XCTAssertEqual(scheme, "http")
        }
    }

    func testParseInvalidHost() {
        let url = URL(string: "olive://invalid-host/start")!

        XCTAssertThrowsError(try URLSchemeParser.parse(url)) { error in
            guard case CallTranscriptionError.invalidURLHost(let host) = error else {
                XCTFail("Expected invalidURLHost error, got \(error)")
                return
            }
            XCTAssertEqual(host, "invalid-host")
        }
    }

    func testParseMissingAction() {
        let url = URL(string: "olive://x-callback-url/")!

        XCTAssertThrowsError(try URLSchemeParser.parse(url)) { error in
            guard case CallTranscriptionError.missingURLAction = error else {
                XCTFail("Expected missingURLAction error, got \(error)")
                return
            }
        }
    }

    func testParseInvalidAction() {
        let url = URL(string: "olive://x-callback-url/invalid")!

        XCTAssertThrowsError(try URLSchemeParser.parse(url)) { error in
            guard case CallTranscriptionError.invalidURLAction(let action) = error else {
                XCTFail("Expected invalidURLAction error, got \(error)")
                return
            }
            XCTAssertEqual(action, "invalid")
        }
    }

    // MARK: - URL Validation

    func testValidateValidCallbackURL() {
        let url = URL(string: "shortcuts://success")!
        XCTAssertNoThrow(try URLSchemeParser.validateCallbackURL(url))
    }

    func testValidateInvalidCallbackScheme() {
        let url = URL(string: "javascript:alert(1)")!

        XCTAssertThrowsError(try URLSchemeParser.validateCallbackURL(url)) { error in
            guard case CallTranscriptionError.invalidCallbackScheme(let scheme) = error else {
                XCTFail("Expected invalidCallbackScheme error, got \(error)")
                return
            }
            XCTAssertEqual(scheme, "javascript")
        }
    }

    func testValidateFileCallbackScheme() {
        let url = URL(string: "file:///etc/passwd")!

        XCTAssertThrowsError(try URLSchemeParser.validateCallbackURL(url)) { error in
            guard case CallTranscriptionError.invalidCallbackScheme(let scheme) = error else {
                XCTFail("Expected invalidCallbackScheme error, got \(error)")
                return
            }
            XCTAssertEqual(scheme, "file")
        }
    }

    func testValidateHTTPCallbackSchemeBlocked() {
        let url = URL(string: "http://example.com/callback")!

        XCTAssertThrowsError(try URLSchemeParser.validateCallbackURL(url)) { error in
            guard case CallTranscriptionError.invalidCallbackScheme(let scheme) = error else {
                XCTFail("Expected invalidCallbackScheme error, got \(error)")
                return
            }
            XCTAssertEqual(scheme, "http")
        }
    }

    func testValidateHTTPSCallbackSchemeAllowed() {
        let url = URL(string: "https://example.com/callback")!
        XCTAssertNoThrow(try URLSchemeParser.validateCallbackURL(url))
    }
}
