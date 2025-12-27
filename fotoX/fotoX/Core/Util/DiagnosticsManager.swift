//
//  DiagnosticsManager.swift
//  fotoX
//
//  Tracks diagnostic information for the app
//

import Foundation

/// Manages diagnostic information for debugging and status display
enum DiagnosticsManager {
    // MARK: - Keys

    private static let lastConnectionTestKey = "diagnostics_lastConnectionTest"
    private static let lastConnectionResultKey = "diagnostics_lastConnectionResult"
    private static let lastUploadTimeKey = "diagnostics_lastUploadTime"
    private static let lastUploadResultKey = "diagnostics_lastUploadResult"
    private static let lastUploadSessionIdKey = "diagnostics_lastUploadSessionId"
    private static let totalUploadsKey = "diagnostics_totalUploads"
    private static let failedUploadsKey = "diagnostics_failedUploads"
    private static let lastErrorKey = "diagnostics_lastError"
    private static let lastErrorTimeKey = "diagnostics_lastErrorTime"

    // MARK: - Connection Test Tracking

    static func recordConnectionTest(success: Bool, error: String? = nil) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastConnectionTestKey)
        UserDefaults.standard.set(success, forKey: lastConnectionResultKey)

        if !success, let error = error {
            recordError(error)
        }
    }

    static func lastConnectionTest() -> (date: Date, success: Bool)? {
        let timestamp = UserDefaults.standard.double(forKey: lastConnectionTestKey)
        guard timestamp > 0 else { return nil }

        let success = UserDefaults.standard.bool(forKey: lastConnectionResultKey)
        return (Date(timeIntervalSince1970: timestamp), success)
    }

    // MARK: - Upload Tracking

    static func recordUploadAttempt(sessionId: String, success: Bool, error: String? = nil) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastUploadTimeKey)
        UserDefaults.standard.set(success, forKey: lastUploadResultKey)
        UserDefaults.standard.set(sessionId, forKey: lastUploadSessionIdKey)

        let totalUploads = UserDefaults.standard.integer(forKey: totalUploadsKey)
        UserDefaults.standard.set(totalUploads + 1, forKey: totalUploadsKey)

        if !success {
            let failedUploads = UserDefaults.standard.integer(forKey: failedUploadsKey)
            UserDefaults.standard.set(failedUploads + 1, forKey: failedUploadsKey)

            if let error = error {
                recordError(error)
            }
        }
    }

    static func lastUpload() -> (date: Date, success: Bool, sessionId: String?)? {
        let timestamp = UserDefaults.standard.double(forKey: lastUploadTimeKey)
        guard timestamp > 0 else { return nil }

        let success = UserDefaults.standard.bool(forKey: lastUploadResultKey)
        let sessionId = UserDefaults.standard.string(forKey: lastUploadSessionIdKey)
        return (Date(timeIntervalSince1970: timestamp), success, sessionId)
    }

    static func uploadStats() -> (total: Int, failed: Int) {
        let total = UserDefaults.standard.integer(forKey: totalUploadsKey)
        let failed = UserDefaults.standard.integer(forKey: failedUploadsKey)
        return (total, failed)
    }

    // MARK: - Error Tracking

    static func recordError(_ error: String) {
        UserDefaults.standard.set(error, forKey: lastErrorKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastErrorTimeKey)
    }

    static func lastError() -> (error: String, date: Date)? {
        guard let error = UserDefaults.standard.string(forKey: lastErrorKey) else { return nil }
        let timestamp = UserDefaults.standard.double(forKey: lastErrorTimeKey)
        guard timestamp > 0 else { return nil }

        return (error, Date(timeIntervalSince1970: timestamp))
    }

    // MARK: - Reset

    static func resetAll() {
        let keys = [
            lastConnectionTestKey,
            lastConnectionResultKey,
            lastUploadTimeKey,
            lastUploadResultKey,
            lastUploadSessionIdKey,
            totalUploadsKey,
            failedUploadsKey,
            lastErrorKey,
            lastErrorTimeKey
        ]

        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
