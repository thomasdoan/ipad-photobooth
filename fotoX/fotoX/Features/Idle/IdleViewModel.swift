//
//  IdleViewModel.swift
//  fotoX
//
//  ViewModel for the idle/attract screen
//

import Foundation
import Observation

/// ViewModel for the idle screen
@Observable
final class IdleViewModel {
    // MARK: - State
    
    /// Whether a session is being created
    var isCreatingSession: Bool = false
    
    /// Error message to display
    var errorMessage: String?
    
    /// Whether to show the error alert
    var showError: Bool = false
    
    // MARK: - Dependencies
    
    private let sessionService: SessionService
    private let testableServices: TestableServiceContainer?
    
    // MARK: - Initialization
    
    init(sessionService: SessionService, testableServices: TestableServiceContainer? = nil) {
        self.sessionService = sessionService
        self.testableServices = testableServices
    }
    
    // MARK: - Actions
    
    /// Starts a new capture session
    @MainActor
    func startSession(appState: AppState) async {
        guard let event = appState.selectedEvent else {
            errorMessage = "No event selected"
            showError = true
            return
        }
        
        guard !isCreatingSession else { return }
        
        isCreatingSession = true
        errorMessage = nil
        
        do {
            let session: Session
            if let testable = testableServices {
                session = try await testable.createSession(eventId: event.id)
            } else {
                session = try await sessionService.createSession(eventId: event.id)
            }
            appState.startSession(with: session)
        } catch let error as APIError {
            errorMessage = error.userMessage
            showError = true
        } catch {
            errorMessage = "Failed to start session. Please try again."
            showError = true
        }
        
        isCreatingSession = false
    }
    
    /// Clears the error
    func clearError() {
        errorMessage = nil
        showError = false
    }
}

