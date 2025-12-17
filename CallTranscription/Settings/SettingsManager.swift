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
        static let hasAcceptedConsentDialog = "hasAcceptedConsentDialog"
        static let silencePauseThreshold = "silencePauseThreshold"
    }

    // Default values
    public static let defaultOutputFolder = "~/Desktop/Transcripts"
    public static let defaultPostRecordingScript = ""
    public static let defaultCaptureSystemAudio = true
    public static let defaultCaptureMicrophone = true
    public static let defaultHasAcceptedConsentDialog = false
    public static let defaultSilencePauseThreshold = SilencePauseThreshold.never

    // Published properties
    @Published public var outputFolder: String
    @Published public var postRecordingScript: String
    @Published public var captureSystemAudio: Bool
    @Published public var captureMicrophone: Bool
    @Published public var hasAcceptedConsentDialog: Bool
    @Published public var silencePauseThreshold: SilencePauseThreshold

    private let userDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

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

        if userDefaults.objectExists(forKey: Keys.hasAcceptedConsentDialog) {
            self.hasAcceptedConsentDialog = userDefaults.bool(forKey: Keys.hasAcceptedConsentDialog)
        } else {
            self.hasAcceptedConsentDialog = Self.defaultHasAcceptedConsentDialog
        }

        // Initialize silencePauseThreshold from UserDefaults or default
        if let rawValue = userDefaults.string(forKey: Keys.silencePauseThreshold),
           let threshold = SilencePauseThreshold(rawValue: rawValue) {
            self.silencePauseThreshold = threshold
        } else {
            self.silencePauseThreshold = Self.defaultSilencePauseThreshold
        }

        // Set up observers to persist changes to UserDefaults
        setupPersistence()
    }

    private func setupPersistence() {
        // Persist outputFolder changes
        $outputFolder
            .dropFirst() // Skip initial value
            .sink { [weak self] newValue in
                self?.userDefaults.set(newValue, forKey: Keys.outputFolder)
            }
            .store(in: &cancellables)

        // Persist postRecordingScript changes
        $postRecordingScript
            .dropFirst() // Skip initial value
            .sink { [weak self] newValue in
                self?.userDefaults.set(newValue, forKey: Keys.postRecordingScript)
            }
            .store(in: &cancellables)

        // Persist captureSystemAudio changes
        $captureSystemAudio
            .dropFirst() // Skip initial value
            .sink { [weak self] newValue in
                self?.userDefaults.set(newValue, forKey: Keys.captureSystemAudio)
            }
            .store(in: &cancellables)

        // Persist captureMicrophone changes
        $captureMicrophone
            .dropFirst() // Skip initial value
            .sink { [weak self] newValue in
                self?.userDefaults.set(newValue, forKey: Keys.captureMicrophone)
            }
            .store(in: &cancellables)

        // Persist hasAcceptedConsentDialog changes
        $hasAcceptedConsentDialog
            .dropFirst() // Skip initial value
            .sink { [weak self] newValue in
                self?.userDefaults.set(newValue, forKey: Keys.hasAcceptedConsentDialog)
            }
            .store(in: &cancellables)

        // Persist silencePauseThreshold changes
        $silencePauseThreshold
            .dropFirst() // Skip initial value
            .sink { [weak self] newValue in
                self?.userDefaults.set(newValue.rawValue, forKey: Keys.silencePauseThreshold)
            }
            .store(in: &cancellables)
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
