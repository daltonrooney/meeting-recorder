import Foundation
import Combine

/// Type of action to perform after recording completes.
public enum PostRecordingActionType: String, CaseIterable, Codable {
    case doNothing = "doNothing"
    case script = "script"
    case shortcut = "shortcut"
}

@MainActor
public final class SettingsManager: ObservableObject {
    // Keys for UserDefaults
    private enum Keys {
        static let outputFolder = "outputFolder"
        static let postRecordingScript = "postRecordingScript"
        static let postRecordingActionType = "postRecordingActionType"
        static let shortcutIdentifier = "shortcutIdentifier"
        static let captureSystemAudio = "captureSystemAudio"
        static let captureMicrophone = "captureMicrophone"
        static let hasAcceptedConsentDialog = "hasAcceptedConsentDialog"
        static let silencePauseThreshold = "silencePauseThreshold"
        static let saveOriginalAudio = "saveOriginalAudio"
        static let filenameTemplate = "filenameTemplate"
        static let outputFolderBookmark = "outputFolderBookmark"
        static let postRecordingScriptBookmark = "postRecordingScriptBookmark"
    }

    // Default values
    public static let defaultOutputFolder = "~/Documents/Transcripts"
    public static let defaultPostRecordingScript = ""
    public static let defaultPostRecordingActionType = PostRecordingActionType.doNothing
    public static let defaultShortcutIdentifier = ""
    public static let defaultCaptureSystemAudio = true
    public static let defaultCaptureMicrophone = true
    public static let defaultHasAcceptedConsentDialog = false
    public static let defaultSilencePauseThreshold = SilencePauseThreshold.never
    public static let defaultSaveOriginalAudio = false
    public static let defaultFilenameTemplate = "transcript_{date}_{time}.txt"

    // Published properties
    @Published public var outputFolder: String
    @Published public var postRecordingScript: String
    @Published public var postRecordingActionType: PostRecordingActionType
    @Published public var shortcutIdentifier: String
    @Published public var captureSystemAudio: Bool
    @Published public var captureMicrophone: Bool
    @Published public var hasAcceptedConsentDialog: Bool
    @Published public var silencePauseThreshold: SilencePauseThreshold
    @Published public var saveOriginalAudio: Bool
    @Published public var filenameTemplate: String
    @Published public var outputFolderBookmark: Data?
    @Published public var postRecordingScriptBookmark: Data?

    private let userDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // Initialize with stored values or defaults
        self.outputFolder = userDefaults.string(forKey: Keys.outputFolder)
            ?? Self.defaultOutputFolder
        self.postRecordingScript = userDefaults.string(forKey: Keys.postRecordingScript)
            ?? Self.defaultPostRecordingScript

        // Initialize postRecordingActionType from UserDefaults or default
        if let rawValue = userDefaults.string(forKey: Keys.postRecordingActionType),
           let actionType = PostRecordingActionType(rawValue: rawValue) {
            self.postRecordingActionType = actionType
        } else {
            self.postRecordingActionType = Self.defaultPostRecordingActionType
        }

        self.shortcutIdentifier = userDefaults.string(forKey: Keys.shortcutIdentifier)
            ?? Self.defaultShortcutIdentifier

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

        if userDefaults.objectExists(forKey: Keys.saveOriginalAudio) {
            self.saveOriginalAudio = userDefaults.bool(forKey: Keys.saveOriginalAudio)
        } else {
            self.saveOriginalAudio = Self.defaultSaveOriginalAudio
        }

        self.filenameTemplate = userDefaults.string(forKey: Keys.filenameTemplate)
            ?? Self.defaultFilenameTemplate

        // Initialize bookmarks (Data stored in UserDefaults)
        self.outputFolderBookmark = userDefaults.data(forKey: Keys.outputFolderBookmark)
        self.postRecordingScriptBookmark = userDefaults.data(forKey: Keys.postRecordingScriptBookmark)

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

        // Persist postRecordingActionType changes
        $postRecordingActionType
            .dropFirst() // Skip initial value
            .sink { [weak self] newValue in
                self?.userDefaults.set(newValue.rawValue, forKey: Keys.postRecordingActionType)
            }
            .store(in: &cancellables)

        // Persist shortcutIdentifier changes
        $shortcutIdentifier
            .dropFirst() // Skip initial value
            .sink { [weak self] newValue in
                self?.userDefaults.set(newValue, forKey: Keys.shortcutIdentifier)
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

        // Persist saveOriginalAudio changes
        $saveOriginalAudio
            .dropFirst() // Skip initial value
            .sink { [weak self] newValue in
                self?.userDefaults.set(newValue, forKey: Keys.saveOriginalAudio)
            }
            .store(in: &cancellables)

        // Persist filenameTemplate changes
        $filenameTemplate
            .dropFirst() // Skip initial value
            .sink { [weak self] newValue in
                self?.userDefaults.set(newValue, forKey: Keys.filenameTemplate)
            }
            .store(in: &cancellables)

        // Persist outputFolderBookmark changes
        $outputFolderBookmark
            .dropFirst() // Skip initial value
            .sink { [weak self] newValue in
                if let data = newValue {
                    self?.userDefaults.set(data, forKey: Keys.outputFolderBookmark)
                } else {
                    self?.userDefaults.removeObject(forKey: Keys.outputFolderBookmark)
                }
            }
            .store(in: &cancellables)

        // Persist postRecordingScriptBookmark changes
        $postRecordingScriptBookmark
            .dropFirst() // Skip initial value
            .sink { [weak self] newValue in
                if let data = newValue {
                    self?.userDefaults.set(data, forKey: Keys.postRecordingScriptBookmark)
                } else {
                    self?.userDefaults.removeObject(forKey: Keys.postRecordingScriptBookmark)
                }
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
