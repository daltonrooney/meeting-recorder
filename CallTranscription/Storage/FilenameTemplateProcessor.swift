import Foundation

public final class FilenameTemplateProcessor {
    private static let defaultTemplate = "transcript_{date}_{time}.txt"

    public init() {}

    public func process(_ template: String, date: Date = Date()) -> String {
        var result = template.isEmpty ? Self.defaultTemplate : template

        result = replaceTokens(in: result, date: date)

        if !result.contains(".") {
            result += ".txt"
        }

        return result
    }

    public func validate(_ template: String) -> Bool {
        if template.contains("../") || template.contains("..\\") {
            return false
        }

        if template.contains("/") {
            return false
        }

        return true
    }

    private func replaceTokens(in template: String, date: Date) -> String {
        var result = template

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")

        if result.contains("{date}") {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)
            result = result.replacingOccurrences(of: "{date}", with: dateString)
        }

        if result.contains("{time}") {
            dateFormatter.dateFormat = "HH_mm_ss"
            let timeString = dateFormatter.string(from: date)
            result = result.replacingOccurrences(of: "{time}", with: timeString)
        }

        return result
    }
}
