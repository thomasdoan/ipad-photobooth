//
//  UploadQueueWorker.swift
//  fotoX
//
//  Background upload queue processor for Worker/R2
//

import Foundation

actor UploadQueueWorker {
    private let store: UploadQueueStore
    private let apiClient: WorkerAPIClient
    private let fileManager: FileManager
    private let uploadsDirectory: URL
    private var isProcessing = false

    init(
        store: UploadQueueStore = UploadQueueStore(),
        apiClient: WorkerAPIClient = WorkerAPIClient(),
        fileManager: FileManager = .default
    ) {
        self.store = store
        self.apiClient = apiClient
        self.fileManager = fileManager
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.uploadsDirectory = documents.appendingPathComponent("Uploads", isDirectory: true)
    }

    func enqueueSession(eventId: Int, session: Session, strips: [CapturedStrip]) async throws {
        try ensureUploadsDirectory()

        let createdAt = ISO8601DateFormatter().string(from: Date())
        let sessionDir = uploadsDirectory.appendingPathComponent(session.sessionId, isDirectory: true)
        try fileManager.createDirectory(at: sessionDir, withIntermediateDirectories: true)

        var assets: [UploadQueueAsset] = []

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

            assets.append(photoAsset)
            assets.append(videoAsset)
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
        onProgress: (@MainActor @Sendable (String) -> Void)? = nil,
        onError: (@MainActor @Sendable (String, APIError) -> Void)? = nil
    ) async throws {
        try await enqueueSession(eventId: eventId, session: session, strips: strips)
        await startProcessing(onProgress: onProgress, onError: onError)
    }

    // MARK: - Processing

    private func process(
        session: UploadQueueSession,
        onProgress: (@MainActor @Sendable (String) -> Void)?,
        onError: (@MainActor @Sendable (String, APIError) -> Void)?
    ) async throws -> UploadQueueSession {
        var workingSession = resetFailures(in: session)
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
                workingSession.completeState = .failed
                try await store.updateSession(workingSession)
                await MainActor.run {
                    onError?(workingSession.sessionId, .uploadFailed("Failed to finalize upload"))
                }
                return workingSession
            }
        }

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
            SessionManifestAsset(
                id: "strip\(asset.stripIndex)_\(asset.kind.rawValue)",
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

        let (_, response) = try await URLSession.shared.upload(for: request, fromFile: fileURL)
        try validateUploadResponse(response)
    }

    private func uploadData(urlString: String, method: String, data: Data, contentType: String) async throws {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.upload(for: request, from: data)
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
