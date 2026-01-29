//
//  UploadQueueViewModel.swift
//  fotoX
//
//  ViewModel for the upload queue management screen
//

import Foundation
import Observation

enum UploadQueueFilter {
    case all
    case failed
}

@Observable
@MainActor
final class UploadQueueViewModel {
    // MARK: - State

    /// Active queue sessions (pending, uploading, failed)
    var activeSessions: [UploadQueueSession] = []

    /// Completed upload history records
    var completedRecords: [CompletedUploadRecord] = []

    /// Whether data is loading
    var isLoading: Bool = false

    /// Whether a retry operation is in progress
    var isRetrying: Bool = false

    /// Error message for display
    var errorMessage: String?

    /// Session ID currently being retried (for per-row spinner)
    var retryingSessionId: String?

    /// Filter for active sessions
    var filter: UploadQueueFilter = .all

    // MARK: - Dependencies

    private let worker: UploadQueueWorker

    // MARK: - Initialization

    init(worker: UploadQueueWorker) {
        self.worker = worker
    }

    // MARK: - Computed

    /// Filtered sessions based on current filter
    var filteredSessions: [UploadQueueSession] {
        switch filter {
        case .all:
            return activeSessions
        case .failed:
            return activeSessions.filter { $0.status == .failed }
        }
    }

    /// Whether there are any failed sessions
    var hasFailedSessions: Bool {
        activeSessions.contains { $0.status == .failed }
    }

    /// Count of failed sessions
    var failedCount: Int {
        activeSessions.filter { $0.status == .failed }.count
    }

    /// Whether the queue is empty (no active sessions)
    var isQueueEmpty: Bool {
        activeSessions.isEmpty
    }

    /// Whether history is empty
    var isHistoryEmpty: Bool {
        completedRecords.isEmpty
    }

    // MARK: - Data Loading

    /// Loads both active queue and history
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let queueSessions = worker.getQueueSessions()
            async let history = worker.getCompletedHistory()

            let (sessions, records) = try await (queueSessions, history)
            activeSessions = sessions
            completedRecords = records
        } catch {
            errorMessage = "Failed to load queue data: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Refreshes data (called by pull-to-refresh or timer)
    func refresh() async {
        do {
            async let queueSessions = worker.getQueueSessions()
            async let history = worker.getCompletedHistory()

            let (sessions, records) = try await (queueSessions, history)
            activeSessions = sessions
            completedRecords = records
        } catch {
            // Silent refresh failure -- don't overwrite existing data
        }
    }

    // MARK: - Retry Actions

    /// Retries a single failed session
    func retrySession(sessionId: String) async {
        retryingSessionId = sessionId
        isRetrying = true

        await worker.retrySession(sessionId: sessionId)

        isRetrying = false
        retryingSessionId = nil

        // Refresh to show updated state
        await refresh()
    }

    /// Retries all failed sessions
    func retryAllFailed() async {
        isRetrying = true

        await worker.retryAllFailed()

        isRetrying = false

        // Refresh to show updated state
        await refresh()
    }
    
    /// Force retries a session (works for stuck uploading sessions too)
    func forceRetrySession(sessionId: String) async {
        retryingSessionId = sessionId
        isRetrying = true

        await worker.forceRetrySession(sessionId: sessionId)

        isRetrying = false
        retryingSessionId = nil

        // Refresh to show updated state
        await refresh()
    }
    
    /// Cancels an in-progress upload and resets it to pending
    func cancelSession(sessionId: String) async {
        await worker.cancelSession(sessionId: sessionId)
        
        // Refresh to show updated state
        await refresh()
    }

    /// Clears completed upload history
    func clearHistory() async {
        do {
            try await worker.clearHistory()
            completedRecords = []
        } catch {
            errorMessage = "Failed to clear history"
        }
    }
}
