//
//  Theme.swift
//  fotoX
//
//  Core model for event theming configuration
//

import Foundation
import SwiftUI

/// Available theme styles for customized UI experiences
enum ThemeStyle: String, Codable, Sendable, CaseIterable {
    case standard
    case casino
    case balatro
    case mahjong
}

extension ThemeStyle {
    var defaultColors: (primary: String, secondary: String, accent: String) {
        switch self {
        case .standard:
            return ("#FF4081", "#212121", "#FFFFFF")
        case .casino:
            return ("#DC143C", "#000000", "#FFD700")
        case .balatro:
            return ("#FF2D6A", "#1a1a2e", "#4DEEEA")
        case .mahjong:
            return ("#B22222", "#1D4E3E", "#F5F5DC")  // Red primary, jade secondary, ivory accent
        }
    }
}

/// Theme configuration for customizing the photobooth UI per event
struct Theme: Equatable, Sendable {
    let id: Int
    let themeStyle: ThemeStyle
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
        case themeStyle = "theme_style"
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        themeStyle = try container.decodeIfPresent(ThemeStyle.self, forKey: .themeStyle) ?? .standard
        primaryColor = try container.decode(String.self, forKey: .primaryColor)
        secondaryColor = try container.decode(String.self, forKey: .secondaryColor)
        accentColor = try container.decode(String.self, forKey: .accentColor)
        fontFamily = try container.decode(String.self, forKey: .fontFamily)
        logoURL = try container.decodeIfPresent(String.self, forKey: .logoURL)
        backgroundURL = try container.decodeIfPresent(String.self, forKey: .backgroundURL)
        photoFrameURL = try container.decodeIfPresent(String.self, forKey: .photoFrameURL)
        stripFrameURL = try container.decodeIfPresent(String.self, forKey: .stripFrameURL)
        stripFooterText = try container.decodeIfPresent(String.self, forKey: .stripFooterText)
    }
}

/// Resolved theme with parsed colors and URLs for use in SwiftUI views
struct AppTheme: Equatable, Sendable {
    let id: Int
    let style: ThemeStyle
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
        self.style = theme.themeStyle
        let colors = theme.themeStyle.defaultColors
        self.primary = Color(hex: colors.primary) ?? .pink
        self.secondary = Color(hex: colors.secondary) ?? .black
        self.accent = Color(hex: colors.accent) ?? .white
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
            self.stripFrameURL = stripFrameValue.isEmpty ? nil : URL(string: stripFrameValue)
        }
        self.stripFooterText = theme.stripFooterText
    }
    
    /// Default theme for when no event is selected
    static let `default` = AppTheme(
        id: 0,
        style: .standard,
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
        style: ThemeStyle,
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
        self.style = style
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
