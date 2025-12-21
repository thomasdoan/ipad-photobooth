# FotoX Architecture

## System Context

```
┌─────────────────────────────────────────────────────────────────┐
│                         Event Venue                              │
│                                                                  │
│   ┌──────────┐         WiFi          ┌──────────────────┐       │
│   │   iPad   │◄─────────────────────►│  Raspberry Pi    │       │
│   │  FotoX   │                       │  (FastAPI)       │       │
│   │   App    │                       │                  │       │
│   └──────────┘                       └────────┬─────────┘       │
│        │                                      │                  │
│        │                                      │ Internet         │
│        ▼                                      ▼                  │
│   ┌──────────┐                       ┌──────────────────┐       │
│   │  Guest   │                       │  Cloud Backend   │       │
│   │  (scans  │                       │  (galleries,     │       │
│   │   QR)    │                       │   email, sync)   │       │
│   └──────────┘                       └──────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

## App Architecture

### Layer Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Presentation Layer                        │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                      SwiftUI Views                         │  │
│  │  EventSelectionView │ IdleView │ CaptureView │ QRView     │  │
│  └───────────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                      ViewModels                            │  │
│  │  @Observable classes managing screen state                 │  │
│  └───────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                        Application Layer                         │
│  ┌─────────────────┐  ┌─────────────────┐  ┌────────────────┐  │
│  │    AppState     │  │   AppRouter     │  │ ServiceContainer│  │
│  │  (navigation,   │  │  (route defs)   │  │  (DI container) │  │
│  │   shared state) │  │                 │  │                 │  │
│  └─────────────────┘  └─────────────────┘  └────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                         Domain Layer                             │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                       Services                             │  │
│  │  EventService │ SessionService │ ThemeService             │  │
│  └───────────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                        Models                              │  │
│  │  Event │ Theme │ Session │ CapturedStrip │ etc.           │  │
│  └───────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                      Infrastructure Layer                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌────────────────┐  │
│  │   APIClient     │  │ CameraController│  │  ImageCache    │  │
│  │  (networking)   │  │ (AVFoundation)  │  │  (caching)     │  │
│  └─────────────────┘  └─────────────────┘  └────────────────┘  │
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

### API Request Flow

```
View                ViewModel              Service              APIClient
  │                     │                     │                     │
  │ ─── user action ──► │                     │                     │
  │                     │ ── await load() ──► │                     │
  │                     │                     │ ── fetch(endpoint) ─►
  │                     │                     │                     │
  │                     │                     │ ◄── Data/Error ─────│
  │                     │ ◄── [Model] ────────│                     │
  │ ◄── @Observable ────│                     │                     │
  │     state update    │                     │                     │
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
            │       ┌─────────────────┐                       │
            │       │   uploading     │                       │
            │       └────────┬────────┘                       │
            │                │ upload complete                │
            │                ▼                                │
            │       ┌─────────────────┐                       │
            └───────│   qrDisplay     │───────────────────────┘
                    └─────────────────┘
                           done/timeout
```

### Capture Flow State Machine

```
┌─────────────────────────────────────────────────────────────────┐
│                    CaptureViewModel States                       │
│                                                                  │
│   ┌───────┐    ┌───────────┐    ┌───────────┐    ┌──────────┐  │
│   │ ready │───►│ countdown │───►│ recording │───►│ photo    │  │
│   └───────┘    │  (3,2,1)  │    │  (10 sec) │    │ capture  │  │
│       ▲        └───────────┘    └───────────┘    └────┬─────┘  │
│       │                                               │        │
│       │        ┌───────────┐                          │        │
│       └────────│  review   │◄─────────────────────────┘        │
│      (retake)  │  strip N  │                                   │
│                └─────┬─────┘                                   │
│                      │ continue (or N=3)                       │
│                      ▼                                         │
│                ┌───────────┐                                   │
│                │  summary  │───► transition to upload          │
│                └───────────┘                                   │
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
    │       ├──► APIClient
    │       ├──► EventService ──► APIClient
    │       ├──► SessionService ──► APIClient
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
- `APIClient` is an actor for thread safety
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
│   │   ├── APIClient.swift        # HTTP client (actor)
│   │   ├── APIError.swift         # Error types
│   │   └── Endpoints.swift        # API routes
│   │
│   ├── Services/
│   │   ├── EventService.swift     # Event API
│   │   ├── SessionService.swift   # Session API
│   │   └── ThemeService.swift     # Theme asset loading
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

