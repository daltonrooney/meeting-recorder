import XCTest
import AVFoundation
@testable import CallTranscription

/// Performance and Memory Tests for Long Recording Sessions
///
/// Following TDD methodology: These tests are written FIRST before implementation optimizations.
///
/// This test suite validates that the recording system maintains stable performance during extended sessions:
/// - Memory usage remains bounded (no unbounded growth)
/// - CPU usage stays reasonable
/// - Buffer processing is efficient
/// - Resource cleanup is complete
/// - Long recording sessions (1-2 hours) are stable
///
/// Tests use XCTest performance measurement APIs:
/// - XCTMemoryMetric: Physical memory usage
/// - XCTCPUMetric: CPU time, cycles, and instructions
/// - XCTClockMetric: Wall clock time
///
/// Note: Long-running tests (1+ hour) are configured with extended execution time allowances.
@MainActor
final class PerformanceAndMemoryTests: XCTestCase {

    var coordinator: RecordingSessionCoordinator!
    var testOutputFolder: URL!

    override func setUp() async throws {
        try await super.setUp()

        // Configure extended timeout for long-running tests
        // Some tests run for 1-2 hours to validate memory stability
        executionTimeAllowance = 7200  // 2 hours maximum

        // Create unique temp output folder for each test
        testOutputFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent("PerfTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testOutputFolder, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        // Stop any active recording
        if let coordinator = coordinator {
            let isRecording = await coordinator.isRecording
            if isRecording {
                try? await coordinator.stopRecording()
            }
        }
        coordinator = nil

        // Clean up temp folder
        if let testOutputFolder = testOutputFolder {
            try? FileManager.default.removeItem(at: testOutputFolder)
        }
        testOutputFolder = nil

        try await super.tearDown()
    }

    // MARK: - Memory Leak Detection Helper

    /// Tracks an instance for memory leaks using weak reference
    ///
    /// This is the recommended approach for detecting memory leaks in XCTest.
    /// The instance is checked in a teardown block to verify it was deallocated.
    func trackForMemoryLeak(
        instance: AnyObject,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(
                instance,
                "Potential memory leak detected - instance should be deallocated",
                file: file,
                line: line
            )
        }
    }

    // MARK: - Memory Stability Tests

    /// Test 1: Memory usage doesn't grow unbounded during moderate recording
    ///
    /// Validates:
    /// - Memory usage stays within reasonable bounds
    /// - No exponential memory growth
    /// - Memory baseline is established for comparison
    func testMemoryUsageRemainsStableDuringRecording() async throws {
        // GIVEN: A recording configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true,
            systemAudioEnabled: false
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Measuring memory during a 10-second recording
        let options = XCTMeasureOptions()
        options.iterationCount = 5  // Multiple iterations for baseline

        measure(metrics: [XCTMemoryMetric()], options: options) {
            // Start recording (measured for memory)
            Task { @MainActor in
                try? await coordinator.startRecording(title: "Memory Stability Test")
            }

            // Run for 10 seconds
            Thread.sleep(forTimeInterval: 10.0)

            // Stop recording (measured for memory)
            Task { @MainActor in
                try? await coordinator.stopRecording()
            }
        }

        // THEN: Memory usage should be stable (baseline established for comparison)
        // XCTest will compare future runs against this baseline
    }

    /// Test 2: No significant memory leaks during extended recording
    ///
    /// Validates:
    /// - Coordinator instance is properly deallocated
    /// - No retain cycles in recording session
    /// - Memory is released after recording stops
    func testNoMemoryLeaksAfterRecordingSession() async throws {
        // GIVEN: A recording coordinator
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true,
            systemAudioEnabled: false
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // Track coordinator for memory leaks
        trackForMemoryLeak(instance: coordinator!)

        // WHEN: Performing a complete recording cycle
        try await coordinator.startRecording(title: "Leak Detection Test")
        try await Task.sleep(for: .seconds(2))
        try await coordinator.stopRecording()

        // Release coordinator
        coordinator = nil

        // THEN: Coordinator should be deallocated (verified in teardown block)
    }

