//
//  GalleryModels.swift
//  fotoX
//
//  Models for the event gallery feature
//

import Foundation

/// Where a session's data comes from
enum SessionSource: Equatable, Sendable {
    /// Only exists locally on device
    case local
    /// Only exists remotely (uploaded to Worker)
    case remote
    /// Exists both locally and remotely
    case both
}

/// Represents a photo or video asset in the gallery
struct GalleryAsset: Identifiable, Equatable, Sendable {
    let id: String
    let kind: AssetKind
    let stripIndex: Int
    let remotePath: String
    /// Local file URL if the asset exists on device (for local-first loading)
    let localURL: URL?
    let mimeType: String
    /// Poster/thumbnail path for videos (points to a photo from the same strip)
    let posterPath: String?
    /// Local poster URL for videos (if the poster photo exists locally)
    let localPosterURL: URL?

    /// Whether this asset can be loaded from local storage
    var isLocallyAvailable: Bool {
        guard let url = localURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// Whether the poster is available locally
    var isPosterLocallyAvailable: Bool {
        guard let url = localPosterURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
}

/// Represents a session in the gallery (can be local, remote, or both)
struct GallerySession: Identifiable, Equatable, Sendable {
    let id: String
    let sessionId: String
    let eventId: Int
    let createdAt: Date
    let source: SessionSource
    /// Thumbnail path for remote loading
    let thumbPath: String?
    /// Local thumbnail URL if available
    let localThumbURL: URL?
    /// Gallery path for the session (e.g., "s/{sessionId}")
    let galleryPath: String
    /// All assets in this session
    var assets: [GalleryAsset]
    
    /// Best URL to use for thumbnail (local-first)
    var thumbnailURL: URL? {
        if let local = localThumbURL, FileManager.default.fileExists(atPath: local.path) {
            return local
        }
        return nil
    }
}

// MARK: - API Response Models

/// Event index response from Worker API
struct EventIndex: Codable, Sendable {
    let version: Int
    let eventId: Int
    let updatedAt: String?
    let sessions: [EventIndexSession]
    
    enum CodingKeys: String, CodingKey {
        case version
        case eventId = "event_id"
        case updatedAt = "updated_at"
        case sessions
    }
}

/// Session entry in the event index
struct EventIndexSession: Codable, Sendable {
    let sessionId: String
    let createdAt: String
    let thumbPath: String
    let galleryPath: String
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case createdAt = "created_at"
        case thumbPath = "thumb_path"
        case galleryPath = "gallery_path"
    }
}

