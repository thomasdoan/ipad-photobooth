//
//  AppState.swift
//  fotoX
//
//  Central app state management
//

import Foundation
import SwiftUI
import Observation
import Sentry

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

    /// Selected frame ID for current session
    var selectedFrameId: String?

    // MARK: - Upload Progress
    
    /// Total assets to upload
    var totalAssetsToUpload: Int = 0
    
    /// Number of assets uploaded
    var assetsUploaded: Int = 0
    
    /// Current upload error (if any)
    var uploadError: APIError?

    /// Composite photo data for the session
    var compositePhotoData: Data?

    /// Composite video URL for the session
    var compositeVideoURL: URL?
    
    // MARK: - QR & Email
    
    /// Email submission status
    var emailSubmitted: Bool = false
    
    // MARK: - UI State
    /// Whether an API operation is in progress
    var isLoading: Bool = false
    /// Current error to display
    var currentError: APIError?
    /// Whether to show the settings sheet
    var showSettings: Bool = false
    /// Whether to show the gallery sheet
    var showGallery: Bool = false

    /// Current layout orientation (updated from root view)
    var layoutOrientation: LayoutOrientation = .portrait
    // MARK: - Volume Button
    /// Trigger for volume button press events (changes UUID to signal a press)
    var volumeButtonTrigger: UUID?
    /// Triggers a volume button action for the current route
    func triggerVolumeButtonAction() {
        volumeButtonTrigger = UUID()
    }
    
    // MARK: - Configuration
    
    /// Base URL for Worker (persisted)
    var workerBaseURL: URL {
        get { WorkerConfiguration.currentBaseURL() }
        set { WorkerConfiguration.saveBaseURL(newValue) }
    }

    /// Capture aspect ratio setting (persisted)
    var captureAspectRatioSetting: CaptureAspectRatio = WorkerConfiguration.currentCaptureAspectRatio() {
        didSet {
            WorkerConfiguration.saveCaptureAspectRatio(captureAspectRatioSetting)
        }
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

    /// Resolved aspect ratio for the current layout orientation
    var resolvedCaptureAspectRatio: CaptureAspectRatio {
        captureAspectRatioSetting.resolved(for: layoutOrientation)
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
        emailSubmitted = false
        currentRoute = .capture(.capturingStrip(index: 0))

        let breadcrumb = Breadcrumb(level: .info, category: "session")
        breadcrumb.message = "Session started"
        breadcrumb.data = [
            "session_id": session.sessionId,
            "event_id": selectedEvent?.id ?? 0
        ]
        SentrySDK.addBreadcrumb(breadcrumb)
    }
    
    /// Adds a captured strip
    func addCapturedStrip(_ strip: CapturedStrip) {
        capturedStrips.append(strip)
    }
    
    /// Transitions to upload phase
    func beginUpload() {
        // Calculate total assets based on upload mode
        let uploadMode = WorkerConfiguration.currentUploadMode()
        switch uploadMode {
        case .all:
            // Individual photos/videos (2 per strip) + composite photo/video if they exist
            var count = capturedStrips.count * 2
            if compositePhotoData != nil { count += 1 }
            if compositeVideoURL != nil { count += 1 }
            totalAssetsToUpload = count
        case .compositeOnly:
            // Just composite photo + composite video if they exist
            var count = 0
            if compositePhotoData != nil { count += 1 }
            if compositeVideoURL != nil { count += 1 }
            totalAssetsToUpload = count
        }
        assetsUploaded = 0
        uploadError = nil
        emailSubmitted = false
        currentRoute = .qrDisplay
    }
    
    /// Updates upload progress
    func assetUploaded() {
        assetsUploaded += 1
    }
    
    /// Upload failed
    func uploadFailed(error: APIError) {
        uploadError = error
    }
    
    /// Resets session and returns to idle
    func resetSession() {
        currentSession = nil
        capturedStrips = []
        selectedFrameId = nil
        totalAssetsToUpload = 0
        assetsUploaded = 0
        uploadError = nil
        compositePhotoData = nil
        compositeVideoURL = nil
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

    /// Updates layout orientation from the current view size.
    func updateLayoutOrientation(for size: CGSize) {
        let nextOrientation: LayoutOrientation = size.width > size.height ? .landscape : .portrait
        if layoutOrientation != nextOrientation {
            layoutOrientation = nextOrientation
        }
    }
}
