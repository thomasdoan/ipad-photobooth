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
    let eventService: LocalEventService
    let sessionService: LocalSessionService
    let themeService: ThemeService
    
    init() {
        let galleryBaseURL = WorkerConfiguration.currentBaseURL()
        self.eventService = LocalEventService()
        self.sessionService = LocalSessionService(galleryBaseURL: galleryBaseURL)
        self.themeService = ThemeService()
    }
}
