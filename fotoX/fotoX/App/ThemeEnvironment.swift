//
//  ThemeEnvironment.swift
//  fotoX
//
//  Environment values and modifiers for theming
//

import SwiftUI

// MARK: - Environment Keys

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .default
}

private struct ThemeAssetsKey: EnvironmentKey {
    static let defaultValue: ThemeAssets? = nil
}

extension EnvironmentValues {
    /// The current app theme
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
    
    /// The current theme assets (cached images)
    var themeAssets: ThemeAssets? {
        get { self[ThemeAssetsKey.self] }
        set { self[ThemeAssetsKey.self] = newValue }
    }
}

// MARK: - View Modifiers

extension View {
    /// Applies the current theme to this view and its descendants
    func withTheme(_ theme: AppTheme, assets: ThemeAssets? = nil) -> some View {
        self
            .environment(\.appTheme, theme)
            .environment(\.themeAssets, assets)
    }
}

// MARK: - Themed View Components

/// A view that provides themed styling
struct ThemedBackground: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.themeAssets) private var assets
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [theme.secondary, theme.secondary.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Background image overlay if available
            if let backgroundImage = assets?.background {
                backgroundImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            }
        }
    }
}

/// A styled primary button using the theme
struct ThemedPrimaryButton: View {
    let title: String
    let action: () -> Void
    
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(theme.secondary)
                .padding(.horizontal, 48)
                .padding(.vertical, 16)
                .background(theme.primary)
                .clipShape(Capsule())
                .shadow(color: theme.primary.opacity(0.4), radius: 8, y: 4)
        }
    }
}

/// A styled secondary button using the theme
struct ThemedSecondaryButton: View {
    let title: String
    let action: () -> Void
    
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(theme.accent)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(theme.secondary.opacity(0.5))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(theme.accent.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

/// Event logo display with fallback
struct ThemedLogo: View {
    let size: CGFloat
    
    @Environment(\.themeAssets) private var assets
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        if let logo = assets?.logo {
            logo
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: size)
        } else {
            // Fallback icon
            Image(systemName: "camera.fill")
                .font(.system(size: size * 0.5))
                .foregroundStyle(theme.primary)
        }
    }
}

/// Photo frame overlay for capture preview
struct ThemedPhotoFrame: View {
    @Environment(\.themeAssets) private var assets
    
    var body: some View {
        if let frame = assets?.photoFrame {
            frame
                .resizable()
                .aspectRatio(contentMode: .fill)
                .allowsHitTesting(false)
        }
    }
}

