//
//  CaptureViewModel.swift
//  fotoX
//
//  ViewModel for the capture flow
//

import Foundation
import Observation

/// ViewModel managing the capture flow state machine
@Observable
final class CaptureViewModel: @unchecked Sendable {
    // MARK: - State
    
    /// Current strip being captured (0, 1, 2)
    var currentStripIndex: Int = 0
    
    /// State of the current strip capture
    var stripState: StripCaptureState = .ready
    
    /// Captured strips
    var capturedStrips: [CapturedStripMedia] = []

    /// Strip captured and pending review
    var pendingStrip: CapturedStripMedia?

    /// Whether the session is complete
    var isSessionComplete: Bool = false
    
    /// Whether the camera is ready
    var isCameraReady: Bool = false
    
    /// Error message
    var errorMessage: String?
    
    /// Configuration
    let config: CaptureConfiguration
    
    // MARK: - Camera

    /// Camera controller (protocol-based for testability and simulator support)
    let cameraController: any CameraControlling

    /// Current recording URL
    private var currentVideoURL: URL?

    /// Current photo data
    private var currentPhotoData: Data?

    // MARK: - Timers

    private var countdownTimer: Timer?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private var reviewTask: Task<Void, Never>?

    // MARK: - Initialization

    /// Creates a CaptureViewModel with the default camera controller for the environment
    convenience init(config: CaptureConfiguration = .default) {
        self.init(config: config, cameraController: CameraControllerFactory.makeController())
    }

    /// Creates a CaptureViewModel with a specific camera controller (for testing)
    init(config: CaptureConfiguration = .default, cameraController: any CameraControlling) {
        self.config = config
        self.cameraController = cameraController
        self.cameraController.delegate = self
    }
    
    // MARK: - Setup
    
    /// Sets up the camera
    @MainActor
    func setupCamera() async {
        do {
            try await cameraController.setup()
            cameraController.startSession()
            isCameraReady = true
        } catch let error as CameraError {
            errorMessage = error.localizedDescription
            stripState = .error(error.localizedDescription)
        } catch {
            errorMessage = "Failed to setup camera"
            stripState = .error("Camera setup failed")
        }
    }
    
    /// Cleans up resources
    func cleanup(deleteTemporaryFiles: Bool = true) {
        cameraController.stopSession()
        if deleteTemporaryFiles {
            cameraController.cleanupTempFiles()
            discardPendingStrip(deleteFile: true)
        }
        cancelReviewTask()
        invalidateTimers()
    }
    
    // MARK: - Capture Flow
    
    /// Starts capturing the current strip
    @MainActor
    func startCapture() {
        guard stripState == .ready else { return }
        guard currentStripIndex < config.stripCount else { return }

        isSessionComplete = false
        if config.countdownSeconds > 0 {
            stripState = .countdown(remaining: config.countdownSeconds)
            startCountdownTimer()
        } else {
            countdownComplete()
        }
    }

    /// Resets state to retry the current strip
    @MainActor
    func retryCurrentStrip() {
        cancelReviewTask()
        currentVideoURL = nil
        currentPhotoData = nil
        stripState = .ready
    }
    
    /// Handles countdown completion
    @MainActor
    private func countdownComplete() {
        // Start recording
        do {
            try cameraController.startRecording()
            stripState = .recording(elapsed: 0)
            recordingStartTime = Date()
            startRecordingTimer()
        } catch {
            stripState = .error("Failed to start recording")
        }
    }
    
    /// Handles recording completion
    @MainActor
    private func recordingComplete() {
        cameraController.stopRecording()
        stripState = .processingVideo
    }
    
    /// Captures the photo after video
    @MainActor
    func capturePhoto() async {
        stripState = .photoCountdown(remaining: config.photoCountdownSeconds)
        
        // Brief countdown for photo
        try? await Task.sleep(nanoseconds: UInt64(config.photoCountdownSeconds) * 1_000_000_000)
        
        stripState = .capturingPhoto
        
        do {
            let photoData = try await cameraController.capturePhoto()
            currentPhotoData = photoData
            stripState = .processingPhoto
            
            // Generate thumbnail and finalize strip
            await finalizeStrip()
        } catch {
            stripState = .error("Failed to capture photo")
        }
    }
    
