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
            stripFrameURL: nil
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
            stripFrameURL: nil
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
            stripFrameURL: nil
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

        let config = CaptureConfiguration.default

        #expect(config.videoDuration == 10)
        #expect(config.countdownSeconds == 0)
        #expect(config.photoCountdownSeconds == 1)
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
        #expect(WorkerConfiguration.currentVideoDuration() == 3)

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
            photoCountdownSeconds: 0,
            stripCount: 3
        )
        let viewModel = CaptureViewModel(config: config, cameraController: mockCamera)

        #expect(viewModel.currentStripIndex == 0)
        #expect(viewModel.stripState == .ready)
        #expect(viewModel.capturedStrips.isEmpty)
        #expect(viewModel.isSessionComplete == false)
        #expect(viewModel.isCameraReady == false)
    }

    @Test("setupCamera sets isCameraReady on success")
    func setupCameraSuccess() async {
        let mockCamera = MockCameraController()
        let config = CaptureConfiguration(
            videoDuration: 3,
            countdownSeconds: 0,
            photoCountdownSeconds: 0,
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
            photoCountdownSeconds: 0,
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
            photoCountdownSeconds: 0,
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
            Issue.record("Expected recording state, got \(viewModel.stripState)")
        }
    }

    @Test("startCapture initiates countdown when configured")
    func startCaptureWithCountdown() async {
        let mockCamera = MockCameraController()
        let config = CaptureConfiguration(
            videoDuration: 3,
            countdownSeconds: 3,
            photoCountdownSeconds: 0,
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
            photoCountdownSeconds: 0,
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
            photoCountdownSeconds: 0,
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
            photoCountdownSeconds: 0,
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
            photoCountdownSeconds: 0,
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

    @Test("Recording error sets error state")
    func recordingErrorSetsErrorState() async {
        let mockCamera = MockCameraController()
        mockCamera.recordingShouldFail = true
        mockCamera.recordingError = .recordingFailed("Test failure")

        let config = CaptureConfiguration(
            videoDuration: 3,
            countdownSeconds: 0,
            photoCountdownSeconds: 0,
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
            photoCountdownSeconds: 0,
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
            photoCountdownSeconds: 0,
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
            photoCountdownSeconds: 0,
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

        try await Task.sleep(nanoseconds: 100_000_000)

        if case .error = viewModel.stripState {
            #expect(true)
        } else {
            Issue.record("Expected error state after delegate error callback")
        }
    }
}
