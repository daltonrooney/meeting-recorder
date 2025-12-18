import Foundation

/// Enum representing the silence pause threshold options.
///
/// Defines preset durations of silence that will trigger automatic pause of recording.
/// The `.never` option disables automatic pause functionality.
public enum SilencePauseThreshold: String, Codable, CaseIterable, Sendable {
    /// Auto-pause after 2 minutes of silence
    case twoMinutes

    /// Auto-pause after 5 minutes of silence
    case fiveMinutes

    /// Auto-pause after 10 minutes of silence
    case tenMinutes

    /// Never auto-pause (silence detection disabled)
    case never

    /// Returns the time interval in seconds for this threshold, or nil for `.never`.
    public var timeInterval: TimeInterval? {
        switch self {
        case .twoMinutes:
            return 120.0
        case .fiveMinutes:
            return 300.0
        case .tenMinutes:
            return 600.0
        case .never:
            return nil
        }
    }

    /// User-facing display name for this threshold.
    public var displayName: String {
        switch self {
        case .twoMinutes:
            return "2 minutes"
        case .fiveMinutes:
            return "5 minutes"
        case .tenMinutes:
            return "10 minutes"
        case .never:
            return "Never"
        }
    }
}
