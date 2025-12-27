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
    let uploadQueueWorker: UploadQueueWorker
    
    init() {
        self.eventService = LocalEventService()
        self.sessionService = LocalSessionService()
        self.themeService = ThemeService()
        self.uploadQueueWorker = UploadQueueWorker()
    }
}
