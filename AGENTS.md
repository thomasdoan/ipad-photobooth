# Agent Context - FotoX iPad App

> Quick context for AI agents working on this codebase

## What is this?

FotoX is an iPad photobooth app built in **Swift/SwiftUI**. It talks to a Raspberry Pi backend over local WiFi to:
1. Fetch events with custom themes
2. Capture 3 strips of video+photo per session  
3. Upload media to the Pi
4. Display QR codes for guests

## Tech Stack

| Layer | Technology |
|-------|------------|
| UI | SwiftUI (iOS 17+) |
| State | @Observable (Swift Observation framework) |
| Networking | URLSession + async/await |
| Camera | AVFoundation |
| Testing | Swift Testing + XCUITest |

## Key Files to Read First

```
fotoX/fotoX/
├── fotoXApp.swift              # App entry, DI setup
├── App/AppState.swift          # Central state (like Redux store)
├── App/AppRouter.swift         # Route definitions
├── Core/Networking/APIClient.swift    # HTTP client
└── Core/Models/                # Data types
```

## Architecture Overview

```
User Flow:
EventSelection → Idle → Capture (×3 strips) → Upload → QR Display
      ↑                                                    │
      └────────────────────────────────────────────────────┘
```

## State Management Pattern

```swift
// Central state - like Zustand/Redux
@Observable class AppState {
    var currentRoute: AppRoute = .eventSelection
    var selectedEvent: Event?
    var currentSession: Session?
}

// Access in views via @Environment
@Environment(AppState.self) private var appState
```

## Navigation Pattern

```swift
// Route enum (not react-router style)
enum AppRoute {
    case eventSelection
    case idle
    case capture(CapturePhase)
    case uploading
    case qrDisplay
    case settings
}

// Navigate by changing state
appState.currentRoute = .idle
```

## API Endpoints (Pi Backend)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/events` | GET | List events |
| `/events/{id}` | GET | Event details |
| `/sessions` | POST | Create session |
| `/sessions/{id}/assets` | POST | Upload media |
| `/sessions/{id}/qr` | GET | Get QR PNG |
| `/sessions/{id}/email` | POST | Submit email |

Base URL: `http://booth.local/api` (configurable)

## File Naming Conventions

```
Feature/
├── FeatureView.swift       # SwiftUI View
├── FeatureViewModel.swift  # @Observable state/logic
```

## Common Patterns

### View + ViewModel
```swift
struct MyView: View {
    @State private var viewModel = MyViewModel()
    var body: some View { ... }
}

@Observable class MyViewModel {
    var items: [Item] = []
    func load() async { ... }
}
```

### Async Data Loading
```swift
.task {
    await viewModel.loadData()
}
```

### Service Injection
```swift
// Services passed as parameters, not singletons
struct MyView: View {
    let services: ServiceContainer
}
```

## Testing

- **Unit tests**: `fotoXTests/` - Model parsing, state logic
- **UI tests**: `fotoXUITests/` - E2E flows with mock data
- **Mock flag**: `--use-mock-data` launch argument

## Key Gotchas

1. **Swift 6 Concurrency**: Project uses strict concurrency. Models need `Sendable`, async code needs proper isolation.

2. **Camera**: Only works on real iPad, not simulator.

3. **Main Actor**: Views and ViewModels are `@MainActor` by default (project setting).

4. **Codable**: JSON keys use snake_case, Swift uses camelCase. See `CodingKeys` enums.

## Making Changes

### Add a new screen
1. Create `Features/NewFeature/NewFeatureView.swift`
2. Create `Features/NewFeature/NewFeatureViewModel.swift`
3. Add route to `AppRouter.swift`
4. Add case to switch in `RootView`

### Add a new API endpoint
1. Add to `Endpoints.swift`
2. Add method to appropriate service
3. Update `TestableServiceContainer` for mocking

### Add a new model
1. Create in `Core/Models/`
2. Implement `Codable` with `CodingKeys` if needed
3. Add unit tests for JSON parsing

## Build Commands

```bash
# Build
xcodebuild build -scheme fotoX -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)'

# Test
xcodebuild test -scheme fotoX -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)'

# Unit tests only
xcodebuild test -scheme fotoX -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' -only-testing:fotoXTests
```

## Questions to Ask User

If unclear on a task, ask about:
1. Which screen/feature does this affect?
2. Should this work offline or require Pi connection?
3. Is this user-facing or operator-only feature?
4. Should it be covered by tests?

