import Foundation
import AppKit

/// Protocol to abstract NSWorkspace for testing
@MainActor
protocol NSWorkspaceProtocol {
    func open(_ url: URL) -> Bool
}

/// NSWorkspace conforms to the protocol
@MainActor
extension NSWorkspace: NSWorkspaceProtocol {
    // NSWorkspace.open(_:) already exists, no implementation needed
}

/// Handles x-callback-url callbacks (success, error, cancel)
@MainActor
final class URLSchemeCallbackHandler {
    private let workspace: NSWorkspaceProtocol

    init(workspace: NSWorkspaceProtocol = NSWorkspace.shared) {
        self.workspace = workspace
    }

    /// Invoke the appropriate callback based on result or error
    /// - Parameters:
    ///   - request: The original URL scheme request
    ///   - result: The action result (if successful)
    ///   - error: The error (if failed)
    func invokeCallback(
        for request: URLSchemeRequest,
        result: URLSchemeActionResult?,
        error: Error?
    ) async {
        if let error = error {
            // Invoke error callback
            await invokeErrorCallback(for: request, error: error)
        } else if let result = result {
            // Invoke success callback
            await invokeSuccessCallback(for: request, result: result)
        }
    }

    /// Invoke the cancel callback
    /// - Parameter request: The original URL scheme request
    func invokeCancel(for request: URLSchemeRequest) async {
        guard let cancelURL = request.cancelCallback else {
            return
        }

        _ = workspace.open(cancelURL)
    }

    // MARK: - Private Helpers

    private func invokeSuccessCallback(
        for request: URLSchemeRequest,
        result: URLSchemeActionResult
    ) async {
        guard let successURL = request.successCallback else {
            return
        }

        var parameters: [String: String] = [:]

        // Add transcript URL if available
        if let transcriptURL = result.transcriptURL {
            parameters["transcriptURL"] = transcriptURL.absoluteString
        }

        let callbackURL = buildCallbackURL(base: successURL, parameters: parameters)
        _ = workspace.open(callbackURL)
    }

    private func invokeErrorCallback(
        for request: URLSchemeRequest,
        error: Error
    ) async {
        guard let errorURL = request.errorCallback else {
            return
        }

        let errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        let parameters = ["errorMessage": errorMessage]

        let callbackURL = buildCallbackURL(base: errorURL, parameters: parameters)
        _ = workspace.open(callbackURL)
    }

    /// Build a callback URL with additional parameters
    /// - Parameters:
    ///   - base: The base callback URL
    ///   - parameters: Additional parameters to append
    /// - Returns: The callback URL with parameters appended
    func buildCallbackURL(base: URL, parameters: [String: String]) -> URL {
        guard !parameters.isEmpty else {
            return base
        }

        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)

        // Get existing query items or create new array
        var queryItems = components?.queryItems ?? []

        // Add new parameters
        for (key, value) in parameters {
            let item = URLQueryItem(
                name: key,
                value: value
            )
            queryItems.append(item)
        }

        components?.queryItems = queryItems

        return components?.url ?? base
    }
}
