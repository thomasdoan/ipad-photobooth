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
    let coupleName1: String?
    let coupleName2: String?
    let hashtag: String?

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

    /// Combined couple's names (e.g., "Jack & Zeu")
    var coupleDisplayName: String? {
        switch (coupleName1, coupleName2) {
        case let (name1?, name2?):
            return "\(name1) & \(name2)"
        case let (name?, nil), let (nil, name?):
            return name
        case (nil, nil):
            return nil
        }
    }
}

extension Event: Codable {
    nonisolated enum CodingKeys: String, CodingKey {
        case id
        case name
        case date
        case theme
        case coupleName1 = "couple_name_1"
        case coupleName2 = "couple_name_2"
        case hashtag
    }
}

/// Response wrapper for events list endpoint
struct EventsResponse: Sendable {
    let events: [Event]
}

extension EventsResponse: Codable {}

