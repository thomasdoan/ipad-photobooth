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

Machine-to-machine API routes are prefixed with `/api`:

- `POST /api/presign`
- `PUT /api/upload`
- `POST /api/complete`
- `GET /api/events/:eventId` - Event sessions list (JSON, for app)
- `GET /api/asset?path=...` - Proxy asset from R2
- `GET /api/health`

Public-facing gallery routes (cleaner URLs for QR codes):

- `GET /s/:sessionId` - Session gallery page (HTML)
- `GET /e/:eventId` - Event gallery page (HTML)
- `GET /static/*` - Gallery CSS/JS assets

Authentication:
- `/api/presign` and `/api/complete` require header `X-FotoX-Key: <PRESIGN_TOKEN>`
- All other routes are public
