import Foundation
import AppKit

/// Main coordinator for handling URL scheme requests
@MainActor
final class URLSchemeHandler {
    private let parser: URLSchemeParser.Type
    private let dispatcher: URLSchemeActionDispatcher
    private let callbackHandler: URLSchemeCallbackHandler

    init(
        appState: any RecordingActionHandler,
        parser: URLSchemeParser.Type = URLSchemeParser.self,
        workspace: NSWorkspaceProtocol = NSWorkspace.shared
    ) {
        self.parser = parser
        self.dispatcher = URLSchemeActionDispatcher(appState: appState)
        self.callbackHandler = URLSchemeCallbackHandler(workspace: workspace)
    }

    /// Handle an incoming URL scheme request
    /// - Parameter url: The URL to handle
    func handle(_ url: URL) async {
        do {
            // Parse the URL
            let request = try parser.parse(url)

            // Dispatch the action
            let result = try await dispatcher.dispatch(request)

            // Invoke success callback
            await callbackHandler.invokeCallback(for: request, result: result, error: nil)

        } catch {
            // Try to parse the URL for error callback
            if let request = try? parser.parse(url) {
                // Invoke error callback
                await callbackHandler.invokeCallback(for: request, result: nil, error: error)
            } else {
                // Cannot even parse URL, log error
                print("Failed to handle URL scheme: \(error.localizedDescription)")
            }
        }
    }
}
