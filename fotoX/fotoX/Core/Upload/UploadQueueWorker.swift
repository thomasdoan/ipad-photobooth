//
//  UploadQueueWorker.swift
//  fotoX
//
//  Background upload queue processor for Worker/R2
//

import Foundation
import Sentry

actor UploadQueueWorker {
    private let store: UploadQueueStore
    private let historyStore: UploadHistoryStore
    private let apiClient: any WorkerAPIClientProtocol
    private let fileManager: FileManager
    let uploadsDirectory: URL
    private var isProcessing = false
    private var autoRetryTask: Task<Void, Never>?
    /// Tracks session IDs currently being processed to prevent duplicate concurrent uploads
    private var inFlightSessions: Set<String> = []
    
    /// Configured URLSession for uploads with explicit timeouts
    private let uploadSession: URLSession
    
    /// Default interval for automatic retry checks (30 seconds)
    static let defaultAutoRetryInterval: TimeInterval = 30
    
    /// Timeout for individual upload requests (30 seconds)
    static let uploadRequestTimeout: TimeInterval = 30
    
    /// Timeout for the entire upload resource - (1 minute)
    static let uploadResourceTimeout: TimeInterval = 60
    
    /// Minimum interval between auto-retry error logs to prevent spam (60 seconds)
    private static let autoRetryErrorLogThrottleInterval: TimeInterval = 60
    
    /// Timestamp of the last logged auto-retry error for throttling
    private var lastAutoRetryErrorLogTime: Date?

    init(
        store: UploadQueueStore = UploadQueueStore(),
        historyStore: UploadHistoryStore = UploadHistoryStore(),
        apiClient: any WorkerAPIClientProtocol = WorkerAPIClient.shared,
        fileManager: FileManager = .default,
        uploadsDirectory: URL? = nil
    ) {
        self.store = store
        self.historyStore = historyStore
        self.apiClient = apiClient
        self.fileManager = fileManager
        if let uploadsDirectory {
            self.uploadsDirectory = uploadsDirectory
        } else {
            let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.uploadsDirectory = documents.appendingPathComponent("Uploads", isDirectory: true)
        }
        
        // Configure upload session with explicit timeouts
        // Note: waitsForConnectivity is set to false so uploads fail fast when offline.
        // This lets auto-retry handle reconnection rather than waiting indefinitely,
        // since timeouts don't apply while waiting for connectivity.
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Self.uploadRequestTimeout
        config.timeoutIntervalForResource = Self.uploadResourceTimeout
        config.waitsForConnectivity = false
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true
        self.uploadSession = URLSession(configuration: config)
    }

    func enqueueSession(
        eventId: Int,
        session: Session,
        strips: [CapturedStrip],
        composite: CompositeStripAssets? = nil
    ) async throws {
        try ensureUploadsDirectory()

        let createdAt = ISO8601DateFormatter().string(from: Date())
        let sessionDir = uploadsDirectory.appendingPathComponent(session.sessionId, isDirectory: true)
        try fileManager.createDirectory(at: sessionDir, withIntermediateDirectories: true)

        var assets: [UploadQueueAsset] = []

        if let composite {
            let photoPath = sessionDir.appendingPathComponent(CompositeStripAssets.photoFileName)
            try composite.photoData.write(to: photoPath, options: .atomic)

            let photoRemotePath = remotePath(
                eventId: eventId,
                sessionId: session.sessionId,
                fileName: CompositeStripAssets.photoFileName
            )

            let photoAsset = UploadQueueAsset(
                id: UUID(),
                kind: .stripPhoto,
                stripIndex: CompositeStripAssets.stripIndex,
                sequenceIndex: AssetUploadMetadata.photoSequenceIndex,
                fileName: CompositeStripAssets.photoFileName,
                mimeType: "image/jpeg",
                localURL: photoPath,
                remotePath: photoRemotePath,
                sizeBytes: composite.photoData.count,
                durationSeconds: nil,
                posterPath: nil,
                state: .pending
            )

            assets.append(photoAsset)

            // Only process composite video if the file actually exists (won't exist in simulator)
            if fileManager.fileExists(atPath: composite.videoURL.path) {
                let videoPath = sessionDir.appendingPathComponent(CompositeStripAssets.videoFileName)
                if fileManager.fileExists(atPath: videoPath.path) {
                    try fileManager.removeItem(at: videoPath)
                }
                try fileManager.moveItem(at: composite.videoURL, to: videoPath)
                let videoRemotePath = remotePath(
                    eventId: eventId,
                    sessionId: session.sessionId,
                    fileName: CompositeStripAssets.videoFileName
                )
                let videoSize = try fileSize(at: videoPath)

                let videoAsset = UploadQueueAsset(
                    id: UUID(),
                    kind: .stripVideo,
                    stripIndex: CompositeStripAssets.stripIndex,
                    sequenceIndex: AssetUploadMetadata.videoSequenceIndex,
                    fileName: CompositeStripAssets.videoFileName,
                    mimeType: "video/mp4",
                    localURL: videoPath,
                    remotePath: videoRemotePath,
                    sizeBytes: videoSize,
                    durationSeconds: nil,
                    posterPath: photoRemotePath,
                    state: .pending
                )

                assets.append(videoAsset)
            }
        }

        for strip in strips {
            let photoFileName = "photo_\(strip.stripIndex).jpg"
            let photoPath = sessionDir.appendingPathComponent(photoFileName)
            try strip.photoData.write(to: photoPath, options: .atomic)

            let photoRemotePath = remotePath(
                eventId: eventId,
                sessionId: session.sessionId,
                fileName: photoFileName
            )

            let photoAsset = UploadQueueAsset(
                id: UUID(),
                kind: .photo,
                stripIndex: strip.stripIndex,
                sequenceIndex: AssetUploadMetadata.photoSequenceIndex,
                fileName: photoFileName,
                mimeType: "image/jpeg",
                localURL: photoPath,
                remotePath: photoRemotePath,
                sizeBytes: strip.photoData.count,
                durationSeconds: nil,
                posterPath: nil,
                state: .pending
            )

            let videoFileName = "video_\(strip.stripIndex).mov"
            let videoPath = sessionDir.appendingPathComponent(videoFileName)
            if fileManager.fileExists(atPath: videoPath.path) {
                try fileManager.removeItem(at: videoPath)
            }
            try fileManager.moveItem(at: strip.videoURL, to: videoPath)
            let videoRemotePath = remotePath(
                eventId: eventId,
                sessionId: session.sessionId,
                fileName: videoFileName
            )
            let videoSize = try fileSize(at: videoPath)

            let videoAsset = UploadQueueAsset(
                id: UUID(),
                kind: .video,
                stripIndex: strip.stripIndex,
                sequenceIndex: AssetUploadMetadata.videoSequenceIndex,
                fileName: videoFileName,
                mimeType: "video/quicktime",
                localURL: videoPath,
                remotePath: videoRemotePath,
                sizeBytes: videoSize,
                durationSeconds: nil,
                posterPath: photoRemotePath,
                state: .pending
            )

            assets.append(videoAsset)
            assets.append(photoAsset)
        }

        let queueSession = UploadQueueSession(
            id: session.sessionId,
            eventId: eventId,
            sessionId: session.sessionId,
            createdAt: createdAt,
            publicGalleryURL: session.universalURL,
            assets: assets,
            manifestState: .pending,
            completeState: .pending
        )

        try await store.addSession(queueSession)

        let breadcrumb = Breadcrumb(level: .info, category: "upload")
        breadcrumb.message = "Session enqueued"
        breadcrumb.data = [
            "session_id": session.sessionId,
            "event_id": eventId,
            "asset_count": assets.count
        ]
        SentrySDK.addBreadcrumb(breadcrumb)
    }

    func startProcessing(
        onProgress: (@MainActor @Sendable (String) -> Void)? = nil,
        onError: (@MainActor @Sendable (String, APIError) -> Void)? = nil
    ) async {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }

        do {
            let sessions = try await store.sessions()
            for session in sessions {
                // Skip if session is already being processed by retry
                guard !inFlightSessions.contains(session.sessionId) else { continue }
                
                // Mark session as in-flight before processing
                inFlightSessions.insert(session.sessionId)
                defer { inFlightSessions.remove(session.sessionId) }
                
                _ = try await process(session: session, onProgress: onProgress, onError: onError)
            }
        } catch let error as APIError {
            await MainActor.run {
                onError?("", error)
            }
        } catch {
            await MainActor.run {
                onError?("", .unknown(error))
            }
        }
    }

    func enqueueAndStart(
        eventId: Int,
        session: Session,
        strips: [CapturedStrip],
        composite: CompositeStripAssets? = nil,
        onProgress: (@MainActor @Sendable (String) -> Void)? = nil,
        onError: (@MainActor @Sendable (String, APIError) -> Void)? = nil
    ) async throws {
        try await enqueueSession(eventId: eventId, session: session, strips: strips, composite: composite)
        await startProcessing(onProgress: onProgress, onError: onError)
    }

    // MARK: - Public API for UI

    /// Returns current queue sessions for UI display
    func getQueueSessions() async throws -> [UploadQueueSession] {
        try await store.sessions()
    }

    /// Returns completed upload history
    func getCompletedHistory() async throws -> [CompletedUploadRecord] {
        try await historyStore.records()
    }

    /// Clears completed upload history
    func clearHistory() async throws {
        try await historyStore.clearAll()
    }

    /// Retries a single failed session by ID (manual retry resets retry count)
    func retrySession(
        sessionId: String,
        onProgress: (@MainActor @Sendable (String) -> Void)? = nil,
        onError: (@MainActor @Sendable (String, APIError) -> Void)? = nil
    ) async {
        // Prevent concurrent processing - check if already processing or session in flight
        guard !isProcessing, !inFlightSessions.contains(sessionId) else { return }
        
        do {
            let sessions = try await store.sessions()
            guard var session = sessions.first(where: { $0.sessionId == sessionId }) else {
                return
            }
            // Only retry if the session has failures
            guard uploadSessionStatus(session) == .failed else { return }
            
            // Reset retry count for manual retry (gives user fresh attempts)
            session.retryCount = 0
            try await store.updateSession(session)
            
            // Mark session as in-flight before processing
            inFlightSessions.insert(sessionId)
            defer { inFlightSessions.remove(sessionId) }
            
            _ = try await process(session: session, onProgress: onProgress, onError: onError)
        } catch let error as APIError {
            await MainActor.run { onError?(sessionId, error) }
        } catch {
            await MainActor.run { onError?(sessionId, .unknown(error)) }
        }
    }

    /// Retries all failed sessions (manual retry resets retry count)
    func retryAllFailed(
        onProgress: (@MainActor @Sendable (String) -> Void)? = nil,
        onError: (@MainActor @Sendable (String, APIError) -> Void)? = nil
    ) async {
        // Prevent concurrent processing with startProcessing
        guard !isProcessing else { return }
        
        do {
            let sessions = try await store.sessions()
            let failed = sessions.filter { uploadSessionStatus($0) == .failed }
            for session in failed {
                // Skip if session is already being processed
                guard !inFlightSessions.contains(session.sessionId) else { continue }
                
                // Reset retry count for manual retry (gives user fresh attempts)
                var resetSession = session
                resetSession.retryCount = 0
                try await store.updateSession(resetSession)
                
                // Mark session as in-flight before processing
                inFlightSessions.insert(session.sessionId)
                defer { inFlightSessions.remove(session.sessionId) }
                
                _ = try await process(session: resetSession, onProgress: onProgress, onError: onError)
            }
        } catch let error as APIError {
            await MainActor.run { onError?("", error) }
        } catch {
            await MainActor.run { onError?("", .unknown(error)) }
        }
    }
    
    /// Force retry a session - works for stuck uploading sessions too
    func forceRetrySession(
        sessionId: String,
        onProgress: (@MainActor @Sendable (String) -> Void)? = nil,
        onError: (@MainActor @Sendable (String, APIError) -> Void)? = nil
    ) async {
        // Remove from in-flight set first (might be stuck there)
        inFlightSessions.remove(sessionId)
        
        do {
            let sessions = try await store.sessions()
            guard var session = sessions.first(where: { $0.sessionId == sessionId }) else {
                return
            }
            
            // Don't retry if already complete
            guard session.status != .completed else { return }
            
            // Reset ALL non-uploaded states (including uploading) to pending
            session.assets = session.assets.map { asset in
                var asset = asset
                if asset.state != .uploaded {
                    asset.state = .pending
                }
                return asset
            }
            if session.manifestState != .uploaded {
                session.manifestState = .pending
            }
            if session.completeState != .uploaded {
                session.completeState = .pending
            }
            
            // Reset retry count and timestamp for manual retry
            session.retryCount = 0
            session.uploadStartedAt = nil
            try await store.updateSession(session)
            
            // Now process normally
            inFlightSessions.insert(sessionId)
            defer { inFlightSessions.remove(sessionId) }
            
            _ = try await process(session: session, onProgress: onProgress, onError: onError)
        } catch let error as APIError {
            await MainActor.run { onError?(sessionId, error) }
        } catch {
            await MainActor.run { onError?(sessionId, .unknown(error)) }
        }
    }
    
    /// Cancels an upload and resets it to pending state
    func cancelSession(sessionId: String) async {
        // Remove from in-flight to stop processing
        inFlightSessions.remove(sessionId)
        
        do {
            let sessions = try await store.sessions()
            guard var session = sessions.first(where: { $0.sessionId == sessionId }) else {
                return
            }
            
            // Reset uploading states to pending
            session.assets = session.assets.map { asset in
                var asset = asset
                if asset.state == .uploading {
                    asset.state = .pending
                }
                return asset
            }
            if session.manifestState == .uploading {
                session.manifestState = .pending
            }
            if session.completeState == .uploading {
                session.completeState = .pending
            }
            session.uploadStartedAt = nil
            
            try await store.updateSession(session)
        } catch {
            print("[UploadQueueWorker] Failed to cancel session: \(error)")
        }
    }
    
    // MARK: - Stale Upload Recovery
    
    /// Resets any sessions that appear to be stuck in uploading state
    /// Called on app startup and periodically before auto-retry
    func recoverStaleUploads() async {
        do {
            let sessions = try await store.sessions()
            for session in sessions where session.isStale {
                var recovered = session
                
                // Reset uploading states to failed (so they show in UI and get auto-retried)
                var hasMarkedAsFailed = false
                recovered.assets = session.assets.map { asset in
                    var asset = asset
                    if asset.state == .uploading || asset.state == .pending {
                        asset.state = .failed
                        hasMarkedAsFailed = true
                    }
                    return asset
                }
                if recovered.manifestState == .uploading {
                    recovered.manifestState = .failed
                }
                if recovered.completeState == .uploading {
                    recovered.completeState = .failed
                }
                
                // Clear the stale timestamp
                recovered.uploadStartedAt = nil
                
                // Remove from in-flight tracking
                inFlightSessions.remove(session.sessionId)
                
                try await store.updateSession(recovered)
                print("[UploadQueueWorker] Recovered stale session: \(session.sessionId)")
            }
        } catch {
            print("[UploadQueueWorker] Failed to recover stale uploads: \(error)")
        }
    }
    
    // MARK: - Auto Retry
    
    /// Starts periodic automatic retry of failed sessions
    /// - Parameter interval: Time between retry attempts (default 30 seconds)
    func startAutoRetry(interval: TimeInterval = defaultAutoRetryInterval) {
        // Cancel any existing task
        autoRetryTask?.cancel()
        
        autoRetryTask = Task {
            // Recover stale uploads immediately on startup (handles crash recovery)
            await recoverStaleUploads()
            
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                
                guard !Task.isCancelled else { break }
                
                // Recover stale uploads before retrying failed sessions
                await recoverStaleUploads()
                await autoRetryFailedSessions()
            }
        }
    }
    
    /// Stops the automatic retry timer
    func stopAutoRetry() {
        autoRetryTask?.cancel()
        autoRetryTask = nil
    }
    
    /// Automatically retries failed sessions that haven't exceeded max retry attempts
    /// Called periodically by the auto-retry timer
    func autoRetryFailedSessions(
        onProgress: (@MainActor @Sendable (String) -> Void)? = nil,
        onError: (@MainActor @Sendable (String, APIError) -> Void)? = nil
    ) async {
        // Prevent concurrent processing with startProcessing
        guard !isProcessing else { return }
        
        do {
            let sessions = try await store.sessions()
            // Only retry failed sessions that can still be auto-retried and aren't in flight
            let retryable = sessions.filter { session in
                uploadSessionStatus(session) == .failed 
                    && session.canAutoRetry 
                    && !inFlightSessions.contains(session.sessionId)
            }
            
            for session in retryable {
                // Double-check session isn't now in flight (actor re-entrancy)
                guard !inFlightSessions.contains(session.sessionId) else { continue }
                
                // Increment retry count before attempting
                var updatedSession = session
                updatedSession.retryCount += 1
                try await store.updateSession(updatedSession)
                
                // Mark session as in-flight before processing
                inFlightSessions.insert(session.sessionId)
                defer { inFlightSessions.remove(session.sessionId) }
                
                _ = try await process(session: updatedSession, onProgress: onProgress, onError: onError)
            }
        } catch {
            // Log with throttling to avoid spam - only log if enough time has passed since last error
            let now = Date()
            let shouldLog: Bool
            if let lastLog = lastAutoRetryErrorLogTime {
                shouldLog = now.timeIntervalSince(lastLog) >= Self.autoRetryErrorLogThrottleInterval
            } else {
                shouldLog = true
            }
            
            if shouldLog {
                lastAutoRetryErrorLogTime = now
                print("[UploadQueueWorker] Auto-retry failed: \(error.localizedDescription)")
                
                // Also invoke onError callback if provided
                let apiError: APIError
                if let err = error as? APIError {
                    apiError = err
                } else {
                    apiError = .unknown(error)
                }
                await MainActor.run {
                    onError?("auto-retry", apiError)
                }
            }
            // The session will be retried on the next interval regardless of logging
        }
    }
    
    /// Returns whether auto-retry is currently active
    var isAutoRetryActive: Bool {
        autoRetryTask != nil && autoRetryTask?.isCancelled == false
    }

    // MARK: - Processing

    private func process(
        session: UploadQueueSession,
        onProgress: (@MainActor @Sendable (String) -> Void)?,
        onError: (@MainActor @Sendable (String, APIError) -> Void)?
    ) async throws -> UploadQueueSession {
        var workingSession = resetFailures(in: session)
        
        // Mark upload start time for stale detection
        workingSession.uploadStartedAt = ISO8601DateFormatter().string(from: Date())
        try await store.updateSession(workingSession)

        let pendingAssets = workingSession.assets.filter { $0.state != .uploaded }
        if !pendingAssets.isEmpty {
            let presignRequest = PresignRequest(
                eventId: workingSession.eventId,
                sessionId: workingSession.sessionId,
                files: pendingAssets.map { asset in
                    PresignFile(path: asset.remotePath, contentType: asset.mimeType, sizeBytes: asset.sizeBytes)
                }
            )

            let presignResponse = try await apiClient.presign(request: presignRequest)
            let uploadMap = Dictionary(uniqueKeysWithValues: presignResponse.uploads.map { ($0.path, $0) })

            for index in workingSession.assets.indices {
                if workingSession.assets[index].state == .uploaded {
                    continue
                }
                let asset = workingSession.assets[index]
                guard let upload = uploadMap[asset.remotePath] else {
                    workingSession.assets[index].state = .failed
                    try await store.updateSession(workingSession)
                    return workingSession
                }

                workingSession.assets[index].state = .uploading
                try await store.updateSession(workingSession)

                do {
                    try await uploadFile(
                        urlString: upload.url,
                        method: upload.method,
                        fileURL: asset.localURL,
                        contentType: asset.mimeType
                    )
                    workingSession.assets[index].state = .uploaded
                    try await store.updateSession(workingSession)
                    await MainActor.run {
                        onProgress?(workingSession.sessionId)
                    }
                } catch {
                    SentrySDK.capture(error: error) { scope in
                        scope.setContext(value: [
                            "session_id": workingSession.sessionId,
                            "event_id": workingSession.eventId,
                            "asset": asset.fileName
                        ], key: "upload")
                    }
                    workingSession.assets[index].state = .failed
                    try await store.updateSession(workingSession)
                    await MainActor.run {
                        onError?(workingSession.sessionId, .uploadFailed("Upload failed for \(asset.fileName)"))
                    }
                    return workingSession
                }
            }
        }

        guard workingSession.assets.allSatisfy({ $0.state == .uploaded }) else {
            return workingSession
        }

        let manifestPath = remotePath(
            eventId: workingSession.eventId,
            sessionId: workingSession.sessionId,
            fileName: "manifest.json"
        )

        if workingSession.manifestState != .uploaded {
            let manifestData = try buildManifestData(from: workingSession)
            let presignRequest = PresignRequest(
                eventId: workingSession.eventId,
                sessionId: workingSession.sessionId,
                files: [
                    PresignFile(
                        path: manifestPath,
                        contentType: "application/json",
                        sizeBytes: manifestData.count
                    )
                ]
            )
            let presignResponse = try await apiClient.presign(request: presignRequest)
            guard let upload = presignResponse.uploads.first(where: { $0.path == manifestPath }) else {
                workingSession.manifestState = .failed
                try await store.updateSession(workingSession)
                return workingSession
            }

            workingSession.manifestState = .uploading
            try await store.updateSession(workingSession)

            do {
                try await uploadData(
                    urlString: upload.url,
                    method: upload.method,
                    data: manifestData,
                    contentType: "application/json"
                )
                workingSession.manifestState = .uploaded
                try await store.updateSession(workingSession)
            } catch {
                SentrySDK.capture(error: error) { scope in
                    scope.setContext(value: [
                        "session_id": workingSession.sessionId,
                        "event_id": workingSession.eventId,
                        "asset": "manifest.json"
                    ], key: "upload")
                }
                workingSession.manifestState = .failed
                try await store.updateSession(workingSession)
                await MainActor.run {
                    onError?(workingSession.sessionId, .uploadFailed("Manifest upload failed"))
                }
                return workingSession
            }
        }

        if workingSession.completeState != .uploaded {
            workingSession.completeState = .uploading
            try await store.updateSession(workingSession)

            do {
                let request = CompleteRequest(
                    eventId: workingSession.eventId,
                    sessionId: workingSession.sessionId,
                    manifestPath: manifestPath
                )
                _ = try await apiClient.complete(request: request)
                workingSession.completeState = .uploaded
                try await store.updateSession(workingSession)
            } catch {
                SentrySDK.capture(error: error) { scope in
                    scope.setContext(value: [
                        "session_id": workingSession.sessionId,
                        "event_id": workingSession.eventId,
                        "asset": "complete"
                    ], key: "upload")
                }
                workingSession.completeState = .failed
                try await store.updateSession(workingSession)
                await MainActor.run {
                    onError?(workingSession.sessionId, .uploadFailed("Failed to finalize upload"))
                }
                return workingSession
            }
        }

        // Record in history before removing from active queue
        let historyRecord = CompletedUploadRecord(
            id: workingSession.sessionId,
            sessionId: workingSession.sessionId,
            eventId: workingSession.eventId,
            createdAt: workingSession.createdAt,
            completedAt: ISO8601DateFormatter().string(from: Date()),
            assetCount: workingSession.assets.count,
            publicGalleryURL: workingSession.publicGalleryURL
        )
        do {
            try await historyStore.addRecord(historyRecord)
        } catch {
            // Log the error with context but don't fail the upload
            // The session completed successfully, history is non-critical
            print("[UploadQueueWorker] Failed to record CompletedUploadRecord in historyStore.addRecord for sessionId=\(workingSession.sessionId), eventId=\(workingSession.eventId): \(error)")
        }

        let completeBreadcrumb = Breadcrumb(level: .info, category: "upload")
        completeBreadcrumb.message = "Session upload complete"
        completeBreadcrumb.data = [
            "session_id": workingSession.sessionId,
            "event_id": workingSession.eventId,
            "asset_count": workingSession.assets.count
        ]
        SentrySDK.addBreadcrumb(completeBreadcrumb)

        try cleanupFiles(for: workingSession)
        try await store.removeSession(sessionId: workingSession.sessionId)
        return workingSession
    }

    private func resetFailures(in session: UploadQueueSession) -> UploadQueueSession {
        var updated = session
        updated.assets = session.assets.map { asset in
            var asset = asset
            if asset.state == .failed {
                asset.state = .pending
            }
            return asset
        }

        if updated.manifestState == .failed {
            updated.manifestState = .pending
        }

        if updated.completeState == .failed {
            updated.completeState = .pending
        }

        return updated
    }

    // MARK: - Helpers

    private func ensureUploadsDirectory() throws {
        if !fileManager.fileExists(atPath: uploadsDirectory.path) {
            try fileManager.createDirectory(at: uploadsDirectory, withIntermediateDirectories: true)
        }
    }

    private func fileSize(at url: URL) throws -> Int {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        return (attributes[.size] as? NSNumber)?.intValue ?? 0
    }

    private func remotePath(eventId: Int, sessionId: String, fileName: String) -> String {
        "events/\(eventId)/sessions/\(sessionId)/\(fileName)"
    }

    private func buildManifestData(from session: UploadQueueSession) throws -> Data {
        let assets = session.assets.map { asset in
            let assetId: String
            switch asset.kind {
            case .stripPhoto:
                assetId = "strip_photo"
            case .stripVideo:
                assetId = "strip_video"
            default:
                assetId = "strip\(asset.stripIndex)_\(asset.kind.rawValue)"
            }

            return SessionManifestAsset(
                id: assetId,
                kind: asset.kind,
                stripIndex: asset.stripIndex,
                sequenceIndex: asset.sequenceIndex,
                contentType: asset.mimeType,
                path: asset.remotePath,
                sizeBytes: asset.sizeBytes,
                durationSeconds: asset.durationSeconds,
                posterPath: asset.posterPath
            )
        }

        let manifest = SessionManifest(
            version: 1,
            eventId: session.eventId,
            sessionId: session.sessionId,
            createdAt: session.createdAt,
            publicGalleryURL: session.publicGalleryURL,
            assets: assets
        )

        let encoder = JSONEncoder()
        return try encoder.encode(manifest)
    }

    private func uploadFile(urlString: String, method: String, fileURL: URL, contentType: String) async throws {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        let (_, response) = try await uploadSession.upload(for: request, fromFile: fileURL)
        try validateUploadResponse(response)
    }

    private func uploadData(urlString: String, method: String, data: Data, contentType: String) async throws {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        let (_, response) = try await uploadSession.upload(for: request, from: data)
        try validateUploadResponse(response)
    }

    private func validateUploadResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: nil)
        }
    }

    private func cleanupFiles(for session: UploadQueueSession) throws {
        // Check if user wants to keep files on device
        if WorkerConfiguration.keepFilesAfterUpload() {
            return
        }

        for asset in session.assets {
            if fileManager.fileExists(atPath: asset.localURL.path) {
                try? fileManager.removeItem(at: asset.localURL)
            }
        }

        let sessionDir = uploadsDirectory.appendingPathComponent(session.sessionId, isDirectory: true)
        if fileManager.fileExists(atPath: sessionDir.path) {
            try? fileManager.removeItem(at: sessionDir)
        }
    }
}
