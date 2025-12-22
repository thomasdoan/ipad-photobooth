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
        sessionId: Int,
        fileData: Data,
        fileName: String,
        mimeType: String,
        metadata: AssetUploadMetadata
    ) async throws -> AssetUploadResponse
    func fetchQRCode(sessionId: Int) async throws -> Data
    func submitEmail(sessionId: Int, email: String) async throws -> EmailSubmissionResponse
}
