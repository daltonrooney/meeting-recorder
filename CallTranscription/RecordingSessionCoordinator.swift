import Foundation
import AVFoundation
import os.log

/// Coordinates the complete recording workflow, integrating all recording components.
///
/// RecordingSessionCoordinator manages:
/// - Audio capture from microphone and system audio
/// - Audio mixing and routing to transcription
/// - Speech transcription and result handling
/// - Transcript file writing with timestamps
/// - Post-recording script execution
///
/// The coordinator implements a strict lifecycle:
/// 1. Start: Initialize and start all components in sequence
/// 2. Record: Route audio and handle transcription results
/// 3. Stop: Stop components, finalize transcript, execute script
///
/// Example usage:
/// ```swift
/// let config = RecordingConfiguration(
///     outputFolder: "/path/to/output",
///     locale: Locale(identifier: "en-US"),
///     microphoneEnabled: true
/// )
///
/// let coordinator = RecordingSessionCoordinator(configuration: config)
/// try await coordinator.startRecording(title: "Meeting Notes")
///
/// // ... recording happens ...
///
/// let transcriptURL = try await coordinator.stopRecording()
/// ```
@MainActor
public final class RecordingSessionCoordinator {

    // MARK: - Public Properties

    /// Whether a recording session is currently active
    public private(set) var isRecording: Bool = false

    // MARK: - Private Properties

    private let configuration: RecordingConfiguration
    private let logger = Logger(subsystem: "dev.rygn.CallTranscription", category: "RecordingSessionCoordinator")

    // Components
    private var microphoneCapture: MicrophoneCapture?
    private var systemAudioCapture: SystemAudioCapture?
    private var audioMixer: AudioMixer?
    private var transcriptionManager: TranscriptionManager?
    private var transcriptWriter: TranscriptWriter?
    private var silenceDetector: SilenceDetector?
    private let outputFolderManager = OutputFolderManager()
    private let bookmarkManager = SecurityScopedBookmarkManager()

    // Session state
    private var recordingStartTime: Date?
    private var currentTitle: String?
    private var isPaused: Bool = false
    private var securityScopedURL: URL? // Tracks URL that needs stopAccessingSecurityScopedResource() call

    // Callbacks
    private var transcriptionResultHandler: ((String, Bool) -> Void)?

    // MARK: - Initialization

    /// Creates a new recording session coordinator with the specified configuration.
    ///
    /// - Parameter configuration: Recording configuration specifying output folder, locale, and enabled sources
    public init(configuration: RecordingConfiguration) {
        self.configuration = configuration
        logger.debug("RecordingSessionCoordinator initialized")
    }

    // MARK: - Public Methods

    /// Registers a callback to be invoked when transcription results are available.
    ///
    /// - Parameter handler: Callback receiving transcription text and whether it's final
    public func onTranscriptionResult(_ handler: @escaping (String, Bool) -> Void) {
        transcriptionResultHandler = handler
    }

    /// Starts a new recording session.
    ///
    /// - Parameter title: Title for the recording session (appears in transcript header)
    /// - Throws: CallTranscriptionError if unable to start recording
    public func startRecording(title: String) async throws {
        guard !isRecording else {
            logger.error("Cannot start: already recording")
            throw CallTranscriptionError.featureNotImplemented("Already recording")
        }

        logger.info("Starting recording: \(title)")
        currentTitle = title
        recordingStartTime = Date()

        do {
            // Validate configuration
            try await validateConfiguration()

            // Initialize components
            try await initializeComponents()

            // Start recording
            try await startComponents()

            isRecording = true
            logger.info("Recording started successfully")

        } catch {
            logger.error("Failed to start recording: \(error.localizedDescription)")
            await cleanup()
            throw error
        }
    }

