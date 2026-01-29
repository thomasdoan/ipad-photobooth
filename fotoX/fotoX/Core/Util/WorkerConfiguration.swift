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
    static let keepFilesAfterUploadKey = "keepFilesAfterUpload"
    static let stripReviewDurationKey = "stripReviewDuration"
    static let autoAdvanceWithoutReviewKey = "autoAdvanceWithoutReview"
    static let manualAdvanceAfterReviewKey = "manualAdvanceAfterReview"
    static let captureAspectRatioKey = "captureAspectRatio"
    static let countdownSecondsKey = "photoCountdownSeconds" // Keep storage key for backwards compatibility
    static let defaultBaseURL = URL(string: "https://id8.events")!
    static let defaultVideoDuration: TimeInterval = 10
    static let defaultStripReviewDuration: TimeInterval = 10
    static let minStripReviewDuration: TimeInterval = 5
    static let maxStripReviewDuration: TimeInterval = 30
    static let defaultAutoAdvanceWithoutReview = false
    static let defaultManualAdvanceAfterReview = false
    static let defaultCaptureAspectRatio: CaptureAspectRatio = .auto
    static let defaultCountdownSeconds: Int = 3
    static let minCountdownSeconds: Int = 0

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
        return max(1, min(10, duration))
    }

    static func saveVideoDuration(_ duration: TimeInterval) {
        let clamped = max(1, min(10, duration))
        UserDefaults.standard.set(clamped, forKey: videoDurationKey)
    }

    static func currentStripReviewDuration() -> TimeInterval {
        let duration = UserDefaults.standard.double(forKey: stripReviewDurationKey)
        if duration == 0 {
            return defaultStripReviewDuration
        }
        return max(minStripReviewDuration, min(maxStripReviewDuration, duration))
    }

    static func saveStripReviewDuration(_ duration: TimeInterval) {
        let clamped = max(minStripReviewDuration, min(maxStripReviewDuration, duration))
        UserDefaults.standard.set(clamped, forKey: stripReviewDurationKey)
    }

    static func autoAdvanceWithoutReview() -> Bool {
        if UserDefaults.standard.object(forKey: autoAdvanceWithoutReviewKey) == nil {
            return defaultAutoAdvanceWithoutReview
        }
        return UserDefaults.standard.bool(forKey: autoAdvanceWithoutReviewKey)
    }

    static func saveAutoAdvanceWithoutReview(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: autoAdvanceWithoutReviewKey)
    }

    static func manualAdvanceAfterReview() -> Bool {
        if UserDefaults.standard.object(forKey: manualAdvanceAfterReviewKey) == nil {
            return defaultManualAdvanceAfterReview
        }
        return UserDefaults.standard.bool(forKey: manualAdvanceAfterReviewKey)
    }

    static func saveManualAdvanceAfterReview(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: manualAdvanceAfterReviewKey)
    }

    static func currentCaptureAspectRatio() -> CaptureAspectRatio {
        guard let rawValue = UserDefaults.standard.string(forKey: captureAspectRatioKey),
              let ratio = CaptureAspectRatio(rawValue: rawValue) else {
            return defaultCaptureAspectRatio
        }
        return ratio
    }

    static func saveCaptureAspectRatio(_ ratio: CaptureAspectRatio) {
        UserDefaults.standard.set(ratio.rawValue, forKey: captureAspectRatioKey)
    }

    static func keepFilesAfterUpload() -> Bool {
        UserDefaults.standard.bool(forKey: keepFilesAfterUploadKey)
    }

    static func saveKeepFilesAfterUpload(_ keep: Bool) {
        UserDefaults.standard.set(keep, forKey: keepFilesAfterUploadKey)
    }

    /// Returns the current countdown seconds, clamped to the video duration
    static func currentCountdownSeconds() -> Int {
        // Check if key exists (integer returns 0 for missing keys, so we need explicit check)
        if UserDefaults.standard.object(forKey: countdownSecondsKey) == nil {
            return defaultCountdownSeconds
        }
        let value = UserDefaults.standard.integer(forKey: countdownSecondsKey)
        let videoDuration = Int(currentVideoDuration())
        // Clamp to valid range (0 to videoDuration)
        return max(minCountdownSeconds, min(videoDuration, value))
    }

    /// Saves the countdown seconds, clamping to valid range
    static func saveCountdownSeconds(_ seconds: Int) {
        let videoDuration = Int(currentVideoDuration())
        let clamped = max(minCountdownSeconds, min(videoDuration, seconds))
        UserDefaults.standard.set(clamped, forKey: countdownSecondsKey)
    }

    /// Legacy alias for backwards compatibility
    static func currentPhotoCountdownSeconds() -> Int {
        currentCountdownSeconds()
    }

    /// Legacy alias for backwards compatibility
    static func savePhotoCountdownSeconds(_ seconds: Int) {
        saveCountdownSeconds(seconds)
    }
}
