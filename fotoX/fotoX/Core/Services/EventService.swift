//
//  EventService.swift
//  fotoX
//
//  Service for fetching and managing events
//

import Foundation

/// Service for event-related API operations
@MainActor
final class EventService: EventServicing {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    /// Fetches all available events from the Pi
    func fetchEvents() async throws -> [Event] {
        let data = try await apiClient.fetchData(Endpoints.events)
        let decoder = JSONDecoder()
        return try decoder.decode([Event].self, from: data)
    }
    
    /// Fetches a specific event with full theme details
    func fetchEvent(id: Int) async throws -> Event {
        let data = try await apiClient.fetchData(Endpoints.event(id: id))
        let decoder = JSONDecoder()
        return try decoder.decode(Event.self, from: data)
    }
}
