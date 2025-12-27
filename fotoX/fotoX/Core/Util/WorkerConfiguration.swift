//
//  WorkerConfiguration.swift
//  fotoX
//
//  Shared configuration for Worker base URL
//

import Foundation

/// Video review mode options
enum VideoReviewMode: Int, Sendable {
    case disabled = 0      // No review screen
    case firstOnly = 1     // Show review only for the first capture
    case allCaptures = 2   // Show review after every capture

    var displayName: String {
        switch self {
        case .disabled: return "Disabled"
        case .firstOnly: return "First Capture Only"
        case .allCaptures: return "All Captures"
        }
    }
}

enum WorkerConfiguration {
    static let baseURLKey = "workerBaseURL"
    static let presignTokenKey = "workerPresignToken"
    static let videoDurationKey = "captureVideoDuration"
    static let videoReviewModeKey = "videoReviewMode"
    static let defaultBaseURL = URL(string: "https://your-worker.workers.dev")!
    static let defaultVideoDuration: TimeInterval = 10
    static let defaultVideoReviewMode: VideoReviewMode = .firstOnly

    static func currentBaseURL() -> URL {
        if let urlString = UserDefaults.standard.string(forKey: baseURLKey),
           let url = URL(string: urlString) {
            return url
        }
        return defaultBaseURL
    }

    static func saveBaseURL(_ url: URL) {
        UserDefaults.standard.set(url.absoluteString, forKey: baseURLKey)
    }

    static func currentPresignToken() -> String? {
        let token = UserDefaults.standard.string(forKey: presignTokenKey)
        return token?.isEmpty == true ? nil : token
    }

    static func savePresignToken(_ token: String) {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(trimmed, forKey: presignTokenKey)
    }

    static func currentVideoDuration() -> TimeInterval {
        let duration = UserDefaults.standard.double(forKey: videoDurationKey)
        // If not set (returns 0), use default
        if duration == 0 {
            return defaultVideoDuration
        }
        // Clamp to valid range (3-10 seconds)
        return max(3, min(10, duration))
    }

    static func saveVideoDuration(_ duration: TimeInterval) {
        let clamped = max(3, min(10, duration))
        UserDefaults.standard.set(clamped, forKey: videoDurationKey)
    }

    static func currentVideoReviewMode() -> VideoReviewMode {
        let rawValue = UserDefaults.standard.integer(forKey: videoReviewModeKey)
        // If not set (returns 0), that's actually .disabled, but we want default to be .firstOnly
        // Check if the key exists
        if UserDefaults.standard.object(forKey: videoReviewModeKey) == nil {
            return defaultVideoReviewMode
        }
        return VideoReviewMode(rawValue: rawValue) ?? defaultVideoReviewMode
    }

    static func saveVideoReviewMode(_ mode: VideoReviewMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: videoReviewModeKey)
    }
}
