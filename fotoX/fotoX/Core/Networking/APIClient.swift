//
//  APIClient.swift
//  fotoX
//
//  Central HTTP client for Pi API communication
//

import Foundation

/// Protocol for API client operations (enables testing with mocks)
protocol APIClientProtocol: Sendable {
    func fetch<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T
    func fetchData(_ endpoint: Endpoint) async throws -> Data
    func send<T: Encodable & Sendable, R: Decodable & Sendable>(_ endpoint: Endpoint, body: T) async throws -> R
    func upload(
        _ endpoint: Endpoint,
        fileData: Data,
        fileName: String,
        mimeType: String,
        metadata: [String: String]
    ) async throws -> AssetUploadResponse
}

/// Main API client for communicating with the Pi backend
actor APIClient: APIClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let maxRetries: Int
    private let retryDelay: TimeInterval
    
    private var _baseURL: URL
    
    var baseURL: URL {
        get { _baseURL }
    }
    
    /// Default base URL for the Pi backend
    nonisolated static let defaultBaseURL = URL(string: "http://booth.local/api")!
    
    init(
        baseURL: URL = APIClient.defaultBaseURL,
        timeoutInterval: TimeInterval = 30,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0
    ) {
        self._baseURL = baseURL
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval * 2
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }
    
    /// Updates the base URL (for settings changes)
    func updateBaseURL(_ url: URL) {
        self._baseURL = url
    }
    
    /// Fetches and decodes JSON from an endpoint
    nonisolated func fetch<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await fetchData(endpoint)
        do {
            return try await MainActor.run {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            }
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        }
    }
    
    /// Fetches raw data from an endpoint (for QR codes, images)
    nonisolated func fetchData(_ endpoint: Endpoint) async throws -> Data {
        let baseURL = await self.baseURL
        guard let request = endpoint.makeRequest(baseURL: baseURL) else {
            throw APIError.invalidURL
        }
        
        return try await performRequest(request)
    }
    
    /// Sends JSON body to an endpoint and decodes response
    nonisolated func send<T: Encodable & Sendable, R: Decodable & Sendable>(
        _ endpoint: Endpoint,
        body: T
    ) async throws -> R {
        let baseURL = await self.baseURL
        guard var request = endpoint.makeRequest(baseURL: baseURL) else {
            throw APIError.invalidURL
        }
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.invalidRequest
        }
        
        let data = try await performRequest(request)
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(R.self, from: data)
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        }
    }
    
    /// Uploads a file with multipart/form-data
    nonisolated func upload(
        _ endpoint: Endpoint,
        fileData: Data,
        fileName: String,
        mimeType: String,
        metadata: [String: String]
    ) async throws -> AssetUploadResponse {
        let baseURL = await self.baseURL
        guard var request = endpoint.makeRequest(baseURL: baseURL) else {
            throw APIError.invalidURL
        }
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add metadata fields
        for (key, value) in metadata {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let data = try await performRequest(request)
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(AssetUploadResponse.self, from: data)
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        }
    }
    
    /// Performs a request with retry logic
    private nonisolated func performRequest(_ request: URLRequest) async throws -> Data {
        let maxRetries = await self.maxRetries
        let retryDelay = await self.retryDelay
        let session = await self.session
        
        var lastError: Error = APIError.unknown(NSError(domain: "APIClient", code: -1))
        
        for attempt in 0..<maxRetries {
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 408, 429, 500...599:
                    // Retryable errors
                    let message = String(data: data, encoding: .utf8)
                    throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
                default:
                    let message = String(data: data, encoding: .utf8)
                    throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
                }
            } catch let error as APIError {
                lastError = error
                if error.isRetryable && attempt < maxRetries - 1 {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * Double(attempt + 1) * 1_000_000_000))
                    continue
                }
                throw error
            } catch let error as URLError {
                switch error.code {
                case .timedOut:
                    lastError = APIError.timeout
                case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost:
                    lastError = APIError.serverUnreachable
                default:
                    lastError = APIError.networkError(error)
                }
                
                if attempt < maxRetries - 1 {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * Double(attempt + 1) * 1_000_000_000))
                    continue
                }
            } catch {
                lastError = APIError.unknown(error)
                if attempt < maxRetries - 1 {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * Double(attempt + 1) * 1_000_000_000))
                    continue
                }
            }
        }
        
        throw lastError
    }
}

