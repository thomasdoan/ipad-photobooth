//
//  EmailCollectionService.swift
//  fotoX
//
//  Service for collecting and uploading guest emails
//

import Foundation

/// Service for managing email collection and upload
@MainActor
final class EmailCollectionService {
    private let workerAPIClient: WorkerAPIClient
    private let fileManager = FileManager.default

    /// Local JSON file path
    private var emailsFileURL: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("emails.json")
    }

    init(workerAPIClient: WorkerAPIClient = .shared) {
        self.workerAPIClient = workerAPIClient
    }

    /// Adds an email entry and uploads to R2
    func submitEmail(sessionId: String, email: String, frameId: String?, eventId: Int?) async throws {
        let entry = EmailEntry(
            timestamp: Date(),
            sessionId: sessionId,
            email: email,
            frameId: frameId,
            eventId: eventId
        )

        // Save locally
        try appendEntry(entry)

        // Upload to R2 (non-blocking - failures logged but not thrown)
        Task {
            do {
                try await uploadEmailsFile(eventId: eventId)
            } catch {
                print("Failed to upload emails file: \(error)")
            }
        }
    }

    /// Appends entry to local JSON file
    private func appendEntry(_ entry: EmailEntry) throws {
        var entries: [EmailEntry] = []

        // Read existing entries if file exists
        if fileManager.fileExists(atPath: emailsFileURL.path) {
            let data = try Data(contentsOf: emailsFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            entries = try decoder.decode([EmailEntry].self, from: data)
        }

        // Append new entry
        entries.append(entry)

        // Write back
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(entries)
        try data.write(to: emailsFileURL)
    }

    /// Uploads the emails JSON file to R2
    private func uploadEmailsFile(eventId: Int?) async throws {
        guard fileManager.fileExists(atPath: emailsFileURL.path) else {
            return
        }

        let data = try Data(contentsOf: emailsFileURL)
        let fileName = "emails_\(eventId ?? 0).json"
        let remotePath = "private/emails/\(fileName)"

        // Use presign flow to upload
        let presignRequest = PresignRequest(
            eventId: eventId ?? 0,
            sessionId: "email-collection",
            files: [
                PresignFile(
                    path: remotePath,
                    contentType: "application/json",
                    sizeBytes: data.count
                )
            ]
        )

        let presignResponse = try await workerAPIClient.presign(request: presignRequest)

        guard let upload = presignResponse.uploads.first else {
            throw APIError.invalidResponse
        }

        // Upload file
        let session = URLSession.shared
        var uploadRequest = URLRequest(url: URL(string: upload.url)!)
        uploadRequest.httpMethod = upload.method
        uploadRequest.httpBody = data
        uploadRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await session.data(for: uploadRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            throw APIError.uploadFailed("Failed to upload email collection")
        }
    }
}
