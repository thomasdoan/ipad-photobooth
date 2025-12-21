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
    
    /// Current Pi base URL
    var baseURLString: String = ""
    
    /// Whether testing connection
    var isTestingConnection: Bool = false
    
    /// Connection test result
    var connectionTestResult: ConnectionTestResult?
    
    /// Validation error
    var urlError: String?
    
    // MARK: - Initialization
    
    init() {
        loadCurrentSettings()
    }
    
    // MARK: - Settings
    
    /// Loads current settings
    private func loadCurrentSettings() {
        if let urlString = UserDefaults.standard.string(forKey: "piBaseURL") {
            baseURLString = urlString
        } else {
            baseURLString = APIClient.defaultBaseURL.absoluteString
        }
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
    
    /// Saves the base URL
    func saveBaseURL() -> Bool {
        guard isURLValid else {
            urlError = "Please enter a valid URL (e.g., http://booth.local/api)"
            return false
        }
        
        urlError = nil
        UserDefaults.standard.set(baseURLString, forKey: "piBaseURL")
        return true
    }
    
    /// Resets to default URL
    func resetToDefault() {
        baseURLString = APIClient.defaultBaseURL.absoluteString
        _ = saveBaseURL()
        connectionTestResult = nil
    }
    
    /// Tests connection to the Pi
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
        
        let testClient = APIClient(baseURL: url, timeoutInterval: 10, maxRetries: 1)
        
        do {
            // Try to fetch events as a connection test
            let data = try await testClient.fetchData(Endpoints.events)
            // Try to decode to verify the response is valid JSON
            let decoder = JSONDecoder()
            let _ = try decoder.decode([Event].self, from: data)
            connectionTestResult = .success
        } catch let error as APIError {
            connectionTestResult = .failure(error.userMessage)
        } catch {
            connectionTestResult = .failure("Connection failed: \(error.localizedDescription)")
        }
        
        isTestingConnection = false
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

