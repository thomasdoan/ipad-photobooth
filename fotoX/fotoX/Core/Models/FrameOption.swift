//
//  FrameOption.swift
//  fotoX
//
//  Local strip frame selection options
//

import SwiftUI

/// Represents a selectable local strip frame option.
///
/// Note: Frames are loaded from the asset catalog when possible, with a fallback
/// to raw bundled resources (e.g. `Chinese.png`).
struct FrameOption: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    /// Name to load (asset name or bundled filename without extension).
    let frameName: String

    init(id: String, displayName: String, frameName: String) {
        self.id = id
        self.displayName = displayName
        self.frameName = frameName
    }

    /// Known local frames shipped with the app.
    ///
    /// If a frame cannot be loaded at runtime, the UI will silently omit it.
    static let availableFrames: [FrameOption] = [
        FrameOption(id: "manilla-forever", displayName: "Manilla Forever", frameName: "Manilla Forever"),
        FrameOption(id: "jackzeu", displayName: "JackZeu", frameName: "JackZeu"),
        FrameOption(id: "innerbloom", displayName: "Innerbloom", frameName: "Innerbloom"),
        FrameOption(id: "we-found-love", displayName: "We Found Love", frameName: "We Found Love"),
        FrameOption(id: "hong-kong", displayName: "Hong Kong", frameName: "Hong Kong"),
        FrameOption(id: "dicey", displayName: "Dicey", frameName: "Dicey"),
        FrameOption(id: "queen-of-hearts", displayName: "Queen of Hearts", frameName: "Queen of Hearts"),
        FrameOption(id: "cherry-on-top", displayName: "Cherry On Top", frameName: "Cherry On Top"),
        FrameOption(id: "got-game", displayName: "Got Game", frameName: "Got Game"),
        FrameOption(id: "lucky-you", displayName: "Lucky You", frameName: "Lucky You"),
        FrameOption(id: "kindred-characters", displayName: "Kindred Characters", frameName: "Kindred Characters"),
        FrameOption(id: "calendar", displayName: "Calendar", frameName: "Calendar"),
        FrameOption(id: "best-map-app", displayName: "Best Map App", frameName: "Best Map App"),
        FrameOption(id: "your-queen-and-king", displayName: "Your Queen and King", frameName: "Your Queen and King"),
        FrameOption(id: "let-me-take-you-out", displayName: "Let Me Take You Out", frameName: "Let Me Take You Out"),
        FrameOption(id: "its-a-deal", displayName: "It's A Deal", frameName: "Its A Deal"),
        FrameOption(id: "orientation", displayName: "Orientation", frameName: "Orientation"),
        FrameOption(id: "take-you-out-again", displayName: "Take You Out Again", frameName: "Take You Out Again"),
        FrameOption(id: "post-game", displayName: "Post Game", frameName: "Post Game"),
        FrameOption(id: "movieticket", displayName: "Movie Ticket", frameName: "MovieTicket"),
        // FrameOption(id: "all-in", displayName: "All In", frameName: "All In"),
        // FrameOption(id: "engaged", displayName: "Engaged", frameName: "Engaged"),
        // FrameOption(id: "jackpot", displayName: "JackPot", frameName: "JackPot"),
    ]

    /// Attempts to load the frame image for use as a themed strip overlay.
    @MainActor
    func loadFrameImage() -> Image? {
        FrameImageLoader.loadImage(named: frameName)
    }
}

/// Loads frame images from either the asset catalog or raw bundled resources.
@MainActor
enum FrameImageLoader {
    static func loadImage(named name: String) -> Image? {
        if let uiImage = UIImage(named: name) {
            return Image(uiImage: uiImage)
        }

        // Fallback: raw resource in bundle (e.g. "Chinese.png", "CustomStripFrame.2.png")
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let uiImage = UIImage(contentsOfFile: url.path) {
            return Image(uiImage: uiImage)
        }

        if let url = Bundle.main.url(forResource: name, withExtension: "jpg"),
           let uiImage = UIImage(contentsOfFile: url.path) {
            return Image(uiImage: uiImage)
        }

        return nil
    }
}