    /// Stops the current recording session.
    ///
    /// - Returns: URL of the finalized transcript file
    /// - Throws: CallTranscriptionError if no recording is active or unable to stop
    public func stopRecording() async throws -> URL {
        guard isRecording else {
            logger.error("Cannot stop: not recording")
            throw CallTranscriptionError.featureNotImplemented("Not currently recording")
        }

        logger.info("Stopping recording")

        do {
            // Stop audio capture
            await stopAudioCapture()

            // Stop transcription
            await stopTranscription()

            // Finalize transcript
            guard let transcriptWriter = transcriptWriter else {
                throw CallTranscriptionError.featureNotImplemented("Transcript writer not available")
            }
            let transcriptURL = try await transcriptWriter.finalize()

            // Execute post-recording action based on configuration
            await executePostRecordingAction(transcriptPath: transcriptURL.path)

            // Cleanup
            await cleanup()

            isRecording = false
            logger.info("Recording stopped successfully")

            return transcriptURL

        } catch {
            logger.error("Failed to stop recording: \(error.localizedDescription)")
            await cleanup()
            isRecording = false
            throw error
        }
    }

    /// Pauses the current recording session.
    ///
    /// - Throws: An error if pausing fails.
    ///
    /// This method pauses audio capture while maintaining the recording session.
    /// Call `resumeRecording()` to continue.
    public func pauseRecording() async throws {
        guard isRecording else {
            throw CallTranscriptionError.notRecording
        }

        guard !isPaused else {
            logger.warning("Cannot pause: already paused")
            throw CallTranscriptionError.featureNotImplemented("Recording is already paused")
        }

        logger.info("Pausing recording session")

        // Pause audio capture sources
        if let micCapture = microphoneCapture {
            nonisolated(unsafe) let unsafeMicCapture = micCapture
            await unsafeMicCapture.pauseCapture()
            logger.debug("Microphone capture paused")
        }

        if let sysCapture = systemAudioCapture {
            nonisolated(unsafe) let unsafeSysCapture = sysCapture
            await unsafeSysCapture.pauseCapture()
            logger.debug("System audio capture paused")
        }

        // Reset silence detector to prevent unexpected auto-pause after manual resume
        // Without this, accumulated silence duration before pause could trigger auto-pause
        // shortly after resuming (e.g., 1:50 accumulated + 10s after resume = auto-pause)
        silenceDetector?.reset()
        logger.debug("Silence detector reset")

        // Note: We don't pause transcription manager - we simply stop feeding it audio
        // When we resume, audio will continue to flow and transcription will continue

        isPaused = true
        logger.info("Recording session paused successfully")
    }

    /// Resumes the current recording session after being paused.
    ///
    /// - Throws: An error if resuming fails.
    ///
    /// This method resumes audio capture after a pause.
    public func resumeRecording() async throws {
        guard isRecording else {
            throw CallTranscriptionError.notRecording
        }

        guard isPaused else {
            logger.warning("Cannot resume: not paused")
            throw CallTranscriptionError.featureNotImplemented("Recording is not paused")
        }

        logger.info("Resuming recording session")

        // Resume audio capture sources
        if let micCapture = microphoneCapture {
            nonisolated(unsafe) let unsafeMicCapture = micCapture
            await unsafeMicCapture.resumeCapture()
            logger.debug("Microphone capture resumed")
        }

        if let sysCapture = systemAudioCapture {
            nonisolated(unsafe) let unsafeSysCapture = sysCapture
            await unsafeSysCapture.resumeCapture()
            logger.debug("System audio capture resumed")
        }

        // Audio will automatically start flowing to transcription manager again

        isPaused = false
        logger.info("Recording session resumed successfully")
    }

    // MARK: - Private Methods - Validation

    private func validateConfiguration() async throws {
        logger.debug("Validating configuration")

        // Validate output folder (with security-scoped bookmark if available)
        let _ = try await outputFolderManager.validateAndPreparePath(configuration.outputFolder, bookmark: configuration.outputFolderBookmark)

        // Ensure at least one audio source is enabled
        guard configuration.microphoneEnabled || configuration.systemAudioEnabled else {
            throw CallTranscriptionError.featureNotImplemented("At least one audio source must be enabled")
        }

        logger.debug("Configuration validated")
    }

