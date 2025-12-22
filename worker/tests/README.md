# Worker Tests

Planned: Miniflare-based tests for Worker routes.

Targets:
- `/health`
- `/presign`
- `/upload`
- `/complete`
- `/s/:sessionId`
- `/e/:eventId`
- `/asset`

Auth:
- `/presign` and `/complete` require `X-FotoX-Key`.