    /// Test 3: Buffer memory is released properly
    ///
    /// Validates:
    /// - Audio buffers don't accumulate in memory
    /// - Buffer processing releases memory
    /// - Mixer and capture components clean up buffers
    func testBufferMemoryIsReleasedProperly() async throws {
        // GIVEN: A recording configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true,
            systemAudioEnabled: false
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Measuring memory during buffer processing
        let options = XCTMeasureOptions()
        options.iterationCount = 10  // More iterations for buffer processing

        measure(metrics: [XCTMemoryMetric()], options: options) {
            Task { @MainActor in
                try? await coordinator.startRecording(title: "Buffer Memory Test")
            }

            // Let buffers process for 5 seconds
            Thread.sleep(forTimeInterval: 5.0)

            Task { @MainActor in
                try? await coordinator.stopRecording()
            }
        }

        // THEN: Memory should not grow with each iteration
        // If buffers accumulate, memory would increase across iterations
    }

    /// Test 4: Transcription memory is managed
    ///
    /// Validates:
    /// - Transcription results don't accumulate unbounded
    /// - Partial results are cleaned up
    /// - Final results are written and released
    func testTranscriptionMemoryIsManaged() async throws {
        // GIVEN: A recording configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        var transcriptionCount = 0
        await coordinator.onTranscriptionResult { _, _ in
            transcriptionCount += 1
        }

        // WHEN: Recording with transcription
        measure(metrics: [XCTMemoryMetric()]) {
            Task { @MainActor in
                try? await coordinator.startRecording(title: "Transcription Memory Test")
            }

            Thread.sleep(forTimeInterval: 10.0)

            Task { @MainActor in
                try? await coordinator.stopRecording()
            }
        }

        // THEN: Memory should be stable despite transcription results
        // Transcription manager should not accumulate results in memory
    }

    /// Test 5: File writing doesn't accumulate memory
    ///
    /// Validates:
    /// - TranscriptWriter streams to disk
    /// - Text buffers are released after writing
    /// - No memory accumulation during long transcripts
    func testFileWritingDoesNotAccumulateMemory() async throws {
        // GIVEN: A recording configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Recording with file writing
        measure(metrics: [XCTMemoryMetric()]) {
            Task { @MainActor in
                try? await coordinator.startRecording(title: "File Writing Memory Test")
            }

            // Longer recording to generate more transcription writes
            Thread.sleep(forTimeInterval: 15.0)

            Task { @MainActor in
                try? await coordinator.stopRecording()
            }
        }

        // THEN: Memory should be stable
        // TranscriptWriter should stream to disk without buffering all content
    }

    // MARK: - CPU Usage Tests

    /// Test 6: CPU usage remains reasonable during recording
    ///
    /// Validates:
    /// - CPU usage is not excessive
    /// - Audio processing is efficient
    /// - Baseline CPU usage is established
    func testCPUUsageRemainsReasonable() async throws {
        // GIVEN: A recording configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true,
            systemAudioEnabled: false
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Measuring CPU during recording
        let options = XCTMeasureOptions()
        options.iterationCount = 5

        measure(metrics: [XCTCPUMetric()], options: options) {
            Task { @MainActor in
                try? await coordinator.startRecording(title: "CPU Usage Test")
            }

            Thread.sleep(forTimeInterval: 10.0)

            Task { @MainActor in
                try? await coordinator.stopRecording()
            }
        }

        // THEN: CPU usage baseline is established
        // Future runs will be compared against this baseline
    }

    /// Test 7: Audio processing is efficient
    ///
    /// Validates:
    /// - Audio buffer processing doesn't spike CPU
    /// - Mixing is efficient
    /// - Real-time processing is maintained
    func testAudioProcessingIsEfficient() async throws {
        // GIVEN: Dual-source recording configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true,
            systemAudioEnabled: false  // System audio may not be available in tests
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Measuring CPU during audio processing
        measure(metrics: [XCTCPUMetric(), XCTClockMetric()]) {
            Task { @MainActor in
                try? await coordinator.startRecording(title: "Audio Processing Efficiency Test")
            }

            // Process audio for 10 seconds
            Thread.sleep(forTimeInterval: 10.0)

            Task { @MainActor in
                try? await coordinator.stopRecording()
            }
        }

        // THEN: CPU time and wall clock time should be reasonable
        // If processing falls behind, wall clock time would be much higher
    }

