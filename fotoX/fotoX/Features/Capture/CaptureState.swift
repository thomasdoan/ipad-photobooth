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

    /// Reviewing captured video before continuing
    case reviewingStrip(CapturedStripMedia)

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

    /// Video review mode setting
    let videoReviewMode: VideoReviewMode

    /// Default configuration
    static var `default`: CaptureConfiguration {
        CaptureConfiguration(
            videoDuration: WorkerConfiguration.currentVideoDuration(),
            countdownSeconds: 0,
            photoCountdownSeconds: 1,
            stripCount: 3,
            videoReviewMode: WorkerConfiguration.currentVideoReviewMode()
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
