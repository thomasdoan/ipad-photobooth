//
//  SessionService.swift
//  fotoX
//
//  Service for managing capture sessions
//

import Foundation

/// Service for session-related API operations
@MainActor
final class SessionService: Sendable {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    /// Creates a new capture session for an event
    func createSession(eventId: Int) async throws -> Session {
        let request = CreateSessionRequest.standard(eventId: eventId)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let baseURL = await apiClient.baseURL
        guard var urlRequest = Endpoints.createSession.makeRequest(baseURL: baseURL) else {
            throw APIError.invalidURL
        }
        urlRequest.httpBody = try encoder.encode(request)
        
        let data = try await performRequest(urlRequest)
        return try decoder.decode(Session.self, from: data)
    }
    
    /// Uploads a video or photo asset to the session
    func uploadAsset(
        sessionId: Int,
        fileData: Data,
        fileName: String,
        mimeType: String,
        metadata: AssetUploadMetadata
    ) async throws -> AssetUploadResponse {
        let metadataDict: [String: String] = [
            "kind": metadata.kind.rawValue,
            "strip_index": String(metadata.stripIndex),
            "sequence_index": String(metadata.sequenceIndex)
        ]
        
        return try await apiClient.upload(
            Endpoints.uploadAsset(sessionId: sessionId),
            fileData: fileData,
            fileName: fileName,
            mimeType: mimeType,
            metadata: metadataDict
        )
    }
    
    /// Fetches the QR code image for a session
    func fetchQRCode(sessionId: Int) async throws -> Data {
        return try await apiClient.fetchData(Endpoints.qrCode(sessionId: sessionId))
    }
    
    /// Submits guest email for a session
    func submitEmail(sessionId: Int, email: String) async throws -> EmailSubmissionResponse {
        let request = EmailSubmissionRequest(email: email)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let baseURL = await apiClient.baseURL
        guard var urlRequest = Endpoints.submitEmail(sessionId: sessionId).makeRequest(baseURL: baseURL) else {
            throw APIError.invalidURL
        }
        urlRequest.httpBody = try encoder.encode(request)
        
        let data = try await performRequest(urlRequest)
        return try decoder.decode(EmailSubmissionResponse.self, from: data)
    }
    
    /// Helper to perform network request
    private func performRequest(_ request: URLRequest) async throws -> Data {
        let session = URLSession.shared
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            let message = String(data: data, encoding: .utf8)
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
        }
        
        return data
    }
}

