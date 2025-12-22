//
//  AppState.swift
//  fotoX
//
//  Central app state management
//

import Foundation
import SwiftUI
import Observation

/// Central observable state for the app
@Observable
final class AppState {
    // MARK: - Navigation
    
    /// Current route/screen
    var currentRoute: AppRoute = .eventSelection
    
    // MARK: - Event & Theme
    
    /// Currently selected event
    var selectedEvent: Event?
    
    /// Resolved theme from selected event
    var currentTheme: AppTheme = .default
    
    /// Cached theme assets (images)
    var themeAssets: ThemeAssets?
    
    // MARK: - Session
    
    /// Current capture session (created when user taps "Start")
    var currentSession: Session?
    
    /// Captured strips for current session
    var capturedStrips: [CapturedStrip] = []
    
    // MARK: - Upload Progress
    
    /// Total assets to upload
    var totalAssetsToUpload: Int = 0
    
    /// Number of assets uploaded
    var assetsUploaded: Int = 0
    
    /// Current upload error (if any)
    var uploadError: APIError?
    
    // MARK: - QR & Email
    
    /// QR code image data
    var qrCodeData: Data?
    
    /// Email submission status
    var emailSubmitted: Bool = false
    
    // MARK: - UI State
    
    /// Whether an API operation is in progress
    var isLoading: Bool = false
    
    /// Current error to display
    var currentError: APIError?
    
    /// Whether to show the settings sheet
    var showSettings: Bool = false
    
    // MARK: - Configuration
    
    /// Base URL for Worker (persisted)
    var workerBaseURL: URL {
        get { WorkerConfiguration.currentBaseURL() }
        set { WorkerConfiguration.saveBaseURL(newValue) }
    }
    
    // MARK: - Computed Properties
    
    /// Upload progress (0.0 - 1.0)
    var uploadProgress: Double {
        guard totalAssetsToUpload > 0 else { return 0 }
        return Double(assetsUploaded) / Double(totalAssetsToUpload)
    }
    
    /// Number of strips captured
    var stripsCompleted: Int {
        capturedStrips.count
    }
    
    /// Whether all strips have been captured
    var allStripsCaptured: Bool {
        capturedStrips.count >= 3
    }
    
    // MARK: - Actions
    
    /// Selects an event and applies its theme
    func selectEvent(_ event: Event) {
        selectedEvent = event
        currentTheme = AppTheme(from: event.theme)
        currentRoute = .idle
    }
    
    /// Starts a new capture session
    func startSession(with session: Session) {
        currentSession = session
        capturedStrips = []
        currentRoute = .capture(.capturingStrip(index: 0))
    }
    
    /// Adds a captured strip
    func addCapturedStrip(_ strip: CapturedStrip) {
        capturedStrips.append(strip)
        
        if capturedStrips.count < 3 {
            currentRoute = .capture(.reviewingStrip(index: strip.stripIndex))
        } else {
            currentRoute = .capture(.summary)
        }
    }
    
    /// Proceeds to next strip after review
    func proceedToNextStrip() {
        let nextIndex = capturedStrips.count
        if nextIndex < 3 {
            currentRoute = .capture(.capturingStrip(index: nextIndex))
        } else {
            currentRoute = .uploading
        }
    }
    
    /// Retakes the current strip
    func retakeStrip(at index: Int) {
        // Remove the strip if it exists
        capturedStrips.removeAll { $0.stripIndex == index }
        currentRoute = .capture(.capturingStrip(index: index))
    }
    
    /// Transitions to upload phase
    func beginUpload() {
        totalAssetsToUpload = capturedStrips.count * 2 // video + photo per strip
        assetsUploaded = 0
        uploadError = nil
        currentRoute = .uploading
    }
    
    /// Updates upload progress
    func assetUploaded() {
        assetsUploaded += 1
    }
    
    /// Upload completed, transition to QR
    func uploadCompleted(qrData: Data) {
        qrCodeData = qrData
        emailSubmitted = false
        currentRoute = .qrDisplay
    }
    
    /// Upload failed
    func uploadFailed(error: APIError) {
        uploadError = error
    }
    
    /// Resets session and returns to idle
    func resetSession() {
        currentSession = nil
        capturedStrips = []
        totalAssetsToUpload = 0
        assetsUploaded = 0
        uploadError = nil
        qrCodeData = nil
        emailSubmitted = false
        currentRoute = .idle
    }
    
    /// Returns to event selection
    func returnToEventSelection() {
        resetSession()
        selectedEvent = nil
        currentTheme = .default
        themeAssets = nil
        currentRoute = .eventSelection
    }
    
    /// Clears the current error
    func clearError() {
        currentError = nil
    }
}
