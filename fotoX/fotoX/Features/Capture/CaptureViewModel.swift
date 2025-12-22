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
    
    /// Whether we're in review mode
    var isReviewing: Bool = false
    
    /// Whether to show the summary
    var showingSummary: Bool = false
    
    /// Error message
    var errorMessage: String?
    
    /// Configuration
    let config: CaptureConfiguration
    
    // MARK: - Camera
    
    /// Camera controller
    let cameraController: CameraController
    
    /// Current recording URL
    private var currentVideoURL: URL?
    
    /// Current photo data
    private var currentPhotoData: Data?
    
    // MARK: - Timers
    
    private var countdownTimer: Timer?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    
    // MARK: - Initialization
    
    init(config: CaptureConfiguration = .default) {
        self.config = config
        self.cameraController = CameraController()
        self.cameraController.delegate = self
    }
    
    // MARK: - Setup
    
    /// Sets up the camera
    @MainActor
    func setupCamera() async {
        do {
            try await cameraController.setup()
            cameraController.startSession()
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
        }
        invalidateTimers()
    }
    
    // MARK: - Capture Flow
    
    /// Starts capturing the current strip
    @MainActor
    func startCapture() {
        guard stripState == .ready || stripState == .complete else { return }
        
        stripState = .countdown(remaining: config.countdownSeconds)
        startCountdownTimer()
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
        
        capturedStrips.append(strip)
        
        // Reset for next or show review
        currentVideoURL = nil
        currentPhotoData = nil
        stripState = .complete
        isReviewing = true
    }
    
    /// Proceeds to the next strip or summary
    @MainActor
    func continueToNext() {
        isReviewing = false
        
        if currentStripIndex < config.stripCount - 1 {
            currentStripIndex += 1
            stripState = .ready
        } else {
            showingSummary = true
        }
    }
    
    /// Retakes the current strip
    @MainActor
    func retakeCurrentStrip() {
        // Remove the strip if it was captured
        capturedStrips.removeAll { $0.stripIndex == currentStripIndex }
        
        isReviewing = false
        stripState = .ready
    }
    
    /// Retakes a specific strip from summary
    @MainActor
    func retakeStrip(at index: Int) {
        capturedStrips.removeAll { $0.stripIndex == index }
        showingSummary = false
        currentStripIndex = index
        stripState = .ready
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
}

// MARK: - CameraControllerDelegate

extension CaptureViewModel: CameraControllerDelegate {
    func cameraController(_ controller: CameraController, didStartRecording url: URL) {
        currentVideoURL = url
    }
    
    func cameraController(_ controller: CameraController, didFinishRecording url: URL) {
        currentVideoURL = url
        
        // Trigger photo capture
        Task { @MainActor in
            await capturePhoto()
        }
    }
    
    func cameraController(_ controller: CameraController, didCapturePhoto data: Data) {
        // Photo captured, handled in capturePhoto()
    }
    
    func cameraController(_ controller: CameraController, didFailWithError error: CameraError) {
        Task { @MainActor in
            errorMessage = error.localizedDescription
            stripState = .error(error.localizedDescription)
        }
    }
}
