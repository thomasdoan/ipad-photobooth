//
//  AppLogger.swift
//  fotoX
//
//  Dual logger for os.Logger and Sentry breadcrumbs
//

import os
import Sentry

/// Unified logging that sends to both os.Logger (for local debugging) and Sentry breadcrumbs (for production observability)
struct AppLogger {
    private static let logger = Logger(subsystem: "id8.fotoX", category: "general")

    /// Logs an informational message
    /// - Parameters:
    ///   - message: The log message
    ///   - category: The breadcrumb category (e.g., "upload", "session")
    ///   - data: Additional context data for Sentry breadcrumb
    static func info(_ message: String, category: String, data: [String: Any] = [:]) {
        logger.info("\(message)")
        let breadcrumb = Breadcrumb(level: .info, category: category)
        breadcrumb.message = message
        breadcrumb.data = data
        SentrySDK.addBreadcrumb(breadcrumb)
    }

    /// Logs an error message and optionally captures to Sentry
    /// - Parameters:
    ///   - message: The log message
    ///   - category: The breadcrumb category (e.g., "upload", "session")
    ///   - error: Optional error to capture in Sentry
    ///   - data: Additional context data for Sentry breadcrumb
    static func error(_ message: String, category: String, error: Error? = nil, data: [String: Any] = [:]) {
        logger.error("\(message)")
        if let error = error {
            SentrySDK.capture(error: error)
        }
        let breadcrumb = Breadcrumb(level: .error, category: category)
        breadcrumb.message = message
        breadcrumb.data = data
        SentrySDK.addBreadcrumb(breadcrumb)
    }
}
