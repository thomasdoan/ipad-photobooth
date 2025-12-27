//
//  LocalEventService.swift
//  fotoX
//
//  Bundled event source (ready for future manifest override)
//

import Foundation

@MainActor
final class LocalEventService: EventServicing {
    func fetchEvents() async throws -> [Event] {
        return BundledEventStore.events
    }

    func fetchEvent(id: Int) async throws -> Event {
        guard let event = BundledEventStore.events.first(where: { $0.id == id }) else {
            throw APIError.httpError(statusCode: 404, message: "Event not found")
        }
        return event
    }
}

private enum BundledEventStore {
    static let events: [Event] = [
        Event(
            id: 1,
            name: "JackZeu's Wedding Shower",
            date: "2026-01-31",
            theme: Theme(
                id: 1,
                primaryColor: "#FF4081",
                secondaryColor: "#212121",
                accentColor: "#FFFFFF",
                fontFamily: "system",
                logoURL: nil,
                backgroundURL: nil,
                photoFrameURL: nil,
                stripFrameURL: nil,
                logoAsset: nil,
                backgroundAsset: nil,
                // Use a bundled frame asset - add "WeddingFrame" to Assets.xcassets
                // Generate with: python tools/frame_generator.py --type text --event "JackZeu's Wedding Shower" --date "January 31, 2026" --color "#FF4081" -o WeddingFrame.png
                photoFrameAsset: "WeddingFrame",
                stripFrameAsset: nil
            )
        ),
        // Event(
        //     id: 2,
        //     name: "Corporate Holiday Party",
        //     date: "2025-12-20",
        //     theme: Theme(
        //         id: 2,
        //         primaryColor: "#0066CC",
        //         secondaryColor: "#1A1A2E",
        //         accentColor: "#FFFFFF",
        //         fontFamily: "system",
        //         logoURL: nil,
        //         backgroundURL: nil,
        //         photoFrameURL: nil,
        //         stripFrameURL: nil,
        //         logoAsset: nil,
        //         backgroundAsset: nil,
        //         photoFrameAsset: "CorporateFrame",
        //         stripFrameAsset: nil
        //     )
        // ),
    ]
}
