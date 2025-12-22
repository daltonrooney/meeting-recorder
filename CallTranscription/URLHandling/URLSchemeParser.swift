import Foundation

/// Parses and validates x-callback-url formatted URLs for the olive:// scheme
@MainActor
final class URLSchemeParser {

    /// Allowed callback URL schemes (whitelist for security)
    /// Only these schemes are permitted for x-success, x-error, and x-cancel callbacks
    private static let allowedCallbackSchemes = Set([
        "shortcuts",      // Shortcuts app
        "x-callback-url", // Standard x-callback-url scheme
        "http",           // Web callbacks (consider privacy implications)
        "https"           // Secure web callbacks (consider privacy implications)
        // Note: applescript removed - could be dangerous
        // Note: file, javascript, data explicitly blocked
    ])

    /// Parse a URL into a URLSchemeRequest
    /// - Parameter url: The URL to parse (must be olive://x-callback-url/action?params)
    /// - Returns: A URLSchemeRequest with all parsed parameters
    /// - Throws: CallTranscriptionError if the URL is invalid
    static func parse(_ url: URL) throws -> URLSchemeRequest {
        // Validate scheme
        guard url.scheme?.lowercased() == "olive" else {
            throw CallTranscriptionError.invalidURLScheme(url.scheme ?? "")
        }

        // Validate host
        guard url.host?.lowercased() == "x-callback-url" else {
            throw CallTranscriptionError.invalidURLHost(url.host ?? "")
        }

        // Extract action from path
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !path.isEmpty else {
            throw CallTranscriptionError.missingURLAction
        }

        guard let action = URLSchemeAction(rawValue: path.lowercased()) else {
            throw CallTranscriptionError.invalidURLAction(path)
        }

        // Parse query parameters
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        var title: String?
        var outputFolder: String?
        var filenameTemplate: String?
        var successCallback: URL?
        var errorCallback: URL?
        var cancelCallback: URL?

        for item in queryItems {
            switch item.name {
            case "title":
                title = item.value?.removingPercentEncoding
            case "outputFolder":
                outputFolder = item.value?.removingPercentEncoding
            case "filenameTemplate":
                filenameTemplate = item.value?.removingPercentEncoding
            case "x-success":
                if let value = item.value, let url = URL(string: value) {
                    try validateCallbackURL(url)
                    successCallback = url
                }
            case "x-error":
                if let value = item.value, let url = URL(string: value) {
                    try validateCallbackURL(url)
                    errorCallback = url
                }
            case "x-cancel":
                if let value = item.value, let url = URL(string: value) {
                    try validateCallbackURL(url)
                    cancelCallback = url
                }
            default:
                break
            }
        }

        return URLSchemeRequest(
            action: action,
            title: title,
            outputFolder: outputFolder,
            filenameTemplate: filenameTemplate,
            successCallback: successCallback,
            errorCallback: errorCallback,
            cancelCallback: cancelCallback
        )
    }

    /// Validate a callback URL for security using whitelist approach
    /// - Parameter url: The callback URL to validate
    /// - Throws: CallTranscriptionError.invalidCallbackScheme if the scheme is not in the allowed list
    static func validateCallbackURL(_ url: URL) throws {
        guard let scheme = url.scheme?.lowercased(), !scheme.isEmpty else {
            throw CallTranscriptionError.invalidCallbackScheme("")
        }

        // Whitelist-only validation: reject anything not explicitly allowed
        guard allowedCallbackSchemes.contains(scheme) else {
            throw CallTranscriptionError.invalidCallbackScheme(scheme)
        }
    }
}
