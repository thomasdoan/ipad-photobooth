//
//  ThemeRegistry.swift
//  fotoX
//
//  Registry for mapping ThemeStyle to ThemeComponentProvider implementations
//

import SwiftUI

/// Singleton registry that maps ThemeStyle to ThemeComponentProvider implementations.
/// Providers are registered at app startup and retrieved when themes are applied.
@MainActor
final class ThemeRegistry: Sendable {
    /// Shared singleton instance
    static let shared = ThemeRegistry()

    /// Registered providers keyed by theme style
    private var providers: [ThemeStyle: ThemeComponentProvider] = [:]

    /// Default provider used when no specific provider is registered
    private var defaultProvider: ThemeComponentProvider?

    private init() {}

    /// Registers a theme component provider for its associated style.
    /// - Parameter provider: The provider to register
    func register(_ provider: ThemeComponentProvider) {
        providers[provider.style] = provider
        // Use the first registered provider as the default
        if defaultProvider == nil {
            defaultProvider = provider
        }
    }

    /// Sets the default provider to use when no specific provider is found.
    /// - Parameter provider: The default provider
    func setDefaultProvider(_ provider: ThemeComponentProvider) {
        defaultProvider = provider
    }

    /// Retrieves the provider for a given theme style.
    /// Falls back to the default provider if no specific one is registered.
    /// - Parameter style: The theme style to look up
    /// - Returns: The registered provider, or the default provider
    func provider(for style: ThemeStyle) -> ThemeComponentProvider {
        if let provider = providers[style] {
            return provider
        }
        // Fallback to default (standard) provider
        guard let fallback = defaultProvider ?? providers[.standard] else {
            fatalError("No theme provider registered for style '\(style)' and no default provider available")
        }
        return fallback
    }

    /// Clears all registered providers (useful for testing)
    func reset() {
        providers.removeAll()
        defaultProvider = nil
    }
}
