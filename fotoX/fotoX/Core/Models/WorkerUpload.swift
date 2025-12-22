//
//  WorkerUpload.swift
//  fotoX
//
//  Models for Worker presign/upload contracts
//

import Foundation

// MARK: - Presign

struct PresignRequest: Codable, Sendable {
    let eventId: Int
    let sessionId: String
    let files: [PresignFile]

    nonisolated enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case sessionId = "session_id"
        case files
    }
}

struct PresignFile: Codable, Sendable {
    let path: String
    let contentType: String
    let sizeBytes: Int

    nonisolated enum CodingKeys: String, CodingKey {
        case path
        case contentType = "content_type"
        case sizeBytes = "size_bytes"
    }
}

struct PresignResponse: Codable, Sendable {
    let uploads: [PresignUpload]
    let expiresInSeconds: Int

    nonisolated enum CodingKeys: String, CodingKey {
        case uploads
        case expiresInSeconds = "expires_in_seconds"
    }
}

struct PresignUpload: Codable, Sendable {
    let path: String
    let method: String
    let url: String
}

// MARK: - Complete

struct CompleteRequest: Codable, Sendable {
    let eventId: Int
    let sessionId: String
    let manifestPath: String

    nonisolated enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case sessionId = "session_id"
        case manifestPath = "manifest_path"
    }
}

struct CompleteResponse: Codable, Sendable {
    let status: String
}

// MARK: - Manifest

struct SessionManifest: Codable, Sendable {
    let version: Int
    let eventId: Int
    let sessionId: String
    let createdAt: String
    let publicGalleryURL: String
    let assets: [SessionManifestAsset]

    nonisolated enum CodingKeys: String, CodingKey {
        case version
        case eventId = "event_id"
        case sessionId = "session_id"
        case createdAt = "created_at"
        case publicGalleryURL = "public_gallery_url"
        case assets
    }
}

struct SessionManifestAsset: Codable, Sendable {
    let id: String
    let kind: AssetKind
    let stripIndex: Int
    let sequenceIndex: Int
    let contentType: String
    let path: String
    let sizeBytes: Int
    let durationSeconds: Double?
    let posterPath: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case id
        case kind
        case stripIndex = "strip_index"
        case sequenceIndex = "sequence_index"
        case contentType = "content_type"
        case path
        case sizeBytes = "size_bytes"
        case durationSeconds = "duration_seconds"
        case posterPath = "poster_path"
    }
}
