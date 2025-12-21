//
//  Event.swift
//  fotoX
//
//  Core model for photobooth events
//

import Foundation

/// Represents a photobooth event with associated theme
struct Event: Identifiable, Equatable, Sendable {
    let id: Int
    let name: String
    let date: String
    let theme: Theme
    
    /// Formatted display date
    @MainActor
    var displayDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let parsedDate = dateFormatter.date(from: date) else { return date }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .long
        return displayFormatter.string(from: parsedDate)
    }
}

extension Event: Codable {}

/// Response wrapper for events list endpoint
struct EventsResponse: Sendable {
    let events: [Event]
}

extension EventsResponse: Codable {}

