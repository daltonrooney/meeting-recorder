import Foundation
import Combine

@MainActor
public final class SettingsManager: ObservableObject {
    // Keys for UserDefaults
    private enum Keys {
        static let outputFolder = "outputFolder"
        static let postRecordingScript = "postRecordingScript"
        static let captureSystemAudio = "captureSystemAudio"
        static let captureMicrophone = "captureMicrophone"
    }

    // Default values
    public static let defaultOutputFolder = "~/Desktop/Transcripts"
    public static let defaultPostRecordingScript = ""
    public static let defaultCaptureSystemAudio = true
    public static let defaultCaptureMicrophone = true

    // Published properties
    @Published public var outputFolder: String
    @Published public var postRecordingScript: String
    @Published public var captureSystemAudio: Bool
    @Published public var captureMicrophone: Bool

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // Initialize with stored values or defaults
        self.outputFolder = userDefaults.string(forKey: Keys.outputFolder)
            ?? Self.defaultOutputFolder
        self.postRecordingScript = userDefaults.string(forKey: Keys.postRecordingScript)
            ?? Self.defaultPostRecordingScript

        // For booleans, check if key exists first to distinguish false from not-set
        if userDefaults.objectExists(forKey: Keys.captureSystemAudio) {
            self.captureSystemAudio = userDefaults.bool(forKey: Keys.captureSystemAudio)
        } else {
            self.captureSystemAudio = Self.defaultCaptureSystemAudio
        }

        if userDefaults.objectExists(forKey: Keys.captureMicrophone) {
            self.captureMicrophone = userDefaults.bool(forKey: Keys.captureMicrophone)
        } else {
            self.captureMicrophone = Self.defaultCaptureMicrophone
        }
    }

    // Path expansion utilities
    public func expandedOutputFolderPath() -> String {
        NSString(string: outputFolder).expandingTildeInPath
    }

    public func expandedPostRecordingScriptPath() -> String {
        NSString(string: postRecordingScript).expandingTildeInPath
    }
}

// UserDefaults extension for checking key existence
extension UserDefaults {
    func objectExists(forKey key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
