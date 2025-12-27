//
//  ServiceProtocols.swift
//  fotoX
//
//  Protocols for swapping service implementations
//

import Foundation

/// Abstraction for event data sources (bundled or remote)
protocol EventServicing: Sendable {
    func fetchEvents() async throws -> [Event]
    func fetchEvent(id: Int) async throws -> Event
}

/// Abstraction for session-related operations
protocol SessionServicing: Sendable {
    func createSession(eventId: Int) async throws -> Session
    func uploadAsset(
        sessionId: String,
        fileData: Data,
        fileName: String,
        mimeType: String,
        metadata: AssetUploadMetadata
    ) async throws -> AssetUploadResponse
    func fetchQRCode(sessionId: String) async throws -> Data
    func submitEmail(sessionId: String, email: String) async throws -> EmailSubmissionResponse
}
