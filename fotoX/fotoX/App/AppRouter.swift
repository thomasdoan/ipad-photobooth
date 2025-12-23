//
//  AppRouter.swift
//  fotoX
//
//  Navigation routing for the app
//

import Foundation

/// Represents the current screen/route in the app
enum AppRoute: Equatable, Sendable {
    /// Event selection screen (initial state)
    case eventSelection

    /// Idle/attract screen for selected event
    case idle

    /// Gallery view for event photos/videos
    case gallery

    /// Active capture session
    case capture(CapturePhase)

    /// Uploading captured assets
    case uploading

    /// QR code and email screen
    case qrDisplay

    /// Settings screen (operator access)
    case settings
}

/// Phases within the capture flow
enum CapturePhase: Equatable, Sendable {
    /// Preparing session (API call in progress)
    case preparingSession
    
    /// Capturing a strip (countdown, recording, photo)
    case capturingStrip(index: Int)
    
    /// Reviewing a captured strip
    case reviewingStrip(index: Int)
    
    /// Summary before upload
    case summary
}

/// State machine for capture flow
enum CaptureStripState: Equatable, Sendable {
    /// Countdown before recording
    case countdown(remaining: Int)
    
    /// Recording video
    case recording(elapsed: TimeInterval)
    
    /// Capturing photo after video
    case capturingPhoto
    
    /// Processing captured media
    case processing
}

