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
- `GET /s/:sessionId`
- `GET /e/:eventId`
- `GET /asset?path=...`
- `GET /health`

Authentication:
- `/presign` and `/complete` require header `X-FotoX-Key: <PRESIGN_TOKEN>`
