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

### POST /presign

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

### POST /complete

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

- Returns an HTML gallery page.
- If manifest is missing: return a "Processing" placeholder.

### GET /e/{event_id}

- Returns an HTML event gallery page using `index.json`.

### GET /health

- Returns `{ "status": "ok" }` for connectivity checks.

## Public Base URL

The Worker should build public URLs using a configurable `PUBLIC_BASE_URL` env var.
This allows an easy switch to a custom domain later without changing stored data.

If the R2 bucket is public, set `R2_PUBLIC_BASE_URL` so gallery pages can link
directly to object URLs. If not set, the Worker should proxy assets via `/asset`.
