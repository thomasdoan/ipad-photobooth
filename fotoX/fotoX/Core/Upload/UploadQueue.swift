//
//  UploadQueue.swift
//  fotoX
//
//  Persisted upload queue models
//

import Foundation

enum UploadQueueItemState: String, Codable, Sendable {
    case pending
    case uploading
    case uploaded
    case failed
}

struct UploadQueueAsset: Identifiable, Codable, Sendable {
    let id: UUID
    let kind: AssetKind
    let stripIndex: Int
    let sequenceIndex: Int
    let fileName: String
    let mimeType: String
    let localURL: URL
    let remotePath: String
    let sizeBytes: Int
    let durationSeconds: Double?
    let posterPath: String?
    var state: UploadQueueItemState
}

struct UploadQueueSession: Identifiable, Codable, Sendable {
    let id: String
    let eventId: Int
    let sessionId: String
    let createdAt: String
    let publicGalleryURL: String
    var assets: [UploadQueueAsset]
    var manifestState: UploadQueueItemState
    var completeState: UploadQueueItemState
    /// Number of automatic retry attempts made for this session
    /// Default to 0 for backward compatibility with older persisted JSON
    var retryCount: Int = 0
    
    /// Maximum number of automatic retry attempts before requiring manual intervention
    static let maxAutoRetries = 5
    
    // Custom init with default retryCount for backward compatibility
    init(
        id: String,
        eventId: Int,
        sessionId: String,
        createdAt: String,
        publicGalleryURL: String,
        assets: [UploadQueueAsset],
        manifestState: UploadQueueItemState,
        completeState: UploadQueueItemState,
        retryCount: Int = 0
    ) {
        self.id = id
        self.eventId = eventId
        self.sessionId = sessionId
        self.createdAt = createdAt
        self.publicGalleryURL = publicGalleryURL
        self.assets = assets
        self.manifestState = manifestState
        self.completeState = completeState
        self.retryCount = retryCount
    }
}

struct UploadQueueSnapshot: Codable, Sendable {
    var sessions: [UploadQueueSession]
}

// MARK: - Session Status

/// Summary status of a queue session for UI display
enum UploadQueueSessionStatus: String, Codable, Sendable {
    case pending
    case uploading
    case failed
    case completed
}

/// Computes the overall status of an upload session
func uploadSessionStatus(_ session: UploadQueueSession) -> UploadQueueSessionStatus {
    // If completeState is uploaded, session is done
    if session.completeState == .uploaded {
        return .completed
    }
    // If any asset, manifest, or complete is failed
    if session.assets.contains(where: { $0.state == .failed })
        || session.manifestState == .failed
        || session.completeState == .failed {
        return .failed
    }
    // If any asset or manifest is currently uploading
    if session.assets.contains(where: { $0.state == .uploading })
        || session.manifestState == .uploading
        || session.completeState == .uploading {
        return .uploading
    }
    return .pending
}

extension UploadQueueSession {
    /// Derived overall status for UI display
    var status: UploadQueueSessionStatus {
        uploadSessionStatus(self)
    }

    /// Number of assets successfully uploaded
    var uploadedAssetCount: Int {
        assets.filter { $0.state == .uploaded }.count
    }

    /// Total number of assets
    var totalAssetCount: Int {
        assets.count
    }
    
    /// Whether this session can be automatically retried (hasn't exceeded max retries)
    var canAutoRetry: Bool {
        retryCount < Self.maxAutoRetries
    }
    
    /// Whether this session requires manual intervention (exceeded max auto-retries)
    var requiresManualRetry: Bool {
        status == .failed && retryCount >= Self.maxAutoRetries
    }

    /// Human-readable progress string
    var progressSummary: String {
        if status == .completed {
            return "Complete"
        }
        if status == .failed {
            if requiresManualRetry {
                return "Retry required"
            }
            let failedCount = assets.filter { $0.state == .failed }.count
            let manifestFailed = manifestState == .failed ? 1 : 0
            let completeFailed = completeState == .failed ? 1 : 0
            let totalFailed = failedCount + manifestFailed + completeFailed
            return "\(totalFailed) failed"
        }
        return "\(uploadedAssetCount)/\(totalAssetCount) assets"
    }
}

// MARK: - Upload History

/// A record of a completed upload session for history display
struct CompletedUploadRecord: Identifiable, Codable, Sendable {
    let id: String          // sessionId
    let sessionId: String
    let eventId: Int
    let createdAt: String
    let completedAt: String
    let assetCount: Int
    let publicGalleryURL: String
}

/// Container for completed upload history
struct UploadHistorySnapshot: Codable, Sendable {
    var records: [CompletedUploadRecord]
}
