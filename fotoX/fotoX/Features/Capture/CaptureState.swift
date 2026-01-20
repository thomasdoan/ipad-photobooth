//
//  CaptureState.swift
//  fotoX
//
//  State machine for the capture flow
//

import Foundation

/// Overall state of a capture strip
enum StripCaptureState: Equatable, Sendable {
    /// Waiting to start countdown
    case ready
    
    /// Countdown before recording (3, 2, 1)
    case countdown(remaining: Int)
    
    /// Recording video
    case recording(elapsed: TimeInterval)
    
    /// Processing video, about to capture photo
    case processingVideo
    
    /// Short countdown before photo
    case photoCountdown(remaining: Int)
    
    /// Capturing photo
    case capturingPhoto
    
    /// Processing photo
    case processingPhoto
    
    /// Strip complete
    case complete
    
    /// Error occurred
    case error(String)
}

/// Configuration for capture
struct CaptureConfiguration: Sendable {
    /// Duration of video recording in seconds
    let videoDuration: TimeInterval
    
    /// Countdown before recording starts
    let countdownSeconds: Int
    
    /// Short countdown before photo capture
    let photoCountdownSeconds: Int
    
    /// Total number of strips to capture
    let stripCount: Int

    /// Review duration after each strip (seconds)
    let stripReviewDuration: TimeInterval

    /// Whether to auto-advance with minimal review UI
    let autoAdvanceWithoutReview: Bool

    /// Short preview duration when auto-advancing without review
    let autoAdvancePreviewDuration: TimeInterval

    /// Whether to require manual advance after review
    let manualAdvanceAfterReview: Bool

    init(
        videoDuration: TimeInterval,
        countdownSeconds: Int,
        photoCountdownSeconds: Int,
        stripCount: Int,
        stripReviewDuration: TimeInterval = WorkerConfiguration.defaultStripReviewDuration,
        autoAdvanceWithoutReview: Bool = WorkerConfiguration.defaultAutoAdvanceWithoutReview,
        autoAdvancePreviewDuration: TimeInterval = 1,
        manualAdvanceAfterReview: Bool = WorkerConfiguration.defaultManualAdvanceAfterReview
    ) {
        self.videoDuration = videoDuration
        self.countdownSeconds = countdownSeconds
        self.photoCountdownSeconds = photoCountdownSeconds
        self.stripCount = stripCount
        self.stripReviewDuration = stripReviewDuration
        self.autoAdvanceWithoutReview = autoAdvanceWithoutReview
        self.autoAdvancePreviewDuration = autoAdvancePreviewDuration
        self.manualAdvanceAfterReview = manualAdvanceAfterReview
    }
    
    /// Default configuration
    static var `default`: CaptureConfiguration {
        CaptureConfiguration(
            videoDuration: WorkerConfiguration.currentVideoDuration(),
            countdownSeconds: 0,
            photoCountdownSeconds: WorkerConfiguration.currentPhotoCountdownSeconds(),
            stripCount: 3,
            stripReviewDuration: WorkerConfiguration.currentStripReviewDuration(),
            autoAdvanceWithoutReview: WorkerConfiguration.autoAdvanceWithoutReview(),
            autoAdvancePreviewDuration: 1,
            manualAdvanceAfterReview: WorkerConfiguration.manualAdvanceAfterReview()
        )
    }
}

/// Represents the captured media for a single strip
struct CapturedStripMedia: Sendable {
    let stripIndex: Int
    let videoURL: URL
    let photoData: Data
    let thumbnailData: Data?
}
