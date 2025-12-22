//
//  MockDataProvider.swift
//  fotoX
//
//  Provides mock data for UI testing - like MSW for iOS
//

import Foundation

/// Provides mock data for testing
/// Similar to fixtures/mocks in Jest or MSW handlers
enum MockDataProvider {
    
    // MARK: - Check if Testing
    
    /// Returns true if app was launched for UI testing
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting")
    }
    
    /// Returns true if we should use mock data
    static var useMockData: Bool {
        ProcessInfo.processInfo.arguments.contains("--use-mock-data")
    }
    
    // MARK: - Mock Events
    
    static let mockEvents: [Event] = [
        Event(
            id: 1,
            name: "Sally & John's Wedding",
            date: "2025-12-31",
            theme: Theme(
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
        ),
        Event(
            id: 2,
            name: "Corporate Holiday Party",
            date: "2025-12-20",
            theme: Theme(
                id: 2,
                primaryColor: "#0066CC",
                secondaryColor: "#1A1A2E",
                accentColor: "#FFFFFF",
                fontFamily: "system",
                logoURL: nil,
                backgroundURL: nil,
                photoFrameURL: nil,
                stripFrameURL: nil
            )
        ),
        Event(
            id: 3,
            name: "Birthday Bash 2025",
            date: "2025-06-15",
            theme: Theme(
                id: 3,
                primaryColor: "#FFD700",
                secondaryColor: "#2D1B4E",
                accentColor: "#FFFFFF",
                fontFamily: "system",
                logoURL: nil,
                backgroundURL: nil,
                photoFrameURL: nil,
                stripFrameURL: nil
            )
        )
    ]
    
    // MARK: - Mock Session
    
    static func mockSession(eventId: Int) -> Session {
        Session(
            sessionId: Int.random(in: 1000...9999),
            publicToken: "mock\(UUID().uuidString.prefix(8))",
            universalURL: "https://pb.example.com/s/mock-session"
        )
    }
    
    // MARK: - Mock QR Code
    
    /// Generates a simple mock QR code image data
    static var mockQRCodeData: Data {
        // Create a simple placeholder image
        // In a real scenario, you could bundle a test QR code image
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Draw a simple pattern to represent QR
            UIColor.black.setFill()
            let cellSize: CGFloat = 10
            for row in 0..<20 {
                for col in 0..<20 {
                    if (row + col) % 2 == 0 || row < 3 || col < 3 || row > 16 || col > 16 {
                        let rect = CGRect(
                            x: CGFloat(col) * cellSize,
                            y: CGFloat(row) * cellSize,
                            width: cellSize,
                            height: cellSize
                        )
                        context.fill(rect)
                    }
                }
            }
        }
        return image.pngData() ?? Data()
    }
    
    // MARK: - Mock Responses
    
    static let mockEmailResponse = EmailSubmissionResponse(status: "ok")
    
    static let mockUploadResponse = AssetUploadResponse(assetId: 12345, status: "ok")
}

// MARK: - Mock Services

/// Mock event service for testing
@MainActor
final class MockEventService: EventServicing {
    var shouldFail = false
    var delaySeconds: Double = 0.5
    
    func fetchEvents() async throws -> [Event] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
        
        if shouldFail {
            throw APIError.serverUnreachable
        }
        
        return MockDataProvider.mockEvents
    }
    
    func fetchEvent(id: Int) async throws -> Event {
        try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
        
        if shouldFail {
            throw APIError.serverUnreachable
        }
        
        guard let event = MockDataProvider.mockEvents.first(where: { $0.id == id }) else {
            throw APIError.httpError(statusCode: 404, message: "Event not found")
        }
        
        return event
    }
}

/// Mock session service for testing
@MainActor
final class MockSessionService: SessionServicing {
    var shouldFailCreate = false
    var shouldFailUpload = false
    var shouldFailQR = false
    var shouldFailEmail = false
    var uploadDelaySeconds: Double = 0.3
    
    func createSession(eventId: Int) async throws -> Session {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        if shouldFailCreate {
            throw APIError.serverUnreachable
        }
        
        return MockDataProvider.mockSession(eventId: eventId)
    }
    
    func uploadAsset(
        sessionId: Int,
        fileData: Data,
        fileName: String,
        mimeType: String,
        metadata: AssetUploadMetadata
    ) async throws -> AssetUploadResponse {
        try await Task.sleep(nanoseconds: UInt64(uploadDelaySeconds * 1_000_000_000))
        
        if shouldFailUpload {
            throw APIError.uploadFailed("Mock upload failure")
        }
        
        return MockDataProvider.mockUploadResponse
    }
    
    func fetchQRCode(sessionId: Int) async throws -> Data {
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        
        if shouldFailQR {
            throw APIError.serverUnreachable
        }
        
        return MockDataProvider.mockQRCodeData
    }
    
    func submitEmail(sessionId: Int, email: String) async throws -> EmailSubmissionResponse {
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        
        if shouldFailEmail {
            throw APIError.httpError(statusCode: 400, message: "Invalid email")
        }
        
        return MockDataProvider.mockEmailResponse
    }
}

import UIKit
