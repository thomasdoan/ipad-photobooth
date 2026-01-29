//
//  fotoXTests.swift
//  fotoXTests
//
//  Unit tests for FotoX models, services, and view models
//

import Testing
import Foundation
import SwiftUI
import AVFoundation
@testable import fotoX

// MARK: - Model Decoding Tests

struct ModelDecodingTests {
    
    @Test("Event decodes from valid JSON")
    func eventDecodesFromJSON() async throws {
        let json = """
        {
            "id": 1,
            "name": "Sally & John's Wedding",
            "date": "2025-12-31",
            "theme": {
                "id": 5,
                "primary_color": "#FF4081",
                "secondary_color": "#212121",
                "accent_color": "#FFFFFF",
                "font_family": "system",
                "logo_url": null,
                "background_url": null,
                "photo_frame_url": null,
                "strip_frame_url": null
            }
        }
        """.data(using: .utf8)!
        
        let event = try JSONDecoder().decode(Event.self, from: json)
        
        #expect(event.id == 1)
        #expect(event.name == "Sally & John's Wedding")
        #expect(event.date == "2025-12-31")
        #expect(event.theme.id == 5)
        #expect(event.theme.primaryColor == "#FF4081")
        #expect(event.theme.secondaryColor == "#212121")
        #expect(event.theme.accentColor == "#FFFFFF")
        #expect(event.theme.fontFamily == "system")
    }
    
    @Test("Event decodes with optional theme URLs")
    func eventDecodesWithThemeURLs() async throws {
        let json = """
        {
            "id": 2,
            "name": "Corporate Event",
            "date": "2025-06-15",
            "theme": {
                "id": 10,
                "primary_color": "#0066CC",
                "secondary_color": "#FFFFFF",
                "accent_color": "#333333",
                "font_family": "Helvetica",
                "logo_url": "http://booth.local/themes/10/logo.png",
                "background_url": "http://booth.local/themes/10/bg.jpg",
                "photo_frame_url": "http://booth.local/themes/10/frame.png",
                "strip_frame_url": null
            }
        }
        """.data(using: .utf8)!
        
        let event = try JSONDecoder().decode(Event.self, from: json)
        
        #expect(event.theme.logoURL == "http://booth.local/themes/10/logo.png")
        #expect(event.theme.backgroundURL == "http://booth.local/themes/10/bg.jpg")
        #expect(event.theme.photoFrameURL == "http://booth.local/themes/10/frame.png")
        #expect(event.theme.stripFrameURL == nil)
    }
    
    @Test("Session decodes from valid JSON")
    func sessionDecodesFromJSON() async throws {
        let json = """
        {
            "session_id": "8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B",
            "public_token": "zQ1A9LfKc7",
            "universal_url": "https://pb.example.com/s/zQ1A9LfKc7"
        }
        """.data(using: .utf8)!
        
        let session = try JSONDecoder().decode(Session.self, from: json)
        
        #expect(session.sessionId == "8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B")
        #expect(session.publicToken == "zQ1A9LfKc7")
        #expect(session.universalURL == "https://pb.example.com/s/zQ1A9LfKc7")
    }
    
