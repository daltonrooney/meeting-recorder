import XCTest
@testable import CallTranscription

final class FilenameTemplateProcessorTests: XCTestCase {
    var processor: FilenameTemplateProcessor!

    override func setUp() {
        super.setUp()
        processor = FilenameTemplateProcessor()
    }

    override func tearDown() {
        processor = nil
        super.tearDown()
    }

    // MARK: - Date Token Tests

    func testProcessTemplateWithDateToken() {
        let date = createDate(year: 2024, month: 1, day: 15, hour: 0, minute: 0, second: 0)
        let result = processor.process("{date}", date: date)
        XCTAssertEqual(result, "2024-01-15.txt")
    }

    // MARK: - Time Token Tests

    func testProcessTemplateWithTimeToken() {
        let date = createDate(year: 2024, month: 1, day: 15, hour: 14, minute: 30, second: 45)
        let result = processor.process("{time}", date: date)
        XCTAssertEqual(result, "14_30_45.txt")
    }

    // MARK: - Multiple Token Tests

    func testProcessTemplateWithBothTokens() {
        let date = createDate(year: 2024, month: 1, day: 15, hour: 14, minute: 30, second: 45)
        let result = processor.process("transcript_{date}_{time}.txt", date: date)
        XCTAssertEqual(result, "transcript_2024-01-15_14_30_45.txt")
    }

    // MARK: - Plain Text Tests

    func testProcessTemplateWithPlainText() {
        let result = processor.process("meeting_notes.txt")
        XCTAssertEqual(result, "meeting_notes.txt")
    }

    // MARK: - Extension Tests

    func testProcessTemplateAutoAppendsTxtExtension() {
        let date = createDate(year: 2024, month: 1, day: 15, hour: 0, minute: 0, second: 0)
        let result = processor.process("file_{date}", date: date)
        XCTAssertEqual(result, "file_2024-01-15.txt")
    }

    func testProcessTemplatePreservesExistingExtension() {
        let date = createDate(year: 2024, month: 1, day: 15, hour: 0, minute: 0, second: 0)
        let result = processor.process("file_{date}.md", date: date)
        XCTAssertEqual(result, "file_2024-01-15.md")
    }

    // MARK: - Invalid Token Tests

    func testProcessTemplateWithInvalidTokens() {
        let result = processor.process("file_{invalid}_test.txt")
        XCTAssertEqual(result, "file_{invalid}_test.txt")
    }

    // MARK: - Validation Tests

    func testValidateRejectsPathTraversal() {
        XCTAssertFalse(processor.validate("../file.txt"))
        XCTAssertFalse(processor.validate("file/../other.txt"))
    }

    func testValidateRejectsSlashes() {
        XCTAssertFalse(processor.validate("path/file.txt"))
        XCTAssertFalse(processor.validate("/absolute/path.txt"))
        XCTAssertFalse(processor.validate("..\\file.txt"))
    }

    func testValidateAcceptsCleanTemplate() {
        XCTAssertTrue(processor.validate("file_{date}.txt"))
        XCTAssertTrue(processor.validate("transcript_{date}_{time}.txt"))
        XCTAssertTrue(processor.validate("meeting_notes.txt"))
    }

    // MARK: - Edge Case Tests

    func testProcessTemplateWithEmptyString() {
        let date = createDate(year: 2024, month: 1, day: 15, hour: 14, minute: 30, second: 45)
        let result = processor.process("", date: date)
        XCTAssertEqual(result, "transcript_2024-01-15_14_30_45.txt")
    }

    // MARK: - Helper Methods

    private func createDate(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        components.timeZone = TimeZone(identifier: "UTC")

        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: components)!
    }
}