    // MARK: - Private Methods - Component Initialization

    private func initializeComponents() async throws {
        logger.debug("Initializing components")

        // Create audio mixer
        audioMixer = AudioMixer(
            microphoneLevel: configuration.microphoneEnabled ? 0.5 : 0.0,
            systemAudioLevel: configuration.systemAudioEnabled ? 0.5 : 0.0
        )

        // Create transcription manager
        transcriptionManager = TranscriptionManager(locale: configuration.locale)

        // Set up audio routing
        setupAudioRouting()

        // Set up transcription handling
        setupTranscriptionHandling()

        // Start accessing security-scoped resource if bookmark is available
        if let bookmarkData = configuration.outputFolderBookmark {
            do {
                let url = try bookmarkManager.resolveBookmark(bookmarkData)
                if url.startAccessingSecurityScopedResource() {
                    securityScopedURL = url
                    logger.info("Started accessing security-scoped resource: \(url.path)")
                } else {
                    logger.warning("Failed to start accessing security-scoped resource: \(url.path)")
                }
            } catch {
                logger.warning("Failed to resolve bookmark for security-scoped access: \(error.localizedDescription)")
            }
        }

        // Create transcript writer (with security-scoped bookmark if available)
        let outputFolderURL = try await outputFolderManager.validateAndPreparePath(configuration.outputFolder, bookmark: configuration.outputFolderBookmark)

        // Process filename template
        let processor = FilenameTemplateProcessor()
        let processedFilename = processor.process(configuration.filenameTemplate)

        transcriptWriter = try await TranscriptWriter(
            outputFolder: outputFolderURL,
            filename: processedFilename,
            title: currentTitle
        )

        // Create silence detector
        silenceDetector = SilenceDetector(threshold: configuration.silencePauseThreshold)
        setupSilenceDetection()

        logger.debug("Components initialized")
    }

    private func setupAudioRouting() {
        guard let audioMixer = audioMixer,
              let transcriptionManager = transcriptionManager else {
            logger.error("Cannot setup audio routing: missing components")
            return
        }

        // Route mixed audio to transcription and silence detector
        audioMixer.mixedBufferHandler = { [weak self] buffer in
            guard let self = self else { return }

            // Feed to silence detector for analysis
            if let silenceDetector = self.silenceDetector {
                silenceDetector.processAudioBuffer(buffer)
            }

            // Feed to transcription manager
            Task { @MainActor in
                await transcriptionManager.feedAudio(buffer)
            }
        }

        logger.debug("Audio routing configured")
    }

    private func setupTranscriptionHandling() {
        guard let transcriptionManager = transcriptionManager else {
            logger.error("Cannot setup transcription handling: missing transcription manager")
            return
        }

        // Handle transcription results
        transcriptionManager.onTranscriptionResult = { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                await self.handleTranscriptionResult(result)
            }
        }

        // Handle transcription errors
        transcriptionManager.onTranscriptionError = { [weak self] error in
            guard let self = self else { return }
            self.logger.error("Transcription error: \(error.localizedDescription)")
        }

