//
//  GalleryViewModel.swift
//  fotoX
//
//  ViewModel for the event gallery screen
//

import Foundation
import Observation

/// ViewModel for displaying event gallery with local and remote sessions
@Observable
final class GalleryViewModel {
    // MARK: - State

    /// All sessions for the event (merged local + remote)
    var sessions: [GallerySession] = []

    /// Whether data is loading
    var isLoading: Bool = false

    /// Error message if load failed
    var errorMessage: String?

    /// Currently selected session for detail view
    var selectedSession: GallerySession?

    // MARK: - Dependencies

    private let eventId: Int
    private let localGalleryService: LocalGalleryService
    private let apiClient: WorkerAPIClient

    /// Shared ISO8601 date formatter for parsing timestamps
    private static let iso8601Formatter = ISO8601DateFormatter()
    
    // MARK: - Initialization
    
    init(eventId: Int, localGalleryService: LocalGalleryService = LocalGalleryService(), apiClient: WorkerAPIClient = .shared) {
        self.eventId = eventId
        self.localGalleryService = localGalleryService
        self.apiClient = apiClient
    }
    
    // MARK: - Actions
    
    /// Loads sessions from both local storage and remote API
    @MainActor
    func loadSessions() async {
        isLoading = true
        errorMessage = nil
        
        // Load local and remote in parallel
        async let localSessions = localGalleryService.fetchLocalSessions(eventId: eventId)
        async let remoteSessions = fetchRemoteSessions()
        
        let (local, remote) = await (localSessions, remoteSessions)
        
        // Merge sessions: local takes precedence for file URLs
        sessions = mergeSessions(local: local, remote: remote)
        
        isLoading = false
    }
    
    /// Refreshes sessions
    @MainActor
    func refresh() async {
        await loadSessions()
    }
    
    // MARK: - Private
    
    private func fetchRemoteSessions() async -> [GallerySession] {
        do {
            let eventIndex = try await apiClient.fetchEventSessions(eventId: eventId)
            var sessions: [GallerySession] = []
            sessions.reserveCapacity(eventIndex.sessions.count)
            for indexSession in eventIndex.sessions {
                let createdAt = Self.iso8601Formatter.date(from: indexSession.createdAt) ?? Date()
                sessions.append(GallerySession(
                    id: indexSession.sessionId,
                    sessionId: indexSession.sessionId,
                    eventId: eventId,
                    createdAt: createdAt,
                    source: .remote,
                    thumbPath: indexSession.thumbPath,
                    localThumbURL: nil,
                    galleryPath: indexSession.galleryPath,
                    assets: [] // Assets loaded on demand in detail view
                ))
            }
            return sessions
        } catch {
            // Don't fail entirely if remote is unavailable - show local only
            await MainActor.run {
                if sessions.isEmpty {
                    errorMessage = "Could not load remote sessions: \(error.localizedDescription)"
                }
            }
            return []
        }
    }
    
    private func mergeSessions(local: [GallerySession], remote: [GallerySession]) -> [GallerySession] {
        var sessionMap: [String: GallerySession] = [:]
        
        // Add remote sessions first
        for session in remote {
            sessionMap[session.sessionId] = session
        }
        
        // Merge local sessions (they have file URLs)
        for localSession in local {
            if var existing = sessionMap[localSession.sessionId] {
                // Session exists both locally and remotely
                existing = GallerySession(
                    id: existing.id,
                    sessionId: existing.sessionId,
                    eventId: existing.eventId,
                    createdAt: existing.createdAt,
                    source: .both,
                    thumbPath: existing.thumbPath,
                    localThumbURL: localSession.localThumbURL,
                    galleryPath: existing.galleryPath,
                    assets: localSession.assets // Use local assets with file URLs
                )
                sessionMap[localSession.sessionId] = existing
            } else {
                // Only exists locally (pending upload or kept files)
                sessionMap[localSession.sessionId] = localSession
            }
        }
        
        // Sort by creation date (newest first)
        return Array(sessionMap.values).sorted { $0.createdAt > $1.createdAt }
    }
}
