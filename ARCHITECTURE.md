# FotoX Architecture

## System Context

```
┌─────────────────────────────────────────────────────────────────┐
│                         Event Venue                             │
│                                                                 │
│   ┌──────────┐                                                  │
│   │   iPad   │                                                  │
│   │  FotoX   │                                                  │
│   │   App    │                                                  │
│   └────┬─────┘                                                  │
│        │                                                        │
└────────┼────────────────────────────────────────────────────────┘
         │ Internet
         ▼
┌───────────────────────────┐        ┌───────────────────────────┐
│   Cloudflare Worker       │◄──────►│        Cloudflare R2      │
│  (presign + galleries)    │        │   (photos/videos/manifest)│
└─────────────┬─────────────┘        └───────────────────────────┘
              │
              ▼
       ┌──────────┐
       │  Guest   │
       │ (scan QR)│
       └──────────┘
```

## App Architecture

### Layer Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Presentation Layer                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                      SwiftUI Views                        │  │
│  │  EventSelectionView │ IdleView │ CaptureView │ QRView     │  │
│  └───────────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                      ViewModels                           │  │
│  │  @Observable classes managing screen state                │  │
│  └───────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                        Application Layer                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │    AppState     │  │   AppRouter     │  │ ServiceContainer│  │
│  │  (navigation,   │  │  (route defs)   │  │  (DI container) │  │
│  │   shared state) │  │                 │  │                 │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                         Domain Layer                            │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                       Services                            │  │
│  │  LocalEventService │ LocalSessionService │ ThemeService   │  │
│  │  UploadQueueWorker                                        │  │
│  └───────────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                        Models                             │  │
│  │  Event │ Theme │ Session │ CapturedStrip │ etc.           │  │
│  └───────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                      Infrastructure Layer                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌────────────────┐   │
│  │ WorkerAPIClient │  │ CameraController│  │  ImageCache    │   │
│  │  (networking)   │  │ (AVFoundation)  │  │  (caching)     │   │
│  └─────────────────┘  └─────────────────┘  └────────────────┘   │
│  ┌─────────────────┐                                            │
│  │ UploadQueueStore│                                            │
│  └─────────────────┘                                            │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

### State Flow

```
┌────────────────────────────────────────────────────────────────┐
│                         AppState                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐ │
│  │ currentRoute │  │selectedEvent │  │   currentSession     │ │
│  │ (navigation) │  │   (Event?)   │  │     (Session?)       │ │
│  └──────────────┘  └──────────────┘  └──────────────────────┘ │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐ │
│  │currentTheme  │  │capturedStrips│  │   uploadProgress     │ │
│  │  (AppTheme)  │  │   [Strip]    │  │     (Double)         │ │
│  └──────────────┘  └──────────────┘  └──────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
                              │
                              │ @Environment
                              ▼
┌────────────────────────────────────────────────────────────────┐
│                          Views                                  │
│                                                                 │
│   Read state:     @Environment(AppState.self) var appState     │
│   Update state:   appState.selectEvent(event)                  │
│                   appState.currentRoute = .idle                │
└────────────────────────────────────────────────────────────────┘
```

### Worker Upload Flow

```
View               ViewModel          UploadQueueWorker      WorkerAPIClient
  │                    │                     │                     │
  │ ── capture done ──►│                     │                     │
  │                    │ ── enqueue ───────► │                     │
  │                    │                     │ ── presign ────────►│
  │                    │                     │ ◄── URLs ──────────│
  │                    │                     │ ── PUT uploads ────►│
  │                    │                     │                     │
  │                    │                     │ ── complete ───────►│
```

## Navigation

### Route State Machine

```
                    ┌─────────────────┐
                    │ eventSelection  │ ◄─────────────────────┐
                    └────────┬────────┘                       │
                             │ select event                   │
                             ▼                                │
                    ┌─────────────────┐                       │
            ┌──────►│      idle       │───────────────────────┤
            │       └────────┬────────┘                       │
            │                │ tap start                      │
            │                ▼                                │
            │       ┌─────────────────┐                       │
            │       │    capture      │                       │
            │       │  (3 strips)     │                       │
            │       └────────┬────────┘                       │
            │                │ all captured                   │
            │                ▼                                │
            │                │ enqueue uploads (background)   │
            │                ▼                                │
            │       ┌─────────────────┐                       │
            └───────│   qrDisplay     │───────────────────────┘
                    │ (QR + email)    │
                    └─────────────────┘
                           done/timeout
```

