# Support Landscape + Aspect Ratio Settings

## Goals
- Support both portrait and landscape orientations on iPad.
- Allow operators to choose capture aspect ratio (Auto, 9:16, 16:9, 4:3).
- Auto maps to 9:16 in portrait and 16:9 in landscape.
- Apply changes immediately to the current session (new captures only).

## Non-Goals
- Per-event aspect ratio settings.
- Horizontal strip layout (strips remain vertical).
- Worker schema changes for aspect ratio metadata.

## UX Notes
- Settings screen includes a segmented picker for aspect ratio.
- Landscape recommendation note: 16:9 for video, 4:3 for photos/prints.

## Implementation Overview
- Add `CaptureAspectRatio` and `LayoutOrientation` helpers.
- Persist aspect ratio selection in `WorkerConfiguration`.
- Track layout orientation in `AppState` from root view geometry.
- Resolve aspect ratio per layout orientation when Auto is selected.
- Update camera orientation + simulator output based on resolved ratio.
- Crop photo/video to the resolved ratio before saving/uploading.
- Update strip previews/composites to use resolved aspect ratio.
- Update iPad orientation support in project settings.

## Open Questions / Follow-ups
- If aspect ratio changes mid-session, composites use the latest ratio (may crop earlier strips).
- Gallery display uses the current setting; older sessions may not match without per-session metadata.
