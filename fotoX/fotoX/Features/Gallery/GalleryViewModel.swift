//
//  GalleryViewModel.swift
//  fotoX
//
//  ViewModel for managing gallery state and data
//

import Foundation
import Observation

/// ViewModel for the gallery screen
@Observable
@MainActor
final class GalleryViewModel {
    // MARK: - State

    var sessions: [SessionWithMedia] = []
    var isLoading = false
    var errorMessage: String?
    var showError = false

    // MARK: - Dependencies

    private let sessionService: SessionService

    // MARK: - Initialization

    init(sessionService: SessionService) {
        self.sessionService = sessionService
    }

    // MARK: - Actions

    /// Loads gallery data for the specified event
    func loadGallery(eventId: Int) async {
        isLoading = true
        errorMessage = nil
        showError = false

        do {
            let response = try await sessionService.fetchEventGallery(eventId: eventId)
            sessions = response.sessions
            isLoading = false
        } catch let error as APIError {
            errorMessage = error.userMessage
            showError = true
            isLoading = false
        } catch {
            errorMessage = "Failed to load gallery: \(error.localizedDescription)"
            showError = true
            isLoading = false
        }
    }

    /// Clears the current error
    func clearError() {
        showError = false
        errorMessage = nil
    }

    /// Gets all media items flattened from sessions
    var allMedia: [GalleryMedia] {
        sessions.flatMap { $0.media }
    }

    /// Gets media grouped by session
    var groupedBySessions: [(session: SessionWithMedia, media: [GalleryMedia])] {
        sessions.map { session in
            (session: session, media: session.media)
        }
    }
}
