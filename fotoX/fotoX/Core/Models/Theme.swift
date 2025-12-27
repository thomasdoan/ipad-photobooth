//
//  Theme.swift
//  fotoX
//
//  Core model for event theming configuration
//

import Foundation
import SwiftUI

/// Theme configuration for customizing the photobooth UI per event
struct Theme: Equatable, Sendable {
    let id: Int
    let primaryColor: String
    let secondaryColor: String
    let accentColor: String
    let fontFamily: String
    let logoURL: String?
    let backgroundURL: String?
    let photoFrameURL: String?
    let stripFrameURL: String?

    // Bundled asset names (from app's asset catalog)
    // These take precedence over URLs if provided
    let logoAsset: String?
    let backgroundAsset: String?
    let photoFrameAsset: String?
    let stripFrameAsset: String?

    init(
        id: Int,
        primaryColor: String,
        secondaryColor: String,
        accentColor: String,
        fontFamily: String,
        logoURL: String? = nil,
        backgroundURL: String? = nil,
        photoFrameURL: String? = nil,
        stripFrameURL: String? = nil,
        logoAsset: String? = nil,
        backgroundAsset: String? = nil,
        photoFrameAsset: String? = nil,
        stripFrameAsset: String? = nil
    ) {
        self.id = id
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.accentColor = accentColor
        self.fontFamily = fontFamily
        self.logoURL = logoURL
        self.backgroundURL = backgroundURL
        self.photoFrameURL = photoFrameURL
        self.stripFrameURL = stripFrameURL
        self.logoAsset = logoAsset
        self.backgroundAsset = backgroundAsset
        self.photoFrameAsset = photoFrameAsset
        self.stripFrameAsset = stripFrameAsset
    }
}

extension Theme: Codable {
    nonisolated enum CodingKeys: String, CodingKey {
        case id
        case primaryColor = "primary_color"
        case secondaryColor = "secondary_color"
        case accentColor = "accent_color"
        case fontFamily = "font_family"
        case logoURL = "logo_url"
        case backgroundURL = "background_url"
        case photoFrameURL = "photo_frame_url"
        case stripFrameURL = "strip_frame_url"
        case logoAsset = "logo_asset"
        case backgroundAsset = "background_asset"
        case photoFrameAsset = "photo_frame_asset"
        case stripFrameAsset = "strip_frame_asset"
    }
}

/// Resolved theme with parsed colors and URLs for use in SwiftUI views
struct AppTheme: Equatable, Sendable {
    let id: Int
    let primary: Color
    let secondary: Color
    let accent: Color
    let fontFamily: String
    let logoURL: URL?
    let backgroundURL: URL?
    let photoFrameURL: URL?
    let stripFrameURL: URL?

    // Bundled asset names (from app's asset catalog)
    let logoAsset: String?
    let backgroundAsset: String?
    let photoFrameAsset: String?
    let stripFrameAsset: String?

    /// Creates an AppTheme from a raw Theme model
    init(from theme: Theme) {
        self.id = theme.id
        self.primary = Color(hex: theme.primaryColor) ?? .pink
        self.secondary = Color(hex: theme.secondaryColor) ?? .black
        self.accent = Color(hex: theme.accentColor) ?? .white
        self.fontFamily = theme.fontFamily
        self.logoURL = theme.logoURL.flatMap { URL(string: $0) }
        self.backgroundURL = theme.backgroundURL.flatMap { URL(string: $0) }
        self.photoFrameURL = theme.photoFrameURL.flatMap { URL(string: $0) }
        self.stripFrameURL = theme.stripFrameURL.flatMap { URL(string: $0) }
        self.logoAsset = theme.logoAsset
        self.backgroundAsset = theme.backgroundAsset
        self.photoFrameAsset = theme.photoFrameAsset
        self.stripFrameAsset = theme.stripFrameAsset
    }

    /// Default theme for when no event is selected
    static let `default` = AppTheme(
        id: 0,
        primary: Color(hex: "#FF4081") ?? .pink,
        secondary: Color(hex: "#212121") ?? .black,
        accent: .white,
        fontFamily: "system",
        logoURL: nil,
        backgroundURL: nil,
        photoFrameURL: nil,
        stripFrameURL: nil,
        logoAsset: nil,
        backgroundAsset: nil,
        photoFrameAsset: nil,
        stripFrameAsset: nil
    )

    private init(
        id: Int,
        primary: Color,
        secondary: Color,
        accent: Color,
        fontFamily: String,
        logoURL: URL?,
        backgroundURL: URL?,
        photoFrameURL: URL?,
        stripFrameURL: URL?,
        logoAsset: String?,
        backgroundAsset: String?,
        photoFrameAsset: String?,
        stripFrameAsset: String?
    ) {
        self.id = id
        self.primary = primary
        self.secondary = secondary
        self.accent = accent
        self.fontFamily = fontFamily
        self.logoURL = logoURL
        self.backgroundURL = backgroundURL
        self.photoFrameURL = photoFrameURL
        self.stripFrameURL = stripFrameURL
        self.logoAsset = logoAsset
        self.backgroundAsset = backgroundAsset
        self.photoFrameAsset = photoFrameAsset
        self.stripFrameAsset = stripFrameAsset
    }
}

