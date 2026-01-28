//
//  UploadHistoryStore.swift
//  fotoX
//
//  Disk-backed store for completed upload history
//

import Foundation

actor UploadHistoryStore {
    private let fileManager: FileManager
    private let fileURL: URL
    private var snapshot = UploadHistorySnapshot(records: [])
    private var isLoaded = false

    /// Maximum number of history records to keep
    let maxRecords: Int

    init(fileManager: FileManager = .default, fileName: String = "upload_history.json", maxRecords: Int = 1000) {
        self.fileManager = fileManager
        self.maxRecords = maxRecords
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documents.appendingPathComponent(fileName)
    }

    private func loadIfNeeded() throws {
        guard !isLoaded else { return }
        defer { isLoaded = true }

        guard fileManager.fileExists(atPath: fileURL.path) else {
            snapshot = UploadHistorySnapshot(records: [])
            return
        }

        let data = try Data(contentsOf: fileURL)
        snapshot = try JSONDecoder().decode(UploadHistorySnapshot.self, from: data)
    }

    func records() throws -> [CompletedUploadRecord] {
        try loadIfNeeded()
        return snapshot.records
    }

    func addRecord(_ record: CompletedUploadRecord) throws {
        try loadIfNeeded()
        snapshot.records.insert(record, at: 0) // newest first
        // Trim to max
        if snapshot.records.count > maxRecords {
            snapshot.records = Array(snapshot.records.prefix(maxRecords))
        }
        try persist()
    }

    func clearAll() throws {
        snapshot = UploadHistorySnapshot(records: [])
        try persist()
    }

    private func persist() throws {
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
    }
}
