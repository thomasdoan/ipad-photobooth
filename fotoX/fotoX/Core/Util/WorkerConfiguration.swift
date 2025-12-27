//
//  WorkerConfiguration.swift
//  fotoX
//
//  Shared configuration for Worker base URL
//

import Foundation

enum WorkerConfiguration {
    static let baseURLKey = "workerBaseURL"
    static let presignTokenKey = "workerPresignToken"
    static let videoDurationKey = "captureVideoDuration"
    static let defaultBaseURL = URL(string: "https://your-worker.workers.dev")!
    static let defaultVideoDuration: TimeInterval = 10

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
}
