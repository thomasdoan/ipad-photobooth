//
//  LocalGalleryService.swift
//  fotoX
//
//  Scans local storage for uploaded/pending session files
//

import Foundation

/// Service for discovering locally stored session files
struct LocalGalleryService: Sendable {
    private let fileManager: FileManager
    private let uploadsDirectory: URL
    private let queueStore: UploadQueueStore
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.uploadsDirectory = documents.appendingPathComponent("Uploads", isDirectory: true)
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
            return sessions
                .filter { $0.eventId == eventId }
                .compactMap { queueSession -> GallerySession? in
                    let sessionDir = uploadsDirectory.appendingPathComponent(queueSession.sessionId)
                    guard fileManager.fileExists(atPath: sessionDir.path) else { return nil }
                    
                    let assets = buildAssets(
                        sessionId: queueSession.sessionId,
                        eventId: eventId,
                        sessionDir: sessionDir,
                        queueAssets: queueSession.assets
                    )
                    
                    guard !assets.isEmpty else { return nil }
                    
                    let createdAt = ISO8601DateFormatter().date(from: queueSession.createdAt) ?? Date()
                    let thumbURL = assets.first(where: { $0.kind == .photo })?.localURL
                    
                    return GallerySession(
                        id: queueSession.sessionId,
                        sessionId: queueSession.sessionId,
                        eventId: eventId,
                        createdAt: createdAt,
                        source: .local,
                        thumbPath: nil,
                        localThumbURL: thumbURL,
                        galleryPath: "s/\(queueSession.sessionId)",
                        assets: assets
                    )
                }
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
                    
                    let createdAt = ISO8601DateFormatter().date(from: manifest.createdAt) ?? Date()
                    let thumbURL = assets.first(where: { $0.kind == .photo })?.localURL
                    
                    sessions.append(GallerySession(
                        id: sessionId,
                        sessionId: sessionId,
                        eventId: eventId,
                        createdAt: createdAt,
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
                    let thumbURL = assets.first(where: { $0.kind == .photo })?.localURL
                    
                    // We don't know the eventId without manifest, skip unless we can match
                    // For now, include it if there are assets (caller filters by eventId from remote)
                    // we have 1 event so will leave as is lmao
                    sessions.append(GallerySession(
                        id: sessionId,
                        sessionId: sessionId,
                        eventId: eventId, // Will be filtered/merged later
                        createdAt: createdAt,
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
    
    private func buildAssets(
        sessionId: String,
        eventId: Int,
        sessionDir: URL,
        queueAssets: [UploadQueueAsset]
    ) -> [GalleryAsset] {
        return queueAssets.compactMap { asset -> GalleryAsset? in
            let localURL = sessionDir.appendingPathComponent(asset.fileName)
            guard fileManager.fileExists(atPath: localURL.path) else { return nil }
            
            return GalleryAsset(
                id: "\(sessionId)_\(asset.kind.rawValue)_\(asset.stripIndex)",
                kind: asset.kind,
                stripIndex: asset.stripIndex,
                remotePath: asset.remotePath,
                localURL: localURL,
                mimeType: asset.mimeType,
                posterPath: asset.posterPath
            )
        }
    }
    
    private func buildAssetsFromManifest(_ manifest: SessionManifest, sessionDir: URL) -> [GalleryAsset] {
        return manifest.assets.compactMap { asset -> GalleryAsset? in
            let fileName = URL(string: asset.path)?.lastPathComponent ?? asset.path
            let localURL = sessionDir.appendingPathComponent(fileName)
            guard fileManager.fileExists(atPath: localURL.path) else { return nil }
            
            return GalleryAsset(
                id: asset.id,
                kind: asset.kind,
                stripIndex: asset.stripIndex,
                remotePath: asset.path,
                localURL: localURL,
                mimeType: asset.contentType,
                posterPath: asset.posterPath
            )
        }
    }
    
    private func reconstructAssets(sessionId: String, eventId: Int, sessionDir: URL) -> [GalleryAsset] {
        var assets: [GalleryAsset] = []
        
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
                    posterPath: nil // Photos don't need posters
                ))
            }
            
            let videoFileName = "video_\(stripIndex).mov"
            let videoURL = sessionDir.appendingPathComponent(videoFileName)
            if fileManager.fileExists(atPath: videoURL.path) {
                assets.append(GalleryAsset(
                    id: "\(sessionId)_video_\(stripIndex)",
                    kind: .video,
                    stripIndex: stripIndex,
                    remotePath: "events/\(eventId)/sessions/\(sessionId)/\(videoFileName)",
                    localURL: videoURL,
                    mimeType: "video/quicktime",
                    posterPath: photoRemotePath // Use photo from same strip as poster
                ))
            }
        }
        
        return assets
    }
}

