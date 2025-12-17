import Foundation
import AVFoundation
import Speech
import OSLog

/// Result from transcription containing text and finality status.
public struct TranscriptionResult {
    /// The transcribed text.
    public let text: String

    /// Whether this is a final result or partial result.
    public let isFinal: Bool

    public init(text: String, isFinal: Bool) {
        self.text = text
        self.isFinal = isFinal
    }
}

/// Manages speech transcription using SpeechTranscriber API (macOS 26+).
///
/// TranscriptionManager provides real-time speech-to-text conversion using Apple's
/// SpeechTranscriber and SpeechAnalyzer APIs. It handles model availability,
/// audio buffer processing, and result delivery.
///
/// - Important: Requires macOS 26.0 or later for SpeechTranscriber API.
///
/// Example usage:
/// ```swift
/// let manager = TranscriptionManager(locale: Locale(identifier: "en-US"))
/// manager.onTranscriptionResult = { result in
///     print("Transcription: \(result.text), Final: \(result.isFinal)")
/// }
/// try await manager.ensureModelAvailable()
/// try await manager.startTranscription()
/// // Feed audio buffers...
/// await manager.feedAudio(buffer)
/// // When done...
/// await manager.stopTranscription()
/// ```
@available(macOS 26.0, *)
@MainActor
public final class TranscriptionManager {

    // MARK: - Public Properties

    /// Callback invoked when transcription results are available.
    public var onTranscriptionResult: (@MainActor (TranscriptionResult) -> Void)?

    /// Callback invoked when transcription errors occur.
    public var onTranscriptionError: (@MainActor (Error) -> Void)?

    // MARK: - Private Properties

    private let locale: Locale
    private let logger = Logger(subsystem: "dev.rygn.CallTranscription", category: "TranscriptionManager")
    private var analyzer: SpeechAnalyzer?
    private var transcriber: SpeechTranscriber?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var analysisTask: Task<Void, Never>?
    private var resultTask: Task<Void, Never>?
    private var isTranscribing = false
    private var analyzerFormat: AVAudioFormat?
    private var audioConverter: AVAudioConverter?

    // MARK: - Initialization

    /// Initializes a new transcription manager.
    ///
    /// - Parameter locale: The locale for transcription (defaults to system locale)
    public init(locale: Locale = Locale.current) {
        // Normalize locale for Speech framework compatibility
        // Speech framework uses standard BCP 47 format (e.g., "en-US")
        // Construct normalized locale from language and region components to preserve locale properties
        if let languageCode = locale.language.languageCode?.identifier,
           let regionCode = locale.region?.identifier {
            self.locale = Locale(identifier: "\(languageCode)-\(regionCode)")
        } else {
            // Fallback to simple normalization if components unavailable
            self.locale = Locale(identifier: locale.identifier.replacingOccurrences(of: "_", with: "-"))
        }
    }

    deinit {
        // Clean up if still transcribing
        if isTranscribing {
            analysisTask?.cancel()
            resultTask?.cancel()
        }
    }

    // MARK: - Public Methods

    /// Ensures the speech recognition model is available for the configured locale.
    ///
    /// This method checks if the locale is supported and if the recognition model
    /// is downloaded. If not downloaded, it may trigger a download.
    ///
    /// - Throws: `CallTranscriptionError.localeNotSupported` if locale is not supported,
    ///   or `CallTranscriptionError.speechRecognitionUnavailable` if model is unavailable
    public func ensureModelAvailable() async throws {
        // Check if locale is supported
        let supportedLocales = SFSpeechRecognizer.supportedLocales()
        let isSupported = supportedLocales.contains { supportedLocale in
            supportedLocale.identifier == locale.identifier
        }

        guard isSupported else {
            throw CallTranscriptionError.localeNotSupported(locale)
        }

        // Check if speech recognizer can be created for this locale
        guard SFSpeechRecognizer(locale: locale) != nil else {
            throw CallTranscriptionError.speechRecognitionUnavailable
        }

        // Model availability is handled implicitly by SpeechTranscriber
        // If the model is not available, transcription start will fail
    }

