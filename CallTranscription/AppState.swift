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

    // MARK: - Private Properties

    /// Settings manager for accessing user preferences.
    private let settingsManager: SettingsManager

    /// Recording session coordinator for managing recording operations.
    private var coordinator: RecordingSessionCoordinator?

    /// Timer for tracking elapsed time.
    private var timer: Timer?

    /// Start time of the current recording.
    private var startTime: Date?

    // MARK: - Initialization

    /// Initializes AppState with a settings manager.
    ///
    /// - Parameter settingsManager: The settings manager to use for configuration.
    ///   Defaults to a new instance if not provided.
    public init(settingsManager: SettingsManager = SettingsManager()) {
        self.settingsManager = settingsManager
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
            postRecordingScriptPath: settingsManager.postRecordingScript.isEmpty ? nil : settingsManager.expandedPostRecordingScriptPath()
        )

        // Create coordinator
        coordinator = RecordingSessionCoordinator(configuration: configuration)

        // Start recording through coordinator
        try await coordinator?.startRecording(title: title)

        // Update UI state
        isRecording = true
        startTime = Date()

        // Start timer for elapsed time tracking
        startTimer()
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

        let transcriptURL = try await coordinator.stopRecording()

        // Stop timer
        stopTimer()

        // Reset state
        isRecording = false
        startTime = nil
        elapsedTime = "00:00"
        self.coordinator = nil

        return transcriptURL
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

        // Calculate total seconds elapsed
        let elapsed = Date().timeIntervalSince(startTime)

        // Format the time
        elapsedTime = formatTime(seconds: Int(elapsed))
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
