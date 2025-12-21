//
//  ServiceContainer.swift
//  fotoX
//
//  Dependency container for services
//

import Foundation

/// Container holding all service dependencies
@MainActor
final class ServiceContainer: Sendable {
    let apiClient: APIClient
    let eventService: EventService
    let sessionService: SessionService
    let themeService: ThemeService
    
    init(baseURL: URL = APIClient.defaultBaseURL) {
        let client = APIClient(baseURL: baseURL)
        self.apiClient = client
        self.eventService = EventService(apiClient: client)
        self.sessionService = SessionService(apiClient: client)
        self.themeService = ThemeService()
    }
}

