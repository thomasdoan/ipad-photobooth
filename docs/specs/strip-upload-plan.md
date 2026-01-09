# Plan: Upload composite photo/video strips

## Goal
Upload the composite photo strip and composite video strip alongside the per-strip photos and videos.
The composite video is a single video where all three strip videos play at the same time.

## Current state (baseline)
- The app builds "Photo Strip" and "Video Strip" views on demand in the gallery UI.
- Uploads only include per-strip photos and videos.
- Worker prefers a `kind === "strip"` asset for event thumbnails, but the app never uploads one.

## Proposed approach
1) **Define composite asset types**
   - Add explicit kinds for composite assets (e.g. `strip_photo`, `strip_video`).
   - Keep per-strip assets as `photo`/`video`.
   - Decide on `strip_index` for composite assets (likely `-1` or a sentinel), plus `sequence_index`.

2) **Generate composite photo strip**
   - Build a renderer that takes the three strip photos and produces a single JPG.
   - Reuse layout math from `StripCompositeMetrics` so the composite matches the on-screen strip.
   - Decide whether to render the themed frame/footer or keep it minimal (plain background + slots).
   - Output file name: `strip_photo.jpg` (or similar).

3) **Generate composite video strip**
   - Create a video compositor that stacks the three video tracks vertically with spacing.
   - Use `AVMutableComposition` + `AVMutableVideoComposition` to place each track in a
     fixed rectangle derived from `StripCompositeMetrics`.
   - Decide duration strategy (shortest vs longest clip) and audio handling.
   - Export to `.mov` or `.mp4` and set `content_type` accordingly.
   - Output file name: `strip_video.mov` (or similar). Consider using the photo strip as poster.

4) **Include composites in upload queue + manifest**
   - Extend `UploadQueueWorker.enqueueSession` to write composite files to the session folder.
   - Add `UploadQueueAsset` entries for the strip photo + strip video with correct metadata.
   - Update manifest generation so composites are included in `assets`.
   - Update `AppState.totalAssetsToUpload` (and any UI progress) to count the two extras.
   - If `UploadViewModel` is used anywhere, add composite upload items too.

5) **Update Worker gallery behavior**
   - Update `worker/src/index.js` to treat `strip_video` as video in the session gallery.
   - Prefer `strip_photo` (or the composite photo) for event gallery thumbnails.
   - Update `gallery.js.js` asset mapping so `strip_video` is `type: "video"`.
   - Update `WORKER_CONTRACTS.md` with new asset kinds and filenames.

6) **Local gallery compatibility**
   - Ensure `LocalGalleryService` can load composite assets from manifest/queue.
   - Update UI switches over `AssetKind` so new cases do not break view rendering.
   - Decide whether to surface composites in the app gallery or keep them hidden.

7) **Tests**
   - Add/adjust app tests for manifest asset count and local gallery asset parsing.
   - Update worker tests for thumbnail selection and gallery rendering of composite video.

## Decisions (from user)
- Naming: keep existing per-strip names; add composite files `strip_photo.jpg` and `strip_video.mp4`.
- Composite video: MP4 container, no audio, if durations differ freeze the shortest.
- UI: composite assets should appear in the gallery UI.
- Event thumbnail: prefer the composite photo strip when present.

## Open decisions
- Output resolution for composites (fixed size vs derived from original video sizes).
- Whether to render theme frames/footers into the composite assets.
