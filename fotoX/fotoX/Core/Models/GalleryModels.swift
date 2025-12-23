//
//  GalleryModels.swift
//  fotoX
//
//  Gallery-related data models
//

import Foundation

/// Represents a media item (photo or video) in the gallery
struct GalleryMedia: Identifiable, Equatable, Sendable, Codable {
    let id: Int
    let sessionId: Int
    let kind: MediaKind
    let stripIndex: Int
    let sequenceIndex: Int
    let url: String
    let thumbnailUrl: String?
    let createdAt: String

    enum MediaKind: String, Codable, Sendable {
        case photo
        case video
    }

    nonisolated enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case kind
        case stripIndex = "strip_index"
        case sequenceIndex = "sequence_index"
        case url
        case thumbnailUrl = "thumbnail_url"
        case createdAt = "created_at"
    }
}

/// Represents a session with its media items
struct SessionWithMedia: Identifiable, Equatable, Sendable, Codable {
    let sessionId: Int
    let createdAt: String
    let media: [GalleryMedia]

    var id: Int { sessionId }

    nonisolated enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case createdAt = "created_at"
        case media
    }
}

/// Response from the gallery API endpoint
struct GalleryResponse: Sendable, Codable {
    let sessions: [SessionWithMedia]
}
