//
//  fotoXApp.swift
//  fotoX
//
//  Main app entry point
//

import SwiftUI

@main
struct fotoXApp: App {
    @State private var appState = AppState()
    @State private var services: ServiceContainer
    @State private var testableServices: TestableServiceContainer
    
    init() {
        let useMocks = MockDataProvider.useMockData
        _services = State(initialValue: ServiceContainer())
        _testableServices = State(initialValue: TestableServiceContainer(useMocks: useMocks))
        
        if useMocks {
            print("🧪 Running with mock data")
        }
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
                
            case .uploading:
                UploadView(services: services, testableServices: testableServices)
                    .transition(.opacity)
                
            case .qrDisplay:
                QRView(services: services, testableServices: testableServices)
                    .transition(.opacity)
                
            case .settings:
                SettingsView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.currentRoute)
        .task {
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
        }
        .sheet(isPresented: Binding(
            get: { appState.showSettings },
            set: { appState.showSettings = $0 }
        )) {
            SettingsView()
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