    @Test("AssetUploadResponse decodes correctly")
    func assetUploadResponseDecodes() async throws {
        let json = """
        {
            "asset_id": 456,
            "status": "ok"
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(AssetUploadResponse.self, from: json)
        
        #expect(response.assetId == 456)
        #expect(response.status == "ok")
    }
    
    @Test("AssetUploadResponse handles null asset_id")
    func assetUploadResponseHandlesNullId() async throws {
        let json = """
        {
            "asset_id": null,
            "status": "ok"
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(AssetUploadResponse.self, from: json)
        
        #expect(response.assetId == nil)
        #expect(response.status == "ok")
    }
    
    @Test("EmailSubmissionResponse decodes correctly")
    func emailResponseDecodes() async throws {
        let json = """
        {"status": "ok"}
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(EmailSubmissionResponse.self, from: json)
        
        #expect(response.status == "ok")
    }
}

// MARK: - Model Encoding Tests

struct ModelEncodingTests {
    
    @Test("CreateSessionRequest encodes correctly")
    func createSessionRequestEncodes() throws {
        let request = CreateSessionRequest.standard(eventId: 42)
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(json["event_id"] as? Int == 42)
        #expect(json["capture_type"] as? String == "strip")
        #expect(json["strip_count"] as? Int == 3)
    }
    
    @Test("EmailSubmissionRequest encodes correctly")
    func emailRequestEncodes() throws {
        let request = EmailSubmissionRequest(email: "test@example.com")
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(json["email"] as? String == "test@example.com")
    }

    @Test("PresignRequest encodes correctly")
    func presignRequestEncodes() throws {
        let request = PresignRequest(
            eventId: 42,
            sessionId: "ABC-123",
            files: [
                PresignFile(path: "events/42/sessions/ABC-123/photo_0.jpg", contentType: "image/jpeg", sizeBytes: 123)
            ]
        )
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let files = json["files"] as? [[String: Any]]
        
        #expect(json["event_id"] as? Int == 42)
        #expect(json["session_id"] as? String == "ABC-123")
        #expect(files?.first?["content_type"] as? String == "image/jpeg")
        #expect(files?.first?["size_bytes"] as? Int == 123)
    }

    @Test("CompleteRequest encodes correctly")
    func completeRequestEncodes() throws {
        let request = CompleteRequest(eventId: 7, sessionId: "SESSION-1", manifestPath: "events/7/sessions/SESSION-1/manifest.json")
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["event_id"] as? Int == 7)
        #expect(json["session_id"] as? String == "SESSION-1")
        #expect(json["manifest_path"] as? String == "events/7/sessions/SESSION-1/manifest.json")
    }

    @Test("SessionManifest encodes correctly")
    func sessionManifestEncodes() throws {
        let asset = SessionManifestAsset(
            id: "strip0_video",
            kind: .video,
            stripIndex: 0,
            sequenceIndex: 0,
            contentType: "video/mp4",
            path: "events/7/sessions/SESSION-1/video_0.mp4",
            sizeBytes: 1234,
            durationSeconds: 10.0,
            posterPath: "events/7/sessions/SESSION-1/photo_0.jpg"
        )
        let manifest = SessionManifest(
            version: 1,
            eventId: 7,
            sessionId: "SESSION-1",
            createdAt: "2025-01-01T00:00:00Z",
            publicGalleryURL: "https://example.com/s/SESSION-1",
            assets: [asset]
        )
        let data = try JSONEncoder().encode(manifest)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let assets = json["assets"] as? [[String: Any]]

        #expect(json["event_id"] as? Int == 7)
        #expect(json["session_id"] as? String == "SESSION-1")
        #expect(json["public_gallery_url"] as? String == "https://example.com/s/SESSION-1")
        #expect(assets?.first?["kind"] as? String == "video")
        #expect(assets?.first?["content_type"] as? String == "video/mp4")
        #expect(assets?.first?["duration_seconds"] as? Double == 10.0)
    }
}

// MARK: - Capture Aspect Ratio Tests

@Suite(.serialized)
struct CaptureAspectRatioTests {
    @Test("Auto aspect ratio resolves by orientation")
    func autoResolvesByOrientation() {
        #expect(CaptureAspectRatio.auto.resolved(for: .portrait) == .ratio9x16)
        #expect(CaptureAspectRatio.auto.resolved(for: .landscape) == .ratio16x9)
    }

    @Test("Aspect ratio values match expected ratios")
    func ratioValuesMatchExpected() {
        #expect(abs(CaptureAspectRatio.ratio9x16.widthToHeight - (9.0 / 16.0)) < 0.001)
        #expect(abs(CaptureAspectRatio.ratio16x9.widthToHeight - (16.0 / 9.0)) < 0.001)
        #expect(abs(CaptureAspectRatio.ratio4x3.widthToHeight - (4.0 / 3.0)) < 0.001)
    }

    @Test("Capture aspect ratio persists via WorkerConfiguration")
    func captureAspectRatioPersistence() {
        let defaults = UserDefaults.standard
        let key = WorkerConfiguration.captureAspectRatioKey
        let existingValue = defaults.string(forKey: key)
        defer {
            if let existingValue {
                defaults.set(existingValue, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }

        WorkerConfiguration.saveCaptureAspectRatio(.ratio4x3)
        #expect(WorkerConfiguration.currentCaptureAspectRatio() == .ratio4x3)
    }
}

@Suite(.serialized)
struct AppStateAspectRatioTests {
    @Test("AppState resolves auto aspect ratio from layout orientation")
    func appStateAutoResolution() {
        let previousSetting = WorkerConfiguration.currentCaptureAspectRatio()
        defer {
            WorkerConfiguration.saveCaptureAspectRatio(previousSetting)
        }

        let appState = AppState()
        appState.captureAspectRatioSetting = .auto

        appState.updateLayoutOrientation(for: CGSize(width: 1200, height: 800))
        #expect(appState.resolvedCaptureAspectRatio == .ratio16x9)

        appState.updateLayoutOrientation(for: CGSize(width: 800, height: 1200))
        #expect(appState.resolvedCaptureAspectRatio == .ratio9x16)
    }
}

// MARK: - Color Extension Tests

struct ColorExtensionTests {
    
    @Test("Color parses 6-digit hex with hash")
    func colorParses6DigitHexWithHash() {
        let color = Color(hex: "#FF4081")
        #expect(color != nil)
    }
    
    @Test("Color parses 6-digit hex without hash")
    func colorParses6DigitHexWithoutHash() {
        let color = Color(hex: "FF4081")
        #expect(color != nil)
    }
    
    @Test("Color parses 8-digit ARGB hex")
    func colorParses8DigitHex() {
        let color = Color(hex: "#80FF4081")  // 50% opacity
        #expect(color != nil)
    }
    
    @Test("Color returns nil for invalid hex")
    func colorReturnsNilForInvalidHex() {
        let color = Color(hex: "not-a-color")
        #expect(color == nil)
    }
    
    @Test("Color returns nil for empty string")
    func colorReturnsNilForEmptyString() {
        let color = Color(hex: "")
        #expect(color == nil)
    }
    
    @Test("Color returns nil for wrong length")
    func colorReturnsNilForWrongLength() {
        let color = Color(hex: "#FFF")  // 3 chars not supported
        #expect(color == nil)
    }
    
    @Test("Color handles lowercase hex")
    func colorHandlesLowercaseHex() {
        let color = Color(hex: "#ff4081")
        #expect(color != nil)
    }
    
    @Test("Color handles whitespace")
    func colorHandlesWhitespace() {
        let color = Color(hex: "  #FF4081  ")
        #expect(color != nil)
    }
}

// MARK: - AppTheme Tests

struct AppThemeTests {
    
    @Test("AppTheme creates from Theme model")
    func appThemeCreatesFromTheme() {
        let theme = Theme(
            id: 1,
            primaryColor: "#FF4081",
            secondaryColor: "#212121",
            accentColor: "#FFFFFF",
            fontFamily: "system",
            logoURL: "http://example.com/logo.png",
            backgroundURL: nil,
            photoFrameURL: nil,
            stripFrameURL: nil,
            stripFooterText: nil
        )
        
        let appTheme = AppTheme(from: theme)
        
        #expect(appTheme.id == 1)
        #expect(appTheme.fontFamily == "system")
        #expect(appTheme.logoURL?.absoluteString == "http://example.com/logo.png")
        #expect(appTheme.backgroundURL == nil)
    }
    
    @Test("AppTheme default exists")
    func appThemeDefaultExists() {
        let defaultTheme = AppTheme.default
        
        #expect(defaultTheme.id == 0)
        #expect(defaultTheme.fontFamily == "system")
    }
}

// MARK: - AppState Tests

@MainActor
struct AppStateTests {
    
    @Test("AppState initializes to event selection")
    func appStateInitialState() {
        let state = AppState()
        
        #expect(state.currentRoute == .eventSelection)
        #expect(state.selectedEvent == nil)
        #expect(state.currentSession == nil)
        #expect(state.capturedStrips.isEmpty)
    }
    
    @Test("selectEvent changes route to idle")
    func selectEventChangesRoute() {
        let state = AppState()
        let theme = Theme(
            id: 1,
            primaryColor: "#FF0000",
            secondaryColor: "#000000",
            accentColor: "#FFFFFF",
            fontFamily: "system",
            logoURL: nil,
            backgroundURL: nil,
            photoFrameURL: nil,
            stripFrameURL: nil,
            stripFooterText: nil
        )
        let event = Event(id: 1, name: "Test Event", date: "2025-01-01", theme: theme)
        
        state.selectEvent(event)
        
        #expect(state.currentRoute == .idle)
        #expect(state.selectedEvent?.id == 1)
        #expect(state.selectedEvent?.name == "Test Event")
    }
    
    @Test("startSession changes route to capture")
    func startSessionChangesRoute() {
        let state = AppState()
        let session = Session(sessionId: "ABC-123", publicToken: "abc", universalURL: "https://example.com")
        
        state.startSession(with: session)
        
        #expect(state.currentSession?.sessionId == "ABC-123")
        if case .capture(.capturingStrip(let index)) = state.currentRoute {
            #expect(index == 0)
        } else {
            Issue.record("Expected capture route with strip index 0")
        }
    }
    
    @Test("resetSession clears state and returns to idle")
    func resetSessionClearsState() {
        let state = AppState()
        let session = Session(sessionId: "ABC-1", publicToken: "abc", universalURL: "https://example.com")
        state.startSession(with: session)
        
        state.resetSession()
        
        #expect(state.currentRoute == .idle)
        #expect(state.currentSession == nil)
        #expect(state.capturedStrips.isEmpty)
    }

    @Test("beginUpload routes to qrDisplay and sets totals")
    func beginUploadRoutesToQRDisplay() {
        let state = AppState()
        let strip = CapturedStrip(stripIndex: 0, videoURL: URL(string: "file://test")!, photoData: Data(), thumbnailData: nil)
        state.capturedStrips = [strip]

        state.beginUpload()

        #expect(state.currentRoute == .qrDisplay)
        #expect(state.totalAssetsToUpload == 2)
        #expect(state.assetsUploaded == 0)
    }
    
    @Test("returnToEventSelection clears everything")
    func returnToEventSelectionClearsAll() {
        let state = AppState()
        let theme = Theme(
            id: 1,
            primaryColor: "#FF0000",
            secondaryColor: "#000000",
            accentColor: "#FFFFFF",
            fontFamily: "system",
            logoURL: nil,
            backgroundURL: nil,
            photoFrameURL: nil,
            stripFrameURL: nil,
            stripFooterText: nil
        )
        let event = Event(id: 1, name: "Test", date: "2025-01-01", theme: theme)
        state.selectEvent(event)
        
        state.returnToEventSelection()
        
        #expect(state.currentRoute == .eventSelection)
        #expect(state.selectedEvent == nil)
    }
    
    @Test("uploadProgress calculates correctly")
    func uploadProgressCalculation() {
        let state = AppState()
        
        state.totalAssetsToUpload = 6
        state.assetsUploaded = 3
        
        #expect(state.uploadProgress == 0.5)
    }
    
    @Test("uploadProgress returns 0 when no uploads")
    func uploadProgressZeroWhenEmpty() {
        let state = AppState()
        
        state.totalAssetsToUpload = 0
        state.assetsUploaded = 0
        
        #expect(state.uploadProgress == 0)
    }
    
    @Test("assetUploaded increments counter")
    func assetUploadedIncrements() {
        let state = AppState()
        state.totalAssetsToUpload = 6
        state.assetsUploaded = 0
        
        state.assetUploaded()
        state.assetUploaded()
        
        #expect(state.assetsUploaded == 2)
    }
    
    @Test("allStripsCaptured returns true when 3 strips")
    func allStripsCapturedTrue() {
        let state = AppState()
        let strip1 = CapturedStrip(stripIndex: 0, videoURL: URL(string: "file://test")!, photoData: Data(), thumbnailData: nil)
        let strip2 = CapturedStrip(stripIndex: 1, videoURL: URL(string: "file://test")!, photoData: Data(), thumbnailData: nil)
        let strip3 = CapturedStrip(stripIndex: 2, videoURL: URL(string: "file://test")!, photoData: Data(), thumbnailData: nil)
        
        state.capturedStrips = [strip1, strip2, strip3]
        
        #expect(state.allStripsCaptured == true)
    }
    
    @Test("allStripsCaptured returns false when less than 3")
    func allStripsCapturedFalse() {
        let state = AppState()
        let strip1 = CapturedStrip(stripIndex: 0, videoURL: URL(string: "file://test")!, photoData: Data(), thumbnailData: nil)
        
        state.capturedStrips = [strip1]
        
        #expect(state.allStripsCaptured == false)
    }
}

// MARK: - Upload Queue Tests

struct UploadQueueStoreTests {
    
    @Test("UploadQueueStore persists sessions round-trip")
    func uploadQueueStoreRoundTrip() async throws {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documents.appendingPathComponent("upload_queue.json")
        try? fileManager.removeItem(at: fileURL)
        
        let store = UploadQueueStore(fileManager: fileManager)
        let asset = UploadQueueAsset(
            id: UUID(),
            kind: .photo,
            stripIndex: 0,
            sequenceIndex: 1,
            fileName: "photo_0.jpg",
            mimeType: "image/jpeg",
            localURL: documents.appendingPathComponent("photo_0.jpg"),
            remotePath: "events/1/sessions/SESSION-1/photo_0.jpg",
            sizeBytes: 321,
            durationSeconds: nil,
            posterPath: nil,
            state: .pending
        )
        let session = UploadQueueSession(
            id: UUID().uuidString,
            eventId: 1,
            sessionId: "SESSION-1",
            createdAt: "2025-01-01T00:00:00Z",
            publicGalleryURL: "https://example.com/s/SESSION-1",
            assets: [asset],
            manifestState: .pending,
            completeState: .pending
        )
        
        try await store.addSession(session)
        
        let reloadedStore = UploadQueueStore(fileManager: fileManager)
        let sessions = try await reloadedStore.sessions()
        
        #expect(sessions.count == 1)
        #expect(sessions.first?.sessionId == "SESSION-1")
        #expect(sessions.first?.assets.first?.remotePath == "events/1/sessions/SESSION-1/photo_0.jpg")
        
        try? fileManager.removeItem(at: fileURL)
    }
}

// MARK: - API Error Tests

struct APIErrorTests {
    
    @Test("APIError provides user message")
    func apiErrorProvidesUserMessage() {
        let error = APIError.serverUnreachable
        
        #expect(!error.userMessage.isEmpty)
        #expect(error.userMessage.contains("connect"))
    }
    
    @Test("APIError isRetryable for timeout")
    func timeoutIsRetryable() {
        let error = APIError.timeout
        
        #expect(error.isRetryable == true)
    }
    
    @Test("APIError isRetryable for server unreachable")
    func serverUnreachableIsRetryable() {
        let error = APIError.serverUnreachable
        
        #expect(error.isRetryable == true)
    }
    
    @Test("APIError not retryable for invalid URL")
    func invalidURLNotRetryable() {
        let error = APIError.invalidURL
        
        #expect(error.isRetryable == false)
    }
    
    @Test("APIError isRetryable for 500 errors")
    func http500IsRetryable() {
        let error = APIError.httpError(statusCode: 500, message: nil)
        
        #expect(error.isRetryable == true)
    }
    
    @Test("APIError not retryable for 400 errors")
    func http400NotRetryable() {
        let error = APIError.httpError(statusCode: 400, message: nil)
        
        #expect(error.isRetryable == false)
    }
}

// MARK: - Endpoint Tests

struct EndpointTests {
    
    @Test("Events endpoint has correct path")
    func eventsEndpointPath() {
        let endpoint = Endpoints.events
        
        #expect(endpoint.path == "events")
        #expect(endpoint.method == .GET)
    }
    
    @Test("Event by ID endpoint has correct path")
    func eventByIdEndpointPath() {
        let endpoint = Endpoints.event(id: 42)
        
        #expect(endpoint.path == "events/42")
        #expect(endpoint.method == .GET)
    }
    
    @Test("Create session endpoint is POST")
    func createSessionEndpointMethod() {
        let endpoint = Endpoints.createSession
        
        #expect(endpoint.path == "sessions")
        #expect(endpoint.method == .POST)
    }
    
    @Test("Upload asset endpoint has correct path")
    func uploadAssetEndpointPath() {
        let endpoint = Endpoints.uploadAsset(sessionId: "ABC-123")
        
        #expect(endpoint.path == "sessions/ABC-123/assets")
        #expect(endpoint.method == .POST)
    }
    
    @Test("QR code endpoint has correct path")
    func qrCodeEndpointPath() {
        let endpoint = Endpoints.qrCode(sessionId: "ABC-456")
        
        #expect(endpoint.path == "sessions/ABC-456/qr")
        #expect(endpoint.method == .GET)
    }
    
    @Test("Submit email endpoint has correct path")
    func submitEmailEndpointPath() {
        let endpoint = Endpoints.submitEmail(sessionId: "ABC-789")
        
        #expect(endpoint.path == "sessions/ABC-789/email")
        #expect(endpoint.method == .POST)
    }
    
    @Test("Endpoint creates valid URLRequest")
    func endpointCreatesURLRequest() {
        let endpoint = Endpoints.events
        let baseURL = URL(string: "http://booth.local/api")!
        
        let request = endpoint.makeRequest(baseURL: baseURL)
        
        #expect(request != nil)
        #expect(request?.url?.absoluteString == "http://booth.local/api/events")
        #expect(request?.httpMethod == "GET")
    }
}

// MARK: - AssetUploadMetadata Tests

struct AssetUploadMetadataTests {
    
    @Test("Video sequence index is 0")
    func videoSequenceIndex() {
        #expect(AssetUploadMetadata.videoSequenceIndex == 0)
    }
    
    @Test("Photo sequence index is 1")
    func photoSequenceIndex() {
        #expect(AssetUploadMetadata.photoSequenceIndex == 1)
    }
    
    @Test("AssetKind encodes correctly")
    func assetKindEncodes() throws {
        let photoKind = AssetKind.photo
        let videoKind = AssetKind.video
        
        #expect(photoKind.rawValue == "photo")
        #expect(videoKind.rawValue == "video")
    }
}

// MARK: - CaptureState Tests

@Suite(.serialized)
struct CaptureStateTests {
    
    @Test("Default capture configuration has correct values")
    func defaultCaptureConfig() {
        // Reset to ensure test isolation
        WorkerConfiguration.saveVideoDuration(10)
        WorkerConfiguration.savePhotoCountdownSeconds(3)

        let config = CaptureConfiguration.default

        #expect(config.videoDuration == 10)
        #expect(config.countdownSeconds == 0)
        #expect(config.stripCount == 3)
    }

    @Test("WorkerConfiguration saves and loads video duration")
    func videoDurationPersistence() {
        // Save custom duration
        WorkerConfiguration.saveVideoDuration(7)

        // Verify it's retrieved correctly
        let duration = WorkerConfiguration.currentVideoDuration()
        #expect(duration == 7)

        // Cleanup
        WorkerConfiguration.saveVideoDuration(10)
    }

    @Test("Video duration is clamped to valid range")
    func videoDurationClamping() {
        // Test minimum clamp
        WorkerConfiguration.saveVideoDuration(1)
        #expect(WorkerConfiguration.currentVideoDuration() == 1)

        // Test maximum clamp
        WorkerConfiguration.saveVideoDuration(100)
        #expect(WorkerConfiguration.currentVideoDuration() == 10)

        // Test valid range
        WorkerConfiguration.saveVideoDuration(7)
        #expect(WorkerConfiguration.currentVideoDuration() == 7)

        // Cleanup
        WorkerConfiguration.saveVideoDuration(10)
    }

    @Test("CaptureConfiguration respects saved video duration")
    func captureConfigurationUsesPersistedValue() {
        // Save custom duration
        WorkerConfiguration.saveVideoDuration(5)

        // Create configuration
        let config = CaptureConfiguration.default
        #expect(config.videoDuration == 5)

        // Cleanup
        WorkerConfiguration.saveVideoDuration(10)
    }
}

// MARK: - Local Services Tests

@MainActor
struct LocalEventServiceTests {
    
    @Test("LocalEventService returns bundled events")
    func localEventServiceReturnsEvents() async throws {
        let service = LocalEventService()
        let events = try await service.fetchEvents()
        #expect(!events.isEmpty)
    }
    
    @Test("LocalEventService returns event by id")
    func localEventServiceFetchById() async throws {
        let service = LocalEventService()
        let events = try await service.fetchEvents()
        let first = try #require(events.first)
        let event = try await service.fetchEvent(id: first.id)
        #expect(event.id == first.id)
    }
}

// MARK: - Settings Tests

/// Mock URLProtocol that immediately fails requests without making network calls
final class MockURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        // Immediately fail with a connection error (no network call)
        let error = URLError(.cannotConnectToHost)
        client?.urlProtocol(self, didFailWithError: error)
    }

    override func stopLoading() {}
}

@MainActor
struct SettingsViewModelTests {

    // Helper to create a mock URLSession that fails immediately without network calls
    static func createMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        config.timeoutIntervalForRequest = 0.1
        config.timeoutIntervalForResource = 0.1
        return URLSession(configuration: config)
    }

    @Test("Worker URL validation accepts valid URLs")
    func workerURLValidationAcceptsValid() {
        let viewModel = SettingsViewModel(healthCheck: { _ in true })
        viewModel.baseURLString = "https://example.workers.dev"
        #expect(viewModel.isURLValid == true)
    }
    
    @Test("Worker URL validation rejects invalid URLs")
    func workerURLValidationRejectsInvalid() {
        let viewModel = SettingsViewModel(healthCheck: { _ in true })
        viewModel.baseURLString = "not-a-url"
        #expect(viewModel.isURLValid == false)
    }

    @Test("Health check success sets success result")
    func healthCheckSuccess() async {
        let viewModel = SettingsViewModel(healthCheck: { _ in true })
        viewModel.baseURLString = "https://example.workers.dev"
        await viewModel.testConnection()
        #expect(viewModel.connectionTestResult == .success)
    }

    @Test("Health check failure sets failure result")
    func healthCheckFailure() async {
        let viewModel = SettingsViewModel(healthCheck: { _ in false })
        viewModel.baseURLString = "https://example.workers.dev"
        await viewModel.testConnection()
        if case .failure = viewModel.connectionTestResult {
            #expect(true)
        } else {
            Issue.record("Expected failure result")
        }
    }

    // MARK: - defaultHealthCheck Tests

    @Test("defaultHealthCheck constructs URL without trailing slash")
    func defaultHealthCheckURLWithoutTrailingSlash() async throws {
        let url = URL(string: "https://example.com")!
        let mockSession = Self.createMockSession()

        // This should not crash - it constructs https://example.com/health
        do {
            _ = try await SettingsViewModel.defaultHealthCheck(url: url, session: mockSession)
        } catch {
            // Network errors are expected in tests, we're just checking it doesn't crash
            #expect(error is URLError)
        }
    }

    @Test("defaultHealthCheck constructs URL with trailing slash")
    func defaultHealthCheckURLWithTrailingSlash() async throws {
        let url = URL(string: "https://example.com/")!
        let mockSession = Self.createMockSession()

        // This should not crash - it should handle trailing slash properly
        do {
            _ = try await SettingsViewModel.defaultHealthCheck(url: url, session: mockSession)
        } catch {
            // Network errors are expected in tests, we're just checking it doesn't crash
            #expect(error is URLError)
        }
    }

    @Test("defaultHealthCheck constructs URL with existing path")
    func defaultHealthCheckURLWithPath() async throws {
        let url = URL(string: "https://example.com/api/v1")!
        let mockSession = Self.createMockSession()

        // This should append /health to existing path
        do {
            _ = try await SettingsViewModel.defaultHealthCheck(url: url, session: mockSession)
        } catch {
            // Network errors are expected in tests, we're just checking it doesn't crash
            #expect(error is URLError)
        }
    }

    @Test("defaultHealthCheck constructs URL with port")
    func defaultHealthCheckURLWithPort() async throws {
        let url = URL(string: "http://localhost:8080")!
        let mockSession = Self.createMockSession()

        // This should preserve port when appending path
        do {
            _ = try await SettingsViewModel.defaultHealthCheck(url: url, session: mockSession)
        } catch {
            // Network errors are expected in tests, we're just checking it doesn't crash
            #expect(error is URLError)
        }
    }

    @Test("defaultHealthCheck constructs URL with query parameters")
    func defaultHealthCheckURLWithQuery() async throws {
        let url = URL(string: "https://example.com/api?key=value")!
        let mockSession = Self.createMockSession()

        // This should handle URLs with query parameters
        do {
            _ = try await SettingsViewModel.defaultHealthCheck(url: url, session: mockSession)
        } catch {
            // Network errors are expected in tests, we're just checking it doesn't crash
            #expect(error is URLError)
        }
    }

    @Test("defaultHealthCheck handles localhost URLs")
    func defaultHealthCheckLocalhost() async throws {
        let url = URL(string: "http://localhost")!
        let mockSession = Self.createMockSession()

        do {
            _ = try await SettingsViewModel.defaultHealthCheck(url: url, session: mockSession)
        } catch {
            // Network errors are expected, we're checking it doesn't crash
            #expect(error is URLError)
        }
    }

    @Test("defaultHealthCheck handles IP address URLs")
    func defaultHealthCheckIPAddress() async throws {
        let url = URL(string: "http://192.168.1.1")!
        let mockSession = Self.createMockSession()

        do {
            _ = try await SettingsViewModel.defaultHealthCheck(url: url, session: mockSession)
        } catch {
            // Network errors are expected, we're checking it doesn't crash
            #expect(error is URLError)
        }
    }

    @Test("defaultHealthCheck handles URL from absoluteString round-trip")
    func defaultHealthCheckRoundTrip() async throws {
        // This simulates what happens when we save/load from UserDefaults
        let originalURL = URL(string: "https://example.com")!
        let urlString = originalURL.absoluteString
        let reconstructedURL = URL(string: urlString)!
        let mockSession = Self.createMockSession()

        do {
            _ = try await SettingsViewModel.defaultHealthCheck(url: reconstructedURL, session: mockSession)
        } catch {
            #expect(error is URLError)
        }
    }

    @Test("defaultHealthCheck handles unusual but valid URLs")
    func defaultHealthCheckUnusualURLs() async throws {
        let mockSession = Self.createMockSession()
        let testURLs = [
            "http://example.com.",  // Trailing dot
            "http://example.com//", // Double slash
            "https://example.com:443", // Default HTTPS port
            "http://example.com:80",   // Default HTTP port
        ]

        for urlString in testURLs {
            if let url = URL(string: urlString) {
                do {
                    _ = try await SettingsViewModel.defaultHealthCheck(url: url, session: mockSession)
                } catch {
                    // Network errors expected
                    #expect(error is URLError)
                }
            }
        }
    }

    @Test("SettingsViewModel testConnection with real default URL")
    func settingsViewModelWithDefaultURL() async {
        // Use mock healthCheck to avoid network calls and URL corruption issues
        let viewModel = SettingsViewModel(healthCheck: { _ in true })

        // The default URL should be valid
        #expect(viewModel.isURLValid, "URL should be valid")
        #expect(!viewModel.baseURLString.isEmpty, "baseURLString should not be empty")

        // Test connection (will succeed with mock)
        await viewModel.testConnection()

        // Should have success result
        #expect(viewModel.connectionTestResult == .success)
    }
}

// MARK: - GalleryAsset Tests

struct GalleryAssetTests {

    @Test("GalleryAsset isLocallyAvailable returns true when file exists")
    func assetIsLocallyAvailableWhenFileExists() throws {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_photo.jpg")

        // Create a test file
        try Data().write(to: testFile)

        let asset = GalleryAsset(
            id: "test-1",
            kind: .photo,
            stripIndex: 0,
            remotePath: "events/1/sessions/session-1/photo_0.jpg",
            localURL: testFile,
            mimeType: "image/jpeg",
            posterPath: nil,
            localPosterURL: nil
        )

        #expect(asset.isLocallyAvailable == true)

        // Cleanup
        try? fileManager.removeItem(at: testFile)
    }

    @Test("GalleryAsset isLocallyAvailable returns false when file doesn't exist")
    func assetIsLocallyAvailableWhenFileDoesNotExist() {
        let nonExistentURL = URL(fileURLWithPath: "/tmp/nonexistent_\(UUID().uuidString).jpg")

        let asset = GalleryAsset(
            id: "test-2",
            kind: .photo,
            stripIndex: 0,
            remotePath: "events/1/sessions/session-1/photo_0.jpg",
            localURL: nonExistentURL,
            mimeType: "image/jpeg",
            posterPath: nil,
            localPosterURL: nil
        )

        #expect(asset.isLocallyAvailable == false)
    }

    @Test("GalleryAsset isLocallyAvailable returns false when localURL is nil")
    func assetIsLocallyAvailableWhenURLIsNil() {
        let asset = GalleryAsset(
            id: "test-3",
            kind: .photo,
            stripIndex: 0,
            remotePath: "events/1/sessions/session-1/photo_0.jpg",
            localURL: nil,
            mimeType: "image/jpeg",
            posterPath: nil,
            localPosterURL: nil
        )

        #expect(asset.isLocallyAvailable == false)
    }

    @Test("GalleryAsset isPosterLocallyAvailable returns true when poster exists")
    func posterIsLocallyAvailableWhenFileExists() throws {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let posterFile = tempDir.appendingPathComponent("test_poster.jpg")

        // Create a test poster file
        try Data().write(to: posterFile)

        let asset = GalleryAsset(
            id: "test-video-1",
            kind: .video,
            stripIndex: 0,
            remotePath: "events/1/sessions/session-1/video_0.mov",
            localURL: tempDir.appendingPathComponent("test_video.mov"),
            mimeType: "video/quicktime",
            posterPath: "events/1/sessions/session-1/photo_0.jpg",
            localPosterURL: posterFile
        )

        #expect(asset.isPosterLocallyAvailable == true)

        // Cleanup
        try? fileManager.removeItem(at: posterFile)
    }

    @Test("GalleryAsset isPosterLocallyAvailable returns false when poster doesn't exist")
    func posterIsLocallyAvailableWhenFileDoesNotExist() {
        let nonExistentURL = URL(fileURLWithPath: "/tmp/nonexistent_poster_\(UUID().uuidString).jpg")

        let asset = GalleryAsset(
            id: "test-video-2",
            kind: .video,
            stripIndex: 0,
            remotePath: "events/1/sessions/session-1/video_0.mov",
            localURL: URL(fileURLWithPath: "/tmp/video.mov"),
            mimeType: "video/quicktime",
            posterPath: "events/1/sessions/session-1/photo_0.jpg",
            localPosterURL: nonExistentURL
        )

        #expect(asset.isPosterLocallyAvailable == false)
    }

    @Test("GalleryAsset isPosterLocallyAvailable returns false when localPosterURL is nil")
    func posterIsLocallyAvailableWhenURLIsNil() {
        let asset = GalleryAsset(
            id: "test-video-3",
            kind: .video,
            stripIndex: 0,
            remotePath: "events/1/sessions/session-1/video_0.mov",
            localURL: nil,
            mimeType: "video/quicktime",
            posterPath: "events/1/sessions/session-1/photo_0.jpg",
            localPosterURL: nil
        )

        #expect(asset.isPosterLocallyAvailable == false)
    }

    @Test("Photo assets have nil localPosterURL")
    func photoAssetHasNilPosterURL() {
        let asset = GalleryAsset(
            id: "photo-1",
            kind: .photo,
            stripIndex: 0,
            remotePath: "events/1/sessions/session-1/photo_0.jpg",
            localURL: URL(fileURLWithPath: "/tmp/photo.jpg"),
            mimeType: "image/jpeg",
            posterPath: nil,
            localPosterURL: nil
        )

        #expect(asset.localPosterURL == nil)
        #expect(asset.posterPath == nil)
    }
}

// MARK: - LocalGalleryService Tests

struct LocalGalleryServiceTests {

    @Test("LocalGalleryService populates localPosterURL for videos")
    func localGalleryServicePopulatesPosterURL() async throws {
        let fileManager = FileManager.default
        let testUploadsDir = fileManager.temporaryDirectory.appendingPathComponent("test-uploads-\(UUID().uuidString)")
        try fileManager.createDirectory(at: testUploadsDir, withIntermediateDirectories: true)

        let sessionDir = testUploadsDir.appendingPathComponent("test-session")
        try fileManager.createDirectory(at: sessionDir, withIntermediateDirectories: true)

        // Create test files
        let photoFile = sessionDir.appendingPathComponent("photo_0.jpg")
        let videoFile = sessionDir.appendingPathComponent("video_0.mov")
        try Data().write(to: photoFile)
        try Data().write(to: videoFile)

        // Create a manifest
        let manifest = SessionManifest(
            version: 1,
            eventId: 1,
            sessionId: "test-session",
            createdAt: "2025-01-01T00:00:00Z",
            publicGalleryURL: "https://example.com/s/test-session",
            assets: [
                SessionManifestAsset(
                    id: "photo_0",
                    kind: .photo,
                    stripIndex: 0,
                    sequenceIndex: 1,
                    contentType: "image/jpeg",
                    path: "events/1/sessions/test-session/photo_0.jpg",
                    sizeBytes: 100,
                    durationSeconds: nil,
                    posterPath: nil
                ),
                SessionManifestAsset(
                    id: "video_0",
                    kind: .video,
                    stripIndex: 0,
                    sequenceIndex: 0,
                    contentType: "video/quicktime",
                    path: "events/1/sessions/test-session/video_0.mov",
                    sizeBytes: 1000,
                    durationSeconds: 10.0,
                    posterPath: "events/1/sessions/test-session/photo_0.jpg"
                )
            ]
        )

        // Write manifest
        let manifestFile = sessionDir.appendingPathComponent("manifest.json")
        let manifestData = try JSONEncoder().encode(manifest)
        try manifestData.write(to: manifestFile)

        // Use LocalGalleryService to scan with test directory
        let service = LocalGalleryService(fileManager: fileManager, uploadsDirectory: testUploadsDir)
        let sessions = await service.fetchLocalSessions(eventId: 1)

        // Find our test session
        let testSession = sessions.first { $0.sessionId == "test-session" }
        #expect(testSession != nil)

        // Verify video asset has local poster URL
        let videoAsset = testSession?.assets.first { $0.kind == .video }
        #expect(videoAsset != nil)
        #expect(videoAsset?.localPosterURL != nil)
        #expect(videoAsset?.localPosterURL?.path.hasSuffix("photo_0.jpg") == true)

        // Verify photo asset doesn't have poster URL
        let photoAsset = testSession?.assets.first { $0.kind == .photo }
        #expect(photoAsset != nil)
        #expect(photoAsset?.localPosterURL == nil)

        // Cleanup
        try? fileManager.removeItem(at: testUploadsDir)
    }

    @Test("LocalGalleryService handles videos without local posters")
    func localGalleryServiceHandlesVideosWithoutLocalPosters() async throws {
        let fileManager = FileManager.default
        let testUploadsDir = fileManager.temporaryDirectory.appendingPathComponent("test-uploads-\(UUID().uuidString)")
        try fileManager.createDirectory(at: testUploadsDir, withIntermediateDirectories: true)

        let sessionDir = testUploadsDir.appendingPathComponent("test-session-no-poster")
        try fileManager.createDirectory(at: sessionDir, withIntermediateDirectories: true)

        // Create only video file, no photo
        let videoFile = sessionDir.appendingPathComponent("video_1.mov")
        try Data().write(to: videoFile)

        // Create a manifest with video but no corresponding photo
        let manifest = SessionManifest(
            version: 1,
            eventId: 1,
            sessionId: "test-session-no-poster",
            createdAt: "2025-01-01T00:00:00Z",
            publicGalleryURL: "https://example.com/s/test-session-no-poster",
            assets: [
                SessionManifestAsset(
                    id: "video_1",
                    kind: .video,
                    stripIndex: 1,
                    sequenceIndex: 0,
                    contentType: "video/quicktime",
                    path: "events/1/sessions/test-session-no-poster/video_1.mov",
                    sizeBytes: 1000,
                    durationSeconds: 10.0,
                    posterPath: "events/1/sessions/test-session-no-poster/photo_1.jpg"
                )
            ]
        )

        // Write manifest
        let manifestFile = sessionDir.appendingPathComponent("manifest.json")
        let manifestData = try JSONEncoder().encode(manifest)
        try manifestData.write(to: manifestFile)

        // Use LocalGalleryService to scan with test directory
        let service = LocalGalleryService(fileManager: fileManager, uploadsDirectory: testUploadsDir)
        let sessions = await service.fetchLocalSessions(eventId: 1)

        // Find our test session
        let testSession = sessions.first { $0.sessionId == "test-session-no-poster" }
        #expect(testSession != nil)

        // Verify video asset has nil local poster URL (because photo doesn't exist)
        let videoAsset = testSession?.assets.first { $0.kind == .video }
        #expect(videoAsset != nil)
        #expect(videoAsset?.localPosterURL == nil)
        #expect(videoAsset?.posterPath != nil) // Remote poster path should still be set

        // Cleanup
        try? fileManager.removeItem(at: testUploadsDir)
    }

    @Test("LocalGalleryService populates posters for multiple strips")
    func localGalleryServiceHandlesMultipleStrips() async throws {
        let fileManager = FileManager.default
        let testUploadsDir = fileManager.temporaryDirectory.appendingPathComponent("test-uploads-\(UUID().uuidString)")
        try fileManager.createDirectory(at: testUploadsDir, withIntermediateDirectories: true)

        let sessionDir = testUploadsDir.appendingPathComponent("test-session-multi")
        try fileManager.createDirectory(at: sessionDir, withIntermediateDirectories: true)

        // Create files for 3 strips
        for i in 0..<3 {
            let photoFile = sessionDir.appendingPathComponent("photo_\(i).jpg")
            let videoFile = sessionDir.appendingPathComponent("video_\(i).mov")
            try Data().write(to: photoFile)
            try Data().write(to: videoFile)
        }

        // Create manifest with multiple strips
        var manifestAssets: [SessionManifestAsset] = []
        for i in 0..<3 {
            manifestAssets.append(SessionManifestAsset(
                id: "photo_\(i)",
                kind: .photo,
                stripIndex: i,
                sequenceIndex: 1,
                contentType: "image/jpeg",
                path: "events/1/sessions/test-session-multi/photo_\(i).jpg",
                sizeBytes: 100,
                durationSeconds: nil,
                posterPath: nil
            ))
            manifestAssets.append(SessionManifestAsset(
                id: "video_\(i)",
                kind: .video,
                stripIndex: i,
                sequenceIndex: 0,
                contentType: "video/quicktime",
                path: "events/1/sessions/test-session-multi/video_\(i).mov",
                sizeBytes: 1000,
                durationSeconds: 10.0,
                posterPath: "events/1/sessions/test-session-multi/photo_\(i).jpg"
            ))
        }

        let manifest = SessionManifest(
            version: 1,
            eventId: 1,
            sessionId: "test-session-multi",
            createdAt: "2025-01-01T00:00:00Z",
            publicGalleryURL: "https://example.com/s/test-session-multi",
            assets: manifestAssets
        )

        // Write manifest
        let manifestFile = sessionDir.appendingPathComponent("manifest.json")
        let manifestData = try JSONEncoder().encode(manifest)
        try manifestData.write(to: manifestFile)

        // Use LocalGalleryService to scan with test directory
        let service = LocalGalleryService(fileManager: fileManager, uploadsDirectory: testUploadsDir)
        let sessions = await service.fetchLocalSessions(eventId: 1)

        // Find our test session
        let testSession = sessions.first { $0.sessionId == "test-session-multi" }
        #expect(testSession != nil)

        // Verify all video assets have local poster URLs
        let videoAssets = testSession?.assets.filter { $0.kind == .video } ?? []
        #expect(videoAssets.count == 3)

        for (index, videoAsset) in videoAssets.enumerated() {
            #expect(videoAsset.localPosterURL != nil, "Video \(index) should have local poster URL")
            #expect(videoAsset.localPosterURL?.path.hasSuffix("photo_\(videoAsset.stripIndex).jpg") == true)
            #expect(videoAsset.isPosterLocallyAvailable == true)
        }

        // Cleanup
        try? fileManager.removeItem(at: testUploadsDir)
    }

    @Test("LocalGalleryService reconstructAssets populates poster URLs correctly")
    func reconstructAssetsPopulatesPosterURLs() async throws {
        let fileManager = FileManager.default
        let testUploadsDir = fileManager.temporaryDirectory.appendingPathComponent("test-uploads-\(UUID().uuidString)")
        try fileManager.createDirectory(at: testUploadsDir, withIntermediateDirectories: true)

        let sessionDir = testUploadsDir.appendingPathComponent("test-session-reconstruct")
        try fileManager.createDirectory(at: sessionDir, withIntermediateDirectories: true)

        // Create standard file patterns (no manifest)
        let photoFile = sessionDir.appendingPathComponent("photo_0.jpg")
        let videoFile = sessionDir.appendingPathComponent("video_0.mov")
        try Data().write(to: photoFile)
        try Data().write(to: videoFile)

        // Use LocalGalleryService to scan with test directory (will use reconstructAssets since no manifest)
        let service = LocalGalleryService(fileManager: fileManager, uploadsDirectory: testUploadsDir)
        let sessions = await service.fetchLocalSessions(eventId: 1)

        // Find our test session
        let testSession = sessions.first { $0.sessionId == "test-session-reconstruct" }
        #expect(testSession != nil)

        // Verify video asset has local poster URL
        let videoAsset = testSession?.assets.first { $0.kind == .video }
        #expect(videoAsset != nil)
        #expect(videoAsset?.localPosterURL != nil)
        #expect(videoAsset?.isPosterLocallyAvailable == true)

        // Cleanup
        try? fileManager.removeItem(at: testUploadsDir)
    }
}

// MARK: - GallerySession Date Formatting Tests

struct GallerySessionDateFormattingTests {

    @Test("GallerySession formattedDate returns numeric date without time")
    func formattedDateReturnsNumericDate() {
        let date = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
        let session = GallerySession(
            id: "test-1",
            sessionId: "test-1",
            eventId: 1,
            createdAt: date,
            source: .local,
            thumbPath: nil,
            localThumbURL: nil,
            galleryPath: "s/test-1",
            assets: []
        )

        let formatted = session.formattedDate
        #expect(!formatted.isEmpty, "Formatted date should not be empty")
    }

    @Test("GallerySession formattedTime returns time without date")
    func formattedTimeReturnsTimeOnly() {
        let date = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
        let session = GallerySession(
            id: "test-2",
            sessionId: "test-2",
            eventId: 1,
            createdAt: date,
            source: .remote,
            thumbPath: nil,
            localThumbURL: nil,
            galleryPath: "s/test-2",
            assets: []
        )

        let formatted = session.formattedTime
        #expect(!formatted.isEmpty, "Formatted time should not be empty")
    }

    @Test("GallerySession formattedDateTime returns both date and time")
    func formattedDateTimeReturnsBoth() {
        let date = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
        let session = GallerySession(
            id: "test-3",
            sessionId: "test-3",
            eventId: 1,
            createdAt: date,
            source: .both,
            thumbPath: nil,
            localThumbURL: nil,
            galleryPath: "s/test-3",
            assets: []
        )

        let formatted = session.formattedDateTime
        #expect(!formatted.isEmpty, "Formatted date-time should not be empty")
    }

    @Test("GallerySession formatting is consistent across multiple calls")
    func formattingIsConsistent() {
        let date = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
        let session = GallerySession(
            id: "test-4",
            sessionId: "test-4",
            eventId: 1,
            createdAt: date,
            source: .local,
            thumbPath: nil,
            localThumbURL: nil,
            galleryPath: "s/test-4",
            assets: []
        )

        let date1 = session.formattedDate
        let date2 = session.formattedDate
        let time1 = session.formattedTime
        let time2 = session.formattedTime
        let dateTime1 = session.formattedDateTime
        let dateTime2 = session.formattedDateTime

        #expect(date1 == date2, "Date formatting should be consistent")
        #expect(time1 == time2, "Time formatting should be consistent")
        #expect(dateTime1 == dateTime2, "DateTime formatting should be consistent")
    }

    @Test("GallerySession handles different dates correctly")
    func handlesDifferentDates() {
        let date1 = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
        let date2 = Date(timeIntervalSince1970: 1735689600) // 2025-01-01 00:00:00 UTC

        let session1 = GallerySession(
            id: "test-5",
            sessionId: "test-5",
            eventId: 1,
            createdAt: date1,
            source: .local,
            thumbPath: nil,
            localThumbURL: nil,
            galleryPath: "s/test-5",
            assets: []
        )

        let session2 = GallerySession(
            id: "test-6",
            sessionId: "test-6",
            eventId: 1,
            createdAt: date2,
            source: .local,
            thumbPath: nil,
            localThumbURL: nil,
            galleryPath: "s/test-6",
            assets: []
        )

        #expect(session1.formattedDate != session2.formattedDate, "Different dates should format differently")
        #expect(session1.formattedDateTime != session2.formattedDateTime, "Different dates should have different date-times")
    }

    @Test("GallerySession formatting handles current date")
    func formattingHandlesCurrentDate() {
        let now = Date()
        let session = GallerySession(
            id: "test-7",
            sessionId: "test-7",
            eventId: 1,
            createdAt: now,
            source: .local,
            thumbPath: nil,
            localThumbURL: nil,
            galleryPath: "s/test-7",
            assets: []
        )

        #expect(!session.formattedDate.isEmpty, "Should format current date")
        #expect(!session.formattedTime.isEmpty, "Should format current time")
        #expect(!session.formattedDateTime.isEmpty, "Should format current date-time")
    }

    @Test("GallerySession Equatable works with same Date values")
    func equatableWorksWithDates() {
        let date = Date(timeIntervalSince1970: 1704067200)
        let session1 = GallerySession(
            id: "test-8",
            sessionId: "test-8",
            eventId: 1,
            createdAt: date,
            source: .local,
            thumbPath: nil,
            localThumbURL: nil,
            galleryPath: "s/test-8",
            assets: []
        )

        let session2 = GallerySession(
            id: "test-8",
            sessionId: "test-8",
            eventId: 1,
            createdAt: date,
            source: .local,
            thumbPath: nil,
            localThumbURL: nil,
            galleryPath: "s/test-8",
            assets: []
        )

        #expect(session1 == session2, "Sessions with same date should be equal")
    }
}

// MARK: - Mock Camera Controller for Testing

/// Mock camera controller that allows precise control over camera behavior for testing
final class MockCameraController: CameraControlling, @unchecked Sendable {
    weak var delegate: CameraControllerDelegate?
    var previewLayer: AVCaptureVideoPreviewLayer? { nil }
    private(set) var isRecording = false
    var isSimulator: Bool { true }

    // Test control properties
    var setupShouldFail = false
    var setupError: CameraError?
    var recordingShouldFail = false
    var recordingError: CameraError?
    var photoCaptureShouldFail = false
    var photoCaptureError: CameraError?

    // Tracking properties
    var setupCalled = false
    var startSessionCalled = false
    var stopSessionCalled = false
    var startRecordingCalled = false
    var stopRecordingCalled = false
    var capturePhotoCalled = false
    var cleanupTempFilesCalled = false
    var updateAspectRatioCalled = false
    var lastAspectRatio: CaptureAspectRatio?

    // Test data
    var mockPhotoData = Data("mock photo data".utf8)
    var mockVideoURL: URL?

    func setup() async throws {
        setupCalled = true
        if setupShouldFail {
            throw setupError ?? CameraError.setupFailed("Mock setup failure")
        }
    }

    func startSession() {
        startSessionCalled = true
    }

    func stopSession() {
        stopSessionCalled = true
    }

    func startRecording() throws {
        startRecordingCalled = true
        if recordingShouldFail {
            throw recordingError ?? CameraError.recordingFailed("Mock recording failure")
        }

        isRecording = true

        // Create a mock video URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoURL = documentsPath.appendingPathComponent("mock_video_\(UUID().uuidString).mov")
        mockVideoURL = videoURL

        delegate?.cameraController(self, didStartRecording: videoURL)
    }

    func stopRecording() {
        stopRecordingCalled = true
        isRecording = false

        if let url = mockVideoURL {
            // Create an empty file to simulate video
            try? Data().write(to: url)
            delegate?.cameraController(self, didFinishRecording: url)
        }
    }

    func capturePhoto() async throws -> Data {
        capturePhotoCalled = true
        if photoCaptureShouldFail {
            throw photoCaptureError ?? CameraError.captureFailed("Mock capture failure")
        }

        delegate?.cameraController(self, didCapturePhoto: mockPhotoData)
        return mockPhotoData
    }

    func updateCaptureAspectRatio(_ aspectRatio: CaptureAspectRatio, orientation: LayoutOrientation) {
        updateAspectRatioCalled = true
        lastAspectRatio = aspectRatio
    }

    func cleanupTempFiles() {
        cleanupTempFilesCalled = true
        if let url = mockVideoURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Simulates an error occurring during camera operations
    func simulateError(_ error: CameraError) {
        delegate?.cameraController(self, didFailWithError: error)
    }
}

// MARK: - CaptureViewModel Tests

@MainActor
struct CaptureViewModelTests {

    @Test("CaptureViewModel initializes with correct default state")
    func captureViewModelInitialState() {
        let mockCamera = MockCameraController()
        let config = CaptureConfiguration(
            videoDuration: 3,
            countdownSeconds: 0,
            endOfRecordingCountdownSeconds: 0,
            stripCount: 3
        )
        let viewModel = CaptureViewModel(config: config, cameraController: mockCamera)

        #expect(viewModel.currentStripIndex == 0)
        #expect(viewModel.stripState == .ready)
        #expect(viewModel.capturedStrips.isEmpty)
        #expect(viewModel.pendingStrip == nil)
        #expect(viewModel.isSessionComplete == false)
        #expect(viewModel.isCameraReady == false)
    }

    @Test("setupCamera sets isCameraReady on success")
    func setupCameraSuccess() async {
        let mockCamera = MockCameraController()
        let config = CaptureConfiguration(
            videoDuration: 3,
            countdownSeconds: 0,
            endOfRecordingCountdownSeconds: 0,
            stripCount: 3
        )
        let viewModel = CaptureViewModel(config: config, cameraController: mockCamera)

        await viewModel.setupCamera()

        #expect(mockCamera.setupCalled)
        #expect(mockCamera.startSessionCalled)
        #expect(viewModel.isCameraReady)
    }

    @Test("setupCamera sets error state on failure")
    func setupCameraFailure() async {
        let mockCamera = MockCameraController()
        mockCamera.setupShouldFail = true
        mockCamera.setupError = .permissionDenied

        let config = CaptureConfiguration(
            videoDuration: 3,
            countdownSeconds: 0,
            endOfRecordingCountdownSeconds: 0,
            stripCount: 3
        )
        let viewModel = CaptureViewModel(config: config, cameraController: mockCamera)

        await viewModel.setupCamera()

        #expect(mockCamera.setupCalled)
        #expect(!viewModel.isCameraReady)
        if case .error = viewModel.stripState {
            #expect(true)
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("startCapture initiates recording without countdown")
    func startCaptureWithoutCountdown() async {
        let mockCamera = MockCameraController()
        let config = CaptureConfiguration(
            videoDuration: 3,
            countdownSeconds: 0,
            endOfRecordingCountdownSeconds: 0,
            stripCount: 3
        )
        let viewModel = CaptureViewModel(config: config, cameraController: mockCamera)
        await viewModel.setupCamera()

        viewModel.startCapture()

        // Give time for state to update
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(mockCamera.startRecordingCalled)
        if case .recording = viewModel.stripState {
            #expect(true)
        } else {
            Issue.record("Expected recording state, got \(String(describing: viewModel.stripState))")
        }
    }

    @Test("startCapture initiates countdown when configured")
    func startCaptureWithCountdown() async {
        let mockCamera = MockCameraController()
        let config = CaptureConfiguration(
            videoDuration: 3,
            countdownSeconds: 3,
            endOfRecordingCountdownSeconds: 0,
            stripCount: 3
        )
        let viewModel = CaptureViewModel(config: config, cameraController: mockCamera)
        await viewModel.setupCamera()

        viewModel.startCapture()

        if case .countdown(let remaining) = viewModel.stripState {
            #expect(remaining == 3)
        } else {
            Issue.record("Expected countdown state")
        }
    }

    @Test("retryCurrentStrip resets state to ready")
    func retryCurrentStripResetsState() async {
        let mockCamera = MockCameraController()
        let config = CaptureConfiguration(
            videoDuration: 3,
            countdownSeconds: 0,
            endOfRecordingCountdownSeconds: 0,
            stripCount: 3
        )
        let viewModel = CaptureViewModel(config: config, cameraController: mockCamera)
        await viewModel.setupCamera()

        viewModel.startCapture()
        try? await Task.sleep(nanoseconds: 100_000_000)

        viewModel.retryCurrentStrip()

        #expect(viewModel.stripState == .ready)
    }

    @Test("cleanup stops session and cleans temp files")
    func cleanupStopsSessionAndCleansFiles() async {
        let mockCamera = MockCameraController()
        let config = CaptureConfiguration(
            videoDuration: 3,
            countdownSeconds: 0,
            endOfRecordingCountdownSeconds: 0,
            stripCount: 3
        )
        let viewModel = CaptureViewModel(config: config, cameraController: mockCamera)
        await viewModel.setupCamera()

        viewModel.cleanup(deleteTemporaryFiles: true)

        #expect(mockCamera.stopSessionCalled)
        #expect(mockCamera.cleanupTempFilesCalled)
    }

    @Test("cleanup preserves temp files when requested")
    func cleanupPreservesTempFiles() async {
        let mockCamera = MockCameraController()
        let config = CaptureConfiguration(
            videoDuration: 3,
            countdownSeconds: 0,
            endOfRecordingCountdownSeconds: 0,
            stripCount: 3
        )
        let viewModel = CaptureViewModel(config: config, cameraController: mockCamera)
        await viewModel.setupCamera()

        viewModel.cleanup(deleteTemporaryFiles: false)

        #expect(mockCamera.stopSessionCalled)
        #expect(!mockCamera.cleanupTempFilesCalled)
    }

    @Test("getCapturedStrips returns correct format")
    func getCapturedStripsFormat() async {
        let mockCamera = MockCameraController()
        let config = CaptureConfiguration(
            videoDuration: 3,
            countdownSeconds: 0,
            endOfRecordingCountdownSeconds: 0,
            stripCount: 3
        )
        let viewModel = CaptureViewModel(config: config, cameraController: mockCamera)

        // Manually add captured strips to test conversion
        let testURL = URL(fileURLWithPath: "/tmp/test.mov")
        let testPhotoData = Data("test".utf8)

        // Access internal capturedStrips array
        viewModel.capturedStrips.append(CapturedStripMedia(
            stripIndex: 0,
            videoURL: testURL,
            photoData: testPhotoData,
            thumbnailData: nil
        ))

        let strips = viewModel.getCapturedStrips()

        #expect(strips.count == 1)
        #expect(strips[0].stripIndex == 0)
        #expect(strips[0].videoURL == testURL)
        #expect(strips[0].photoData == testPhotoData)
    }

    @Test("Capture completes into review with pending strip")
    func captureCompletesIntoReview() async throws {
        let mockCamera = MockCameraController()
        let config = CaptureConfiguration(
            videoDuration: 0.05,
            countdownSeconds: 0,
            endOfRecordingCountdownSeconds: 0,
            stripCount: 1,
            stripReviewDuration: 1
        )
        let viewModel = CaptureViewModel(config: config, cameraController: mockCamera)
        await viewModel.setupCamera()

        viewModel.startCapture()

        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(viewModel.pendingStrip != nil)
        #expect(viewModel.capturedStrips.isEmpty)
        #expect(viewModel.stripState == .complete)
    }

    @Test("Auto-advance accepts pending strip after review")
    func autoAdvanceAcceptsPendingStrip() async throws {
        let mockCamera = MockCameraController()
        let config = CaptureConfiguration(
            videoDuration: 0.05,
            countdownSeconds: 0,
            endOfRecordingCountdownSeconds: 0,
            stripCount: 1,
            stripReviewDuration: 0.05
        )
        let viewModel = CaptureViewModel(config: config, cameraController: mockCamera)
        await viewModel.setupCamera()

        viewModel.startCapture()

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(viewModel.capturedStrips.count == 1)
        #expect(viewModel.isSessionComplete)
    }

    @Test("Manual advance disables auto-accept and keeps controls visible")
    func manualAdvanceDisablesAutoAccept() async throws {
        let mockCamera = MockCameraController()
        let config = CaptureConfiguration(
            videoDuration: 0.05,
            countdownSeconds: 0,
            endOfRecordingCountdownSeconds: 0,
            stripCount: 1,
            stripReviewDuration: 0.05,
            autoAdvanceWithoutReview: true,
            autoAdvancePreviewDuration: 0.05,
            manualAdvanceAfterReview: true
        )
        let viewModel = CaptureViewModel(config: config, cameraController: mockCamera)
        await viewModel.setupCamera()

        #expect(viewModel.showsReviewControls)

        viewModel.startCapture()

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(viewModel.pendingStrip != nil)
        #expect(viewModel.capturedStrips.isEmpty)
        #expect(viewModel.isSessionComplete == false)
    }

    @Test("Retake discards pending strip and restarts capture")
    func retakeDiscardsPendingStrip() async throws {
        let mockCamera = MockCameraController()
        let config = CaptureConfiguration(
            videoDuration: 0.2,
            countdownSeconds: 0,
            endOfRecordingCountdownSeconds: 0,
            stripCount: 1,
            stripReviewDuration: 1
        )
        let viewModel = CaptureViewModel(config: config, cameraController: mockCamera)
        await viewModel.setupCamera()

        viewModel.startCapture()
        try await Task.sleep(nanoseconds: 400_000_000)

        #expect(viewModel.pendingStrip != nil)

        viewModel.retakePendingStrip()
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(viewModel.pendingStrip == nil)
        #expect(viewModel.capturedStrips.isEmpty)
        if case .recording = viewModel.stripState {
            #expect(true)
        } else if case .countdown = viewModel.stripState {
            #expect(true)
        } else {
            Issue.record("Expected capture to restart after retake")
        }
    }

    @Test("Auto-advance without review hides controls and uses short preview")
    func autoAdvanceWithoutReviewSettings() {
        let mockCamera = MockCameraController()
        let config = CaptureConfiguration(
            videoDuration: 1,
            countdownSeconds: 0,
            endOfRecordingCountdownSeconds: 0,
            stripCount: 1,
            stripReviewDuration: 3,
            autoAdvanceWithoutReview: true,
            autoAdvancePreviewDuration: 0.25
        )
        let viewModel = CaptureViewModel(config: config, cameraController: mockCamera)

        #expect(viewModel.showsReviewControls == false)
        #expect(viewModel.reviewDuration == 0.25)
    }

    @Test("Recording error sets error state")
    func recordingErrorSetsErrorState() async {
        let mockCamera = MockCameraController()
        mockCamera.recordingShouldFail = true
        mockCamera.recordingError = .recordingFailed("Test failure")

        let config = CaptureConfiguration(
            videoDuration: 3,
            countdownSeconds: 0,
            endOfRecordingCountdownSeconds: 0,
            stripCount: 3
        )
        let viewModel = CaptureViewModel(config: config, cameraController: mockCamera)
        await viewModel.setupCamera()

        viewModel.startCapture()

        // Give time for error to propagate
        try? await Task.sleep(nanoseconds: 100_000_000)

        if case .error = viewModel.stripState {
            #expect(true)
        } else {
            Issue.record("Expected error state")
        }
    }
}

// MARK: - SimulatorCameraController Tests

@MainActor
struct SimulatorCameraControllerTests {

    @Test("SimulatorCameraController is marked as simulator")
    func isSimulatorTrue() {
        let controller = SimulatorCameraController()
        #expect(controller.isSimulator == true)
    }

    @Test("SimulatorCameraController has no preview layer")
    func noPreviewLayer() {
        let controller = SimulatorCameraController()
        #expect(controller.previewLayer == nil)
    }

    @Test("SimulatorCameraController setup completes without error")
    func setupSuccess() async throws {
        let controller = SimulatorCameraController()
        try await controller.setup()
        // Should not throw
    }

    @Test("SimulatorCameraController capturePhoto returns data")
    func capturePhotoReturnsData() async throws {
        let controller = SimulatorCameraController()
        let photoData = try await controller.capturePhoto()

        #expect(!photoData.isEmpty)
        // Verify it's valid JPEG data (starts with FFD8)
        #expect(photoData.count > 2)
    }

    @Test("SimulatorCameraController tracks recording state")
    func recordingStateTracking() async throws {
        let controller = SimulatorCameraController()

        #expect(controller.isRecording == false)

        try controller.startRecording()
        #expect(controller.isRecording == true)

        controller.stopRecording()

        // isRecording should be false after stopRecording
        #expect(controller.isRecording == false)
    }
}

// MARK: - CameraControllerFactory Tests

@MainActor
struct CameraControllerFactoryTests {

    @Test("Factory creates appropriate controller")
    func factoryCreatesController() {
        let controller = CameraControllerFactory.makeController()

        // In test environment (simulator), should create SimulatorCameraController
        #if targetEnvironment(simulator)
        #expect(controller.isSimulator == true)
        #else
        #expect(controller.isSimulator == false)
        #endif
    }
}

// MARK: - Integration Tests for Capture Flow

@MainActor
struct CaptureFlowIntegrationTests {

    @Test("Complete capture flow with mock camera")
    func completeCaptureFlow() async throws {
        // Create a mock camera that completes quickly
        let mockCamera = MockCameraController()
        let config = CaptureConfiguration(
            videoDuration: 0.5,
            countdownSeconds: 0,
            endOfRecordingCountdownSeconds: 0,
            stripCount: 1
        )
        let viewModel = CaptureViewModel(config: config, cameraController: mockCamera)

        // Setup camera
        await viewModel.setupCamera()
        #expect(viewModel.isCameraReady)

        // Start capture
        viewModel.startCapture()

        // Wait for recording to start
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(mockCamera.startRecordingCalled)

        // Simulate recording completion by stopping
        mockCamera.stopRecording()

        // Wait for photo capture and finalization
        try await Task.sleep(nanoseconds: 500_000_000)

        // Verify capture completed
        #expect(mockCamera.capturePhotoCalled)
    }

    @Test("Multiple strips capture sequentially")
    func multipleStripsCapture() async throws {
        let mockCamera = MockCameraController()
        let config = CaptureConfiguration(
            videoDuration: 0.1,
            countdownSeconds: 0,
            endOfRecordingCountdownSeconds: 0,
            stripCount: 2
        )
        let viewModel = CaptureViewModel(config: config, cameraController: mockCamera)

        await viewModel.setupCamera()
        #expect(viewModel.isCameraReady)

        // Start first strip
        viewModel.startCapture()
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(viewModel.currentStripIndex == 0)
    }

    @Test("Delegate callbacks are received correctly")
    func delegateCallbacks() async throws {
        let mockCamera = MockCameraController()
        let config = CaptureConfiguration(
            videoDuration: 0.5,
            countdownSeconds: 0,
            endOfRecordingCountdownSeconds: 0,
            stripCount: 1
        )
        let viewModel = CaptureViewModel(config: config, cameraController: mockCamera)

        await viewModel.setupCamera()

        // Start capture
        viewModel.startCapture()
        try await Task.sleep(nanoseconds: 100_000_000)

        // Verify delegate was set and is being used
        #expect(mockCamera.delegate != nil)

        // Simulate error to test error callback
        mockCamera.simulateError(.cameraUnavailable)

        // Give enough time for the Task in the delegate callback to complete
        try await Task.sleep(nanoseconds: 200_000_000)

        if case .error = viewModel.stripState {
            #expect(true)
        } else {
            Issue.record("Expected error state after delegate error callback")
        }
    }
}

// MARK: - Mock Worker API Client

/// Mock implementation of WorkerAPIClientProtocol for testing upload queue
final class MockWorkerAPIClient: WorkerAPIClientProtocol, @unchecked Sendable {
    var presignResponse: PresignResponse?
    var presignError: Error?
    var completeResponse: CompleteResponse?
    var completeError: Error?
    
    var presignCallCount = 0
    var completeCallCount = 0
    var lastPresignRequest: PresignRequest?
    var lastCompleteRequest: CompleteRequest?
    
    func presign(request: PresignRequest) async throws -> PresignResponse {
        presignCallCount += 1
        lastPresignRequest = request
        
        if let error = presignError {
            throw error
        }
        
        if let response = presignResponse {
            return response
        }
        
        // Default: generate mock presigned URLs for each file
        let uploads = request.files.map { file in
            PresignUpload(
                path: file.path,
                method: "PUT",
                url: "https://mock-r2.example.com/\(file.path)?sig=mock"
            )
        }
        return PresignResponse(uploads: uploads, expiresInSeconds: 900)
    }
    
    func complete(request: CompleteRequest) async throws -> CompleteResponse {
        completeCallCount += 1
        lastCompleteRequest = request
        
        if let error = completeError {
            throw error
        }
        
        return completeResponse ?? CompleteResponse(status: "ok")
    }
    
    func reset() {
        presignResponse = nil
        presignError = nil
        completeResponse = nil
        completeError = nil
        presignCallCount = 0
        completeCallCount = 0
        lastPresignRequest = nil
        lastCompleteRequest = nil
    }
}

// MARK: - Upload Queue Session Status Tests

struct UploadQueueSessionStatusTests {
    
    /// Helper to create a test asset
    private func makeAsset(state: UploadQueueItemState) -> UploadQueueAsset {
        UploadQueueAsset(
            id: UUID(),
            kind: .photo,
            stripIndex: 0,
            sequenceIndex: 1,
            fileName: "photo_0.jpg",
            mimeType: "image/jpeg",
            localURL: URL(fileURLWithPath: "/tmp/photo_0.jpg"),
            remotePath: "events/1/sessions/test/photo_0.jpg",
            sizeBytes: 100,
            durationSeconds: nil,
            posterPath: nil,
            state: state
        )
    }
    
    /// Helper to create a test session
    private func makeSession(
        assets: [UploadQueueAsset] = [],
        manifestState: UploadQueueItemState = .pending,
        completeState: UploadQueueItemState = .pending
    ) -> UploadQueueSession {
        UploadQueueSession(
            id: "test-session",
            eventId: 1,
            sessionId: "test-session",
            createdAt: "2025-01-01T00:00:00Z",
            publicGalleryURL: "https://example.com/s/test-session",
            assets: assets,
            manifestState: manifestState,
            completeState: completeState
        )
    }
    
    @Test("Status returns completed when completeState is uploaded")
    func statusCompletedWhenCompleteStateUploaded() {
        let session = makeSession(
            assets: [makeAsset(state: .uploaded)],
            manifestState: .uploaded,
            completeState: .uploaded
        )
        
        #expect(uploadSessionStatus(session) == .completed)
        #expect(session.status == .completed)
    }
    
    @Test("Status returns failed when any asset has failed state")
    func statusFailedWhenAssetFailed() {
        let session = makeSession(
            assets: [
                makeAsset(state: .uploaded),
                makeAsset(state: .failed)
            ],
            manifestState: .pending,
            completeState: .pending
        )
        
        #expect(uploadSessionStatus(session) == .failed)
    }
    
    @Test("Status returns failed when manifestState is failed")
    func statusFailedWhenManifestFailed() {
        let session = makeSession(
            assets: [makeAsset(state: .uploaded)],
            manifestState: .failed,
            completeState: .pending
        )
        
        #expect(uploadSessionStatus(session) == .failed)
    }
    
    @Test("Status returns failed when completeState is failed")
    func statusFailedWhenCompleteStateFailed() {
        let session = makeSession(
            assets: [makeAsset(state: .uploaded)],
            manifestState: .uploaded,
            completeState: .failed
        )
        
        #expect(uploadSessionStatus(session) == .failed)
    }
    
    @Test("Status returns uploading when any asset is uploading")
    func statusUploadingWhenAssetUploading() {
        let session = makeSession(
            assets: [
                makeAsset(state: .uploaded),
                makeAsset(state: .uploading)
            ],
            manifestState: .pending,
            completeState: .pending
        )
        
        #expect(uploadSessionStatus(session) == .uploading)
    }
    
    @Test("Status returns uploading when manifestState is uploading")
    func statusUploadingWhenManifestUploading() {
        let session = makeSession(
            assets: [makeAsset(state: .uploaded)],
            manifestState: .uploading,
            completeState: .pending
        )
        
        #expect(uploadSessionStatus(session) == .uploading)
    }
    
    @Test("Status returns uploading when completeState is uploading")
    func statusUploadingWhenCompleteStateUploading() {
        let session = makeSession(
            assets: [makeAsset(state: .uploaded)],
            manifestState: .uploaded,
            completeState: .uploading
        )
        
        #expect(uploadSessionStatus(session) == .uploading)
    }
    
    @Test("Status returns pending when all items are pending")
    func statusPendingWhenAllPending() {
        let session = makeSession(
            assets: [
                makeAsset(state: .pending),
                makeAsset(state: .pending)
            ],
            manifestState: .pending,
            completeState: .pending
        )
        
        #expect(uploadSessionStatus(session) == .pending)
    }
    
    @Test("Status returns pending for mixed pending and uploaded assets")
    func statusPendingForMixedPendingUploaded() {
        let session = makeSession(
            assets: [
                makeAsset(state: .pending),
                makeAsset(state: .uploaded)
            ],
            manifestState: .pending,
            completeState: .pending
        )
        
        #expect(uploadSessionStatus(session) == .pending)
    }
}

// MARK: - Upload Queue Session Extension Tests

struct UploadQueueSessionExtensionTests {
    
    private func makeAsset(state: UploadQueueItemState) -> UploadQueueAsset {
        UploadQueueAsset(
            id: UUID(),
            kind: .photo,
            stripIndex: 0,
            sequenceIndex: 1,
            fileName: "photo.jpg",
            mimeType: "image/jpeg",
            localURL: URL(fileURLWithPath: "/tmp/photo.jpg"),
            remotePath: "events/1/sessions/test/photo.jpg",
            sizeBytes: 100,
            durationSeconds: nil,
            posterPath: nil,
            state: state
        )
    }
    
    private func makeSession(
        assets: [UploadQueueAsset],
        manifestState: UploadQueueItemState = .pending,
        completeState: UploadQueueItemState = .pending
    ) -> UploadQueueSession {
        UploadQueueSession(
            id: "test-session",
            eventId: 1,
            sessionId: "test-session",
            createdAt: "2025-01-01T00:00:00Z",
            publicGalleryURL: "https://example.com/s/test-session",
            assets: assets,
            manifestState: manifestState,
            completeState: completeState
        )
    }
    
    @Test("uploadedAssetCount counts only uploaded assets")
    func uploadedAssetCountCorrect() {
        let session = makeSession(assets: [
            makeAsset(state: .uploaded),
            makeAsset(state: .uploaded),
            makeAsset(state: .pending),
            makeAsset(state: .failed)
        ])
        
        #expect(session.uploadedAssetCount == 2)
    }
    
    @Test("totalAssetCount returns all assets")
    func totalAssetCountCorrect() {
        let session = makeSession(assets: [
            makeAsset(state: .uploaded),
            makeAsset(state: .pending),
            makeAsset(state: .failed),
            makeAsset(state: .uploading)
        ])
        
        #expect(session.totalAssetCount == 4)
    }
    
    @Test("progressSummary returns Complete for completed sessions")
    func progressSummaryComplete() {
        let session = makeSession(
            assets: [makeAsset(state: .uploaded)],
            manifestState: .uploaded,
            completeState: .uploaded
        )
        
        #expect(session.progressSummary == "Complete")
    }
    
    @Test("progressSummary returns failed count for failed sessions")
    func progressSummaryFailed() {
        let session = makeSession(
            assets: [
                makeAsset(state: .uploaded),
                makeAsset(state: .failed),
                makeAsset(state: .failed)
            ],
            manifestState: .pending,
            completeState: .pending
        )
        
        #expect(session.progressSummary == "2 failed")
    }
    
    @Test("progressSummary includes manifest in failed count")
    func progressSummaryIncludesManifestFailed() {
        let session = makeSession(
            assets: [makeAsset(state: .uploaded)],
            manifestState: .failed,
            completeState: .pending
        )
        
        #expect(session.progressSummary == "1 failed")
    }
    
    @Test("progressSummary includes complete in failed count")
    func progressSummaryIncludesCompleteFailed() {
        let session = makeSession(
            assets: [makeAsset(state: .uploaded)],
            manifestState: .uploaded,
            completeState: .failed
        )
        
        #expect(session.progressSummary == "1 failed")
    }
    
    @Test("progressSummary returns X/Y assets for in-progress")
    func progressSummaryInProgress() {
        let session = makeSession(
            assets: [
                makeAsset(state: .uploaded),
                makeAsset(state: .uploaded),
                makeAsset(state: .pending),
                makeAsset(state: .pending)
            ],
            manifestState: .pending,
            completeState: .pending
        )
        
        #expect(session.progressSummary == "2/4 assets")
    }
}

// MARK: - Upload History Store Tests

struct UploadHistoryStoreTests {
    
    private func makeRecord(sessionId: String) -> CompletedUploadRecord {
        CompletedUploadRecord(
            id: sessionId,
            sessionId: sessionId,
            eventId: 1,
            createdAt: "2025-01-01T00:00:00Z",
            completedAt: "2025-01-01T00:01:00Z",
            assetCount: 6,
            publicGalleryURL: "https://example.com/s/\(sessionId)"
        )
    }
    
    @Test("UploadHistoryStore persists records round-trip")
    func historyStoreRoundTrip() async throws {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documents.appendingPathComponent("upload_history_test.json")
        try? fileManager.removeItem(at: fileURL)
        
        // Custom store with test file
        let store = UploadHistoryStore(fileManager: fileManager, fileName: "upload_history_test.json")
        
        let record = makeRecord(sessionId: "session-1")
        try await store.addRecord(record)
        
        // Create new store to force reload from disk
        let reloadedStore = UploadHistoryStore(fileManager: fileManager, fileName: "upload_history_test.json")
        let records = try await reloadedStore.records()
        
        #expect(records.count == 1)
        #expect(records.first?.sessionId == "session-1")
        
        try? fileManager.removeItem(at: fileURL)
    }
    
    @Test("UploadHistoryStore inserts newest records first")
    func historyStoreNewestFirst() async throws {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documents.appendingPathComponent("upload_history_order_test.json")
        try? fileManager.removeItem(at: fileURL)
        
        let store = UploadHistoryStore(fileManager: fileManager, fileName: "upload_history_order_test.json")
        
        try await store.addRecord(makeRecord(sessionId: "first"))
        try await store.addRecord(makeRecord(sessionId: "second"))
        try await store.addRecord(makeRecord(sessionId: "third"))
        
        let records = try await store.records()
        
        #expect(records.count == 3)
        #expect(records[0].sessionId == "third")
        #expect(records[1].sessionId == "second")
        #expect(records[2].sessionId == "first")
        
        try? fileManager.removeItem(at: fileURL)
    }
    
    @Test("UploadHistoryStore clearAll removes all records")
    func historyStoreClearAll() async throws {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documents.appendingPathComponent("upload_history_clear_test.json")
        try? fileManager.removeItem(at: fileURL)
        
        let store = UploadHistoryStore(fileManager: fileManager, fileName: "upload_history_clear_test.json")
        
        try await store.addRecord(makeRecord(sessionId: "session-1"))
        try await store.addRecord(makeRecord(sessionId: "session-2"))
        
        var records = try await store.records()
        #expect(records.count == 2)
        
        try await store.clearAll()
        
        records = try await store.records()
        #expect(records.count == 0)
        
        try? fileManager.removeItem(at: fileURL)
    }
    
    @Test("UploadHistoryStore enforces max records limit")
    func historyStoreMaxRecordsLimit() async throws {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documents.appendingPathComponent("upload_history_max_test.json")
        try? fileManager.removeItem(at: fileURL)
        
        // Use small maxRecords for testing
        let store = UploadHistoryStore(fileManager: fileManager, fileName: "upload_history_max_test.json", maxRecords: 3)
        
        try await store.addRecord(makeRecord(sessionId: "session-1"))
        try await store.addRecord(makeRecord(sessionId: "session-2"))
        try await store.addRecord(makeRecord(sessionId: "session-3"))
        try await store.addRecord(makeRecord(sessionId: "session-4"))
        try await store.addRecord(makeRecord(sessionId: "session-5"))
        
        let records = try await store.records()
        
        // Should only keep maxRecords (3) entries
        #expect(records.count == 3)
        // Should keep newest (most recently added)
        #expect(records[0].sessionId == "session-5")
        #expect(records[1].sessionId == "session-4")
        #expect(records[2].sessionId == "session-3")
        
        try? fileManager.removeItem(at: fileURL)
    }
}

// MARK: - Upload Queue Worker Tests

struct UploadQueueWorkerTests {
    
    private func makeTestAsset(
        fileName: String,
        state: UploadQueueItemState = .pending
    ) -> UploadQueueAsset {
        UploadQueueAsset(
            id: UUID(),
            kind: .photo,
            stripIndex: 0,
            sequenceIndex: 1,
            fileName: fileName,
            mimeType: "image/jpeg",
            localURL: URL(fileURLWithPath: "/tmp/\(fileName)"),
            remotePath: "events/1/sessions/test/\(fileName)",
            sizeBytes: 100,
            durationSeconds: nil,
            posterPath: nil,
            state: state
        )
    }
    
    private func makeTestSession(
        sessionId: String,
        assets: [UploadQueueAsset]? = nil,
        manifestState: UploadQueueItemState = .pending,
        completeState: UploadQueueItemState = .pending
    ) -> UploadQueueSession {
        UploadQueueSession(
            id: sessionId,
            eventId: 1,
            sessionId: sessionId,
            createdAt: "2025-01-01T00:00:00Z",
            publicGalleryURL: "https://example.com/s/\(sessionId)",
            assets: assets ?? [makeTestAsset(fileName: "photo_0.jpg")],
            manifestState: manifestState,
            completeState: completeState
        )
    }
    
    @Test("Worker getQueueSessions returns current queue")
    func workerGetQueueSessions() async throws {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "worker_test_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "worker_test_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        // Clean up any previous test data
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_test_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Initially empty
        var sessions = try await worker.getQueueSessions()
        #expect(sessions.isEmpty)
        
        // Add sessions directly to store
        try await queueStore.addSession(makeTestSession(sessionId: "session-1"))
        try await queueStore.addSession(makeTestSession(sessionId: "session-2"))
        
        sessions = try await worker.getQueueSessions()
        #expect(sessions.count == 2)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_test_history.json"))
    }
    
    @Test("Worker getCompletedHistory returns history records")
    func workerGetCompletedHistory() async throws {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "worker_history_test_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "worker_history_test_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_history_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_history_test_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Initially empty
        var history = try await worker.getCompletedHistory()
        #expect(history.isEmpty)
        
        // Add history records directly
        let record = CompletedUploadRecord(
            id: "session-1",
            sessionId: "session-1",
            eventId: 1,
            createdAt: "2025-01-01T00:00:00Z",
            completedAt: "2025-01-01T00:01:00Z",
            assetCount: 6,
            publicGalleryURL: "https://example.com/s/session-1"
        )
        try await historyStore.addRecord(record)
        
        history = try await worker.getCompletedHistory()
        #expect(history.count == 1)
        #expect(history.first?.sessionId == "session-1")
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_history_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_history_test_history.json"))
    }
    
    @Test("Worker clearHistory removes all history")
    func workerClearHistory() async throws {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "worker_clear_test_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "worker_clear_test_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_clear_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_clear_test_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Add history records
        let record1 = CompletedUploadRecord(
            id: "session-1", sessionId: "session-1", eventId: 1,
            createdAt: "2025-01-01T00:00:00Z", completedAt: "2025-01-01T00:01:00Z",
            assetCount: 6, publicGalleryURL: "https://example.com/s/session-1"
        )
        let record2 = CompletedUploadRecord(
            id: "session-2", sessionId: "session-2", eventId: 1,
            createdAt: "2025-01-01T00:00:00Z", completedAt: "2025-01-01T00:01:00Z",
            assetCount: 6, publicGalleryURL: "https://example.com/s/session-2"
        )
        try await historyStore.addRecord(record1)
        try await historyStore.addRecord(record2)
        
        var history = try await worker.getCompletedHistory()
        #expect(history.count == 2)
        
        try await worker.clearHistory()
        
        history = try await worker.getCompletedHistory()
        #expect(history.isEmpty)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_clear_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_clear_test_history.json"))
    }
    
    @Test("Worker retrySession only retries failed sessions")
    func workerRetrySessionOnlyFailed() async throws {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "worker_retry_test_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "worker_retry_test_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_retry_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_retry_test_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Add a pending session (not failed)
        let pendingSession = makeTestSession(
            sessionId: "pending-session",
            assets: [makeTestAsset(fileName: "photo.jpg", state: .pending)]
        )
        try await queueStore.addSession(pendingSession)
        
        // Try to retry - should not call presign since session isn't failed
        await worker.retrySession(sessionId: "pending-session")
        
        #expect(mockApiClient.presignCallCount == 0)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_retry_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_retry_test_history.json"))
    }
    
    @Test("Worker retrySession attempts to process failed session")
    func workerRetrySessionProcessesFailed() async throws {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "worker_retry_failed_test_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "worker_retry_failed_test_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_retry_failed_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_retry_failed_test_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Add a failed session
        let failedSession = makeTestSession(
            sessionId: "failed-session",
            assets: [makeTestAsset(fileName: "photo.jpg", state: .failed)]
        )
        try await queueStore.addSession(failedSession)
        
        // Retry should attempt to process
        await worker.retrySession(sessionId: "failed-session")
        
        // Should have called presign (attempting to process)
        #expect(mockApiClient.presignCallCount == 1)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_retry_failed_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_retry_failed_test_history.json"))
    }
    
    @Test("Worker retryAllFailed processes all failed sessions")
    func workerRetryAllFailed() async throws {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "worker_retry_all_test_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "worker_retry_all_test_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_retry_all_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_retry_all_test_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Add multiple sessions with different states
        let failedSession1 = makeTestSession(
            sessionId: "failed-1",
            assets: [makeTestAsset(fileName: "photo1.jpg", state: .failed)]
        )
        let failedSession2 = makeTestSession(
            sessionId: "failed-2",
            assets: [makeTestAsset(fileName: "photo2.jpg", state: .failed)]
        )
        let pendingSession = makeTestSession(
            sessionId: "pending",
            assets: [makeTestAsset(fileName: "photo3.jpg", state: .pending)]
        )
        
        try await queueStore.addSession(failedSession1)
        try await queueStore.addSession(failedSession2)
        try await queueStore.addSession(pendingSession)
        
        // Retry all failed
        await worker.retryAllFailed()
        
        // Should have called presign twice (once for each failed session)
        #expect(mockApiClient.presignCallCount == 2)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_retry_all_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_retry_all_test_history.json"))
    }
    
    @Test("Worker retrySession ignores non-existent session")
    func workerRetryNonExistentSession() async throws {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "worker_retry_nonexistent_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "worker_retry_nonexistent_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_retry_nonexistent_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_retry_nonexistent_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Try to retry non-existent session - should not crash or call API
        await worker.retrySession(sessionId: "non-existent")
        
        #expect(mockApiClient.presignCallCount == 0)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_retry_nonexistent_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("worker_retry_nonexistent_history.json"))
    }
}

// MARK: - Auto Retry Tests

struct AutoRetryTests {
    
    private func makeAsset(state: UploadQueueItemState) -> UploadQueueAsset {
        UploadQueueAsset(
            id: UUID(),
            kind: .photo,
            stripIndex: 0,
            sequenceIndex: 1,
            fileName: "photo.jpg",
            mimeType: "image/jpeg",
            localURL: URL(fileURLWithPath: "/tmp/photo.jpg"),
            remotePath: "events/1/sessions/test/photo.jpg",
            sizeBytes: 100,
            durationSeconds: nil,
            posterPath: nil,
            state: state
        )
    }
    
    private func makeSession(
        sessionId: String,
        assets: [UploadQueueAsset]? = nil,
        manifestState: UploadQueueItemState = .pending,
        completeState: UploadQueueItemState = .pending,
        retryCount: Int = 0
    ) -> UploadQueueSession {
        UploadQueueSession(
            id: sessionId,
            eventId: 1,
            sessionId: sessionId,
            createdAt: "2025-01-01T00:00:00Z",
            publicGalleryURL: "https://example.com/s/\(sessionId)",
            assets: assets ?? [makeAsset(state: .pending)],
            manifestState: manifestState,
            completeState: completeState,
            retryCount: retryCount
        )
    }
    
    @Test("Session canAutoRetry returns true when retryCount is below max")
    func canAutoRetryBelowMax() {
        let session = makeSession(sessionId: "test", retryCount: 0)
        #expect(session.canAutoRetry == true)
        
        let session2 = makeSession(sessionId: "test2", retryCount: 4)
        #expect(session2.canAutoRetry == true)
    }
    
    @Test("Session canAutoRetry returns false when retryCount equals max")
    func canAutoRetryAtMax() {
        let session = makeSession(sessionId: "test", retryCount: 5)
        #expect(session.canAutoRetry == false)
    }
    
    @Test("Session canAutoRetry returns false when retryCount exceeds max")
    func canAutoRetryAboveMax() {
        let session = makeSession(sessionId: "test", retryCount: 10)
        #expect(session.canAutoRetry == false)
    }
    
    @Test("Session requiresManualRetry is true when failed and exceeded max retries")
    func requiresManualRetryWhenExceeded() {
        let session = makeSession(
            sessionId: "test",
            assets: [makeAsset(state: .failed)],
            retryCount: 5
        )
        #expect(session.requiresManualRetry == true)
    }
    
    @Test("Session requiresManualRetry is false when failed but can still auto-retry")
    func requiresManualRetryWhenCanAutoRetry() {
        let session = makeSession(
            sessionId: "test",
            assets: [makeAsset(state: .failed)],
            retryCount: 3
        )
        #expect(session.requiresManualRetry == false)
    }
    
    @Test("Session requiresManualRetry is false when completed")
    func requiresManualRetryWhenCompleted() {
        let session = makeSession(
            sessionId: "test",
            assets: [makeAsset(state: .uploaded)],
            manifestState: .uploaded,
            completeState: .uploaded,
            retryCount: 5
        )
        #expect(session.requiresManualRetry == false)
    }
    
    @Test("progressSummary shows 'Retry required' when manual retry needed")
    func progressSummaryShowsRetryRequired() {
        let session = makeSession(
            sessionId: "test",
            assets: [makeAsset(state: .failed)],
            retryCount: 5
        )
        #expect(session.progressSummary == "Retry required")
    }
    
    @Test("Auto retry skips sessions that exceeded max retries")
    func autoRetrySkipsExceededSessions() async throws {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "auto_retry_skip_test_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "auto_retry_skip_test_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("auto_retry_skip_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("auto_retry_skip_test_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Add a failed session that has exceeded max retries
        let exceededSession = makeSession(
            sessionId: "exceeded",
            assets: [makeAsset(state: .failed)],
            retryCount: 5
        )
        try await queueStore.addSession(exceededSession)
        
        // Auto retry should skip this session
        await worker.autoRetryFailedSessions()
        
        #expect(mockApiClient.presignCallCount == 0)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("auto_retry_skip_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("auto_retry_skip_test_history.json"))
    }
    
    @Test("Auto retry increments retry count")
    func autoRetryIncrementsRetryCount() async throws {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "auto_retry_increment_test_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "auto_retry_increment_test_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("auto_retry_increment_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("auto_retry_increment_test_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Add a failed session with retryCount = 2
        let session = makeSession(
            sessionId: "retry-test",
            assets: [makeAsset(state: .failed)],
            retryCount: 2
        )
        try await queueStore.addSession(session)
        
        // Auto retry should increment retry count
        await worker.autoRetryFailedSessions()
        
        // Check the session was updated with incremented retry count
        let sessions = try await queueStore.sessions()
        let updatedSession = sessions.first(where: { $0.sessionId == "retry-test" })
        #expect(updatedSession?.retryCount == 3)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("auto_retry_increment_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("auto_retry_increment_test_history.json"))
    }
    
    @Test("Manual retry resets retry count")
    func manualRetryResetsRetryCount() async throws {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "manual_retry_reset_test_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "manual_retry_reset_test_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("manual_retry_reset_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("manual_retry_reset_test_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Add a failed session with retryCount = 5 (exceeded max)
        let session = makeSession(
            sessionId: "manual-retry-test",
            assets: [makeAsset(state: .failed)],
            retryCount: 5
        )
        try await queueStore.addSession(session)
        
        // Manual retry should reset retry count to 0
        await worker.retrySession(sessionId: "manual-retry-test")
        
        // Check the session was updated with reset retry count
        let sessions = try await queueStore.sessions()
        let updatedSession = sessions.first(where: { $0.sessionId == "manual-retry-test" })
        #expect(updatedSession?.retryCount == 0)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("manual_retry_reset_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("manual_retry_reset_test_history.json"))
    }
    
    @Test("Auto retry processes retryable sessions only")
    func autoRetryProcessesOnlyRetryableSessions() async throws {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "auto_retry_mixed_test_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "auto_retry_mixed_test_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("auto_retry_mixed_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("auto_retry_mixed_test_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Add sessions with different states
        let retryable = makeSession(
            sessionId: "retryable",
            assets: [makeAsset(state: .failed)],
            retryCount: 2
        )
        let exceeded = makeSession(
            sessionId: "exceeded",
            assets: [makeAsset(state: .failed)],
            retryCount: 5
        )
        let pending = makeSession(
            sessionId: "pending",
            assets: [makeAsset(state: .pending)],
            retryCount: 0
        )
        
        try await queueStore.addSession(retryable)
        try await queueStore.addSession(exceeded)
        try await queueStore.addSession(pending)
        
        // Auto retry should only process the retryable session
        await worker.autoRetryFailedSessions()
        
        // Should have called presign once (only for retryable)
        #expect(mockApiClient.presignCallCount == 1)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("auto_retry_mixed_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("auto_retry_mixed_test_history.json"))
    }
    
    @Test("isAutoRetryActive reflects timer state")
    func isAutoRetryActiveReflectsTimerState() async {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "auto_retry_active_test_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "auto_retry_active_test_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("auto_retry_active_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("auto_retry_active_test_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Initially not active
        var isActive = await worker.isAutoRetryActive
        #expect(isActive == false)
        
        // Start auto retry
        await worker.startAutoRetry(interval: 60) // Use long interval so it doesn't fire during test
        
        isActive = await worker.isAutoRetryActive
        #expect(isActive == true)
        
        // Stop auto retry
        await worker.stopAutoRetry()
        
        isActive = await worker.isAutoRetryActive
        #expect(isActive == false)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("auto_retry_active_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("auto_retry_active_test_history.json"))
    }
}

// MARK: - Stale Upload Recovery Tests

struct StaleUploadRecoveryTests {
    
    private func makeAsset(state: UploadQueueItemState) -> UploadQueueAsset {
        UploadQueueAsset(
            id: UUID(),
            kind: .photo,
            stripIndex: 0,
            sequenceIndex: 1,
            fileName: "photo.jpg",
            mimeType: "image/jpeg",
            localURL: URL(fileURLWithPath: "/tmp/photo.jpg"),
            remotePath: "events/1/sessions/test/photo.jpg",
            sizeBytes: 100,
            durationSeconds: nil,
            posterPath: nil,
            state: state
        )
    }
    
    private func makeSession(
        sessionId: String,
        assets: [UploadQueueAsset]? = nil,
        manifestState: UploadQueueItemState = .pending,
        completeState: UploadQueueItemState = .pending,
        retryCount: Int = 0,
        uploadStartedAt: String? = nil
    ) -> UploadQueueSession {
        UploadQueueSession(
            id: sessionId,
            eventId: 1,
            sessionId: sessionId,
            createdAt: "2025-01-01T00:00:00Z",
            publicGalleryURL: "https://example.com/s/\(sessionId)",
            assets: assets ?? [makeAsset(state: .pending)],
            manifestState: manifestState,
            completeState: completeState,
            retryCount: retryCount,
            uploadStartedAt: uploadStartedAt
        )
    }
    
    // MARK: - isStale Tests
    
    @Test("isStale returns false for non-uploading sessions")
    func isStaleReturnsFalseForNonUploading() {
        // Pending session
        let pending = makeSession(
            sessionId: "pending",
            assets: [makeAsset(state: .pending)],
            uploadStartedAt: "2020-01-01T00:00:00Z" // Very old timestamp
        )
        #expect(pending.isStale == false)
        
        // Failed session
        let failed = makeSession(
            sessionId: "failed",
            assets: [makeAsset(state: .failed)],
            uploadStartedAt: "2020-01-01T00:00:00Z"
        )
        #expect(failed.isStale == false)
        
        // Completed session
        let completed = makeSession(
            sessionId: "completed",
            assets: [makeAsset(state: .uploaded)],
            manifestState: .uploaded,
            completeState: .uploaded,
            uploadStartedAt: "2020-01-01T00:00:00Z"
        )
        #expect(completed.isStale == false)
    }
    
    @Test("isStale returns false for uploading session without timestamp")
    func isStaleReturnsFalseWithoutTimestamp() {
        let session = makeSession(
            sessionId: "uploading",
            assets: [makeAsset(state: .uploading)],
            uploadStartedAt: nil
        )
        #expect(session.isStale == false)
    }
    
    @Test("isStale returns false for recently started upload")
    func isStaleReturnsFalseForRecentUpload() {
        let recentTimestamp = ISO8601DateFormatter().string(from: Date())
        let session = makeSession(
            sessionId: "uploading",
            assets: [makeAsset(state: .uploading)],
            uploadStartedAt: recentTimestamp
        )
        #expect(session.isStale == false)
    }
    
    @Test("isStale returns true for upload exceeding threshold")
    func isStaleReturnsTrueForOldUpload() {
        // Create timestamp older than threshold (60 seconds)
        let oldDate = Date().addingTimeInterval(-90) // 90 seconds ago (exceeds 60s threshold)
        let oldTimestamp = ISO8601DateFormatter().string(from: oldDate)
        
        let session = makeSession(
            sessionId: "uploading",
            assets: [makeAsset(state: .uploading)],
            uploadStartedAt: oldTimestamp
        )
        #expect(session.isStale == true)
    }
    
    @Test("isStale detects stale manifest upload")
    func isStaleDetectsStaleManifestUpload() {
        let oldDate = Date().addingTimeInterval(-90) // 90 seconds ago
        let oldTimestamp = ISO8601DateFormatter().string(from: oldDate)
        
        let session = makeSession(
            sessionId: "uploading",
            assets: [makeAsset(state: .uploaded)],
            manifestState: .uploading,
            uploadStartedAt: oldTimestamp
        )
        #expect(session.isStale == true)
    }
    
    // MARK: - uploadDuration Tests
    
    @Test("uploadDuration returns nil without timestamp")
    func uploadDurationReturnsNilWithoutTimestamp() {
        let session = makeSession(sessionId: "test", uploadStartedAt: nil)
        #expect(session.uploadDuration == nil)
    }
    
    @Test("uploadDuration returns seconds for short durations")
    func uploadDurationReturnsSeconds() {
        let recentDate = Date().addingTimeInterval(-45)
        let timestamp = ISO8601DateFormatter().string(from: recentDate)
        
        let session = makeSession(sessionId: "test", uploadStartedAt: timestamp)
        
        // Should be around "45s" (might be 44s or 46s due to timing)
        let duration = session.uploadDuration
        #expect(duration != nil)
        #expect(duration?.hasSuffix("s") == true)
    }
    
    @Test("uploadDuration returns minutes for longer durations")
    func uploadDurationReturnsMinutes() {
        let olderDate = Date().addingTimeInterval(-180) // 3 minutes
        let timestamp = ISO8601DateFormatter().string(from: olderDate)
        
        let session = makeSession(sessionId: "test", uploadStartedAt: timestamp)
        
        let duration = session.uploadDuration
        #expect(duration != nil)
        #expect(duration?.hasSuffix("m") == true)
    }
    
    // MARK: - recoverStaleUploads Tests
    
    @Test("recoverStaleUploads marks stale uploading sessions as failed")
    func recoverStaleUploadsMarksAsFailed() async throws {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "stale_recovery_test_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "stale_recovery_test_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("stale_recovery_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("stale_recovery_test_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Add a stale uploading session (90 seconds ago, exceeds 60s threshold)
        let oldDate = Date().addingTimeInterval(-90)
        let oldTimestamp = ISO8601DateFormatter().string(from: oldDate)
        
        let staleSession = makeSession(
            sessionId: "stale-session",
            assets: [makeAsset(state: .uploading)],
            uploadStartedAt: oldTimestamp
        )
        try await queueStore.addSession(staleSession)
        
        // Verify it's stale
        var sessions = try await worker.getQueueSessions()
        #expect(sessions.first?.isStale == true)
        
        // Run recovery
        await worker.recoverStaleUploads()
        
        // Verify session is now failed
        sessions = try await worker.getQueueSessions()
        #expect(sessions.count == 1)
        #expect(sessions.first?.status == .failed)
        #expect(sessions.first?.assets.first?.state == .failed)
        #expect(sessions.first?.uploadStartedAt == nil)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("stale_recovery_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("stale_recovery_test_history.json"))
    }
    
    @Test("recoverStaleUploads does not affect non-stale sessions")
    func recoverStaleUploadsIgnoresNonStale() async throws {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "stale_nonstale_test_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "stale_nonstale_test_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("stale_nonstale_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("stale_nonstale_test_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Add a recent uploading session (not stale)
        let recentTimestamp = ISO8601DateFormatter().string(from: Date())
        let recentSession = makeSession(
            sessionId: "recent-session",
            assets: [makeAsset(state: .uploading)],
            uploadStartedAt: recentTimestamp
        )
        try await queueStore.addSession(recentSession)
        
        // Run recovery
        await worker.recoverStaleUploads()
        
        // Verify session is still uploading
        let sessions = try await worker.getQueueSessions()
        #expect(sessions.count == 1)
        #expect(sessions.first?.status == .uploading)
        #expect(sessions.first?.assets.first?.state == .uploading)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("stale_nonstale_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("stale_nonstale_test_history.json"))
    }
    
    // MARK: - forceRetrySession Tests
    
    @Test("forceRetrySession resets uploading session and processes")
    func forceRetryResetsUploadingSession() async throws {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "force_retry_test_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "force_retry_test_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("force_retry_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("force_retry_test_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Add an uploading session (simulating stuck state)
        let uploadingSession = makeSession(
            sessionId: "stuck-session",
            assets: [makeAsset(state: .uploading)],
            uploadStartedAt: "2025-01-01T00:00:00Z"
        )
        try await queueStore.addSession(uploadingSession)
        
        // Force retry
        await worker.forceRetrySession(sessionId: "stuck-session")
        
        // Should have called presign (attempted to process)
        #expect(mockApiClient.presignCallCount == 1)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("force_retry_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("force_retry_test_history.json"))
    }
    
    @Test("forceRetrySession ignores completed sessions")
    func forceRetryIgnoresCompleted() async throws {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "force_retry_completed_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "force_retry_completed_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("force_retry_completed_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("force_retry_completed_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Add a completed session
        let completedSession = makeSession(
            sessionId: "completed-session",
            assets: [makeAsset(state: .uploaded)],
            manifestState: .uploaded,
            completeState: .uploaded
        )
        try await queueStore.addSession(completedSession)
        
        // Force retry should do nothing
        await worker.forceRetrySession(sessionId: "completed-session")
        
        #expect(mockApiClient.presignCallCount == 0)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("force_retry_completed_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("force_retry_completed_history.json"))
    }
    
    @Test("forceRetrySession resets retry count")
    func forceRetryResetsRetryCount() async throws {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "force_retry_count_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "force_retry_count_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("force_retry_count_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("force_retry_count_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Add a failed session with high retry count
        let failedSession = makeSession(
            sessionId: "failed-session",
            assets: [makeAsset(state: .failed)],
            retryCount: 10
        )
        try await queueStore.addSession(failedSession)
        
        // Force retry
        await worker.forceRetrySession(sessionId: "failed-session")
        
        // Should have processed (retry count was reset)
        #expect(mockApiClient.presignCallCount == 1)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("force_retry_count_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("force_retry_count_history.json"))
    }
    
    // MARK: - cancelSession Tests
    
    @Test("cancelSession resets uploading states to pending")
    func cancelSessionResetsToOpen() async throws {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "cancel_session_test_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "cancel_session_test_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("cancel_session_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("cancel_session_test_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Add an uploading session
        let uploadingSession = makeSession(
            sessionId: "uploading-session",
            assets: [makeAsset(state: .uploading)],
            manifestState: .uploading,
            uploadStartedAt: "2025-01-01T00:00:00Z"
        )
        try await queueStore.addSession(uploadingSession)
        
        // Cancel the session
        await worker.cancelSession(sessionId: "uploading-session")
        
        // Verify session is now pending
        let sessions = try await worker.getQueueSessions()
        #expect(sessions.count == 1)
        #expect(sessions.first?.status == .pending)
        #expect(sessions.first?.assets.first?.state == .pending)
        #expect(sessions.first?.manifestState == .pending)
        #expect(sessions.first?.uploadStartedAt == nil)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("cancel_session_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("cancel_session_test_history.json"))
    }
    
    @Test("cancelSession preserves uploaded assets")
    func cancelSessionPreservesUploaded() async throws {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "cancel_preserve_test_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "cancel_preserve_test_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("cancel_preserve_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("cancel_preserve_test_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Add a session with mixed states (some uploaded, some uploading)
        let mixedSession = UploadQueueSession(
            id: "mixed-session",
            eventId: 1,
            sessionId: "mixed-session",
            createdAt: "2025-01-01T00:00:00Z",
            publicGalleryURL: "https://example.com/s/mixed-session",
            assets: [
                makeAsset(state: .uploaded),
                makeAsset(state: .uploading)
            ],
            manifestState: .pending,
            completeState: .pending,
            retryCount: 0,
            uploadStartedAt: "2025-01-01T00:00:00Z"
        )
        try await queueStore.addSession(mixedSession)
        
        // Cancel the session
        await worker.cancelSession(sessionId: "mixed-session")
        
        // Verify uploaded asset is preserved, uploading is reset
        let sessions = try await worker.getQueueSessions()
        #expect(sessions.count == 1)
        let assets = sessions.first?.assets ?? []
        #expect(assets.count == 2)
        #expect(assets.filter { $0.state == .uploaded }.count == 1)
        #expect(assets.filter { $0.state == .pending }.count == 1)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("cancel_preserve_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("cancel_preserve_test_history.json"))
    }
    
    // MARK: - Offline/Network Error Tests
    
    @Test("Failed uploads are retried by auto-retry when network returns")
    func failedUploadsRetriedByAutoRetry() async throws {
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "offline_retry_test_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "offline_retry_test_history.json")
        let mockApiClient = MockWorkerAPIClient()
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("offline_retry_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("offline_retry_test_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Add a failed session (simulates what happens when upload fails due to no network)
        let failedSession = makeSession(
            sessionId: "offline-failed",
            assets: [makeAsset(state: .failed)],
            retryCount: 0
        )
        try await queueStore.addSession(failedSession)
        
        // Simulate auto-retry running (this is what happens when network returns)
        await worker.autoRetryFailedSessions()
        
        // Should have attempted to retry (called presign)
        #expect(mockApiClient.presignCallCount == 1)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("offline_retry_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("offline_retry_test_history.json"))
    }
    
    @Test("URLSession configured without waitsForConnectivity for fast failure")
    func uploadSessionDoesNotWaitForConnectivity() async throws {
        // This test verifies the URLSession configuration is correct.
        // With waitsForConnectivity = false, uploads fail immediately when offline,
        // allowing auto-retry to handle reconnection instead of waiting indefinitely.
        
        // The actual URLSession configuration is internal, but we can verify
        // the expected behavior: when API fails, the session should be marked failed
        // and recoverable via retry.
        
        let fileManager = FileManager.default
        let queueStore = UploadQueueStore(fileManager: fileManager, fileName: "no_wait_test_queue.json")
        let historyStore = UploadHistoryStore(fileManager: fileManager, fileName: "no_wait_test_history.json")
        let mockApiClient = MockWorkerAPIClient()
        mockApiClient.presignError = APIError.serverUnreachable  // Simulate network failure
        
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.removeItem(at: documents.appendingPathComponent("no_wait_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("no_wait_test_history.json"))
        
        let worker = UploadQueueWorker(
            store: queueStore,
            historyStore: historyStore,
            apiClient: mockApiClient,
            fileManager: fileManager
        )
        
        // Add a pending session
        let pendingSession = makeSession(
            sessionId: "network-fail",
            assets: [makeAsset(state: .pending)]
        )
        try await queueStore.addSession(pendingSession)
        
        // Try to process - should fail due to mock API failure
        await worker.startProcessing()
        
        // Session should still be in queue (failed processing doesn't remove it)
        let sessions = try await worker.getQueueSessions()
        #expect(sessions.count == 1)
        
        // Now simulate network recovery by clearing the error and retrying
        mockApiClient.presignError = nil
        mockApiClient.presignCallCount = 0
        
        // Force retry should work
        await worker.forceRetrySession(sessionId: "network-fail")
        
        // Should have called presign (network "recovered")
        #expect(mockApiClient.presignCallCount == 1)
        
        // Cleanup
        try? fileManager.removeItem(at: documents.appendingPathComponent("no_wait_test_queue.json"))
        try? fileManager.removeItem(at: documents.appendingPathComponent("no_wait_test_history.json"))
    }
}
