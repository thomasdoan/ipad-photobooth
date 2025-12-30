# TODO

## Feature
- [ ] Email support

## Performance Optimization
- [ ] Fix expensive DateFormatter creation in gallery view
  - SessionCard creates 2 DateFormatters per cell render (24+ creations for 12 visible cells)
  - Solution: Create thread-safe DateFormatterCache actor + pre-format dates during GallerySession creation
  - See detailed plan: `/Users/thomas/.claude/plans/peaceful-foraging-cupcake.md`
  - Files to modify:
    - New: `fotoX/Core/Util/DateFormatterCache.swift`
    - `fotoX/Core/Models/GalleryModels.swift`
    - `fotoX/Features/Gallery/GalleryViewModel.swift`
    - `fotoX/Core/Services/LocalGalleryService.swift`
    - `fotoX/Features/Gallery/GalleryView.swift`
    - `fotoX/Features/Gallery/SessionDetailView.swift`
    - `fotoX/Core/Models/Event.swift`

- [ ] Fix video player memory management issues/Fix video player lifecycle to prevent multiple simultaneous playback
  - **CRITICAL**: TabView in SessionDetailView allocates ALL AVPlayer instances simultaneously (10 videos = 200-300MB)
  - TabView with `.page` style eagerly creates all child views, causing all video players to load at once
  - Missing proper cleanup: no `currentItem = nil`, observer removal, or lifecycle management
  - Nested `.onAppear` conflicts in StripReviewView causing double initialization
  - Solution: Create VideoPlayerManager + replace TabView with lazy-loading ScrollView + fix lifecycle issues
  - See detailed plan: `/Users/thomas/.claude/plans/glimmering-twirling-starfish.md`
  - Expected: 10 videos = 1-3 AVPlayer instances (30-50MB)
  - Files to modify:
    - New: `fotoX/Core/Util/VideoPlayerManager.swift`
    - `fotoX/Features/Gallery/SessionDetailView.swift`
    - `fotoX/Features/Capture/StripReviewView.swift`
    - New: `fotoX/fotoXTests/VideoPlayerManagerTests.swift`
