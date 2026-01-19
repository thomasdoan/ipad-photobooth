//
//  WorkerAPIClient.swift
//  fotoX
//
//  HTTP client for Cloudflare Worker endpoints
//

import Foundation

struct WorkerAPIClient: Sendable {
    static let shared = WorkerAPIClient()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func presign(request: PresignRequest) async throws -> PresignResponse {
        let url = WorkerConfiguration.currentBaseURL().appendingPathComponent("presign")
        guard let token = WorkerConfiguration.currentPresignToken(), !token.isEmpty else {
            throw APIError.uploadFailed("Missing presign token")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(token, forHTTPHeaderField: "X-FotoX-Key")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(PresignResponse.self, from: data)
    }

    func complete(request: CompleteRequest) async throws -> CompleteResponse {
        let url = WorkerConfiguration.currentBaseURL().appendingPathComponent("complete")
        guard let token = WorkerConfiguration.currentPresignToken(), !token.isEmpty else {
            throw APIError.uploadFailed("Missing presign token")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(token, forHTTPHeaderField: "X-FotoX-Key")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(CompleteResponse.self, from: data)
    }

    /// Fetches the event index with all sessions (public endpoint, no auth required)
    func fetchEventSessions(eventId: Int) async throws -> EventIndex {
        let url = WorkerConfiguration.currentBaseURL()
            .appendingPathComponent("events")
            .appendingPathComponent("\(eventId)")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = 15

        let (data, response) = try await session.data(for: urlRequest)
        try validate(response: response, data: data)
        
        return try JSONDecoder().decode(EventIndex.self, from: data)
    }

    /// Builds a URL for fetching an asset from the Worker
    func assetURL(path: String) -> URL? {
        let baseURL = WorkerConfiguration.currentBaseURL()
        guard var components = URLComponents(url: baseURL.appendingPathComponent("asset"), resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.queryItems = [URLQueryItem(name: "path", value: path)]
        return components.url
    }

    /// Fetches the session manifest to get asset list (public endpoint)
    func fetchSessionManifest(sessionId: String) async throws -> SessionManifest {
        let manifestPath = "sessions/\(sessionId)/manifest.json"
        guard let url = assetURL(path: manifestPath) else {
            throw APIError.invalidResponse
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = 15

        let (data, response) = try await session.data(for: urlRequest)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(SessionManifest.self, from: data)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8)
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
        }
    }
}