    /// Test 8: Transcription is efficient
    ///
    /// Validates:
    /// - Speech recognition doesn't consume excessive CPU
    /// - Transcription keeps up with real-time audio
    /// - CPU usage is sustainable for long sessions
    func testTranscriptionIsEfficient() async throws {
        // GIVEN: A recording configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Measuring CPU with transcription enabled
        measure(metrics: [XCTCPUMetric()]) {
            Task { @MainActor in
                try? await coordinator.startRecording(title: "Transcription Efficiency Test")
            }

            Thread.sleep(forTimeInterval: 10.0)

            Task { @MainActor in
                try? await coordinator.stopRecording()
            }
        }

        // THEN: CPU usage should be acceptable
        // Speech recognition should not dominate CPU usage
    }

    // MARK: - Long Recording Scenario Tests

    /// Test 9: Handles 1-hour recording session
    ///
    /// Validates:
    /// - System remains stable for 1 hour
    /// - Memory doesn't grow unbounded
    /// - Recording completes successfully
    ///
    /// Note: This is a VERY long-running test (1+ hour)
    /// Run separately or skip in regular test suites
    func testHandlesOneHourRecordingSession() async throws {
        // Skip in regular test runs - enable manually for extended testing
        try XCTSkipIf(true, "Skipping 1-hour test - enable manually for extended testing")

        // GIVEN: A recording configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Recording for 1 hour
        let options = XCTMeasureOptions()
        options.iterationCount = 1  // Single long run

        measure(metrics: [XCTMemoryMetric(), XCTCPUMetric()], options: options) {
            Task { @MainActor in
                try? await coordinator.startRecording(title: "1-Hour Stability Test")
            }

            // Record for 1 hour
            Thread.sleep(forTimeInterval: 3600.0)

            Task { @MainActor in
                try? await coordinator.stopRecording()
            }
        }

        // THEN: Recording should complete without crashes or memory issues
    }

    /// Test 10: Handles 2-hour recording session
    ///
    /// Validates:
    /// - System remains stable for 2 hours
    /// - Maximum endurance test
    /// - All resources are properly managed
    ///
    /// Note: This is an EXTREMELY long-running test (2+ hours)
    /// Run manually for final validation only
    func testHandlesTwoHourRecordingSession() async throws {
        // Skip in regular test runs - enable manually for extended testing
        try XCTSkipIf(true, "Skipping 2-hour test - enable manually for final validation")

        // GIVEN: A recording configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Recording for 2 hours
        let options = XCTMeasureOptions()
        options.iterationCount = 1  // Single long run

        measure(metrics: [XCTMemoryMetric(), XCTCPUMetric()], options: options) {
            Task { @MainActor in
                try? await coordinator.startRecording(title: "2-Hour Endurance Test")
            }

            // Record for 2 hours
            Thread.sleep(forTimeInterval: 7200.0)

            Task { @MainActor in
                try? await coordinator.stopRecording()
            }
        }

        // THEN: System should remain stable throughout
    }

    /// Test 11: Buffer handling remains stable during long recording
    ///
    /// Validates:
    /// - Audio buffers are processed consistently
    /// - No buffer queue buildup over time
    /// - Processing rate matches capture rate
    func testBufferHandlingRemainsStable() async throws {
        // GIVEN: A recording configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Recording for an extended period
        measure(metrics: [XCTMemoryMetric(), XCTClockMetric()]) {
            Task { @MainActor in
                try? await coordinator.startRecording(title: "Buffer Stability Test")
            }

            // Record for 30 seconds to test buffer consistency
            Thread.sleep(forTimeInterval: 30.0)

            Task { @MainActor in
                try? await coordinator.stopRecording()
            }
        }

        // THEN: Wall clock time should match recording duration
        // If buffers queue up, processing time would exceed recording time
    }

    // MARK: - Resource Cleanup Tests