    /// Starts transcription.
    ///
    /// Initializes the SpeechAnalyzer and SpeechTranscriber, creates the input
    /// stream for audio buffers, and begins processing transcription results.
    ///
    /// - Throws: `CallTranscriptionError.localeNotSupported` if locale is not supported,
    ///   or `CallTranscriptionError.speechRecognitionUnavailable` if transcription unavailable
    public func startTranscription() async throws {
        guard !isTranscribing else {
            return // Already transcribing
        }

        // Ensure model is available
        try await ensureModelAvailable()

        // Create transcriber for the locale using preset optimized for real-time
        let transcriber = SpeechTranscriber(
            locale: locale,
            preset: .transcription
        )
        self.transcriber = transcriber

        // Create analyzer with transcriber module
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        self.analyzer = analyzer

        // Get best audio format for the analyzer
        let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])
        self.analyzerFormat = analyzerFormat

        // Create input stream for audio buffers
        let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()
        self.inputContinuation = continuation

        // Start result processing task
        resultTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                for try await result in transcriber.results {
                    let text = String(result.text.characters)
                    let transcriptionResult = TranscriptionResult(
                        text: text,
                        isFinal: result.isFinal
                    )

                    // Deliver result
                    self.onTranscriptionResult?(transcriptionResult)
                }
            } catch {
                // Log error and notify user if result streaming fails unexpectedly
                self.logger.error("Result streaming failed: \(error.localizedDescription)")
                self.onTranscriptionError?(error)
            }
        }

        // Start analysis task
        analysisTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await analyzer.start(inputSequence: stream)
            } catch {
                // Log error - analysis failure typically means input stream issues
                await MainActor.run {
                    self.logger.error("Analysis failed: \(error.localizedDescription)")
                    self.onTranscriptionError?(error)
                }
            }
        }

        isTranscribing = true
    }

    /// Feeds an audio buffer to the transcription system.
    ///
    /// - Parameter buffer: The audio buffer to process
    /// - Note: This method must be called from the MainActor context
    public func feedAudio(_ buffer: AVAudioPCMBuffer) async {
        guard isTranscribing, let continuation = inputContinuation, let analyzerFormat = analyzerFormat else {
            return
        }

        // Convert buffer to analyzer format if needed
        let convertedBuffer: AVAudioPCMBuffer
        if buffer.format == analyzerFormat {
            convertedBuffer = buffer
        } else {
            // Create converter if needed
            if audioConverter == nil || audioConverter?.inputFormat != buffer.format {
                guard let converter = AVAudioConverter(from: buffer.format, to: analyzerFormat) else {
                    logger.error("Failed to create audio converter from \(buffer.format.sampleRate)Hz to \(analyzerFormat.sampleRate)Hz")
                    return
                }
                audioConverter = converter
            }

            // Calculate output buffer capacity based on sample rate ratio
            let sampleRateRatio = analyzerFormat.sampleRate / buffer.format.sampleRate
            let outputCapacity = AVAudioFrameCount(Double(buffer.frameLength) * sampleRateRatio)

            guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: analyzerFormat, frameCapacity: outputCapacity) else {
                logger.error("Failed to create output buffer with capacity \(outputCapacity)")
                return
            }

            var error: NSError?
            let status = audioConverter?.convert(to: outputBuffer, error: &error) { inNumPackets, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            guard status != .error, error == nil else {
                logger.error("Audio conversion failed: \(error?.localizedDescription ?? "unknown error")")
                return
            }

            convertedBuffer = outputBuffer
        }

        // Wrap buffer in AnalyzerInput and yield to stream
        let input = AnalyzerInput(buffer: convertedBuffer)
        continuation.yield(input)
    }

    /// Stops transcription and cleans up resources.
    ///
    /// Finishes the input stream, waits for final results, and releases resources.
    public func stopTranscription() async {
        guard isTranscribing else {
            return
        }

        isTranscribing = false

        // Finish input stream to signal end of audio
        inputContinuation?.finish()
        inputContinuation = nil

        // Finalize analyzer to get final results
        if let analyzer = analyzer {
            do {
                try await analyzer.finalizeAndFinishThroughEndOfInput()
            } catch {
                // Finalize may fail if already finished
            }
        }

        // Wait for tasks to complete
        await resultTask?.value
        await analysisTask?.value

        // Clean up resources
        resultTask = nil
        analysisTask = nil
        analyzer = nil
        transcriber = nil
        audioConverter = nil
        analyzerFormat = nil
    }
}
