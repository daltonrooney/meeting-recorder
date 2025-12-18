import Foundation

/// Singleton container for accessing AppState from App Intents.
///
/// This provides a thread-safe way for App Intents to access the main AppState instance.
/// The AppState is set during app launch and remains available throughout the app's lifecycle.
@MainActor
final class AppStateContainer {
    /// Shared instance of the container
    static let shared = AppStateContainer()

    /// The main AppState instance
    private(set) var appState: AppState?

    /// The main SettingsManager instance
    private(set) var settingsManager: SettingsManager?

    private init() {}

    /// Sets the AppState instance (called during app initialization)
    func setAppState(_ appState: AppState, settingsManager: SettingsManager) {
        self.appState = appState
        self.settingsManager = settingsManager
    }

    /// Gets the AppState, throwing if not available
    func requireAppState() throws -> AppState {
        guard let appState = appState else {
            throw AppStateContainerError.appStateNotAvailable
        }
        return appState
    }

    /// Gets the SettingsManager, throwing if not available
    func requireSettingsManager() throws -> SettingsManager {
        guard let settingsManager = settingsManager else {
            throw AppStateContainerError.settingsManagerNotAvailable
        }
        return settingsManager
    }
}

enum AppStateContainerError: Error, LocalizedError {
    case appStateNotAvailable
    case settingsManagerNotAvailable

    var errorDescription: String? {
        switch self {
        case .appStateNotAvailable:
            return "App state is not available. Please ensure the app is running."
        case .settingsManagerNotAvailable:
            return "Settings manager is not available. Please ensure the app is running."
        }
    }
}
