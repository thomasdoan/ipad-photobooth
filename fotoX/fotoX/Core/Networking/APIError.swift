//
//  APIError.swift
//  fotoX
//
//  Error types for API operations
//

import Foundation

/// Errors that can occur during API communication with the Pi
enum APIError: Error, LocalizedError, Sendable {
    case invalidURL
    case invalidRequest
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case networkError(Error)
    case timeout
    case serverUnreachable
    case uploadFailed(String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .invalidRequest:
            return "Failed to create request"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, let message):
            if let message = message {
                return "Server error (\(statusCode)): \(message)"
            }
            return "Server error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .timeout:
            return "Request timed out"
        case .serverUnreachable:
            return "Cannot connect to photobooth server"
        case .uploadFailed(let reason):
            return "Upload failed: \(reason)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    /// User-friendly message for display
    var userMessage: String {
        switch self {
        case .serverUnreachable, .timeout:
            return "Cannot connect to the photobooth. Please check the connection."
        case .httpError(let statusCode, _) where statusCode >= 500:
            return "The photobooth server is having issues. Please try again."
        case .httpError:
            return "Something went wrong. Please try again."
        case .uploadFailed:
            return "Failed to upload your photos. Please try again."
        default:
            return "Something went wrong. Please try again."
        }
    }
    
    /// Whether this error is recoverable with a retry
    var isRetryable: Bool {
        switch self {
        case .timeout, .serverUnreachable, .networkError:
            return true
        case .httpError(let statusCode, _):
            return statusCode >= 500 || statusCode == 429
        default:
            return false
        }
    }
}

