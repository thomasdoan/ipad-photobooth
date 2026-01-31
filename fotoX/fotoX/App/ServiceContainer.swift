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
    let emailCollectionService: EmailCollectionService

    init() {
        self.eventService = LocalEventService()
        self.emailCollectionService = EmailCollectionService()
        self.sessionService = LocalSessionService(emailCollectionService: emailCollectionService)
        self.themeService = ThemeService()
        self.uploadQueueWorker = UploadQueueWorker()
    }
}
