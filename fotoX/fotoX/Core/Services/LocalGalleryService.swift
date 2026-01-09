//
//  LocalGalleryService.swift
//  fotoX
//
//  Scans local storage for uploaded/pending session files
//

import Foundation
import os

/// Service for discovering locally stored session files
struct LocalGalleryService: Sendable {
    private let fileManager: FileManager
    private let uploadsDirectory: URL
    private let queueStore: UploadQueueStore

    private static let logger = Logger(subsystem: "fotoX", category: "DateParsing")

    init(fileManager: FileManager = .default, uploadsDirectory: URL? = nil) {
        self.fileManager = fileManager
        if let uploadsDirectory = uploadsDirectory {
            self.uploadsDirectory = uploadsDirectory
        } else {
            let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.uploadsDirectory = documents.appendingPathComponent("Uploads", isDirectory: true)
        }
        self.queueStore = UploadQueueStore(fileManager: fileManager)
    }
    
    /// Fetches all local sessions for a given event
    func fetchLocalSessions(eventId: Int) async -> [GallerySession] {
        // Get metadata from upload queue (includes eventId, createdAt, etc.)
        let queueSessions = await getQueueSessions(eventId: eventId)
        
        // Also scan uploads directory for completed sessions that may have been kept
        let directorySessions = await scanUploadsDirectory(eventId: eventId)
        
        // Merge: queue sessions take precedence for metadata
        var sessionMap: [String: GallerySession] = [:]
        
        for session in directorySessions {
            sessionMap[session.sessionId] = session
        }
        
        for session in queueSessions {
            sessionMap[session.sessionId] = session
        }
        
        return Array(sessionMap.values).sorted { $0.createdAt > $1.createdAt }
    }
    
    /// Gets sessions from the upload queue that have local files
    private func getQueueSessions(eventId: Int) async -> [GallerySession] {
        do {
            let sessions = try await queueStore.sessions()
            var results: [GallerySession] = []
            for queueSession in sessions where queueSession.eventId == eventId {
                let sessionDir = uploadsDirectory.appendingPathComponent(queueSession.sessionId)
                guard fileManager.fileExists(atPath: sessionDir.path) else { continue }
                
                let assets = buildAssets(
                    sessionId: queueSession.sessionId,
                    eventId: eventId,
                    sessionDir: sessionDir,
                    queueAssets: queueSession.assets
                )
                
                guard !assets.isEmpty else { continue }

                let parsedDate = Self.parseDate(
                    queueSession.createdAt,
                    fallbackURL: sessionDir,
                    fileManager: fileManager
                )
                let createdAt = parsedDate.date
                let thumbURL = assets.first(where: { $0.kind == .stripPhoto })?.localURL
                    ?? assets.first(where: { $0.kind == .photo })?.localURL

                results.append(GallerySession(
                    id: queueSession.sessionId,
                    sessionId: queueSession.sessionId,
                    eventId: eventId,
                    createdAt: createdAt,
                    timestampUncertain: parsedDate.timestampUncertain,
                    source: .local,
                    thumbPath: nil,
                    localThumbURL: thumbURL,
                    galleryPath: "s/\(queueSession.sessionId)",
                    assets: assets
                ))
            }
            return results
        } catch {
            return []
        }
    }
    
