//
//  WorkerConfiguration.swift
//  fotoX
//
//  Shared configuration for Worker base URL
//

import Foundation

enum WorkerConfiguration {
    static let baseURLKey = "workerBaseURL"
    static let presignTokenKey = "workerPresignToken"
    static let defaultBaseURL = URL(string: "https://your-worker.workers.dev")!

    static func currentBaseURL() -> URL {
        if let urlString = UserDefaults.standard.string(forKey: baseURLKey),
           let url = URL(string: urlString) {
            return url
        }
        return defaultBaseURL
    }

    static func saveBaseURL(_ url: URL) {
        UserDefaults.standard.set(url.absoluteString, forKey: baseURLKey)
    }

    static func currentPresignToken() -> String? {
        let token = UserDefaults.standard.string(forKey: presignTokenKey)
        return token?.isEmpty == true ? nil : token
    }

    static func savePresignToken(_ token: String) {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(trimmed, forKey: presignTokenKey)
    }
}
