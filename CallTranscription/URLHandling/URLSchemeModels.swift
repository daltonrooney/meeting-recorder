import Foundation

/// Represents an action that can be triggered via the URL scheme
enum URLSchemeAction: String, Sendable {
    case start
    case stop
    case pause
    case resume
}

/// Represents a parsed URL scheme request with all parameters
struct URLSchemeRequest: Sendable {
    let action: URLSchemeAction
    let title: String?
    let outputFolder: String?
    let filenameTemplate: String?
    let successCallback: URL?
    let errorCallback: URL?
    let cancelCallback: URL?
}

/// Represents the result of executing a URL scheme action
struct URLSchemeActionResult: Sendable {
    let transcriptURL: URL?
}
