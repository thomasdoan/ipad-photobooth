//
//  Endpoints.swift
//  fotoX
//
//  API endpoint definitions for Pi communication
//

import Foundation

/// HTTP methods used by the API
enum HTTPMethod: String, Sendable {
    case GET
    case POST
    case PUT
    case DELETE
}

/// API endpoint configuration
struct Endpoint: Sendable {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]
    let queryItems: [URLQueryItem]?
    
    init(
        path: String,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem]? = nil
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
    }
    
    /// Creates a URLRequest for this endpoint
    func makeRequest(baseURL: URL) -> URLRequest? {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems
        
        guard let url = components?.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Default headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
}

/// Collection of API endpoints
enum Endpoints {
    /// GET /events - Fetch list of available events
    static let events = Endpoint(path: "events")
    
    /// GET /events/{id} - Fetch specific event details
    static func event(id: Int) -> Endpoint {
        Endpoint(path: "events/\(id)")
    }
    
    /// POST /sessions - Create a new capture session
    static let createSession = Endpoint(
        path: "sessions",
        method: .POST,
        headers: ["Content-Type": "application/json"]
    )
    
    /// POST /sessions/{id}/assets - Upload an asset
    static func uploadAsset(sessionId: String) -> Endpoint {
        Endpoint(
            path: "sessions/\(sessionId)/assets",
            method: .POST
        )
    }
    
    /// GET /sessions/{id}/qr - Get QR code for session
    static func qrCode(sessionId: String) -> Endpoint {
        Endpoint(path: "sessions/\(sessionId)/qr")
    }
    
    /// POST /sessions/{id}/email - Submit guest email
    static func submitEmail(sessionId: String) -> Endpoint {
        Endpoint(
            path: "sessions/\(sessionId)/email",
            method: .POST,
            headers: ["Content-Type": "application/json"]
        )
    }
}