    /// Scans the uploads directory for sessions (for kept files after upload)
    private func scanUploadsDirectory(eventId: Int) async -> [GallerySession] {
        guard fileManager.fileExists(atPath: uploadsDirectory.path) else { return [] }
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: uploadsDirectory,
                includingPropertiesForKeys: [.isDirectoryKey, .creationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            var sessions: [GallerySession] = []
            
            for itemURL in contents {
                let resourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey, .creationDateKey])
                guard resourceValues.isDirectory == true else { continue }
                
                let sessionId = itemURL.lastPathComponent
                
                // Try to read manifest for metadata
                let manifestURL = itemURL.appendingPathComponent("manifest.json")
                if let manifest = readManifest(at: manifestURL), manifest.eventId == eventId {
                    let assets = buildAssetsFromManifest(manifest, sessionDir: itemURL)
                    guard !assets.isEmpty else { continue }

                    let parsedDate = Self.parseDate(
                        manifest.createdAt,
                        fallbackURL: itemURL,
                        fileManager: fileManager
                    )
                    let createdAt = parsedDate.date
                    let thumbURL = assets.first(where: { $0.kind == .stripPhoto })?.localURL
                        ?? assets.first(where: { $0.kind == .photo })?.localURL

                    sessions.append(GallerySession(
                        id: sessionId,
                        sessionId: sessionId,
                        eventId: eventId,
                        createdAt: createdAt,
                        timestampUncertain: parsedDate.timestampUncertain,
                        source: .local,
                        thumbPath: nil,
                        localThumbURL: thumbURL,
                        galleryPath: "s/\(sessionId)",
                        assets: assets
                    ))
                } else {
                    // No manifest - reconstruct from files
                    // We need to match by scanning existing files
                    let assets = reconstructAssets(sessionId: sessionId, eventId: eventId, sessionDir: itemURL)
                    guard !assets.isEmpty else { continue }

                    let createdAt = resourceValues.creationDate ?? Date()
                    let timestampUncertain = resourceValues.creationDate == nil
                    let thumbURL = assets.first(where: { $0.kind == .stripPhoto })?.localURL
                        ?? assets.first(where: { $0.kind == .photo })?.localURL

                    // We don't know the eventId without manifest, skip unless we can match
                    // For now, include it if there are assets (caller filters by eventId from remote)
                    // we have 1 event so will leave as is lmao
                    sessions.append(GallerySession(
                        id: sessionId,
                        sessionId: sessionId,
                        eventId: eventId, // Will be filtered/merged later
                        createdAt: createdAt,
                        timestampUncertain: timestampUncertain,
                        source: .local,
                        thumbPath: nil,
                        localThumbURL: thumbURL,
                        galleryPath: "s/\(sessionId)",
                        assets: assets
                    ))
                }
            }
            
