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
}

struct UploadQueueSnapshot: Codable, Sendable {
    var sessions: [UploadQueueSession]
}
