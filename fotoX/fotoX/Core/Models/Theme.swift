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
    let stripFooterText: String?
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
        case stripFooterText = "strip_footer_text"
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
    let stripFrameAssetName: String?
    let stripFooterText: String?
    
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
        let stripFrameValue = theme.stripFrameURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if stripFrameValue.lowercased().hasPrefix("asset:") {
            let assetName = stripFrameValue.dropFirst("asset:".count)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            self.stripFrameAssetName = assetName.isEmpty ? nil : String(assetName)
            self.stripFrameURL = nil
        } else {
            self.stripFrameAssetName = nil
            self.stripFrameURL = theme.stripFrameURL.flatMap { URL(string: $0) }
        }
        self.stripFooterText = theme.stripFooterText
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
        stripFrameAssetName: nil,
        stripFooterText: nil
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
        stripFrameAssetName: String?,
        stripFooterText: String?
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
        self.stripFrameAssetName = stripFrameAssetName
        self.stripFooterText = stripFooterText
    }
}
