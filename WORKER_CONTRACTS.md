# FotoX Worker + R2 Data Contracts

This document defines the shared contracts between the iPad app and the Cloudflare Worker/R2 stack.
It is intentionally version-light and easy to extend.

## Session ID

- `session_id`: UUID string generated on-device (example: `8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B`)
- Scope: globally unique across all events
- Used in object keys and gallery URLs

## Object Layout (R2)

```
events/{event_id}/sessions/{session_id}/photo_0.jpg
events/{event_id}/sessions/{session_id}/video_0.mp4
events/{event_id}/sessions/{session_id}/strip_photo.jpg
events/{event_id}/sessions/{session_id}/strip_video.mp4
events/{event_id}/sessions/{session_id}/manifest.json
events/{event_id}/index.json
```

## manifest.json (per session)

**Path:** `events/{event_id}/sessions/{session_id}/manifest.json`

```json
{
  "version": 1,
  "event_id": 42,
  "session_id": "8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B",
  "created_at": "2025-02-01T18:20:15Z",
  "public_gallery_url": "https://<worker>.workers.dev/s/8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B",
  "assets": [
    {
      "id": "strip_photo",
      "kind": "strip_photo",
      "strip_index": -1,
      "sequence_index": 1,
      "content_type": "image/jpeg",
      "path": "events/42/sessions/8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B/strip_photo.jpg",
      "size_bytes": 483221
    },
    {
      "id": "strip_video",
      "kind": "strip_video",
      "strip_index": -1,
      "sequence_index": 0,
      "content_type": "video/mp4",
      "path": "events/42/sessions/8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B/strip_video.mp4",
      "size_bytes": 18234903,
      "duration_seconds": 10.0,
      "poster_path": "events/42/sessions/8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B/strip_photo.jpg"
    },
    {
      "id": "strip0_video",
      "kind": "video",
      "strip_index": 0,
      "sequence_index": 0,
      "content_type": "video/mp4",
      "path": "events/42/sessions/8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B/video_0.mp4",
      "size_bytes": 18234903,
      "duration_seconds": 10.0,
      "poster_path": "events/42/sessions/8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B/photo_0.jpg"
    },
    {
      "id": "strip0_photo",
      "kind": "photo",
      "strip_index": 0,
      "sequence_index": 1,
      "content_type": "image/jpeg",
      "path": "events/42/sessions/8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B/photo_0.jpg",
      "size_bytes": 483221
    }
  ]
}
```

Notes:
- `path` is the R2 object key (not a URL) to keep the manifest domain-agnostic.
- `public_gallery_url` can be derived on-device but is stored for convenience.
- Composite strip assets use `kind: "strip_photo"` / `kind: "strip_video"` with `strip_index: -1`.

## index.json (per event)

**Path:** `events/{event_id}/index.json`

```json
{
  "version": 1,
  "event_id": 42,
  "updated_at": "2025-02-01T18:22:40Z",
  "sessions": [
    {
      "session_id": "8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B",
      "created_at": "2025-02-01T18:20:15Z",
      "thumb_path": "events/42/sessions/8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B/photo_0.jpg",
      "gallery_path": "s/8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B"
    }
  ]
}
```

Notes:
- `gallery_path` is a relative path to the gallery route, so a custom domain can be swapped later.
- `thumb_path` points to a representative image for the event gallery list.

## Worker API (minimal)

Machine-to-machine API routes are prefixed with `/api`. Public-facing gallery pages use cleaner URLs without the prefix.

### POST /api/presign

Request:
```json
{
  "event_id": 42,
  "session_id": "8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B",
  "files": [
    { "path": "events/42/sessions/...", "content_type": "image/jpeg", "size_bytes": 483221 }
  ]
}
```

Headers:
- `X-FotoX-Key: <PRESIGN_TOKEN>`

Response:
```json
{
  "uploads": [
    { "path": "events/42/sessions/...", "method": "PUT", "url": "https://..." }
  ],
  "expires_in_seconds": 900
}
```

### POST /api/complete

Request:
```json
{
  "event_id": 42,
  "session_id": "8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B",
  "manifest_path": "events/42/sessions/.../manifest.json"
}
```

Headers:
- `X-FotoX-Key: <PRESIGN_TOKEN>`

Response:
```json
{ "status": "ok" }
```

### GET /s/{session_id}

- Returns an HTML gallery page (public-facing, no `/api` prefix).
- If manifest is missing: return a "Processing" placeholder.

### GET /e/{event_id}

- Returns an HTML event gallery page using `index.json` (public-facing, no `/api` prefix).

### GET /api/events/{event_id}

Returns the event index as JSON (for app consumption).

Response:
```json
{
  "version": 1,
  "event_id": 42,
  "updated_at": "2025-02-01T18:22:40Z",
  "sessions": [
    {
      "session_id": "8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B",
      "created_at": "2025-02-01T18:20:15Z",
      "thumb_path": "events/42/sessions/.../photo_0.jpg",
      "gallery_path": "s/8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B"
    }
  ]
}
```

Notes:
- No authentication required (public endpoint)
- Returns empty `sessions` array if no sessions exist yet

### GET /api/events/{event_id}/thumbnails

Returns a single representative photo URL from each session at the event, with pagination.

Query parameters:
- `limit`: Number of thumbnails to return (default: 20, max: 100)
- `cursor`: Session ID to start after (for pagination)

Response:
```json
{
  "event_id": 42,
  "updated_at": "2025-02-01T18:22:40Z",
  "thumbnails": [
    {
      "session_id": "8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B",
      "created_at": "2025-02-01T18:20:15Z",
      "url": "https://<worker>.workers.dev/api/asset?path=events/42/sessions/.../photo_0.jpg"
    }
  ],
  "next_cursor": "NEXT-SESSION-ID",
  "has_more": true
}
```

Example pagination:
```
GET /api/events/42/thumbnails?limit=10
GET /api/events/42/thumbnails?limit=10&cursor=8D9E2D3D-9A6A-4F20-9C5D-2F6C2B6A8F7B
```

Notes:
- No authentication required (public endpoint)
- Returns resolved asset URLs (either via `/api/asset` proxy or direct R2 URL if configured)
- `next_cursor` is `null` when there are no more results
- `has_more` indicates if more pages are available

### GET /api/health

- Returns `{ "status": "ok" }` for connectivity checks.

### GET /api/asset

Proxies assets from R2 with caching and range request support.

Query parameters:
- `path`: R2 object key (e.g., `events/42/sessions/.../photo_0.jpg`)

Response:
- Returns the asset with appropriate `Content-Type`
- Supports `Range` header for video streaming (returns 206 Partial Content)
- Adds `Accept-Ranges: bytes` and `Cache-Control: public, max-age=3600`

Example:
```
GET /api/asset?path=events/42/sessions/ABC123/video_0.mov
Range: bytes=0-1000000

HTTP/1.1 206 Partial Content
Content-Type: video/quicktime
Content-Range: bytes 0-1000000/5000000
Accept-Ranges: bytes
```

Notes:
- No authentication required (public endpoint)
- If `R2_PUBLIC_BASE_URL` is set, consider using direct R2 URLs instead

## Public Base URL

The Worker should build public URLs using a configurable `PUBLIC_BASE_URL` env var.
This allows an easy switch to a custom domain later without changing stored data.

If the R2 bucket is public, set `R2_PUBLIC_BASE_URL` so gallery pages can link
directly to object URLs. If not set, the Worker should proxy assets via `/asset`.
