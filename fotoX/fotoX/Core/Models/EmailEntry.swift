//
//  EmailEntry.swift
//  fotoX
//
//  Email collection entry model
//

import Foundation

/// Represents a guest email submission
struct EmailEntry: Codable, Sendable {
    let timestamp: Date
    let sessionId: String
    let email: String
    let frameId: String?
    let eventId: Int?

    init(timestamp: Date = Date(), sessionId: String, email: String, frameId: String?, eventId: Int?) {
        self.timestamp = timestamp
        self.sessionId = sessionId
        self.email = email
        self.frameId = frameId
        self.eventId = eventId
    }
}

extension EmailEntry {
    enum CodingKeys: String, CodingKey {
        case timestamp
        case sessionId = "session_id"
        case email
        case frameId = "frame_id"
        case eventId = "event_id"
    }
}
