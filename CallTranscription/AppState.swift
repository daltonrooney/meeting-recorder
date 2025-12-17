import Foundation
import Combine

/// The central state management object for the Call Transcription application.
///
/// `AppState` coordinates the recording state, elapsed time tracking, and integrates
/// with the recording subsystems through RecordingSessionCoordinator.
@MainActor
public final class AppState: ObservableObject {

    // MARK: - Published Properties

    /// Whether the app is currently recording.
    @Published public private(set) var isRecording: Bool = false

    /// The elapsed time of the current recording in MM:SS or HH:MM:SS format.
    @Published public private(set) var elapsedTime: String = "00:00"

    /// Whether the consent dialog should be shown.
    @Published public private(set) var showConsentDialog: Bool = false

    /// Whether the recording is currently paused.
    @Published public private(set) var isPaused: Bool = false

    // MARK: - Private Properties

    /// Settings manager for accessing user preferences.
    private let settingsManager: SettingsManager

    /// Recording session coordinator for managing recording operations.
    private var coordinator: RecordingSessionCoordinator?

    /// Timer for tracking elapsed time.
    private var timer: Timer?

    /// Start time of the current recording.
    private var startTime: Date?

    /// Total paused duration to subtract from elapsed time.
    private var totalPausedDuration: TimeInterval = 0

    /// Time when recording was paused (for tracking paused duration).
    private var pauseStartTime: Date?

    // MARK: - Initialization

    /// Initializes AppState with a settings manager.
    ///
    /// - Parameter settingsManager: The settings manager to use for configuration.
    ///   Defaults to a new instance if not provided.
    public init(settingsManager: SettingsManager = SettingsManager()) {
        self.settingsManager = settingsManager
        // Show consent dialog if user hasn't accepted it yet
        self.showConsentDialog = !settingsManager.hasAcceptedConsentDialog
    }

    nonisolated deinit {
        MainActor.assumeIsolated {
            timer?.invalidate()
            timer = nil
        }
    }

    // MARK: - Public Methods

    /// Starts a new recording session (UI state only - for testing).
    ///
    /// This method updates only the UI state without actual recording.
    /// Use `startRecording(title:)` for actual recording operations.
    ///
    /// If recording is already in progress, this method handles the call gracefully
    /// by doing nothing (idempotent).
    public func startRecording() {
        // Handle multiple start calls gracefully
        guard !isRecording else {
            return
        }

        // Update UI state only
        isRecording = true
        startTime = Date()

        // Start timer for elapsed time tracking
        startTimer()
    }

    /// Starts a new recording session with actual recording hardware.
    ///
    /// This method:
    /// - Creates a RecordingSessionCoordinator with current settings
    /// - Starts the recording through the coordinator
    /// - Changes `isRecording` to true
    /// - Resets elapsed time tracking
    /// - Starts the elapsed time timer
    ///
    /// - Parameter title: The title for the recording session
    /// - Throws: `CallTranscriptionError` if recording fails to start
    ///
    /// If recording is already in progress, this method handles the call gracefully
    /// by doing nothing (idempotent).
    public func startActualRecording(title: String) async throws {
        // Handle multiple start calls gracefully
        guard !isRecording else {
            return
        }

        // Build configuration from settings
        let configuration = RecordingConfiguration(
            outputFolder: settingsManager.expandedOutputFolderPath(),
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: settingsManager.captureMicrophone,
            systemAudioEnabled: settingsManager.captureSystemAudio,
            postRecordingScriptPath: settingsManager.postRecordingScript.isEmpty ? nil : settingsManager.expandedPostRecordingScriptPath(),
            silencePauseThreshold: settingsManager.silencePauseThreshold
        )

        // Create coordinator locally first
        let newCoordinator = RecordingSessionCoordinator(configuration: configuration)

        do {
            // Try to start recording
            try await newCoordinator.startRecording(title: title)

            // Only update state after successful start
            self.coordinator = newCoordinator
            isRecording = true
            isPaused = false
            startTime = Date()
            totalPausedDuration = 0
            pauseStartTime = nil
            startTimer()
        } catch {
            // Coordinator failed to start, ensure it's not retained
            // No cleanup needed since we haven't assigned to self.coordinator yet
            throw error
        }
    }

    /// Stops the current recording session (UI state only - for testing).
    ///
    /// This method updates only the UI state without stopping actual recording.
    /// Use `stopRecording() async throws` for actual recording operations.
    ///
    /// If recording is not in progress, this method handles the call gracefully
    /// by doing nothing (idempotent).
    public func stopRecording() {
        // Handle stop when not recording gracefully
        guard isRecording else {
            return
        }

        // Stop timer
        stopTimer()

        // Reset state
        isRecording = false
        startTime = nil
        elapsedTime = "00:00"
    }

