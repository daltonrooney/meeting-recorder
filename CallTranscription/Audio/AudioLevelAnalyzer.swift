import Foundation
import AVFoundation
import Accelerate

/// Utility for analyzing audio buffer levels and detecting silence.
///
/// AudioLevelAnalyzer provides methods to:
/// - Calculate RMS (Root Mean Square) amplitude from audio buffers
/// - Convert RMS values to decibels (dB)
/// - Detect silence based on a threshold (default -40 dB)
///
/// The analyzer uses Accelerate framework for efficient RMS calculation.
public struct AudioLevelAnalyzer {

    /// Result of audio level analysis.
    public struct AnalysisResult {
        /// RMS (Root Mean Square) amplitude (0.0 to 1.0)
        public let rms: Float

        /// Level in decibels relative to full scale
        public let db: Float

        /// Whether the audio is considered silent (below threshold)
        public let isSilent: Bool
    }

    /// Default silence threshold in dB (below this is considered silence)
    ///
    /// -40 dB is an industry-standard threshold for detecting room silence.
    /// This represents approximately 1% of full-scale amplitude and effectively
    /// captures the ambient noise floor in typical quiet environments.
    public static let defaultSilenceThreshold: Float = -40.0

    // MARK: - Public Methods

    /// Calculates the RMS (Root Mean Square) amplitude from an audio buffer.
    ///
    /// RMS provides a measure of the average signal level, calculated as:
    /// RMS = sqrt(sum of squares / number of samples)
    ///
    /// - Parameter buffer: The audio buffer to analyze
    /// - Returns: RMS value (0.0 to 1.0), or 0.0 if buffer is empty/invalid
    public static func calculateRMS(from buffer: AVAudioPCMBuffer) -> Float {
        guard buffer.frameLength > 0,
              let channelData = buffer.floatChannelData else {
            return 0.0
        }

        let frameCount = Int(buffer.frameLength)
        let samples = channelData[0]

        // Use Accelerate framework for efficient calculation
        var rms: Float = 0.0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(frameCount))

        return rms
    }

    /// Converts an RMS value to decibels (dB).
    ///
    /// The conversion formula is: dB = 20 * log10(RMS)
    /// - 0 dB represents full scale (RMS = 1.0)
    /// - Negative infinity represents silence (RMS = 0.0)
    ///
    /// - Parameter rms: RMS value to convert (0.0 to 1.0)
    /// - Returns: Level in dB, or -infinity if RMS is 0
    public static func convertToDecibels(rms: Float) -> Float {
        guard rms > 0 else {
            return -Float.infinity
        }

        return 20.0 * log10(rms)
    }

    /// Checks if an audio buffer is silent based on a dB threshold.
    ///
    /// - Parameters:
    ///   - buffer: The audio buffer to check
    ///   - threshold: Silence threshold in dB (default: -40.0 dB)
    /// - Returns: true if the buffer level is below the threshold
    public static func isSilent(_ buffer: AVAudioPCMBuffer, threshold: Float = defaultSilenceThreshold) -> Bool {
        let rms = calculateRMS(from: buffer)
        let db = convertToDecibels(rms: rms)

        // Check if below threshold (db < threshold means quieter/more negative)
        // Special case: -infinity is always silent
        if db.isInfinite {
            return true
        }

        return db < threshold
    }

    /// Analyzes an audio buffer and returns comprehensive level information.
    ///
    /// - Parameters:
    ///   - buffer: The audio buffer to analyze
    ///   - threshold: Silence threshold in dB (default: -40.0 dB)
    /// - Returns: Analysis result containing RMS, dB, and silence detection
    public static func analyze(_ buffer: AVAudioPCMBuffer, threshold: Float = defaultSilenceThreshold) -> AnalysisResult {
        let rms = calculateRMS(from: buffer)
        let db = convertToDecibels(rms: rms)
        let isSilent = db.isInfinite || db < threshold

        return AnalysisResult(rms: rms, db: db, isSilent: isSilent)
    }
}
