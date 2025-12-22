//
//  fotoXTests.swift
//  fotoXTests
//
//  Unit tests for FotoX models, services, and view models
//

import Testing
import Foundation
import SwiftUI
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

struct CaptureStateTests {
    
    @Test("Default capture configuration has correct values")
    func defaultCaptureConfig() {
        let config = CaptureConfiguration.default
        
        #expect(config.videoDuration == 10)
        #expect(config.countdownSeconds == 0)
        #expect(config.photoCountdownSeconds == 1)
        #expect(config.stripCount == 3)
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

@MainActor
struct SettingsViewModelTests {
    
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
}