Summary: after capture, the app immediately shows the QR code and email entry while uploads run in the background.
The QR code is generated locally from the session URL, so it works even if the venue is offline.

### Capture Flow State Machine

```
┌─────────────────────────────────────────────────────────────────┐
│                    CaptureViewModel States                      │
│                                                                 │
│   ┌───────┐    ┌───────────┐    ┌──────────┐                    │
│   │ ready │───►│ recording │───►│ photo    │                    │
│   └───────┘    │  (10 sec) │    │ capture  │                    │
│       ▲        └───────────┘    └────┬─────┘                    │
│       │                               │                         │
│       │                               ▼                         │
│       └──────────── repeat ×3 ────────┘                         │
│                                                                 │
│                     done → enqueue uploads                      │
└─────────────────────────────────────────────────────────────────┘
```

## Module Dependencies

```
fotoXApp
    │
    ├──► AppState
    │
    ├──► ServiceContainer
    │       │
    │       ├──► LocalEventService
    │       ├──► LocalSessionService
    │       ├──► UploadQueueWorker ──► WorkerAPIClient
    │       └──► ThemeService
    │
    └──► Features
            │
            ├──► EventSelection
            │       └──► EventSelectionViewModel
            │
            ├──► Idle
            │       └──► IdleViewModel
            │
            ├──► Capture
            │       ├──► CaptureViewModel
            │       └──► CameraController
            │
            ├──► Upload
            │       └──► UploadViewModel
            │
            ├──► QR
            │       └──► QRViewModel
            │
            └──► Settings
                    └──► SettingsViewModel
```

## Key Design Decisions

### 1. No Third-Party Dependencies
- Pure Swift/SwiftUI implementation
- URLSession for networking
- AVFoundation for camera
- Reduces complexity and maintenance burden

### 2. Protocol-Light Design
- Direct class/struct usage where protocols add no value
- Protocols used sparingly for testability
- Simpler than heavy protocol-oriented design

### 3. Observable over Combine
- Uses iOS 17+ `@Observable` macro
- Cleaner than `ObservableObject` + `@Published`
- Better compile-time optimization

### 4. Actor for Networking
- `WorkerAPIClient` is an actor for thread safety
- Prevents data races in concurrent requests
- Safe to call from any context

### 5. Value Types for Models
- All API models are structs (value types)
- Immutable by default
- Thread-safe without synchronization

### 6. Mock Injection for Testing
- `TestableServiceContainer` wraps real services
- Launch argument `--use-mock-data` enables mocks
- UI tests run without real backend

## File Map

```
fotoX/fotoX/
│
├── fotoXApp.swift                 # Entry point, DI setup
│
├── App/
│   ├── AppState.swift             # Central state store
│   ├── AppRouter.swift            # Route definitions
│   ├── ServiceContainer.swift     # Production DI
│   └── ThemeEnvironment.swift     # Theme context
│
├── Core/
│   ├── Models/
│   │   ├── Event.swift            # Event + nested Theme
│   │   ├── Theme.swift            # Theme colors/assets
│   │   ├── Session.swift          # Capture session
│   │   └── AssetUploadMetadata.swift
│   │
│   ├── Networking/
│   │   ├── WorkerAPIClient.swift  # Worker HTTP client
│   │   └── APIError.swift         # Error types
│   │
│   ├── Services/
│   │   ├── LocalEventService.swift   # Bundled events
│   │   ├── LocalSessionService.swift # Local sessions + QR
│   │   └── ThemeService.swift        # Theme asset loading
│   │
│   ├── Upload/
│   │   ├── UploadQueueWorker.swift # Upload coordinator
│   │   └── UploadQueueStore.swift  # Queue persistence
│   │
│   ├── Testing/
│   │   ├── MockDataProvider.swift # Fake data
│   │   └── TestableServiceContainer.swift
│   │
│   └── Util/
│       ├── Color+Hex.swift        # Hex color parsing
│       └── ImageCache.swift       # Image caching
│
└── Features/
    ├── EventSelection/            # Event list screen
    ├── Idle/                      # Attract screen
    ├── Capture/                   # Video/photo capture
    ├── Upload/                    # Upload progress
    ├── QR/                        # QR + email screen
    └── Settings/                  # Operator settings
```
