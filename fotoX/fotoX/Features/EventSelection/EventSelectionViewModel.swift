//
//  EventSelectionViewModel.swift
//  fotoX
//
//  ViewModel for event selection screen
//

import Foundation
import Observation

/// ViewModel for the event selection screen
@Observable
final class EventSelectionViewModel<EventService: EventServicing> {
    // MARK: - State
    
    /// List of available events
    var events: [Event] = []
    
    /// Whether events are being loaded
    var isLoading: Bool = false
    
    /// Error message to display
    var errorMessage: String?
    
    /// Whether to show the error alert
    var showError: Bool = false
    
    // MARK: - Dependencies
    
    private let eventService: EventService
    private let themeService: ThemeService
    private let testableServices: TestableServiceContainer?
    
    // MARK: - Initialization
    
    init(eventService: EventService, themeService: ThemeService, testableServices: TestableServiceContainer? = nil) {
        self.eventService = eventService
        self.themeService = themeService
        self.testableServices = testableServices
    }
    
    // MARK: - Actions
    
    /// Loads events from the Pi (or mock data in test mode)
    @MainActor
    func loadEvents() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Use testable services if available (for mock data)
            if let testable = testableServices {
                events = try await testable.fetchEvents()
            } else {
                events = try await eventService.fetchEvents()
            }
        } catch let error as APIError {
            errorMessage = error.userMessage
            showError = true
        } catch {
            errorMessage = "Failed to load events. Please check your connection."
            showError = true
        }
        
        isLoading = false
    }
    
    /// Selects an event and loads its theme assets
    @MainActor
    func selectEvent(_ event: Event, appState: AppState) async {
        isLoading = true
        
        // First, set the event and theme
        appState.selectEvent(event)
        
        // Then load theme assets in background
        let appTheme = AppTheme(from: event.theme)
        
        do {
            let assets = try await themeService.loadThemeAssets(for: appTheme)
            appState.themeAssets = assets
        } catch {
            // Theme assets are optional, continue without them
            print("Failed to load theme assets: \(error)")
        }
        
        isLoading = false
    }
    
    /// Refreshes the events list
    @MainActor
    func refresh() async {
        await loadEvents()
    }
    
    /// Clears the error
    func clearError() {
        errorMessage = nil
        showError = false
    }
}