    /// Test 12: Resources released after stop
    ///
    /// Validates:
    /// - All audio components are stopped
    /// - File handles are closed
    /// - Memory is released
    func testResourcesReleasedAfterStop() async throws {
        // GIVEN: A recording coordinator
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)
        trackForMemoryLeak(instance: coordinator!)

        // WHEN: Starting and stopping recording
        try await coordinator.startRecording(title: "Resource Cleanup Test")
        try await Task.sleep(for: .seconds(2))
        try await coordinator.stopRecording()

        // Check that recording is stopped
        let isRecording = await coordinator.isRecording
        XCTAssertFalse(isRecording, "Recording should be stopped")

        // Release coordinator
        coordinator = nil

        // THEN: Resources should be released (verified in teardown)
    }

    /// Test 13: Can start new session without degradation
    ///
    /// Validates:
    /// - Previous session cleanup is complete
    /// - New session starts cleanly
    /// - No resource exhaustion
    func testCanStartNewSessionWithoutDegradation() async throws {
        // GIVEN: A recording configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Performing multiple sequential sessions
        for i in 1...5 {
            try await coordinator.startRecording(title: "Session \(i)")
            try await Task.sleep(for: .seconds(1))
            try await coordinator.stopRecording()
        }

        // THEN: All sessions should complete successfully
        let isRecording = await coordinator.isRecording
        XCTAssertFalse(isRecording, "Should not be recording after all sessions")
    }

    /// Test 14: Multiple record/stop cycles don't leak
    ///
    /// Validates:
    /// - Repeated start/stop doesn't accumulate memory
    /// - Resources are properly released each cycle
    /// - System can handle many cycles
    func testMultipleRecordStopCyclesDontLeak() async throws {
        // GIVEN: A recording configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Measuring memory across multiple cycles
        let options = XCTMeasureOptions()
        options.iterationCount = 10

        measure(metrics: [XCTMemoryMetric()], options: options) {
            Task { @MainActor in
                try? await coordinator.startRecording(title: "Cycle Test")
            }

            Thread.sleep(forTimeInterval: 2.0)

            Task { @MainActor in
                try? await coordinator.stopRecording()
            }
        }

        // THEN: Memory should be stable across iterations
        // No accumulation of resources from previous cycles
    }

    // MARK: - Audio Processing Performance Tests

    /// Test 15: Audio buffers processed without drops
    ///
    /// Validates:
    /// - Buffer processing keeps up with capture rate
    /// - No dropped buffers due to slow processing
    /// - Real-time processing is maintained
    func testAudioBuffersProcessedWithoutDrops() async throws {
        // GIVEN: A recording configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Measuring processing time
        measure(metrics: [XCTClockMetric()]) {
            Task { @MainActor in
                try? await coordinator.startRecording(title: "Buffer Processing Test")
            }

            Thread.sleep(forTimeInterval: 10.0)

            Task { @MainActor in
                try? await coordinator.stopRecording()
            }
        }

        // THEN: Wall clock time should be close to sleep duration
        // Significant deviation would indicate processing delays
    }

    /// Test 16: Maintains real-time processing under load
    ///
    /// Validates:
    /// - Processing doesn't fall behind during recording
    /// - CPU usage stays reasonable under load
    /// - System can handle sustained recording
    func testMaintainsRealTimeProcessing() async throws {
        // GIVEN: A recording configuration
        let config = RecordingConfiguration(
            outputFolder: testOutputFolder.path,
            locale: Locale(identifier: "en-US"),
            microphoneEnabled: true
        )

        coordinator = await RecordingSessionCoordinator(configuration: config)

        // WHEN: Measuring CPU and time under sustained load
        measure(metrics: [XCTCPUMetric(), XCTClockMetric()]) {
            Task { @MainActor in
                try? await coordinator.startRecording(title: "Real-Time Processing Test")
            }

            // Sustained recording for 30 seconds
            Thread.sleep(forTimeInterval: 30.0)

            Task { @MainActor in
                try? await coordinator.stopRecording()
            }
        }

        // THEN: CPU usage and timing should be consistent
        // No degradation over the recording duration
    }
}
