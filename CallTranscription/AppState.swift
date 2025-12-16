import Foundation
import Combine

/// The central state management object for the Call Transcription application.
///
/// `AppState` coordinates the recording state, elapsed time tracking, and will eventually
/// coordinate between different subsystems (audio capture, speech recognition, etc.).
@MainActor
public final class AppState: ObservableObject {

    // MARK: - Published Properties

    /// Whether the app is currently recording.
    @Published public private(set) var isRecording: Bool = false

    /// The elapsed time of the current recording in MM:SS or HH:MM:SS format.
    @Published public private(set) var elapsedTime: String = "00:00"

    // MARK: - Private Properties

    /// Timer for tracking elapsed time.
    private var timer: Timer?

    /// Start time of the current recording.
    private var startTime: Date?

    /// Total accumulated seconds for the current recording.
    private var totalSeconds: Int = 0

    // MARK: - Initialization

    public init() {
        // Initialize with default values (already set in property declarations)
    }

    // MARK: - Public Methods

    /// Starts a new recording session.
    ///
    /// This method:
    /// - Changes `isRecording` to true
    /// - Resets elapsed time tracking
    /// - Starts the elapsed time timer
    ///
    /// If recording is already in progress, this method handles the call gracefully
    /// by doing nothing (idempotent).
    public func startRecording() async {
        // Handle multiple start calls gracefully
        guard !isRecording else {
            return
        }

        // Update state
        isRecording = true
        totalSeconds = 0
        startTime = Date()

        // Start timer for elapsed time tracking
        startTimer()
    }

    /// Stops the current recording session.
    ///
    /// This method:
    /// - Changes `isRecording` to false
    /// - Stops the elapsed time timer
    /// - Resets elapsed time to "00:00"
    ///
    /// If recording is not in progress, this method handles the call gracefully
    /// by doing nothing (idempotent).
    public func stopRecording() async {
        // Handle stop when not recording gracefully
        guard isRecording else {
            return
        }

        // Stop timer
        stopTimer()

        // Reset state
        isRecording = false
        totalSeconds = 0
        startTime = nil
        elapsedTime = "00:00"
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
        totalSeconds = Int(elapsed)

        // Format the time
        elapsedTime = formatTime(seconds: totalSeconds)
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
