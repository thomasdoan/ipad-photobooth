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
final class SettingsViewModel {
    // MARK: - State
    
    /// Current Worker base URL
    var baseURLString: String = ""

    /// Shared presign token for uploads
    var presignToken: String = ""

    /// Video duration in seconds for capture
    var videoDuration: Double = 10

    /// Whether to show text overlays on frame (couple's names, date, hashtag)
    var frameTextOverlays: Bool = true

    /// Whether testing connection
    var isTestingConnection: Bool = false
    
    /// Connection test result
    var connectionTestResult: ConnectionTestResult?
    
    /// Validation error
    var urlError: String?
    
    // MARK: - Initialization
    
    private let healthCheck: @Sendable (URL) async throws -> Bool
    
    init() {
        self.healthCheck = SettingsViewModel.defaultHealthCheck
        loadCurrentSettings()
    }

    init(healthCheck: @escaping @Sendable (URL) async throws -> Bool) {
        self.healthCheck = healthCheck
        loadCurrentSettings()
    }
    
    // MARK: - Settings
    
    /// Loads current settings
    private func loadCurrentSettings() {
        baseURLString = WorkerConfiguration.currentBaseURL().absoluteString
        presignToken = WorkerConfiguration.currentPresignToken() ?? ""
        videoDuration = WorkerConfiguration.currentVideoDuration()
        frameTextOverlays = WorkerConfiguration.currentFrameTextOverlays()
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
        WorkerConfiguration.saveFrameTextOverlays(frameTextOverlays)
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
        frameTextOverlays = WorkerConfiguration.defaultFrameTextOverlays
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

    private static func defaultHealthCheck(url: URL) async throws -> Bool {
        var request = URLRequest(url: url.appendingPathComponent("health"))
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        let (_, response) = try await URLSession.shared.data(for: request)
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
