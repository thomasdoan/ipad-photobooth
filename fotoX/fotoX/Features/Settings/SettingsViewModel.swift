//
//  SettingsViewModel.swift
//  fotoX
//
//  ViewModel for the settings screen
//

import Foundation
import Observation

/// ViewModel for operator settings
@Observable
@MainActor
final class SettingsViewModel {
    // MARK: - State
    
    /// Current Worker base URL
    var baseURLString: String = ""

    /// Shared presign token for uploads
    var presignToken: String = ""

    /// Video duration in seconds for capture
    var videoDuration: Double = 10

    /// Review duration in seconds after each strip
    var stripReviewDuration: Double = 5

    /// Whether to auto-advance without review controls
    var autoAdvanceWithoutReview: Bool = false

    /// Whether to require manual advance after review
    var manualAdvanceAfterReview: Bool = false

    /// Whether to keep files on device after upload
    var keepFilesAfterUpload: Bool = false

    /// Capture aspect ratio setting
    var captureAspectRatioSetting: CaptureAspectRatio = .auto

    /// Photo countdown duration in seconds
    var photoCountdownSeconds: Double = 3

    /// Whether to show individual photos/videos in session details
    var showIndividualMedia: Bool = false

    /// Whether testing connection
    var isTestingConnection: Bool = false
    
    /// Connection test result
    var connectionTestResult: ConnectionTestResult?
    
    /// Validation error
    var urlError: String?
    
    // MARK: - Initialization
    private let healthCheck: @Sendable (URL) async throws -> Bool
       
    init(healthCheck: @escaping @Sendable (URL) async throws -> Bool = { url in
        try await SettingsViewModel.defaultHealthCheck(url: url)
    }) {
        self.healthCheck = healthCheck
        loadCurrentSettings()
    }

    // MARK: - Settings
    
    /// Loads current settings
    private func loadCurrentSettings() {
        baseURLString = WorkerConfiguration.currentBaseURL().absoluteString
        presignToken = WorkerConfiguration.currentPresignToken() ?? ""
        videoDuration = WorkerConfiguration.currentVideoDuration()
        stripReviewDuration = WorkerConfiguration.currentStripReviewDuration()
        autoAdvanceWithoutReview = WorkerConfiguration.autoAdvanceWithoutReview()
        manualAdvanceAfterReview = WorkerConfiguration.manualAdvanceAfterReview()
        keepFilesAfterUpload = WorkerConfiguration.keepFilesAfterUpload()
        captureAspectRatioSetting = WorkerConfiguration.currentCaptureAspectRatio()
        photoCountdownSeconds = Double(WorkerConfiguration.currentPhotoCountdownSeconds())
        showIndividualMedia = WorkerConfiguration.showIndividualMedia()
    }
    
    /// Validates the URL
    var isURLValid: Bool {
        guard let url = URL(string: baseURLString),
              url.scheme == "http" || url.scheme == "https",
              url.host != nil else {
            return false
        }
        return true
    }
    
    /// Saves all settings
    func saveSettings() -> Bool {
        guard isURLValid else {
            urlError = "Please enter a valid URL (e.g., https://your-worker.workers.dev)"
            return false
        }

        urlError = nil
        if let url = URL(string: baseURLString) {
            WorkerConfiguration.saveBaseURL(url)
        }
        WorkerConfiguration.savePresignToken(presignToken)
        WorkerConfiguration.saveVideoDuration(videoDuration)
        WorkerConfiguration.saveStripReviewDuration(stripReviewDuration)
        WorkerConfiguration.saveAutoAdvanceWithoutReview(autoAdvanceWithoutReview)
        WorkerConfiguration.saveManualAdvanceAfterReview(manualAdvanceAfterReview)
        WorkerConfiguration.saveKeepFilesAfterUpload(keepFilesAfterUpload)
        WorkerConfiguration.saveCaptureAspectRatio(captureAspectRatioSetting)
        WorkerConfiguration.savePhotoCountdownSeconds(Int(photoCountdownSeconds))
        WorkerConfiguration.saveShowIndividualMedia(showIndividualMedia)
        return true
    }

    /// Saves the base URL (deprecated, use saveSettings instead)
    func saveBaseURL() -> Bool {
        return saveSettings()
    }
    
    /// Resets to default URL
    func resetToDefault() {
        baseURLString = WorkerConfiguration.defaultBaseURL.absoluteString
        videoDuration = WorkerConfiguration.defaultVideoDuration
        stripReviewDuration = WorkerConfiguration.defaultStripReviewDuration
        autoAdvanceWithoutReview = WorkerConfiguration.defaultAutoAdvanceWithoutReview
        manualAdvanceAfterReview = WorkerConfiguration.defaultManualAdvanceAfterReview
        keepFilesAfterUpload = false
        captureAspectRatioSetting = WorkerConfiguration.defaultCaptureAspectRatio
        photoCountdownSeconds = Double(WorkerConfiguration.defaultPhotoCountdownSeconds)
        showIndividualMedia = WorkerConfiguration.defaultShowIndividualMedia
        _ = saveSettings()
        connectionTestResult = nil
    }
    
    /// Tests connection to the Worker
    @MainActor
    func testConnection() async {
        guard isURLValid else {
            urlError = "Please enter a valid URL first"
            return
        }
        
        isTestingConnection = true
        connectionTestResult = nil

        guard let url = URL(string: baseURLString) else {
            connectionTestResult = .failure("Invalid URL")
            isTestingConnection = false
            return
        }
        
        do {
            let isHealthy = try await healthCheck(url)
            connectionTestResult = isHealthy ? .success : .failure("Worker did not respond successfully")
        } catch {
            connectionTestResult = .failure("Connection failed: \(error.localizedDescription)")
        }
        
        isTestingConnection = false
    }

    static func defaultHealthCheck(url: URL, session: URLSession = .shared) async throws -> Bool {
        let apiURL = url.appendingPathComponent("api").appendingPathComponent("health")

        var request = URLRequest(url: apiURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }
        return (200..<400).contains(httpResponse.statusCode)
    }
    
    /// Clears test result
    func clearTestResult() {
        connectionTestResult = nil
    }
}

/// Result of connection test
enum ConnectionTestResult: Equatable {
    case success
    case failure(String)
}
