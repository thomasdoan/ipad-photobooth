# FotoX Worker

Minimal Cloudflare Worker that handles:
- Presigned upload URLs (signed Worker upload URLs)
- Asset upload to R2
- Session and event gallery pages

## Setup

1) Configure R2 binding in `worker/wrangler.toml`.
2) Set secret for upload signing:

```
wrangler secret put UPLOAD_SECRET
```

3) Set shared presign token (required for /presign and /complete):

```
wrangler secret put PRESIGN_TOKEN
```

4) (Optional) Set public base URLs:
- `PUBLIC_BASE_URL` (Worker URL)
- `R2_PUBLIC_BASE_URL` (if R2 bucket is public)

## Routes

- `POST /presign`
- `PUT /upload`
- `POST /complete`
- `GET /s/:sessionId` - Session gallery page (HTML)
- `GET /e/:eventId` - Event gallery page (HTML)
- `GET /api/e/:eventId` - Event sessions list (JSON, for app)
- `GET /asset?path=...` - Proxy asset from R2
- `GET /health`

Authentication:
- `/presign` and `/complete` require header `X-FotoX-Key: <PRESIGN_TOKEN>`
- All other routes are public