    /// Finalizes the current strip
    @MainActor
    private func finalizeStrip() async {
        guard let videoURL = currentVideoURL,
              let photoData = currentPhotoData else {
            stripState = .error("Missing capture data")
            return
        }
        
        // Generate thumbnail
        let thumbnailData = await CameraController.generateThumbnail(from: videoURL)
        
        let strip = CapturedStripMedia(
            stripIndex: currentStripIndex,
            videoURL: videoURL,
            photoData: photoData,
            thumbnailData: thumbnailData
        )
        
        pendingStrip = strip

        // Reset for review
        currentVideoURL = nil
        currentPhotoData = nil
        stripState = .complete
        startReviewTimer()
    }

    /// Accepts the pending strip and moves to the next one (or completes the session)
    @MainActor
    func acceptPendingStripAndAdvance() {
        guard let pendingStrip = pendingStrip else { return }
        cancelReviewTask()

        capturedStrips.append(pendingStrip)
        self.pendingStrip = nil

        if currentStripIndex < config.stripCount - 1 {
            currentStripIndex += 1
            stripState = .ready
            startCapture()
        } else {
            isSessionComplete = true
        }
    }

    /// Discards the pending strip and restarts capture
    @MainActor
    func retakePendingStrip() {
        guard pendingStrip != nil else { return }
        cancelReviewTask()
        discardPendingStrip(deleteFile: true)
        stripState = .ready
        startCapture()
    }

    /// Effective review duration based on settings
    var reviewDuration: TimeInterval {
        config.autoAdvanceWithoutReview ? config.autoAdvancePreviewDuration : config.stripReviewDuration
    }

    /// Whether review controls should be visible
    var showsReviewControls: Bool {
        !config.autoAdvanceWithoutReview
    }
    
    /// Converts captured strips to the model format
    func getCapturedStrips() -> [CapturedStrip] {
        capturedStrips.map { media in
            CapturedStrip(
                stripIndex: media.stripIndex,
                videoURL: media.videoURL,
                photoData: media.photoData,
                thumbnailData: media.thumbnailData
            )
        }
    }
    
    // MARK: - Timers
    
    private func startCountdownTimer() {
        invalidateTimers()
        
        var remaining = config.countdownSeconds
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            remaining -= 1
            
            Task { @MainActor in
                if case .error = self.stripState {
                    timer.invalidate()
                    return
                }
                if remaining > 0 {
                    self.stripState = .countdown(remaining: remaining)
                } else {
                    timer.invalidate()
                    self.countdownComplete()
                }
            }
        }
    }
    
    private func startRecordingTimer() {
        invalidateTimers()
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self,
                  let startTime = self.recordingStartTime else {
                timer.invalidate()
                return
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            
            Task { @MainActor in
                if case .error = self.stripState {
                    timer.invalidate()
                    return
                }
                if elapsed >= self.config.videoDuration {
                    timer.invalidate()
                    self.recordingComplete()
                } else {
                    self.stripState = .recording(elapsed: elapsed)
                }
            }
        }
    }
    
    private func invalidateTimers() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    @MainActor
    private func startReviewTimer() {
        cancelReviewTask()
        let duration = reviewDuration
        reviewTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            acceptPendingStripAndAdvance()
        }
    }

    private func cancelReviewTask() {
        reviewTask?.cancel()
        reviewTask = nil
    }

    private func discardPendingStrip(deleteFile: Bool) {
        if deleteFile, let url = pendingStrip?.videoURL {
            try? FileManager.default.removeItem(at: url)
        }
        pendingStrip = nil
    }
}

// MARK: - CameraControllerDelegate

extension CaptureViewModel: CameraControllerDelegate {
    func cameraController(_ controller: any CameraControlling, didStartRecording url: URL) {
        currentVideoURL = url
    }

    func cameraController(_ controller: any CameraControlling, didFinishRecording url: URL) {
        currentVideoURL = url

        // Trigger photo capture
        Task { @MainActor in
            await capturePhoto()
        }
    }

    func cameraController(_ controller: any CameraControlling, didCapturePhoto data: Data) {
        // Photo captured, handled in capturePhoto()
    }

    func cameraController(_ controller: any CameraControlling, didFailWithError error: CameraError) {
        Task { @MainActor in
            invalidateTimers()
            errorMessage = error.localizedDescription
            stripState = .error(error.localizedDescription)
        }
    }
}