        logger.debug("Transcription handling configured")
    }

    private func setupSilenceDetection() {
        guard let silenceDetector = silenceDetector else {
            logger.error("Cannot setup silence detection: missing silence detector")
            return
        }

        // Handle silence threshold exceeded (auto-pause)
        silenceDetector.onSilenceThresholdExceeded = { @Sendable [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                // Guard against race: check state is valid for pause
                guard self.isRecording else {
                    self.logger.debug("Ignoring auto-pause: recording already stopped")
                    return
                }

                do {
                    try await self.pauseRecording()
                    self.logger.info("Auto-paused recording due to silence")
                } catch {
                    self.logger.error("Failed to auto-pause: \(error.localizedDescription)")
                }
            }
        }

        // Handle audio detected after silence (auto-resume)
        silenceDetector.onAudioDetectedAfterSilence = { @Sendable [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                // Guard against race: check recording is active and paused
                guard self.isRecording else {
                    self.logger.debug("Ignoring auto-resume: recording already stopped")
                    return
                }

                do {
                    try await self.resumeRecording()
                    self.logger.info("Auto-resumed recording after audio detected")
                } catch {
                    self.logger.error("Failed to auto-resume: \(error.localizedDescription)")
                }
            }
        }

        logger.debug("Silence detection configured")
    }

    // MARK: - Private Methods - Component Control

    private func startComponents() async throws {
        logger.debug("Starting components")

        // Ensure model is available
        guard let transcriptionManager = transcriptionManager else {
            throw CallTranscriptionError.featureNotImplemented("Transcription manager not available")
        }
        try await transcriptionManager.ensureModelAvailable()

        // Start transcription
        try await transcriptionManager.startTranscription()

        // Start microphone if enabled
        if configuration.microphoneEnabled {
            try await startMicrophone()
        }

        // Start system audio if enabled
        if configuration.systemAudioEnabled {
            try await startSystemAudio()
        }

        logger.debug("Components started")
    }

    private func startMicrophone() async throws {
        logger.debug("Starting microphone capture")

        // Check permission
        let permissionHandler = await MicrophonePermissionHandler()
        try await permissionHandler.ensurePermission()

        // Create and start capture
        microphoneCapture = MicrophoneCapture()

        guard let microphoneCapture = microphoneCapture,
              let audioMixer = audioMixer else {
            throw CallTranscriptionError.featureNotImplemented("Microphone capture or mixer not available")
        }

        // Route microphone audio to mixer
        microphoneCapture.audioBufferHandler = { @Sendable [weak self, weak audioMixer] buffer in
            guard let self = self, let audioMixer = audioMixer else { return }
            nonisolated(unsafe) let unsafeBuffer = buffer
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                do {
                    try await audioMixer.feedMicrophoneBuffer(unsafeBuffer)
                } catch {
                    self.logger.error("Failed to feed microphone buffer: \(error.localizedDescription)")
                }
            }
        }

        nonisolated(unsafe) let unsafeMicCapture = microphoneCapture
        try await unsafeMicCapture.startCapture()
        logger.debug("Microphone capture started")
    }

    private func startSystemAudio() async throws {
        logger.debug("Starting system audio capture")

        systemAudioCapture = SystemAudioCapture()

        guard let systemAudioCapture = systemAudioCapture,
              let audioMixer = audioMixer else {
            throw CallTranscriptionError.featureNotImplemented("System audio capture or mixer not available")
        }

        // Route system audio to mixer
        systemAudioCapture.audioBufferHandler = { @Sendable [weak self, weak audioMixer] buffer in
            guard let self = self, let audioMixer = audioMixer else { return }
            nonisolated(unsafe) let unsafeBuffer = buffer
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                do {
                    try await audioMixer.feedSystemAudioBuffer(unsafeBuffer)
                } catch {
                    self.logger.error("Failed to feed system audio buffer: \(error.localizedDescription)")
                }
            }
        }

        nonisolated(unsafe) let unsafeSysCapture = systemAudioCapture
        try await unsafeSysCapture.startCapture()
        logger.debug("System audio capture started")
    }

    private func stopAudioCapture() async {
        logger.debug("Stopping audio capture")

        if let microphoneCapture = microphoneCapture {
            nonisolated(unsafe) let unsafeMicCapture = microphoneCapture
            await unsafeMicCapture.stopCapture()
        }

        if let systemAudioCapture = systemAudioCapture {
            nonisolated(unsafe) let unsafeSysCapture = systemAudioCapture
            await unsafeSysCapture.stopCapture()
        }

        logger.debug("Audio capture stopped")
    }

    private func stopTranscription() async {
        logger.debug("Stopping transcription")

        if let transcriptionManager = transcriptionManager {
            await transcriptionManager.stopTranscription()
        }

        logger.debug("Transcription stopped")
    }

    // MARK: - Private Methods - Transcription Handling

    private func handleTranscriptionResult(_ result: TranscriptionResult) async {
        guard let transcriptWriter = transcriptWriter,
              let recordingStartTime = recordingStartTime else {
            logger.error("Cannot handle transcription: missing writer or start time")
            return
        }

        // Calculate timestamp relative to recording start
        let timestamp = Date().timeIntervalSince(recordingStartTime)

        // Write to file
        do {
            try await transcriptWriter.append(result.text, timestamp: timestamp)
            logger.debug("Wrote transcription: \(result.text)")
        } catch {
            logger.error("Failed to write transcription: \(error.localizedDescription)")
        }

        // Notify callback
        transcriptionResultHandler?(result.text, result.isFinal)
    }

    // MARK: - Private Methods - Post-Recording Actions

    private func executePostRecordingAction(transcriptPath: String) async {
        switch configuration.postRecordingActionType {
        case .doNothing:
            logger.debug("No post-recording action configured")

        case .script:
            if let scriptPath = configuration.postRecordingScriptPath, !scriptPath.isEmpty {
                await executePostRecordingScript(scriptPath: scriptPath, transcriptPath: transcriptPath)
            } else {
                logger.warning("Post-recording action set to script but no script path configured")
            }

        case .shortcut:
            if let shortcutIdentifier = configuration.shortcutIdentifier, !shortcutIdentifier.isEmpty {
                await executePostRecordingShortcut(shortcutName: shortcutIdentifier, transcriptPath: transcriptPath)
            } else {
                logger.warning("Post-recording action set to shortcut but no shortcut configured")
            }
        }
    }

    private func executePostRecordingScript(scriptPath: String, transcriptPath: String) async {
        logger.info("Executing post-recording script: \(scriptPath)")

        let executor = ShellScriptExecutor()
        do {
            let result = try await executor.execute(
                scriptPath: scriptPath,
                transcriptPath: transcriptPath
            )

            if result.exitCode == 0 {
                logger.info("Post-recording script completed successfully")
            } else {
                logger.warning("Post-recording script exited with code \(result.exitCode)")
            }

            if let output = result.standardOutput, !output.isEmpty {
                logger.debug("Script output: \(output)")
            }

        } catch {
            logger.error("Post-recording script failed: \(error.localizedDescription)")
            // Don't throw - script failure shouldn't prevent transcript from being available
        }
    }

    private func executePostRecordingShortcut(shortcutName: String, transcriptPath: String) async {
        logger.info("Executing post-recording shortcut: \(shortcutName)")

        let executor = ShortcutExecutor()
        let result = await executor.execute(
            shortcutName: shortcutName,
            transcriptPath: transcriptPath
        )

        if result.success {
            logger.info("Post-recording shortcut completed successfully")
            if let output = result.output, !output.isEmpty {
                logger.debug("Shortcut output: \(output)")
            }
        } else {
            logger.error("Post-recording shortcut failed: \(result.errorMessage ?? "Unknown error")")
            // Don't throw - shortcut failure shouldn't prevent transcript from being available
        }
    }

    // MARK: - Private Methods - Cleanup

    private func cleanup() async {
        logger.debug("Cleaning up resources")

        // Stop accessing security-scoped resource if it was started
        if let url = securityScopedURL {
            url.stopAccessingSecurityScopedResource()
            logger.info("Stopped accessing security-scoped resource: \(url.path)")
            securityScopedURL = nil
        }

        // Reset silence detector state
        silenceDetector?.reset()

        microphoneCapture = nil
        systemAudioCapture = nil
        audioMixer = nil
        transcriptionManager = nil
        transcriptWriter = nil
        silenceDetector = nil
        recordingStartTime = nil
        currentTitle = nil
        isPaused = false

        logger.debug("Cleanup complete")
    }
}
