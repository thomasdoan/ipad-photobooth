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

    /// Whether testing connection
    var isTestingConnection: Bool = false

    /// Connection test result
    var connectionTestResult: ConnectionTestResult?

    /// URL validation error
    var urlError: String?

    /// Token validation error
    var tokenError: String?

    /// Whether settings were saved successfully
    var showSaveConfirmation: Bool = false

    // MARK: - Diagnostics

    /// Last connection test info
    var lastConnectionTest: (date: Date, success: Bool)?

    /// Last upload info
    var lastUpload: (date: Date, success: Bool, sessionId: String?)?

    /// Upload statistics
    var uploadStats: (total: Int, failed: Int) = (0, 0)

    /// Last error info
    var lastError: (error: String, date: Date)?

    // MARK: - Initialization

    private let healthCheck: @Sendable (URL) async throws -> Bool

    init() {
        self.healthCheck = SettingsViewModel.defaultHealthCheck
        loadCurrentSettings()
        loadDiagnostics()
    }

    init(healthCheck: @escaping @Sendable (URL) async throws -> Bool) {
        self.healthCheck = healthCheck
        loadCurrentSettings()
        loadDiagnostics()
    }

    // MARK: - Settings

    /// Loads current settings
    private func loadCurrentSettings() {
        baseURLString = WorkerConfiguration.currentBaseURL().absoluteString
        presignToken = WorkerConfiguration.currentPresignToken() ?? ""
        videoDuration = WorkerConfiguration.currentVideoDuration()
    }

    /// Loads diagnostic information
    func loadDiagnostics() {
        lastConnectionTest = DiagnosticsManager.lastConnectionTest()
        lastUpload = DiagnosticsManager.lastUpload()
        uploadStats = DiagnosticsManager.uploadStats()
        lastError = DiagnosticsManager.lastError()
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

    /// Validates the presign token
    var isTokenValid: Bool {
        !presignToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns masked token for display
    var maskedToken: String {
        let trimmed = presignToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 4 else {
            return trimmed.isEmpty ? "" : String(repeating: "•", count: trimmed.count)
        }
        let suffix = String(trimmed.suffix(4))
        return String(repeating: "•", count: min(8, trimmed.count - 4)) + suffix
    }

    /// Saves all settings
    func saveSettings() -> Bool {
        var hasErrors = false

        // Validate URL
        if !isURLValid {
            urlError = "Please enter a valid URL (e.g., https://your-worker.workers.dev)"
            hasErrors = true
        } else {
            urlError = nil
        }

        // Validate token
        if !isTokenValid {
            tokenError = "Presign token is required for uploads"
            hasErrors = true
        } else {
            tokenError = nil
        }

        if hasErrors {
            return false
        }

        if let url = URL(string: baseURLString) {
            WorkerConfiguration.saveBaseURL(url)
        }
        WorkerConfiguration.savePresignToken(presignToken)
        WorkerConfiguration.saveVideoDuration(videoDuration)

        showSaveConfirmation = true
        return true
    }

    /// Resets to default URL and video duration
    func resetToDefault() {
        baseURLString = WorkerConfiguration.defaultBaseURL.absoluteString
        videoDuration = WorkerConfiguration.defaultVideoDuration
        // Note: Does not reset presign token as it's user-specific
        connectionTestResult = nil
        urlError = nil
    }

    /// Clears diagnostics data
    func clearDiagnostics() {
        DiagnosticsManager.resetAll()
        loadDiagnostics()
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
            DiagnosticsManager.recordConnectionTest(success: false, error: "Invalid URL")
            isTestingConnection = false
            loadDiagnostics()
            return
        }

        do {
            let isHealthy = try await healthCheck(url)
            if isHealthy {
                connectionTestResult = .success
                DiagnosticsManager.recordConnectionTest(success: true)
            } else {
                connectionTestResult = .failure("Worker returned unhealthy status")
                DiagnosticsManager.recordConnectionTest(success: false, error: "Worker returned unhealthy status")
            }
        } catch let error as URLError {
            let message = friendlyErrorMessage(for: error)
            connectionTestResult = .failure(message)
            DiagnosticsManager.recordConnectionTest(success: false, error: message)
        } catch {
            let message = "Connection failed: \(error.localizedDescription)"
            connectionTestResult = .failure(message)
            DiagnosticsManager.recordConnectionTest(success: false, error: message)
        }

        loadDiagnostics()
        isTestingConnection = false
    }

    /// Converts URLError to user-friendly message
    private func friendlyErrorMessage(for error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet:
            return "No internet connection"
        case .timedOut:
            return "Connection timed out (server may be unreachable)"
        case .cannotFindHost:
            return "Cannot find host (check URL)"
        case .cannotConnectToHost:
            return "Cannot connect to host (server may be down)"
        case .networkConnectionLost:
            return "Network connection lost"
        case .dnsLookupFailed:
            return "DNS lookup failed (check URL)"
        case .secureConnectionFailed:
            return "Secure connection failed (SSL/TLS error)"
        case .serverCertificateUntrusted:
            return "Server certificate untrusted"
        default:
            return "Connection failed: \(error.localizedDescription)"
        }
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
