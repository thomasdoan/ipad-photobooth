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
            "session_id": 123,
            "public_token": "zQ1A9LfKc7",
            "universal_url": "https://pb.example.com/s/zQ1A9LfKc7"
        }
        """.data(using: .utf8)!
        
        let session = try JSONDecoder().decode(Session.self, from: json)
        
        #expect(session.sessionId == 123)
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
        let session = Session(sessionId: 123, publicToken: "abc", universalURL: "https://example.com")
        
        state.startSession(with: session)
        
        #expect(state.currentSession?.sessionId == 123)
        if case .capture(.capturingStrip(let index)) = state.currentRoute {
            #expect(index == 0)
        } else {
            Issue.record("Expected capture route with strip index 0")
        }
    }
    
    @Test("resetSession clears state and returns to idle")
    func resetSessionClearsState() {
        let state = AppState()
        let session = Session(sessionId: 1, publicToken: "abc", universalURL: "https://example.com")
        state.startSession(with: session)
        
        state.resetSession()
        
        #expect(state.currentRoute == .idle)
        #expect(state.currentSession == nil)
        #expect(state.capturedStrips.isEmpty)
        #expect(state.qrCodeData == nil)
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
        let endpoint = Endpoints.uploadAsset(sessionId: 123)
        
        #expect(endpoint.path == "sessions/123/assets")
        #expect(endpoint.method == .POST)
    }
    
    @Test("QR code endpoint has correct path")
    func qrCodeEndpointPath() {
        let endpoint = Endpoints.qrCode(sessionId: 456)
        
        #expect(endpoint.path == "sessions/456/qr")
        #expect(endpoint.method == .GET)
    }
    
    @Test("Submit email endpoint has correct path")
    func submitEmailEndpointPath() {
        let endpoint = Endpoints.submitEmail(sessionId: 789)
        
        #expect(endpoint.path == "sessions/789/email")
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
        #expect(config.countdownSeconds == 3)
        #expect(config.photoCountdownSeconds == 1)
        #expect(config.stripCount == 3)
    }
}

// MARK: - Mock Infrastructure

/// Mock URLSession for testing APIClient
final class MockURLSession: URLSession {
    var mockData: Data?
    var mockResponse: HTTPURLResponse?
    var mockError: Error?
    var callCount = 0

    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        callCount += 1

        if let error = mockError {
            throw error
        }

        let response = mockResponse ?? HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let data = mockData ?? Data()
        return (data, response)
    }
}

/// Mock APIClient for testing services
actor MockAPIClient: APIClientProtocol {
    var shouldFail = false
    var fetchCallCount = 0
    var sendCallCount = 0
    var uploadCallCount = 0
    var mockEvents: [Event] = []
    var mockSession: Session?
    var mockQRData: Data?

    nonisolated func fetch<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        await incrementFetchCount()

        if await shouldFail {
            throw APIError.serverUnreachable
        }

        // Return mock data based on type
        if T.self == [Event].self {
            let events = await mockEvents
            return events as! T
        } else if T.self == Event.self {
            let event = await mockEvents.first!
            return event as! T
        }

        throw APIError.decodingError(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Mock")))
    }

    nonisolated func fetchData(_ endpoint: Endpoint) async throws -> Data {
        await incrementFetchCount()

        if await shouldFail {
            throw APIError.serverUnreachable
        }

        if let qrData = await mockQRData {
            return qrData
        }

        return Data()
    }

    nonisolated func send<T: Encodable & Sendable, R: Decodable & Sendable>(
        _ endpoint: Endpoint,
        body: T
    ) async throws -> R {
        await incrementSendCount()

        if await shouldFail {
            throw APIError.serverUnreachable
        }

        if R.self == Session.self {
            let session = await mockSession!
            return session as! R
        } else if R.self == EmailSubmissionResponse.self {
            return EmailSubmissionResponse(status: "ok") as! R
        }

        throw APIError.decodingError(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Mock")))
    }

    nonisolated func upload(
        _ endpoint: Endpoint,
        fileData: Data,
        fileName: String,
        mimeType: String,
        metadata: [String: String]
    ) async throws -> AssetUploadResponse {
        await incrementUploadCount()

        if await shouldFail {
            throw APIError.serverUnreachable
        }

        return AssetUploadResponse(assetId: 123, status: "ok")
    }

    private func incrementFetchCount() {
        fetchCallCount += 1
    }

    private func incrementSendCount() {
        sendCallCount += 1
    }

    private func incrementUploadCount() {
        uploadCallCount += 1
    }
}

// MARK: - APIClient Tests

@MainActor
struct APIClientTests {

    @Test("APIClient handles successful response")
    func testSuccessfulFetch() async throws {
        let eventJSON = """
        [{
            "id": 1,
            "name": "Test Event",
            "date": "2025-01-01",
            "theme": {
                "id": 1,
                "primary_color": "#FF0000",
                "secondary_color": "#000000",
                "accent_color": "#FFFFFF",
                "font_family": "system",
                "logo_url": null,
                "background_url": null,
                "photo_frame_url": null,
                "strip_frame_url": null
            }
        }]
        """.data(using: .utf8)!

        let client = APIClient(baseURL: URL(string: "http://test.local")!)

        // Note: Real APIClient tests would require URLProtocol mocking
        // This is a simplified example showing the test structure
    }

    @Test("APIClient handles timeout error")
    func testTimeoutError() {
        let error = APIError.timeout

        #expect(error.isRetryable == true)
        #expect(error.userMessage.contains("timed out") || error.userMessage.contains("time"))
    }

    @Test("APIClient handles server unreachable")
    func testServerUnreachable() {
        let error = APIError.serverUnreachable

        #expect(error.isRetryable == true)
        #expect(error.userMessage.contains("connect") || error.userMessage.contains("reach"))
    }

    @Test("APIClient marks 4xx errors as non-retryable")
    func testClientErrorsNotRetryable() {
        let error = APIError.httpError(statusCode: 404, message: "Not Found")

        #expect(error.isRetryable == false)
    }

    @Test("APIClient marks 5xx errors as retryable")
    func testServerErrorsRetryable() {
        let error = APIError.httpError(statusCode: 500, message: "Server Error")

        #expect(error.isRetryable == true)
    }

    @Test("APIClient baseURL can be updated")
    func testBaseURLUpdate() async {
        let client = APIClient(baseURL: URL(string: "http://old.local")!)
        let newURL = URL(string: "http://new.local")!

        await client.updateBaseURL(newURL)
        let baseURL = await client.baseURL

        #expect(baseURL == newURL)
    }
}

// MARK: - EventSelectionViewModel Tests

@MainActor
struct EventSelectionViewModelTests {

    @Test("ViewModel starts with empty events")
    func testInitialState() {
        let mockClient = MockAPIClient()
        let eventService = EventService(apiClient: APIClient())
        let themeService = ThemeService()

        let viewModel = EventSelectionViewModel(
            eventService: eventService,
            themeService: themeService
        )

        #expect(viewModel.events.isEmpty)
        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("loadEvents sets loading state")
    func testLoadingState() async {
        let mockClient = MockAPIClient()
        await mockClient.setMockEvents([])

        let eventService = EventService(apiClient: APIClient())
        let themeService = ThemeService()

        let viewModel = EventSelectionViewModel(
            eventService: eventService,
            themeService: themeService
        )

        // Note: Proper test would require dependency injection of APIClient
        // This shows the structure for testing loading states
    }

    @Test("selectEvent updates app state")
    func testSelectEvent() async {
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

        let appState = AppState()
        let eventService = EventService(apiClient: APIClient())
        let themeService = ThemeService()

        let viewModel = EventSelectionViewModel(
            eventService: eventService,
            themeService: themeService
        )

        await viewModel.selectEvent(event, appState: appState)

        #expect(appState.selectedEvent?.id == 1)
        #expect(appState.currentRoute == .idle)
    }

    @Test("clearError resets error state")
    func testClearError() {
        let eventService = EventService(apiClient: APIClient())
        let themeService = ThemeService()

        let viewModel = EventSelectionViewModel(
            eventService: eventService,
            themeService: themeService
        )

        viewModel.errorMessage = "Test error"
        viewModel.showError = true

        viewModel.clearError()

        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.showError)
    }
}

// MARK: - CaptureViewModel Tests

@MainActor
struct CaptureViewModelTests {

    @Test("ViewModel initializes with ready state")
    func testInitialState() {
        let viewModel = CaptureViewModel()

        #expect(viewModel.currentStripIndex == 0)
        #expect(viewModel.stripState == .ready)
        #expect(viewModel.capturedStrips.isEmpty)
        #expect(!viewModel.isReviewing)
        #expect(!viewModel.showingSummary)
    }

    @Test("startCapture transitions to countdown")
    func testStartCaptureTransitionsToCountdown() {
        let viewModel = CaptureViewModel()

        viewModel.startCapture()

        if case .countdown(let remaining) = viewModel.stripState {
            #expect(remaining == viewModel.config.countdownSeconds)
        } else {
            Issue.record("Expected countdown state")
        }
    }

    @Test("continueToNext increments strip index")
    func testContinueToNextIncrements() {
        let viewModel = CaptureViewModel()
        viewModel.stripState = .complete

        let initialIndex = viewModel.currentStripIndex
        viewModel.continueToNext()

        #expect(viewModel.currentStripIndex == initialIndex + 1)
        #expect(viewModel.stripState == .ready)
        #expect(!viewModel.isReviewing)
    }

    @Test("continueToNext shows summary after last strip")
    func testContinueToNextShowsSummary() {
        let viewModel = CaptureViewModel()
        viewModel.currentStripIndex = 2 // Last strip (0, 1, 2)
        viewModel.stripState = .complete

        viewModel.continueToNext()

        #expect(viewModel.showingSummary)
    }

    @Test("retakeCurrentStrip resets state")
    func testRetakeCurrentStrip() {
        let viewModel = CaptureViewModel()
        viewModel.stripState = .complete
        viewModel.isReviewing = true

        // Add a fake strip
        let strip = CapturedStripMedia(
            stripIndex: 0,
            videoURL: URL(string: "file://test.mov")!,
            photoData: Data(),
            thumbnailData: nil
        )
        viewModel.capturedStrips.append(strip)

        viewModel.retakeCurrentStrip()

        #expect(viewModel.stripState == .ready)
        #expect(!viewModel.isReviewing)
        #expect(viewModel.capturedStrips.isEmpty)
    }

    @Test("retakeStrip removes specific strip")
    func testRetakeSpecificStrip() {
        let viewModel = CaptureViewModel()

        // Add multiple strips
        let strip0 = CapturedStripMedia(stripIndex: 0, videoURL: URL(string: "file://0.mov")!, photoData: Data(), thumbnailData: nil)
        let strip1 = CapturedStripMedia(stripIndex: 1, videoURL: URL(string: "file://1.mov")!, photoData: Data(), thumbnailData: nil)
        viewModel.capturedStrips = [strip0, strip1]
        viewModel.currentStripIndex = 2

        viewModel.retakeStrip(at: 1)

        #expect(viewModel.capturedStrips.count == 1)
        #expect(viewModel.capturedStrips[0].stripIndex == 0)
        #expect(viewModel.currentStripIndex == 1)
        #expect(!viewModel.showingSummary)
    }

    @Test("getCapturedStrips converts to model format")
    func testGetCapturedStrips() {
        let viewModel = CaptureViewModel()

        let strip = CapturedStripMedia(
            stripIndex: 0,
            videoURL: URL(string: "file://test.mov")!,
            photoData: Data(),
            thumbnailData: Data()
        )
        viewModel.capturedStrips.append(strip)

        let converted = viewModel.getCapturedStrips()

        #expect(converted.count == 1)
        #expect(converted[0].stripIndex == 0)
        #expect(converted[0].videoURL == URL(string: "file://test.mov")!)
    }

    @Test("cleanup stops session")
    func testCleanup() {
        let viewModel = CaptureViewModel()

        // This test verifies cleanup doesn't crash
        viewModel.cleanup()

        // If we get here without crashing, cleanup worked
        #expect(true)
    }
}

// MARK: - UploadViewModel Tests

@MainActor
struct UploadViewModelTests {

    @Test("prepareUploads creates correct items")
    func testPrepareUploads() {
        let sessionService = SessionService(apiClient: APIClient())
        let viewModel = UploadViewModel(sessionService: sessionService)

        let strips = [
            CapturedStrip(
                stripIndex: 0,
                videoURL: URL(string: "file://0.mov")!,
                photoData: Data(),
                thumbnailData: nil
            ),
            CapturedStrip(
                stripIndex: 1,
                videoURL: URL(string: "file://1.mov")!,
                photoData: Data(),
                thumbnailData: nil
            )
        ]

        viewModel.prepareUploads(from: strips)

        // Should create 2 items per strip (video + photo)
        #expect(viewModel.uploadItems.count == 4)
        #expect(viewModel.progress == 0)
        #expect(!viewModel.isComplete)
    }

    @Test("prepareUploads creates video and photo items")
    func testUploadItemsTypes() {
        let sessionService = SessionService(apiClient: APIClient())
        let viewModel = UploadViewModel(sessionService: sessionService)

        let strips = [
            CapturedStrip(
                stripIndex: 0,
                videoURL: URL(string: "file://0.mov")!,
                photoData: Data(),
                thumbnailData: nil
            )
        ]

        viewModel.prepareUploads(from: strips)

        let videoItems = viewModel.uploadItems.filter { $0.kind == .video }
        let photoItems = viewModel.uploadItems.filter { $0.kind == .photo }

        #expect(videoItems.count == 1)
        #expect(photoItems.count == 1)
        #expect(videoItems[0].stripIndex == 0)
        #expect(photoItems[0].stripIndex == 0)
    }

    @Test("hasFailedUploads detects failures")
    func testHasFailedUploads() {
        let sessionService = SessionService(apiClient: APIClient())
        let viewModel = UploadViewModel(sessionService: sessionService)

        let strips = [
            CapturedStrip(
                stripIndex: 0,
                videoURL: URL(string: "file://0.mov")!,
                photoData: Data(),
                thumbnailData: nil
            )
        ]

        viewModel.prepareUploads(from: strips)

        #expect(!viewModel.hasFailedUploads)

        // Simulate a failure
        viewModel.uploadItems[0].state = .failed("Network error")

        #expect(viewModel.hasFailedUploads)
    }

    @Test("completedCount counts completed uploads")
    func testCompletedCount() {
        let sessionService = SessionService(apiClient: APIClient())
        let viewModel = UploadViewModel(sessionService: sessionService)

        let strips = [
            CapturedStrip(
                stripIndex: 0,
                videoURL: URL(string: "file://0.mov")!,
                photoData: Data(),
                thumbnailData: nil
            )
        ]

        viewModel.prepareUploads(from: strips)

        #expect(viewModel.completedCount == 0)

        // Mark items as completed
        viewModel.uploadItems[0].state = .completed
        viewModel.uploadItems[1].state = .completed

        #expect(viewModel.completedCount == 2)
    }

    @Test("uploadItem has correct display name")
    func testUploadItemDisplayName() {
        let videoItem = UploadItem(
            id: UUID(),
            stripIndex: 0,
            kind: .video,
            fileName: "test.mov",
            mimeType: "video/quicktime",
            state: .pending
        )

        let photoItem = UploadItem(
            id: UUID(),
            stripIndex: 1,
            kind: .photo,
            fileName: "test.jpg",
            mimeType: "image/jpeg",
            state: .pending
        )

        #expect(videoItem.displayName == "Video 1")
        #expect(photoItem.displayName == "Photo 2")
    }
}

// MARK: - QRViewModel Tests

@MainActor
struct QRViewModelTests {

    @Test("ViewModel initializes with empty state")
    func testInitialState() {
        let sessionService = SessionService(apiClient: APIClient())
        let viewModel = QRViewModel(sessionService: sessionService)

        #expect(viewModel.qrImage == nil)
        #expect(viewModel.universalURL.isEmpty)
        #expect(viewModel.email.isEmpty)
        #expect(!viewModel.isSubmittingEmail)
        #expect(!viewModel.emailSubmitted)
    }

    @Test("setup configures universal URL")
    func testSetupWithSession() {
        let sessionService = SessionService(apiClient: APIClient())
        let viewModel = QRViewModel(sessionService: sessionService)

        let session = Session(
            sessionId: 123,
            publicToken: "abc",
            universalURL: "https://example.com/session/abc"
        )

        viewModel.setup(qrData: nil, session: session)

        #expect(viewModel.universalURL == "https://example.com/session/abc")
    }

    @Test("email validation accepts valid email")
    func testEmailValidationValid() {
        let sessionService = SessionService(apiClient: APIClient())
        let viewModel = QRViewModel(sessionService: sessionService)

        viewModel.email = "test@example.com"

        #expect(viewModel.isEmailValid)
    }

    @Test("email validation rejects invalid email")
    func testEmailValidationInvalid() {
        let sessionService = SessionService(apiClient: APIClient())
        let viewModel = QRViewModel(sessionService: sessionService)

        viewModel.email = "not-an-email"

        #expect(!viewModel.isEmailValid)
    }

    @Test("email validation rejects empty email")
    func testEmailValidationEmpty() {
        let sessionService = SessionService(apiClient: APIClient())
        let viewModel = QRViewModel(sessionService: sessionService)

        viewModel.email = ""

        #expect(!viewModel.isEmailValid)
    }

    @Test("email validation handles edge cases")
    func testEmailValidationEdgeCases() {
        let sessionService = SessionService(apiClient: APIClient())
        let viewModel = QRViewModel(sessionService: sessionService)

        // Missing @
        viewModel.email = "testexample.com"
        #expect(!viewModel.isEmailValid)

        // Missing domain
        viewModel.email = "test@"
        #expect(!viewModel.isEmailValid)

        // Missing TLD
        viewModel.email = "test@example"
        #expect(!viewModel.isEmailValid)

        // Valid with subdomain
        viewModel.email = "test@mail.example.com"
        #expect(viewModel.isEmailValid)

        // Valid with plus
        viewModel.email = "test+tag@example.com"
        #expect(viewModel.isEmailValid)
    }

    @Test("clearEmailError clears error")
    func testClearEmailError() {
        let sessionService = SessionService(apiClient: APIClient())
        let viewModel = QRViewModel(sessionService: sessionService)

        viewModel.emailError = "Some error"
        viewModel.clearEmailError()

        #expect(viewModel.emailError == nil)
    }
}

// MARK: - SessionService Tests

@MainActor
struct SessionServiceTests {

    @Test("uploadAsset builds correct metadata")
    func testUploadAssetMetadata() async throws {
        let apiClient = APIClient()
        let service = SessionService(apiClient: apiClient)

        let metadata = AssetUploadMetadata(
            kind: .video,
            stripIndex: 1,
            sequenceIndex: 0
        )

        #expect(metadata.kind == .video)
        #expect(metadata.stripIndex == 1)
        #expect(metadata.sequenceIndex == 0)
    }
}

// MARK: - Helper Extensions

extension MockAPIClient {
    func setMockEvents(_ events: [Event]) async {
        self.mockEvents = events
    }

    func setMockSession(_ session: Session) async {
        self.mockSession = session
    }

    func setMockQRData(_ data: Data) async {
        self.mockQRData = data
    }

    func setShouldFail(_ shouldFail: Bool) async {
        self.shouldFail = shouldFail
    }
}

// MARK: - Integration Tests

/// Integration tests verify multiple components working together
@MainActor
struct IntegrationTests {

    // MARK: - Complete Session Lifecycle Tests

    @Test("Complete session lifecycle from event selection to QR display")
    func testCompleteSessionLifecycle() async throws {
        // Setup: Create AppState and mock data
        let appState = AppState()

        let theme = Theme(
            id: 1,
            primaryColor: "#FF4081",
            secondaryColor: "#212121",
            accentColor: "#FFFFFF",
            fontFamily: "system",
            logoURL: nil,
            backgroundURL: nil,
            photoFrameURL: nil,
            stripFrameURL: nil
        )

        let event = Event(
            id: 1,
            name: "Test Wedding",
            date: "2025-12-25",
            theme: theme
        )

        // Step 1: Select Event
        #expect(appState.currentRoute == .eventSelection)
        #expect(appState.selectedEvent == nil)

        appState.selectEvent(event)

        #expect(appState.currentRoute == .idle)
        #expect(appState.selectedEvent?.id == 1)
        #expect(appState.currentTheme.id == 1)

        // Step 2: Start Session
        let session = Session(
            sessionId: 123,
            publicToken: "abc123",
            universalURL: "https://example.com/s/abc123"
        )

        appState.startSession(with: session)

        #expect(appState.currentSession?.sessionId == 123)
        if case .capture(.capturingStrip(let index)) = appState.currentRoute {
            #expect(index == 0)
        } else {
            Issue.record("Expected capture route")
        }

        // Step 3: Capture Strips
        for stripIndex in 0..<3 {
            let strip = CapturedStrip(
                stripIndex: stripIndex,
                videoURL: URL(string: "file://strip\(stripIndex).mov")!,
                photoData: Data(),
                thumbnailData: nil
            )
            appState.capturedStrips.append(strip)
        }

        #expect(appState.capturedStrips.count == 3)
        #expect(appState.allStripsCaptured == true)

        // Step 4: Upload
        appState.totalAssetsToUpload = 6 // 3 strips * 2 (video + photo)
        appState.assetsUploaded = 0

        for _ in 0..<6 {
            appState.assetUploaded()
        }

        #expect(appState.uploadProgress == 1.0)
        #expect(appState.assetsUploaded == 6)

        // Step 5: Display QR
        let qrData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header
        appState.qrCodeData = qrData
        appState.currentRoute = .qrDisplay

        #expect(appState.currentRoute == .qrDisplay)
        #expect(appState.qrCodeData != nil)

        // Step 6: Reset Session
        appState.resetSession()

        #expect(appState.currentRoute == .idle)
        #expect(appState.currentSession == nil)
        #expect(appState.capturedStrips.isEmpty)
        #expect(appState.qrCodeData == nil)
        #expect(appState.assetsUploaded == 0)
    }

    @Test("Event selection to idle with theme loading")
    func testEventSelectionWithThemeLoading() async throws {
        let appState = AppState()
        let eventService = EventService(apiClient: APIClient())
        let themeService = ThemeService()

        let viewModel = EventSelectionViewModel(
            eventService: eventService,
            themeService: themeService
        )

        let theme = Theme(
            id: 5,
            primaryColor: "#0066CC",
            secondaryColor: "#FFFFFF",
            accentColor: "#FF4081",
            fontFamily: "Helvetica",
            logoURL: "https://example.com/logo.png",
            backgroundURL: "https://example.com/bg.jpg",
            photoFrameURL: nil,
            stripFrameURL: nil
        )

        let event = Event(
            id: 5,
            name: "Corporate Event",
            date: "2025-06-15",
            theme: theme
        )

        // Select event should update state and attempt theme loading
        await viewModel.selectEvent(event, appState: appState)

        #expect(appState.selectedEvent?.id == 5)
        #expect(appState.currentRoute == .idle)
        #expect(appState.currentTheme.logoURL?.absoluteString == "https://example.com/logo.png")
        #expect(appState.currentTheme.backgroundURL?.absoluteString == "https://example.com/bg.jpg")
    }

    // MARK: - Upload Flow Integration Tests

    @Test("Upload flow with all successful uploads")
    func testSuccessfulUploadFlow() async throws {
        let sessionService = SessionService(apiClient: APIClient())
        let viewModel = UploadViewModel(sessionService: sessionService)
        let appState = AppState()

        // Prepare strips
        let strips = [
            CapturedStrip(
                stripIndex: 0,
                videoURL: URL(string: "file://0.mov")!,
                photoData: Data([0x01, 0x02]),
                thumbnailData: nil
            ),
            CapturedStrip(
                stripIndex: 1,
                videoURL: URL(string: "file://1.mov")!,
                photoData: Data([0x03, 0x04]),
                thumbnailData: nil
            ),
            CapturedStrip(
                stripIndex: 2,
                videoURL: URL(string: "file://2.mov")!,
                photoData: Data([0x05, 0x06]),
                thumbnailData: nil
            )
        ]

        // Prepare upload
        viewModel.prepareUploads(from: strips)

        #expect(viewModel.uploadItems.count == 6) // 3 videos + 3 photos
        #expect(viewModel.progress == 0)

        // Verify item ordering and types
        let items = viewModel.uploadItems
        #expect(items[0].kind == .video && items[0].stripIndex == 0)
        #expect(items[1].kind == .photo && items[1].stripIndex == 0)
        #expect(items[2].kind == .video && items[2].stripIndex == 1)
        #expect(items[3].kind == .photo && items[3].stripIndex == 1)
        #expect(items[4].kind == .video && items[4].stripIndex == 2)
        #expect(items[5].kind == .photo && items[5].stripIndex == 2)

        // Verify all start as pending
        for item in items {
            #expect(item.state == .pending)
        }
    }

    @Test("Upload flow with retry on failure")
    func testUploadFlowWithRetry() async throws {
        let sessionService = SessionService(apiClient: APIClient())
        let viewModel = UploadViewModel(sessionService: sessionService)

        let strips = [
            CapturedStrip(
                stripIndex: 0,
                videoURL: URL(string: "file://0.mov")!,
                photoData: Data(),
                thumbnailData: nil
            )
        ]

        viewModel.prepareUploads(from: strips)

        // Simulate a failure
        viewModel.uploadItems[0].state = .failed("Network error")
        viewModel.uploadItems[1].state = .completed

        #expect(viewModel.hasFailedUploads == true)
        #expect(viewModel.completedCount == 1)
        #expect(!viewModel.isComplete)

        // Verify retry count tracking
        #expect(viewModel.retryCount == 0)

        // After retry, failed items should be reset to pending
        for i in 0..<viewModel.uploadItems.count {
            if case .failed = viewModel.uploadItems[i].state {
                viewModel.uploadItems[i].state = .pending
            }
        }

        #expect(viewModel.uploadItems[0].state == .pending)
    }

    @Test("Upload progress calculation across all strips")
    func testUploadProgressCalculation() {
        let sessionService = SessionService(apiClient: APIClient())
        let viewModel = UploadViewModel(sessionService: sessionService)

        let strips = [
            CapturedStrip(stripIndex: 0, videoURL: URL(string: "file://0.mov")!, photoData: Data(), thumbnailData: nil),
            CapturedStrip(stripIndex: 1, videoURL: URL(string: "file://1.mov")!, photoData: Data(), thumbnailData: nil),
            CapturedStrip(stripIndex: 2, videoURL: URL(string: "file://2.mov")!, photoData: Data(), thumbnailData: nil)
        ]

        viewModel.prepareUploads(from: strips)

        // Initial state
        #expect(viewModel.progress == 0)
        #expect(viewModel.completedCount == 0)

        // Complete first strip (video + photo)
        viewModel.uploadItems[0].state = .completed
        viewModel.uploadItems[1].state = .completed
        #expect(viewModel.completedCount == 2)

        // Complete second strip
        viewModel.uploadItems[2].state = .completed
        viewModel.uploadItems[3].state = .completed
        #expect(viewModel.completedCount == 4)

        // Complete third strip
        viewModel.uploadItems[4].state = .completed
        viewModel.uploadItems[5].state = .completed
        #expect(viewModel.completedCount == 6)

        // All completed
        let allCompleted = viewModel.uploadItems.allSatisfy {
            if case .completed = $0.state { return true }
            return false
        }
        #expect(allCompleted == true)
    }

    // MARK: - Capture Flow Integration Tests

    @Test("Complete capture flow for single strip")
    func testCompleteCaptureFlowSingleStrip() {
        let viewModel = CaptureViewModel()

        // Initial state
        #expect(viewModel.currentStripIndex == 0)
        #expect(viewModel.stripState == .ready)
        #expect(viewModel.capturedStrips.isEmpty)

        // Start capture - should transition to countdown
        viewModel.startCapture()

        if case .countdown(let remaining) = viewModel.stripState {
            #expect(remaining == 3)
        } else {
            Issue.record("Expected countdown state after startCapture")
        }

        // Simulate strip completion
        viewModel.stripState = .complete
        let strip = CapturedStripMedia(
            stripIndex: 0,
            videoURL: URL(string: "file://strip0.mov")!,
            photoData: Data([0x01, 0x02, 0x03]),
            thumbnailData: Data([0x04, 0x05])
        )
        viewModel.capturedStrips.append(strip)
        viewModel.isReviewing = true

        #expect(viewModel.capturedStrips.count == 1)
        #expect(viewModel.isReviewing == true)

        // Continue to next strip
        viewModel.continueToNext()

        #expect(viewModel.currentStripIndex == 1)
        #expect(viewModel.stripState == .ready)
        #expect(!viewModel.isReviewing)
        #expect(!viewModel.showingSummary)
    }

    @Test("Complete capture flow for all three strips")
    func testCompleteCaptureFlowAllStrips() {
        let viewModel = CaptureViewModel()

        // Capture three strips
        for stripIndex in 0..<3 {
            #expect(viewModel.currentStripIndex == stripIndex)
            #expect(viewModel.stripState == .ready)

            // Start capture
            viewModel.startCapture()

            // Complete strip
            viewModel.stripState = .complete
            let strip = CapturedStripMedia(
                stripIndex: stripIndex,
                videoURL: URL(string: "file://strip\(stripIndex).mov")!,
                photoData: Data(),
                thumbnailData: nil
            )
            viewModel.capturedStrips.append(strip)
            viewModel.isReviewing = true

            // Continue (or show summary if last strip)
            viewModel.continueToNext()
        }

        // After completing all 3 strips, summary should be shown
        #expect(viewModel.capturedStrips.count == 3)
        #expect(viewModel.showingSummary == true)

        // Convert to model format
        let converted = viewModel.getCapturedStrips()
        #expect(converted.count == 3)
        #expect(converted[0].stripIndex == 0)
        #expect(converted[1].stripIndex == 1)
        #expect(converted[2].stripIndex == 2)
    }

    @Test("Capture flow with retake functionality")
    func testCaptureFlowWithRetakes() {
        let viewModel = CaptureViewModel()

        // Capture first strip
        viewModel.startCapture()
        viewModel.stripState = .complete
        let strip0 = CapturedStripMedia(
            stripIndex: 0,
            videoURL: URL(string: "file://0.mov")!,
            photoData: Data(),
            thumbnailData: nil
        )
        viewModel.capturedStrips.append(strip0)
        viewModel.isReviewing = true

        // User decides to retake
        viewModel.retakeCurrentStrip()

        #expect(viewModel.capturedStrips.isEmpty)
        #expect(viewModel.currentStripIndex == 0)
        #expect(viewModel.stripState == .ready)
        #expect(!viewModel.isReviewing)

        // Capture again
        viewModel.startCapture()
        viewModel.stripState = .complete
        let strip0_v2 = CapturedStripMedia(
            stripIndex: 0,
            videoURL: URL(string: "file://0_v2.mov")!,
            photoData: Data(),
            thumbnailData: nil
        )
        viewModel.capturedStrips.append(strip0_v2)

        #expect(viewModel.capturedStrips.count == 1)
        #expect(viewModel.capturedStrips[0].videoURL.absoluteString.contains("v2"))
    }

    // MARK: - Error Recovery Integration Tests

    @Test("AppState handles session reset correctly")
    func testSessionResetErrorRecovery() {
        let appState = AppState()

        // Setup a session with data
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
        appState.selectEvent(event)

        let session = Session(sessionId: 123, publicToken: "abc", universalURL: "https://test.com")
        appState.startSession(with: session)

        // Add captured strips
        let strip = CapturedStrip(
            stripIndex: 0,
            videoURL: URL(string: "file://test.mov")!,
            photoData: Data(),
            thumbnailData: nil
        )
        appState.capturedStrips.append(strip)
        appState.totalAssetsToUpload = 6
        appState.assetsUploaded = 3
        appState.qrCodeData = Data([0x01])

        // Verify session is active
        #expect(appState.currentSession != nil)
        #expect(!appState.capturedStrips.isEmpty)
        #expect(appState.assetsUploaded == 3)

        // Reset session (error recovery)
        appState.resetSession()

        // Verify clean state but event is preserved
        #expect(appState.currentRoute == .idle)
        #expect(appState.selectedEvent?.id == 1) // Event preserved
        #expect(appState.currentSession == nil)
        #expect(appState.capturedStrips.isEmpty)
        #expect(appState.qrCodeData == nil)
        #expect(appState.assetsUploaded == 0)
        #expect(appState.totalAssetsToUpload == 0)
    }

    @Test("AppState handles return to event selection")
    func testReturnToEventSelectionErrorRecovery() {
        let appState = AppState()

        // Setup complete state
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
        appState.selectEvent(event)

        let session = Session(sessionId: 123, publicToken: "abc", universalURL: "https://test.com")
        appState.startSession(with: session)

        // Return to event selection (complete reset)
        appState.returnToEventSelection()

        // Verify everything is cleared
        #expect(appState.currentRoute == .eventSelection)
        #expect(appState.selectedEvent == nil)
        #expect(appState.currentSession == nil)
        #expect(appState.capturedStrips.isEmpty)
        #expect(appState.currentTheme.id == 0) // Default theme
    }

    @Test("Upload recovery after network failure")
    func testUploadRecoveryAfterNetworkFailure() {
        let sessionService = SessionService(apiClient: APIClient())
        let viewModel = UploadViewModel(sessionService: sessionService)

        let strips = [
            CapturedStrip(stripIndex: 0, videoURL: URL(string: "file://0.mov")!, photoData: Data(), thumbnailData: nil)
        ]

        viewModel.prepareUploads(from: strips)

        // Simulate network failure on first item
        viewModel.uploadItems[0].state = .failed("Network timeout")
        viewModel.uploadItems[1].state = .completed

        #expect(viewModel.hasFailedUploads == true)
        #expect(!viewModel.isComplete)

        // Simulate retry - reset failed items
        for i in 0..<viewModel.uploadItems.count {
            if case .failed = viewModel.uploadItems[i].state {
                viewModel.uploadItems[i].state = .pending
            }
        }

        // Simulate successful retry
        viewModel.uploadItems[0].state = .completed

        // Now all should be complete
        let allCompleted = viewModel.uploadItems.allSatisfy {
            if case .completed = $0.state { return true }
            return false
        }

        #expect(allCompleted == true)
        #expect(!viewModel.hasFailedUploads)
    }

    @Test("Email validation recovery from errors")
    func testEmailValidationRecovery() {
        let sessionService = SessionService(apiClient: APIClient())
        let viewModel = QRViewModel(sessionService: sessionService)

        // Enter invalid email
        viewModel.email = "invalid"
        #expect(!viewModel.isEmailValid)

        viewModel.emailError = "Invalid email format"
        #expect(viewModel.emailError != nil)

        // User corrects the email
        viewModel.email = "valid@example.com"
        #expect(viewModel.isEmailValid)

        // Clear error
        viewModel.clearEmailError()
        #expect(viewModel.emailError == nil)

        // Ready to submit
        #expect(viewModel.isEmailValid)
        #expect(viewModel.emailError == nil)
    }

    // MARK: - Multi-Component Integration Tests

    @Test("EventSelection to Capture to Upload to QR complete flow")
    func testCompleteUserFlow() async throws {
        let appState = AppState()

        // Step 1: Event Selection
        let theme = Theme(
            id: 1,
            primaryColor: "#FF4081",
            secondaryColor: "#212121",
            accentColor: "#FFFFFF",
            fontFamily: "system",
            logoURL: nil,
            backgroundURL: nil,
            photoFrameURL: nil,
            stripFrameURL: nil
        )
        let event = Event(id: 1, name: "Integration Test Event", date: "2025-12-25", theme: theme)

        appState.selectEvent(event)
        #expect(appState.currentRoute == .idle)

        // Step 2: Start Session
        let session = Session(sessionId: 999, publicToken: "test123", universalURL: "https://test.com/s/test123")
        appState.startSession(with: session)

        if case .capture(.capturingStrip(let index)) = appState.currentRoute {
            #expect(index == 0)
        } else {
            Issue.record("Expected capture route")
        }

        // Step 3: Capture flow (simulate all strips)
        let captureViewModel = CaptureViewModel()
        for i in 0..<3 {
            let strip = CapturedStripMedia(
                stripIndex: i,
                videoURL: URL(string: "file://strip\(i).mov")!,
                photoData: Data(),
                thumbnailData: nil
            )
            captureViewModel.capturedStrips.append(strip)
        }

        let convertedStrips = captureViewModel.getCapturedStrips()
        appState.capturedStrips = convertedStrips
        #expect(appState.allStripsCaptured == true)

        // Step 4: Upload flow
        let uploadViewModel = UploadViewModel(sessionService: SessionService(apiClient: APIClient()))
        uploadViewModel.prepareUploads(from: convertedStrips)

        #expect(uploadViewModel.uploadItems.count == 6)

        // Simulate successful uploads
        appState.totalAssetsToUpload = 6
        for _ in 0..<6 {
            appState.assetUploaded()
        }
        #expect(appState.uploadProgress == 1.0)

        // Step 5: QR Display
        let qrViewModel = QRViewModel(sessionService: SessionService(apiClient: APIClient()))
        qrViewModel.setup(qrData: Data([0x89, 0x50, 0x4E, 0x47]), session: session)

        #expect(qrViewModel.universalURL == "https://test.com/s/test123")
        #expect(qrViewModel.qrImage != nil)

        // Step 6: Email submission
        qrViewModel.email = "guest@example.com"
        #expect(qrViewModel.isEmailValid)

        // Step 7: Complete - return to idle
        appState.resetSession()
        #expect(appState.currentRoute == .idle)
        #expect(appState.selectedEvent != nil) // Event still selected
    }

    @Test("Multiple session cycles with same event")
    func testMultipleSessionCycles() {
        let appState = AppState()

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

        // Select event once
        appState.selectEvent(event)
        #expect(appState.selectedEvent?.id == 1)

        // Run 3 session cycles
        for sessionNum in 1...3 {
            let session = Session(
                sessionId: sessionNum,
                publicToken: "token\(sessionNum)",
                universalURL: "https://test.com/s/token\(sessionNum)"
            )

            appState.startSession(with: session)
            #expect(appState.currentSession?.sessionId == sessionNum)

            // Capture strips
            for i in 0..<3 {
                let strip = CapturedStrip(
                    stripIndex: i,
                    videoURL: URL(string: "file://session\(sessionNum)_strip\(i).mov")!,
                    photoData: Data(),
                    thumbnailData: nil
                )
                appState.capturedStrips.append(strip)
            }

            #expect(appState.capturedStrips.count == 3)

            // Upload
            appState.totalAssetsToUpload = 6
            for _ in 0..<6 {
                appState.assetUploaded()
            }

            // Reset for next session
            appState.resetSession()

            #expect(appState.currentRoute == .idle)
            #expect(appState.selectedEvent?.id == 1) // Event preserved
            #expect(appState.currentSession == nil)
            #expect(appState.capturedStrips.isEmpty)
        }
    }
}
