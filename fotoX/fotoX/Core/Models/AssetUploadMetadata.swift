//
//  AssetUploadMetadata.swift
//  fotoX
//
//  Metadata for uploading captured assets to the Pi
//

import Foundation

/// Type of captured asset
enum AssetKind: String, Codable, Sendable {
    case photo
    case video
    case stripPhoto = "strip_photo"
    case stripVideo = "strip_video"
}

extension AssetKind {
    var isVideo: Bool {
        self == .video || self == .stripVideo
    }

    var isPhoto: Bool {
        self == .photo || self == .stripPhoto
    }

    var isComposite: Bool {
        self == .stripPhoto || self == .stripVideo
    }
}

/// Metadata attached to asset uploads
struct AssetUploadMetadata: Sendable {
    let kind: AssetKind
    let stripIndex: Int
    let sequenceIndex: Int
    
    /// Sequence index for video (always 0)
    static let videoSequenceIndex = 0
    
    /// Sequence index for photo (always 1, captured after video)
    static let photoSequenceIndex = 1
}

/// Response from asset upload endpoint
struct AssetUploadResponse: Sendable {
    let assetId: Int?
    let status: String?
}

extension AssetUploadResponse: Codable {
    nonisolated enum CodingKeys: String, CodingKey {
        case assetId = "asset_id"
        case status
    }
}

/// Represents a captured strip with video and photo data
struct CapturedStrip: Sendable {
    let stripIndex: Int
    let videoURL: URL
    let photoData: Data
    let thumbnailData: Data?
}

/// Represents all captured data for a session
struct SessionCapture: Sendable {
    let sessionId: String
    let strips: [CapturedStrip]
    
    var totalAssetCount: Int {
        strips.count * 2 // video + photo per strip
    }
}