    /// Stops the current recording session with actual recording hardware.
    ///
    /// This method:
    /// - Stops the recording through the coordinator
    /// - Changes `isRecording` to false
    /// - Stops the elapsed time timer
    /// - Resets elapsed time to "00:00"
    /// - Returns the URL of the transcript file
    ///
    /// - Returns: The URL of the completed transcript file
    /// - Throws: `CallTranscriptionError` if stopping fails
    ///
    /// If recording is not in progress, this method throws an error.
    @discardableResult
    public func stopActualRecording() async throws -> URL {
        // Handle stop when not recording gracefully
        guard isRecording else {
            throw CallTranscriptionError.notRecording
        }

        // Stop recording through coordinator
        guard let coordinator = coordinator else {
            throw CallTranscriptionError.notRecording
        }

        do {
            let transcriptURL = try await coordinator.stopRecording()

            // Cleanup state after success
            stopTimer()
            isRecording = false
            isPaused = false
            startTime = nil
            elapsedTime = "00:00"
            totalPausedDuration = 0
            pauseStartTime = nil
            self.coordinator = nil

            return transcriptURL
        } catch {
            // Ensure cleanup even on error to keep app usable
            stopTimer()
            isRecording = false
            isPaused = false
            startTime = nil
            elapsedTime = "00:00"
            totalPausedDuration = 0
            pauseStartTime = nil
            self.coordinator = nil
            throw error
        }
    }

    /// Dismisses the consent dialog.
    ///
    /// - Parameter rememberChoice: If true, the user's acceptance is persisted to settings
    ///   and the dialog won't be shown again. If false, the dialog is dismissed for this session
    ///   but will appear again on next app launch.
    public func dismissConsentDialog(rememberChoice: Bool) {
        showConsentDialog = false
        if rememberChoice {
            settingsManager.hasAcceptedConsentDialog = true
        }
    }

    /// Pauses the current recording session.
    ///
    /// - Throws: `CallTranscriptionError.notRecording` if not currently recording.
    ///
    /// Pausing stops the timer and pauses audio capture while maintaining the recording session.
    /// Call `resumeRecording()` to continue.
    public func pauseRecording() async throws {
        guard isRecording else {
            throw CallTranscriptionError.notRecording
        }

        // Idempotent - if already paused, do nothing
        guard !isPaused else {
            return
        }

        // Ensure coordinator exists
        guard let coordinator = coordinator else {
            throw CallTranscriptionError.notRecording
        }

        // Pause the coordinator
        try await coordinator.pauseRecording()

        // Update state
        isPaused = true
        pauseStartTime = Date()

        // Stop the timer while paused
        stopTimer()
    }

    /// Resumes the current recording session after being paused.
    ///
    /// - Throws: `CallTranscriptionError.notPaused` if not currently paused.
    ///
    /// Resumes audio capture and restarts the elapsed time timer.
    public func resumeRecording() async throws {
        guard isPaused else {
            throw CallTranscriptionError.notPaused
        }

        // Ensure coordinator exists
        guard let coordinator = coordinator else {
            throw CallTranscriptionError.notRecording
        }

        // Calculate paused duration
        if let pauseStart = pauseStartTime {
            totalPausedDuration += Date().timeIntervalSince(pauseStart)
            pauseStartTime = nil
        }

        // Resume the coordinator
        try await coordinator.resumeRecording()

        // Update state
        isPaused = false

        // Restart the timer
        startTimer()
    }

    // MARK: - Private Methods

    /// Starts the timer for tracking elapsed time.
    private func startTimer() {
        // Invalidate any existing timer
        stopTimer()

        // Create a new timer that fires every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateElapsedTime()
            }
        }

        // Ensure the timer fires on the common run loop mode
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    /// Stops the elapsed time timer.
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// Updates the elapsed time based on the start time.
    private func updateElapsedTime() {
        guard let startTime = startTime else {
            return
        }

        // Calculate total elapsed time excluding paused duration
        let totalElapsed = Date().timeIntervalSince(startTime)
        let activeElapsed = totalElapsed - totalPausedDuration

        // Format the time
        elapsedTime = formatTime(seconds: Int(activeElapsed))
    }

    /// Formats seconds into a time string (MM:SS or HH:MM:SS).
    ///
    /// - Parameter seconds: The number of seconds to format.
    /// - Returns: A formatted time string in MM:SS format (or HH:MM:SS if >= 1 hour).
    private func formatTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            // HH:MM:SS format
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            // MM:SS format
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}
