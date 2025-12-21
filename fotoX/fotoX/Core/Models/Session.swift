//
//  Session.swift
//  fotoX
//
//  Core model for capture sessions
//

import Foundation

/// Represents a capture session created on the Pi
struct Session: Equatable, Sendable {
    let sessionId: Int
    let publicToken: String
    let universalURL: String
}

extension Session: Codable {
    nonisolated enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case publicToken = "public_token"
        case universalURL = "universal_url"
    }
}

/// Request body for creating a new session
struct CreateSessionRequest: Sendable {
    let eventId: Int
    let captureType: String
    let stripCount: Int
    
    /// Default request for standard 3-strip capture
    nonisolated static func standard(eventId: Int) -> CreateSessionRequest {
        CreateSessionRequest(
            eventId: eventId,
            captureType: "strip",
            stripCount: 3
        )
    }
}

extension CreateSessionRequest: Codable {
    nonisolated enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case captureType = "capture_type"
        case stripCount = "strip_count"
    }
}

/// Response from email submission endpoint
struct EmailSubmissionResponse: Sendable {
    let status: String
}

extension EmailSubmissionResponse: Codable {}

/// Request body for email submission
struct EmailSubmissionRequest: Sendable {
    let email: String
}

extension EmailSubmissionRequest: Codable {}

