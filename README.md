# FotoX - iPad Photobooth App

A production-quality iPad photobooth app built with SwiftUI. Designed to run local capture on the iPad and upload to Cloudflare Worker + R2 for public galleries.

## Features

- **Event Selection** - Browse and select from bundled events
- **Themed UI** - Each event has custom colors, logos, and backgrounds
- **3-Strip Capture** - Record three 10-second videos with photos
- **Background Upload Queue** - Offline-tolerant uploads with retry
- **QR Code Display** - Guests scan to access their gallery
- **Email Collection** - Optional email input for photo delivery
- **Operator Settings** - Configure Worker connection

## Requirements

- **Xcode 15.0+** (or Xcode 16 beta)
- **iOS 17.0+ / iPadOS 17.0+**
- **macOS Sonoma 14.0+** (for development)
- Physical iPad recommended for camera features

## Quick Start

### 1. Clone & Open

```bash
git clone <repository-url>
cd FotoX
open fotoX/fotoX.xcodeproj
```

### 2. Build & Run

1. Open `fotoX/fotoX.xcodeproj` in Xcode
2. Select your target device:
   - **iPad Simulator** - For UI testing (no camera)
   - **Physical iPad** - For full functionality
3. Press `Cmd+R` or click the Play button

### 3. Configure Worker Connection

On first launch:
1. The app will try to connect to your Worker base URL
2. To update it:
   - Tap **Settings** on the event selection screen
   - Update the **Base URL** (e.g., `https://your-worker.workers.dev`)
   - Tap **Test Connection** to verify
   - Tap **Save**

## Project Structure

```
FotoX/
├── WORKER_CONTRACTS.md         # Worker + R2 schema and endpoints
├── README.md                    # This file
├── REACT_TO_SWIFT.md           # Guide for React developers
├── worker/                     # Cloudflare Worker source
└── fotoX/
    ├── fotoX.xcodeproj         # Xcode project
    ├── fotoX/                   # Main app source
    │   ├── fotoXApp.swift      # App entry point
    │   ├── App/                # App state & navigation
    │   ├── Core/               # Models, networking, services
    │   │   ├── Models/
    │   │   ├── Networking/
    │   │   ├── Services/
    │   │   ├── Testing/        # Mock data for tests
    │   │   └── Util/
    │   └── Features/           # UI screens
    │       ├── EventSelection/
    │       ├── Idle/
    │       ├── Capture/
    │       ├── Upload/
    │       ├── QR/
    │       └── Settings/
    ├── fotoXTests/             # Unit tests
    └── fotoXUITests/           # UI/E2E tests
```

## Building

### Debug Build (Simulator)

```bash
cd fotoX
xcodebuild build \
  -scheme fotoX \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)'
```

### Release Build (Device)

```bash
cd fotoX
xcodebuild build \
  -scheme fotoX \
  -configuration Release \
  -destination 'generic/platform=iOS'
```

### Archive for Distribution

```bash
cd fotoX
xcodebuild archive \
  -scheme fotoX \
  -archivePath ./build/FotoX.xcarchive \
  -destination 'generic/platform=iOS'
```

## Testing

### Run All Tests

```bash
cd fotoX
xcodebuild test \
  -scheme fotoX \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)'
```

### Run Unit Tests Only (Fast)

```bash
cd fotoX
xcodebuild test \
  -scheme fotoX \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
  -only-testing:fotoXTests
```

### Run UI Tests Only

```bash
cd fotoX
xcodebuild test \
  -scheme fotoX \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
  -only-testing:fotoXUITests
```

### Run Tests in Xcode

- `Cmd+U` - Run all tests
- `Cmd+Ctrl+U` - Run test under cursor
- Click diamond icon next to test name

### Test with Mock Data

The app supports mock data for testing without a Worker:

```bash
# Launch app with mock data
xcrun simctl launch booted id8.fotoX --uitesting --use-mock-data
```

## Configuration

### Worker Base URL

Default: `https://your-worker.workers.dev`

Change via:
1. **Settings UI** - Tap Settings → Update Base URL → Save
2. **UserDefaults** - Key: `workerBaseURL`

### Supported Endpoints (Worker)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/presign` | POST | Get presigned upload URLs |
| `/upload` | PUT | Upload asset to R2 |
| `/complete` | POST | Finalize session + index |
| `/s/{session_id}` | GET | Session gallery page |
| `/e/{event_id}` | GET | Event gallery page |

## Development

### Adding a New Feature

1. Create folder under `Features/`
2. Add `View.swift` and `ViewModel.swift`
3. Register in `AppRouter.swift`
4. Add route handling in `RootView`

### Running with Mock Services

For development without a Worker backend:

```swift
// In fotoXApp.swift, services are auto-mocked when launched with:
// --use-mock-data flag

// Or manually create mock container:
let services = TestableServiceContainer(useMocks: true)
```

### Debugging

1. **Network Issues**: Check Console.app for network logs
2. **Camera Issues**: Must test on physical device
3. **UI Issues**: Use Xcode's View Debugger (`Debug → View Debugging`)

## Deployment

### TestFlight

1. Archive the app (`Product → Archive`)
2. Open Organizer (`Window → Organizer`)
3. Select archive → Distribute App → TestFlight

### Ad-Hoc Distribution

1. Archive the app
2. Export with Ad-Hoc profile
3. Install via Apple Configurator or MDM

### App Store

1. Archive the app
2. Distribute via App Store Connect
3. Submit for review

## Permissions

The app requires these permissions (configured in build settings):

| Permission | Usage |
|------------|-------|
| Camera | Record videos and take photos |
| Microphone | Record audio with videos |
| Network | Connect to Worker + R2 |

## Troubleshooting

### "Cannot connect to Worker"

1. Verify the Worker URL in Settings
2. Open `https://<worker>.workers.dev/health` in a browser
3. Ensure the iPad has internet access
4. Check Cloudflare dashboard logs for errors

### Camera not working

- Camera only works on **physical iPad**, not simulator
- Check camera permission in Settings app
- Restart app after granting permission

### Events not loading

1. Ensure the app has bundled events (see `LocalEventService`)
2. Check Xcode console for errors

### Build errors

```bash
# Clean build folder
cd fotoX
xcodebuild clean -scheme fotoX

# Reset package cache (if using SPM)
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     fotoXApp                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  AppState   │  │  Services   │  │   Router    │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└─────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │  Event   │    │  Idle    │    │ Capture  │
    │Selection │───▶│  Screen  │───▶│  Flow    │
    └──────────┘    └──────────┘    └──────────┘
                                          │
                    ┌─────────────────────┤
                    ▼                     ▼
              ┌──────────┐          ┌──────────┐
              │ Upload   │─────────▶│    QR    │
              │  Queue   │          │  Screen  │
              └──────────┘          └──────────┘
```

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing`)
3. Write tests for new functionality
4. Ensure all tests pass (`Cmd+U`)
5. Submit pull request

## License

[Add your license here]

## Support

For issues and questions:
- Check [Troubleshooting](#troubleshooting) section
- Open a GitHub issue
- Contact the development team

# apple-pi
