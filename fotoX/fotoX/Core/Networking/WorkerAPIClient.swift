//
//  WorkerAPIClient.swift
//  fotoX
//
//  HTTP client for Cloudflare Worker endpoints
//

import Foundation

struct WorkerAPIClient: Sendable {
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
