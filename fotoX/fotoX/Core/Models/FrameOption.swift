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
        FrameOption(id: "innerbloom", displayName: "Innerbloom", frameName: "Innerbloom"),
        FrameOption(id: "wefoundlove", displayName: "We Found Love", frameName: "WeFoundLoveFrame"),
        FrameOption(id: "movieticket", displayName: "Movie Ticket", frameName: "MovieTicket"),
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

