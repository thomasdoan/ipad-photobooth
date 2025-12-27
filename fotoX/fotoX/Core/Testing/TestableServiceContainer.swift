//
//  TestableServiceContainer.swift
//  fotoX
//
//  Service container that supports mock injection for testing
//

import Foundation

/// Service container that can use real or mock services
/// Similar to how you'd set up dependency injection in React with test providers
@MainActor
final class TestableServiceContainer: Sendable {
    
    // MARK: - Service Access
    
    /// Local services used when mocks are not enabled
    let eventService: LocalEventService
    let sessionService: LocalSessionService
    let themeService: ThemeService
    let apiClient: APIClient?
    
    // Mock services (available when testing)
    private(set) var mockEventService: MockEventService?
    private(set) var mockSessionService: MockSessionService?
    
    /// Whether using mock services
    let isMocking: Bool
    
    // MARK: - Initialization
    
    init(useMocks: Bool = MockDataProvider.useMockData) {
        self.isMocking = useMocks
        
        self.themeService = ThemeService()
        self.eventService = LocalEventService()
        self.sessionService = LocalSessionService()
        self.apiClient = nil

        if useMocks {
            self.mockEventService = MockEventService()
            self.mockSessionService = MockSessionService()
        } else {
            self.mockEventService = nil
            self.mockSessionService = nil
        }
    }
    
    // MARK: - Mock Service Access (for testing configuration)
    
    /// Fetches events using the appropriate service
    func fetchEvents() async throws -> [Event] {
        if let mock = mockEventService {
            return try await mock.fetchEvents()
        }
        return try await eventService.fetchEvents()
    }
    
    /// Fetches a single event
    func fetchEvent(id: Int) async throws -> Event {
        if let mock = mockEventService {
            return try await mock.fetchEvent(id: id)
        }
        return try await eventService.fetchEvent(id: id)
    }
    
    /// Creates a session
    func createSession(eventId: Int) async throws -> Session {
        if let mock = mockSessionService {
            return try await mock.createSession(eventId: eventId)
        }
        return try await sessionService.createSession(eventId: eventId)
    }
    
    /// Uploads an asset
    func uploadAsset(
        sessionId: String,
        fileData: Data,
        fileName: String,
        mimeType: String,
        metadata: AssetUploadMetadata
    ) async throws -> AssetUploadResponse {
        if let mock = mockSessionService {
            return try await mock.uploadAsset(
                sessionId: sessionId,
                fileData: fileData,
                fileName: fileName,
                mimeType: mimeType,
                metadata: metadata
            )
        }
        return try await sessionService.uploadAsset(
            sessionId: sessionId,
            fileData: fileData,
            fileName: fileName,
            mimeType: mimeType,
            metadata: metadata
        )
    }
    
    /// Fetches QR code
    func fetchQRCode(sessionId: String) async throws -> Data {
        if let mock = mockSessionService {
            return try await mock.fetchQRCode(sessionId: sessionId)
        }
        return try await sessionService.fetchQRCode(sessionId: sessionId)
    }
    
    /// Submits email
    func submitEmail(sessionId: String, email: String) async throws -> EmailSubmissionResponse {
        if let mock = mockSessionService {
            return try await mock.submitEmail(sessionId: sessionId, email: email)
        }
        return try await sessionService.submitEmail(sessionId: sessionId, email: email)
    }
}
