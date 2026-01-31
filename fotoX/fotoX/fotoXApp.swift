//
//  fotoXApp.swift
//  fotoX
//
//  Main app entry point
//

import SwiftUI
import Sentry


@main
struct fotoXApp: App {
    @State private var appState = AppState()
    @State private var services: ServiceContainer
    @State private var testableServices: TestableServiceContainer

    @MainActor
    init() {
        // Register theme providers
        Self.registerThemeProviders()

        SentrySDK.start { options in
            options.dsn = "https://2aa3d859a1f0b1fe245e46d5589d65bd@o4510791751041024.ingest.us.sentry.io/4510792228601856"

            // Adds IP for users.
            // For more information, visit: https://docs.sentry.io/platforms/apple/data-management/data-collected/
            options.sendDefaultPii = true

            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0

            // Configure profiling. Visit https://docs.sentry.io/platforms/apple/profiling/ to learn more.
            options.configureProfiling = {
                $0.sessionSampleRate = 1.0 // We recommend adjusting this value in production.
                $0.lifecycle = .trace
            }

            // Uncomment the following lines to add more data to your events
            // options.attachScreenshot = true // This adds a screenshot to the error events
            // options.attachViewHierarchy = true // This adds the view hierarchy to the error events
            
            // Enable experimental logging features
            options.experimental.enableLogs = true
        }

        let useMocks = MockDataProvider.useMockData
        _services = State(initialValue: ServiceContainer())
        _testableServices = State(initialValue: TestableServiceContainer(useMocks: useMocks))
        
        if useMocks {
            print("Running with mock data")
        }
    }

    @MainActor
    private static func registerThemeProviders() {
        let registry = ThemeRegistry.shared
        let standardProvider = StandardThemeProvider()
        registry.register(standardProvider)
        registry.setDefaultProvider(standardProvider)
        registry.register(CasinoThemeProvider())
    }

    var body: some Scene {
        WindowGroup {
            RootView(services: services, testableServices: testableServices)
                .environment(appState)
                .withTheme(appState.currentTheme, assets: appState.themeAssets)
        }
    }
}

/// Root view that handles navigation based on app state
@MainActor
struct RootView: View {
    @Environment(AppState.self) private var appState
    let services: ServiceContainer
    let testableServices: TestableServiceContainer
    
    var body: some View {
        ZStack {
            // Background
            ThemedBackground()
            
            // Main content based on current route
            switch appState.currentRoute {
            case .eventSelection:
                EventSelectionView(services: services, testableServices: testableServices)
                    .transition(.opacity)
                
            case .idle:
                IdleView(services: services, testableServices: testableServices)
                    .transition(.opacity)
                
            case .capture:
                CaptureView(services: services)
                    .transition(.opacity)
                
            case .qrDisplay:
                QRView(services: services, testableServices: testableServices)
                    .transition(.opacity)
                
            case .settings:
                SettingsView(uploadQueueWorker: services.uploadQueueWorker)
                    .transition(.opacity)
                
            }

            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        appState.updateLayoutOrientation(for: geometry.size)
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        appState.updateLayoutOrientation(for: newSize)
                    }
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.currentRoute)
        .fotoXStatusBarHidden()
        .task {
            // Process any pending uploads on launch
            await services.uploadQueueWorker.startProcessing(
                onProgress: { sessionId in
                    if appState.currentSession?.sessionId == sessionId {
                        appState.assetUploaded()
                    }
                },
                onError: { sessionId, error in
                    if sessionId.isEmpty || appState.currentSession?.sessionId == sessionId {
                        appState.uploadFailed(error: error)
                    }
                }
            )
            
            // Start automatic retry for failed uploads (checks every 30 seconds)
            await services.uploadQueueWorker.startAutoRetry()
        }
        .sheet(isPresented: Binding(
            get: { appState.showSettings },
            set: { appState.showSettings = $0 }
        )) {
            SettingsView(uploadQueueWorker: services.uploadQueueWorker)
                .fotoXStatusBarHidden()
        }
        .fullScreenCover(isPresented: Binding(
            get: { appState.showGallery },
            set: { appState.showGallery = $0 }
        )) {
            if let eventId = appState.selectedEvent?.id {
                GalleryView(eventId: eventId)
                    .environment(appState)
                    .fotoXStatusBarHidden()
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { appState.currentError != nil },
                set: { if !$0 { appState.clearError() } }
            ),
            presenting: appState.currentError
        ) { _ in
            Button("OK") {
                appState.clearError()
            }
        } message: { error in
            Text(error.userMessage)
        }
    }
}
