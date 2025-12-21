# FotoX - iPad Photobooth App

A SwiftUI iPad app for running a cloud-backed photobooth system. Built to work with a Raspberry Pi backend over local Wi-Fi.

## Quick Comparison: React vs SwiftUI

If you're coming from React/TypeScript, here's a mental model:

| React/TS Concept | SwiftUI Equivalent |
|------------------|-------------------|
| `useState`       | `@State` |
| `useContext`     | `@Environment` |
| Zustand store    | `@Observable` class |
| `props`          | Regular function parameters |
| `useEffect`      | `.task { }` or `.onAppear { }` |
| JSX              | SwiftUI View DSL |
| `async/await`    | Same! Swift has `async/await` too |
| `interface`      | `protocol` |
| `type`           | `struct`               |
| Component        | `View` (it's a protocol/interface) |

## Project Structure

```
fotoX/fotoX/
├── fotoXApp.swift          # Like index.tsx - app entry point
├── App/                    # Global state & routing
│   ├── AppState.swift      # Like a Redux store - central state
│   ├── AppRouter.swift     # Route definitions (enum instead of react-router)
│   ├── ServiceContainer.swift  # Dependency injection container
│   └── ThemeEnvironment.swift  # Theme context provider
├── Core/
│   ├── Models/             # TypeScript interfaces → Swift structs
│   ├── Networking/         # API client (like axios/fetch wrapper)
│   └── Services/           # Business logic layer
│   └── Util/               # Helpers (Color parsing, image cache)
└── Features/               # Feature-based folders (like Next.js app router)
    ├── EventSelection/     # Event list screen
    ├── Idle/               # Attract/idle screen
    ├── Capture/            # Video + photo capture
    ├── Upload/             # Upload progress
    ├── QR/                 # QR code display
    └── Settings/           # Operator settings
```

## Key Concepts

### 1. Views (Components)

In React you write:
```tsx
function MyComponent({ name }: { name: string }) {
  const [count, setCount] = useState(0);
  return <div onClick={() => setCount(c => c + 1)}>{name}: {count}</div>;
}
```

In SwiftUI:
```swift
struct MyComponent: View {
    let name: String              // props are just properties
    @State private var count = 0  // useState equivalent
    
    var body: some View {         // like render()
        Text("\(name): \(count)")
            .onTapGesture { count += 1 }
    }
}
```

### 2. State Management

**Local State (`@State`)** - Like `useState`:
```swift
@State private var email = ""
@State private var isLoading = false
```

**Shared State (`@Observable`)** - Like a Zustand store:
```swift
// Define the store
@Observable
class AppState {
    var currentRoute: AppRoute = .eventSelection
    var selectedEvent: Event?
    
    func selectEvent(_ event: Event) {
        selectedEvent = event
        currentRoute = .idle
    }
}

// Use in a view (like useStore hook)
struct MyView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        Button("Go") { appState.selectEvent(someEvent) }
    }
}
```

**Environment (`@Environment`)** - Like React Context:
```swift
// Inject at the top
ContentView()
    .environment(appState)  // Like <Context.Provider value={appState}>

// Access anywhere below
@Environment(AppState.self) private var appState  // Like useContext()
```

### 3. Navigation

Instead of react-router, we use an enum + switch statement:

```swift
// Define routes (like your route config)
enum AppRoute {
    case eventSelection
    case idle
    case capture
    case uploading
    case qrDisplay
}

// In the root view (like your App.tsx router)
switch appState.currentRoute {
case .eventSelection:
    EventSelectionView()
case .idle:
    IdleView()
// ... etc
}

// Navigate by changing state (like navigate('/idle'))
appState.currentRoute = .idle
```

### 4. Async Operations

Swift has native `async/await` just like modern JS:

```swift
// In React:
// useEffect(() => { fetchData().then(setData) }, [])

// In SwiftUI:
.task {
    let events = try await eventService.fetchEvents()
    self.events = events
}
```

### 5. Networking

The `APIClient` is like an axios instance:

```swift
// Similar to: const api = axios.create({ baseURL: '...' })
let client = APIClient(baseURL: URL(string: "http://booth.local/api")!)

// Similar to: const data = await api.get('/events')
let data = try await client.fetchData(Endpoints.events)
```

**Endpoints** are defined as static constants (like API route constants):
```swift
enum Endpoints {
    static let events = Endpoint(path: "events")
    static func event(id: Int) -> Endpoint {
        Endpoint(path: "events/\(id)")
    }
}
```

### 6. Models (Types)

Swift `struct` ≈ TypeScript `interface`:

```swift
// TypeScript:
// interface Event {
//   id: number;
//   name: string;
//   theme: Theme;
// }

// Swift:
struct Event: Codable {
    let id: Int
    let name: String
    let theme: Theme
}
```

`Codable` is like having automatic JSON serialization - no need for manual parsing.

## App Flow

```
┌─────────────────┐
│ Event Selection │  ← Fetch events from Pi, show list
└────────┬────────┘
         │ tap event
         ▼
┌─────────────────┐
│   Idle Screen   │  ← Themed attract screen, "Tap to Start"
└────────┬────────┘
         │ tap start → POST /sessions
         ▼
┌─────────────────┐
│  Capture Flow   │  ← 3 strips × (10s video + photo)
│  ┌───────────┐  │
│  │ Countdown │──┼──→ Recording → Photo → Review
│  └───────────┘  │         │
│       ↑         │         │ retake?
│       └─────────┼─────────┘
└────────┬────────┘
         │ all 3 done
         ▼
┌─────────────────┐
│    Uploading    │  ← POST /sessions/{id}/assets (multipart)
└────────┬────────┘
         │ success → GET /sessions/{id}/qr
         ▼
┌─────────────────┐
│   QR Display    │  ← Show QR + optional email input
└────────┬────────┘
         │ done (or 60s timeout)
         ▼
      Back to Idle
```

## State Machine (Capture Flow)

The capture flow uses a state machine pattern (like XState):

```swift
enum StripCaptureState {
    case ready                      // Waiting for user
    case countdown(remaining: Int)  // 3, 2, 1...
    case recording(elapsed: Double) // Recording 10s video
    case processingVideo            // Saving video
    case photoCountdown(remaining: Int)  // Brief pause
    case capturingPhoto             // Taking photo
    case complete                   // Strip done
    case error(String)              // Something went wrong
}
```

State transitions happen in the `CaptureViewModel`:
```swift
// Start countdown
stripState = .countdown(remaining: 3)

// After countdown completes
stripState = .recording(elapsed: 0)

// After 10 seconds
stripState = .processingVideo
```

## Camera (AVFoundation)

`CameraController` wraps Apple's AVFoundation framework (like a custom React hook for camera):

```swift
let camera = CameraController()

// Setup (like initializing a library)
try await camera.setup()
camera.startSession()

// Record video
try camera.startRecording()  // Starts saving to file
// ... 10 seconds later ...
camera.stopRecording()       // Triggers delegate callback

// Capture photo
let photoData = try await camera.capturePhoto()  // Returns JPEG data
```

The camera preview is displayed using `CameraPreview`, which wraps a UIKit view:
```swift
CameraPreview(cameraController: camera)
    .aspectRatio(9/16, contentMode: .fit)
```

## Theming

Themes are fetched from the Pi and applied via SwiftUI's environment:

```swift
// Theme model (from API)
struct AppTheme {
    let primary: Color    // Button colors, accents
    let secondary: Color  // Background
    let accent: Color     // Text
    let logoURL: URL?
    let backgroundURL: URL?
}

// Apply theme at root
.withTheme(appState.currentTheme)

// Use anywhere in the tree
@Environment(\.appTheme) private var theme

Button("Start") { }
    .foregroundStyle(theme.secondary)
    .background(theme.primary)
```

## API Endpoints

All communication goes through the local Pi (no direct cloud calls):

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/events` | GET | List available events |
| `/events/{id}` | GET | Get event + full theme |
| `/sessions` | POST | Create capture session |
| `/sessions/{id}/assets` | POST | Upload video/photo (multipart) |
| `/sessions/{id}/qr` | GET | Get QR code PNG |
| `/sessions/{id}/email` | POST | Submit guest email |

## Building & Running

1. Open `fotoX/fotoX.xcodeproj` in Xcode
2. Select an iPad simulator (or real iPad)
3. Press `Cmd+R` to build and run

**Note:** Camera features only work on real devices, not simulators.

## Configuration

The Pi base URL defaults to `http://booth.local/api` but can be changed:

1. Triple-tap the top-right corner on the Idle or QR screen
2. Settings panel opens
3. Enter new URL and tap "Test Connection"
4. Save

The URL is persisted in `UserDefaults` (like localStorage).

## Key Files to Understand

| File | What it does |
|------|--------------|
| `fotoXApp.swift` | App entry point, sets up dependency injection |
| `AppState.swift` | Central state store (routes, selected event, session) |
| `APIClient.swift` | HTTP client with retry logic |
| `CaptureViewModel.swift` | State machine for 3-strip capture |
| `CameraController.swift` | AVFoundation wrapper |
| `EventSelectionView.swift` | Good example of a list view |
| `IdleView.swift` | Good example of themed UI |

## Common Patterns

### Loading States
```swift
@State private var isLoading = false
@State private var error: String?

.task {
    isLoading = true
    do {
        data = try await service.fetch()
    } catch {
        self.error = error.localizedDescription
    }
    isLoading = false
}
```

### View + ViewModel Pattern
```swift
// ViewModel (like a custom hook)
@Observable
class MyViewModel {
    var items: [Item] = []
    var isLoading = false
    
    func load() async { ... }
}

// View
struct MyView: View {
    @State private var viewModel = MyViewModel()
    
    var body: some View {
        List(viewModel.items) { item in ... }
            .task { await viewModel.load() }
    }
}
```

### Conditional Rendering
```swift
// React: {isLoading ? <Spinner /> : <Content />}
// SwiftUI:
if isLoading {
    ProgressView()
} else {
    ContentView()
}

// Or with switch:
switch state {
case .loading: ProgressView()
case .loaded(let data): DataView(data: data)
case .error(let msg): ErrorView(message: msg)
}
```

## Debugging Tips

1. **Print statements**: Use `print("debug: \(variable)")` - shows in Xcode console
2. **Preview**: Add `#Preview { MyView() }` at bottom of file for live preview
3. **Breakpoints**: Click line number gutter in Xcode
4. **Network**: The simulator respects system proxy settings for Charles/Proxyman

## Swift Syntax Cheatsheet

```swift
// Optional (like T | undefined)
var name: String?           // Can be nil
name ?? "default"           // Nullish coalescing
if let name = name { }      // Optional unwrapping (like if (name))
name!                       // Force unwrap (dangerous, like name!)

// Closures (arrow functions)
{ param in return param * 2 }  // Full form
{ $0 * 2 }                     // Shorthand (like _ => _ * 2)

// String interpolation
"Hello \(name)"               // Like `Hello ${name}`

// Array methods
items.map { $0.name }         // Like items.map(i => i.name)
items.filter { $0.active }    // Like items.filter(i => i.active)
items.first { $0.id == 5 }    // Like items.find(i => i.id === 5)

// Enums with associated values (like discriminated unions)
enum Result {
    case success(Data)
    case failure(Error)
}
```

---

Happy coding! 🎉