            return sessions
        } catch {
            return []
        }
    }
    
    private func readManifest(at url: URL) -> SessionManifest? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SessionManifest.self, from: data)
    }

    static func parseDate(
        _ value: String,
        fallbackURL: URL?,
        fileManager: FileManager
    ) -> (date: Date, timestampUncertain: Bool) {
        if let parsedDate = try? Date(value, strategy: .iso8601) {
            return (parsedDate, false)
        }

        if let fallbackURL,
           let attributes = try? fileManager.attributesOfItem(atPath: fallbackURL.path),
           let creationDate = attributes[.creationDate] as? Date {
            Self.logger.warning("Failed to parse session date: \(value). Using file creation date.")
            return (creationDate, false)
        }

        Self.logger.warning("Failed to parse session date: \(value). File creation date unavailable; timestamp marked uncertain.")
        return (Date(), true)
    }
    
    private func buildAssets(
        sessionId: String,
        eventId: Int,
        sessionDir: URL,
        queueAssets: [UploadQueueAsset]
    ) -> [GalleryAsset] {
        // First pass: build a map of strip index to photo URLs for poster lookup
        var photoURLsByStrip: [Int: URL] = [:]
        for asset in queueAssets where asset.kind.isPhoto {
            let localURL = sessionDir.appendingPathComponent(asset.fileName)
            if fileManager.fileExists(atPath: localURL.path) {
                photoURLsByStrip[asset.stripIndex] = localURL
            }
        }

        // Second pass: build assets with poster URLs for videos
        return queueAssets.compactMap { asset -> GalleryAsset? in
            let localURL = sessionDir.appendingPathComponent(asset.fileName)
            guard fileManager.fileExists(atPath: localURL.path) else { return nil }

            // For videos, find the local poster URL from the same strip
            let localPosterURL: URL? = if asset.kind.isVideo {
                photoURLsByStrip[asset.stripIndex]
            } else {
                nil
            }

            return GalleryAsset(
                id: "\(sessionId)_\(asset.kind.rawValue)_\(asset.stripIndex)",
                kind: asset.kind,
                stripIndex: asset.stripIndex,
                remotePath: asset.remotePath,
                localURL: localURL,
                mimeType: asset.mimeType,
                posterPath: asset.posterPath,
                localPosterURL: localPosterURL
            )
        }
    }
    
    private func buildAssetsFromManifest(_ manifest: SessionManifest, sessionDir: URL) -> [GalleryAsset] {
        // First pass: build a map of strip index to photo URLs for poster lookup
        var photoURLsByStrip: [Int: URL] = [:]
        for asset in manifest.assets where asset.kind.isPhoto {
            let fileName = URL(string: asset.path)?.lastPathComponent ?? asset.path
            let localURL = sessionDir.appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: localURL.path) {
                photoURLsByStrip[asset.stripIndex] = localURL
            }
        }

        // Second pass: build assets with poster URLs for videos
        return manifest.assets.compactMap { asset -> GalleryAsset? in
            let fileName = URL(string: asset.path)?.lastPathComponent ?? asset.path
            let localURL = sessionDir.appendingPathComponent(fileName)
            guard fileManager.fileExists(atPath: localURL.path) else { return nil }

            // For videos, find the local poster URL from the same strip
            let localPosterURL: URL? = if asset.kind.isVideo {
                photoURLsByStrip[asset.stripIndex]
            } else {
                nil
            }

            return GalleryAsset(
                id: asset.id,
                kind: asset.kind,
                stripIndex: asset.stripIndex,
                remotePath: asset.path,
                localURL: localURL,
                mimeType: asset.contentType,
                posterPath: asset.posterPath,
                localPosterURL: localPosterURL
            )
        }
    }
    
    private func reconstructAssets(sessionId: String, eventId: Int, sessionDir: URL) -> [GalleryAsset] {
        var assets: [GalleryAsset] = []

        let stripPhotoURL = sessionDir.appendingPathComponent(CompositeStripAssets.photoFileName)
        let stripPhotoRemotePath = "events/\(eventId)/sessions/\(sessionId)/\(CompositeStripAssets.photoFileName)"
        if fileManager.fileExists(atPath: stripPhotoURL.path) {
            assets.append(GalleryAsset(
                id: "\(sessionId)_strip_photo",
                kind: .stripPhoto,
                stripIndex: CompositeStripAssets.stripIndex,
                remotePath: stripPhotoRemotePath,
                localURL: stripPhotoURL,
                mimeType: "image/jpeg",
                posterPath: nil,
                localPosterURL: nil
            ))
        }

        let stripVideoURL = sessionDir.appendingPathComponent(CompositeStripAssets.videoFileName)
        if fileManager.fileExists(atPath: stripVideoURL.path) {
            let localPosterURL = fileManager.fileExists(atPath: stripPhotoURL.path) ? stripPhotoURL : nil
            assets.append(GalleryAsset(
                id: "\(sessionId)_strip_video",
                kind: .stripVideo,
                stripIndex: CompositeStripAssets.stripIndex,
                remotePath: "events/\(eventId)/sessions/\(sessionId)/\(CompositeStripAssets.videoFileName)",
                localURL: stripVideoURL,
                mimeType: "video/mp4",
                posterPath: stripPhotoRemotePath,
                localPosterURL: localPosterURL
            ))
        }

        // Look for standard file patterns: photo_0.jpg, video_0.mov, etc.
        for stripIndex in 0..<3 {
            let photoFileName = "photo_\(stripIndex).jpg"
            let photoURL = sessionDir.appendingPathComponent(photoFileName)
            let photoRemotePath = "events/\(eventId)/sessions/\(sessionId)/\(photoFileName)"

            if fileManager.fileExists(atPath: photoURL.path) {
                assets.append(GalleryAsset(
                    id: "\(sessionId)_photo_\(stripIndex)",
                    kind: .photo,
                    stripIndex: stripIndex,
                    remotePath: photoRemotePath,
                    localURL: photoURL,
                    mimeType: "image/jpeg",
                    posterPath: nil, // Photos don't need posters
                    localPosterURL: nil
                ))
            }

            let videoFileName = "video_\(stripIndex).mov"
            let videoURL = sessionDir.appendingPathComponent(videoFileName)
            if fileManager.fileExists(atPath: videoURL.path) {
                // Check if the photo from this strip exists locally for the poster
                let localPosterURL = fileManager.fileExists(atPath: photoURL.path) ? photoURL : nil

                assets.append(GalleryAsset(
                    id: "\(sessionId)_video_\(stripIndex)",
                    kind: .video,
                    stripIndex: stripIndex,
                    remotePath: "events/\(eventId)/sessions/\(sessionId)/\(videoFileName)",
                    localURL: videoURL,
                    mimeType: "video/quicktime",
                    posterPath: photoRemotePath, // Use photo from same strip as poster
                    localPosterURL: localPosterURL
                ))
            }
        }

        return assets
    }
}
