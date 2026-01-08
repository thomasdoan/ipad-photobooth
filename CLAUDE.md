# Project: FotoX

## Quick Reference
- **Platform**: iOS 17+ (iPad)
- **Language**: Swift 6.0
- **UI Framework**: SwiftUI
- **Architecture**: MVVM with @Observable
- **Minimum Deployment**: iOS 17.0
- **Package Manager**: Swift Package Manager
- **Bundle ID**: `id8.fotoX`

## XcodeBuildMCP Integration
**IMPORTANT**: This project uses XcodeBuildMCP for all Xcode operations.

### Session Setup (run once per session)
```
session-set-defaults:
  projectPath: fotoX/fotoX.xcodeproj
  scheme: fotoX
  simulatorId: 9D388E32-3A3C-4674-9469-DABB2AEF3C5B  # iPad Air 13-inch (M3)
  useLatestOS: true
  suppressWarnings: true
```

### Commands
| Action | Command |
|--------|---------|
| Build | `build_sim` |
| Build & Run | `build_run_sim` |
| Run All Tests | `test_sim` |
| Unit Tests Only | `test_sim` with `extraArgs: ["-only-testing:fotoXTests"]` |
| UI Tests Only | `test_sim` with `extraArgs: ["-only-testing:fotoXUITests"]` |
| Clean | `clean` |
| Screenshot | `screenshot` |
| UI Hierarchy | `describe_ui` |

## Coding Standards

### Swift Style
- Use Swift 6 strict concurrency
- Prefer `@Observable` over `ObservableObject`
- Use `async/await` for all async operations
- Follow Apple's Swift API Design Guidelines
- Use `guard` for early exits
- Prefer value types (structs) over reference types (classes)

### SwiftUI Patterns
- Extract views when they exceed 100 lines
- Use `@State` for local view state only
- Use `@Environment` for dependency injection
- Prefer `NavigationStack` over deprecated `NavigationView`
- Use `@Bindable` for bindings to @Observable objects

### Navigation Pattern
```swift
// Use NavigationStack with type-safe routing
enum Route: Hashable {
    case detail(Item)
    case settings
}

NavigationStack(path: $router.path) {
    ContentView()
        .navigationDestination(for: Route.self) { route in
            // Handle routing
        }
}
```

### Error Handling
```swift
// Always use typed errors
enum AppError: LocalizedError {
    case networkError(underlying: Error)
    case validationError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error): return error.localizedDescription
        case .validationError(let msg): return msg
        }
    }
}
```

## Testing Requirements
- Unit tests for all ViewModels
- UI tests for critical user flows
- Use Swift Testing framework (`@Test`, `#expect`)
- Minimum 80% code coverage for business logic

## DO NOT
- Write UITests during scaffolding phase
- Use deprecated APIs (UIKit when SwiftUI suffices)
- Create massive monolithic views
- Use force unwrapping (`!`) without justification
- Ignore Swift 6 concurrency warnings

## Planning Workflow
When starting new features:
1. Create feature spec in `docs/specs/[feature-name].md`
2. Use `ultrathink` for architectural decisions
3. Use Plan Mode (`Shift+Tab`) for implementation strategy
4. Implement incrementally with tests

## Memory Imports
@import AGENTS.md
@import ARCHITECTURE.md
@import README.md
@import WORKER_CONTRACTS.md
```

## Architecture
- Uses MVVM with @Observable ViewModels
- Parent stores create child stores for modal presentations

## Navigation Pattern
### Sheet-Based Navigation
**Pattern**: Parent stores create optional child stores for modal presentations
**Rules**:
1. Parent ViewModel holds `@Published var childViewModel: ChildViewModel?`
2. View observes and presents sheet when non-nil
3. Dismissal sets childViewModel to nil

### Example
```swift
@Observable
final class ParentViewModel {
    var detailViewModel: DetailViewModel?
    
    func showDetail(for item: Item) {
        detailViewModel = DetailViewModel(item: item)
    }
}
```

## Testing

### Testing Workflow
**IMPORTANT**: After adding or modifying ANY feature, you MUST run tests in this order:

1. **Run Unit Tests First** (fast feedback):
   ```
   test_sim with extraArgs: ["-only-testing:fotoXTests"]
   ```

2. **Run UI Tests** (if UI changes were made):
   ```
   test_sim with extraArgs: ["-only-testing:fotoXUITests"]
   ```

3. **Fix any failures before proceeding** - Do not move on to the next feature until all tests pass.

### Test Commands Reference
- All tests: `test_sim`
- Unit tests only: `test_sim` with `extraArgs: ["-only-testing:fotoXTests"]`
- UI tests only: `test_sim` with `extraArgs: ["-only-testing:fotoXUITests"]`
