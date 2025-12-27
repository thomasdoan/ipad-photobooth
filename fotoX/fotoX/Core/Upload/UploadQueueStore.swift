//
//  UploadQueueStore.swift
//  fotoX
//
//  Disk-backed upload queue store
//

import Foundation

actor UploadQueueStore {
    private let fileManager: FileManager
    private let fileURL: URL
    private var snapshot = UploadQueueSnapshot(sessions: [])
    private var isLoaded = false

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documents.appendingPathComponent("upload_queue.json")
    }

    func loadIfNeeded() async throws {
        guard !isLoaded else { return }
        defer { isLoaded = true }

        guard fileManager.fileExists(atPath: fileURL.path) else {
            snapshot = UploadQueueSnapshot(sessions: [])
            return
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        snapshot = try decoder.decode(UploadQueueSnapshot.self, from: data)
    }

    func sessions() async throws -> [UploadQueueSession] {
        try await loadIfNeeded()
        return snapshot.sessions
    }

    func addSession(_ session: UploadQueueSession) async throws {
        try await loadIfNeeded()
        snapshot.sessions.append(session)
        try persist()
    }

    func updateSession(_ session: UploadQueueSession) async throws {
        try await loadIfNeeded()
        if let index = snapshot.sessions.firstIndex(where: { $0.sessionId == session.sessionId }) {
            snapshot.sessions[index] = session
        } else {
            snapshot.sessions.append(session)
        }
        try persist()
    }

    func removeSession(sessionId: String) async throws {
        try await loadIfNeeded()
        snapshot.sessions.removeAll { $0.sessionId == sessionId }
        try persist()
    }

    private func persist() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
    }
}
