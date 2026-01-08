import { describe, it, expect, beforeAll } from 'vitest'
import worker from '../src/index.js'

describe('FotoX Worker Tests', () => {
  const env = {
    UPLOAD_SECRET: 'test-secret-key',
    PRESIGN_TOKEN: 'test-presign-token',
    PUBLIC_BASE_URL: 'https://test-worker.dev',
    R2_PUBLIC_BASE_URL: '',
    R2_BUCKET: {
      get: async () => null,
      put: async () => {},
      head: async () => null,
    },
  }

  // Helper to create a request
  const makeRequest = (path, options = {}) => {
    const url = `https://test-worker.dev${path}`
    return new Request(url, options)
  }

  describe('Security - Session ID Validation', () => {
    it('should accept valid UUID-format session IDs', async () => {
      const request = makeRequest('/s/abc123-def456')
      const response = await worker.fetch(request, env)

      // Should not return 400 validation error
      expect(response.status).not.toBe(400)
    })

    it('should accept alphanumeric session IDs', async () => {
      const request = makeRequest('/s/session123')
      const response = await worker.fetch(request, env)

      expect(response.status).not.toBe(400)
    })

    it('should reject empty session IDs', async () => {
      const request = makeRequest('/s/')
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(400)
      const body = await response.json()
      expect(body.error).toContain('Session ID is required')
    })

    it('should reject session IDs with forward slash', async () => {
      // Testing with a session ID containing / directly
      const request = new Request('https://test-worker.dev/s/session/path')
      const response = await worker.fetch(request, env)

      // The validation catches the slash and returns 400
      expect(response.status).toBe(400)
      const body = await response.json()
      expect(body.error).toContain('Invalid Session ID format')
    })

    it('should reject session IDs with backslash', async () => {
      const request = makeRequest('/s/session\\path')
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(400)
    })

    it('should reject session IDs with double dots', async () => {
      const request = makeRequest('/s/session..path')
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(400)
    })

    it('should reject session IDs with special characters', async () => {
      const request = makeRequest('/s/session<script>')
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(400)
    })

    it('should reject URL-encoded path traversal attempts', async () => {
      const request = makeRequest('/s/..%2F..%2Fsecret')
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(400)
    })
  })

  describe('Security - Event ID Validation', () => {
    it('should accept valid positive integer event IDs', async () => {
      const request = makeRequest('/e/123')
      const response = await worker.fetch(request, env)

      expect(response.status).not.toBe(400)
    })

    it('should reject empty event IDs', async () => {
      const request = makeRequest('/e/')
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(400)
      const body = await response.json()
      expect(body.error).toContain('Event ID is required')
    })

    it('should reject path traversal attempts', async () => {
      // Test with event ID containing path traversal characters
      const request = makeRequest('/e/123../456')
      const response = await worker.fetch(request, env)

      // This will return 404 because route won't match, or 400 if it contains ..
      expect([400, 404]).toContain(response.status)
    })

    it('should reject non-numeric event IDs', async () => {
      const request = makeRequest('/e/abc')
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(400)
      const body = await response.json()
      expect(body.error).toContain('valid positive integer')
    })

    it('should reject negative event IDs', async () => {
      const request = makeRequest('/e/-123')
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(400)
    })

    it('should reject zero as event ID', async () => {
      const request = makeRequest('/e/0')
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(400)
    })

    it('should reject floating point event IDs', async () => {
      const request = makeRequest('/e/12.34')
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(400)
    })
  })

  describe('Security - Authentication', () => {
    it('should require auth token for presign endpoint', async () => {
      const request = makeRequest('/presign', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ files: [] }),
      })
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(401)
      const body = await response.json()
      expect(body.error).toBe('Unauthorized')
    })

    it('should accept valid auth token for presign', async () => {
      const request = makeRequest('/presign', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-FotoX-Key': 'test-presign-token',
        },
        body: JSON.stringify({ files: [{ path: 'test.jpg' }] }),
      })
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(200)
    })

    it('should reject invalid auth token for presign', async () => {
      const request = makeRequest('/presign', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-FotoX-Key': 'wrong-token',
        },
        body: JSON.stringify({ files: [] }),
      })
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(401)
    })

    it('should require auth token for complete endpoint', async () => {
      const request = makeRequest('/complete', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          event_id: '123',
          session_id: 'test-session',
          manifest_path: 'test/manifest.json',
        }),
      })
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(401)
    })
  })

  describe('Security - CSP Headers', () => {
    it('should set Content-Security-Policy header on session gallery', async () => {
      const request = makeRequest('/s/test-session')
      const response = await worker.fetch(request, env)

      const csp = response.headers.get('Content-Security-Policy')
      expect(csp).toBeTruthy()
      expect(csp).toContain("script-src 'self'")
      expect(csp).toContain("style-src 'self'")
      expect(csp).toContain("default-src 'self'")
    })

    it('should set Content-Security-Policy header on event gallery', async () => {
      const request = makeRequest('/e/123')
      const response = await worker.fetch(request, env)

      const csp = response.headers.get('Content-Security-Policy')
      expect(csp).toBeTruthy()
    })

    it('should not allow unsafe-inline in script-src', async () => {
      const request = makeRequest('/s/test-session')
      const response = await worker.fetch(request, env)

      const csp = response.headers.get('Content-Security-Policy')
      expect(csp).not.toContain('unsafe-inline')
    })

    it('should not allow img-src from arbitrary HTTPS origins', async () => {
      const request = makeRequest('/s/test-session')
      const response = await worker.fetch(request, env)

      const csp = response.headers.get('Content-Security-Policy')
      expect(csp).not.toContain('https:')
    })

    it('should allow data: and blob: for img-src', async () => {
      const request = makeRequest('/s/test-session')
      const response = await worker.fetch(request, env)

      const csp = response.headers.get('Content-Security-Policy')
      expect(csp).toContain('img-src')
      expect(csp).toContain('data:')
      expect(csp).toContain('blob:')
    })

    it('should allow blob: for media-src', async () => {
      const request = makeRequest('/s/test-session')
      const response = await worker.fetch(request, env)

      const csp = response.headers.get('Content-Security-Policy')
      expect(csp).toContain('media-src')
      expect(csp).toContain('blob:')
    })
  })

  describe('Functionality - Gallery Views', () => {
    it('should return HTML for session gallery', async () => {
      const request = makeRequest('/s/test-session')
      const response = await worker.fetch(request, env)

      expect(response.headers.get('Content-Type')).toContain('text/html')
      const html = await response.text()
      expect(html).toContain('<!doctype html>')
    })

    it('should return HTML for event gallery', async () => {
      const request = makeRequest('/e/123')
      const response = await worker.fetch(request, env)

      expect(response.headers.get('Content-Type')).toContain('text/html')
      const html = await response.text()
      expect(html).toContain('<!doctype html>')
    })

    it('should return JSON for event API endpoint', async () => {
      const request = makeRequest('/api/e/123')
      const response = await worker.fetch(request, env)

      expect(response.headers.get('Content-Type')).toContain('application/json')
      const body = await response.json()
      expect(body).toHaveProperty('version')
      expect(body).toHaveProperty('sessions')
    })

    it('should show processing message for missing session manifest', async () => {
      const request = makeRequest('/s/processing-session')
      const response = await worker.fetch(request, env)

      const html = await response.text()
      expect(html.toLowerCase()).toContain('processing')
    })

    it('should return empty event for missing event index', async () => {
      const request = makeRequest('/api/e/999')
      const response = await worker.fetch(request, env)

      const body = await response.json()
      expect(body.sessions).toEqual([])
      expect(body.event_id).toBe(999)
    })
  })

  describe('Functionality - Static Assets', () => {
    it('should serve CSS with correct content type', async () => {
      const request = makeRequest('/static/gallery.v1.css')
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(200)
      expect(response.headers.get('Content-Type')).toContain('text/css')
    })

    it('should serve CSS with immutable cache headers', async () => {
      const request = makeRequest('/static/gallery.v1.css')
      const response = await worker.fetch(request, env)

      const cacheControl = response.headers.get('Cache-Control')
      expect(cacheControl).toContain('immutable')
      expect(cacheControl).toContain('max-age=31536000')
    })

    it('should serve JS with correct content type', async () => {
      const request = makeRequest('/static/gallery.v3.js')
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(200)
      expect(response.headers.get('Content-Type')).toContain('javascript')
    })

    it('should serve JS with immutable cache headers', async () => {
      const request = makeRequest('/static/gallery.v3.js')
      const response = await worker.fetch(request, env)

      const cacheControl = response.headers.get('Cache-Control')
      expect(cacheControl).toContain('immutable')
      expect(cacheControl).toContain('max-age=31536000')
    })

    it('should return 404 for unknown static files', async () => {
      const request = makeRequest('/static/unknown.css')
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(404)
    })
  })

  describe('Functionality - Asset Serving', () => {
    it('should require path parameter', async () => {
      const request = makeRequest('/asset')
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(400)
      const text = await response.text()
      expect(text).toContain('Missing path')
    })

    it('should return 404 for missing assets', async () => {
      const request = makeRequest('/asset?path=nonexistent.jpg')
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(404)
    })

    it('should handle asset requests with proper headers', async () => {
      // Mock R2 bucket to return a test object
      const mockEnv = {
        ...env,
        R2_BUCKET: {
          get: async (path) => ({
            body: new ReadableStream(),
            httpMetadata: { contentType: 'image/jpeg' },
            size: 1024,
          }),
        },
      }

      const request = makeRequest('/asset?path=test.jpg')
      const response = await worker.fetch(request, mockEnv)

      expect(response.headers.get('Accept-Ranges')).toBe('bytes')
      expect(response.headers.get('Cache-Control')).toContain('max-age=3600')
    })
  })

  describe('Functionality - Upload Flow', () => {
    it('should return presigned upload URLs', async () => {
      const request = makeRequest('/presign', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-FotoX-Key': 'test-presign-token',
        },
        body: JSON.stringify({
          files: [
            { path: 'sessions/test/photo1.jpg' },
            { path: 'sessions/test/photo2.jpg' },
          ],
        }),
      })
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(200)
      const body = await response.json()
      expect(body.uploads).toHaveLength(2)
      expect(body.uploads[0]).toHaveProperty('path')
      expect(body.uploads[0]).toHaveProperty('url')
      expect(body.uploads[0]).toHaveProperty('method', 'PUT')
      expect(body.expires_in_seconds).toBe(900)
    })

    it('should reject upload with missing parameters', async () => {
      const request = makeRequest('/upload', { method: 'PUT' })
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(400)
    })

    it('should reject expired upload URLs', async () => {
      const request = makeRequest(
        '/upload?path=test.jpg&expires=1000000000&sig=invalid',
        { method: 'PUT', body: 'test' }
      )
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(403)
      const text = await response.text()
      expect(text.toLowerCase()).toContain('expired')
    })

    it('should reject upload with invalid signature', async () => {
      const futureTime = Math.floor(Date.now() / 1000) + 3600
      const request = makeRequest(
        `/upload?path=test.jpg&expires=${futureTime}&sig=invalid`,
        { method: 'PUT', body: 'test' }
      )
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(403)
      const text = await response.text()
      expect(text.toLowerCase()).toContain('signature')
    })

    it('should require fields for complete endpoint', async () => {
      const request = makeRequest('/complete', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-FotoX-Key': 'test-presign-token',
        },
        body: JSON.stringify({ event_id: '123' }),
      })
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(400)
      const body = await response.json()
      expect(body.error).toContain('Missing fields')
    })
  })

  describe('Edge Cases', () => {
    it('should handle session gallery with escaped HTML in title', async () => {
      const request = makeRequest('/s/test-session')
      const response = await worker.fetch(request, env)

      const html = await response.text()
      // Title should be escaped
      expect(html).toContain('<title>')
      expect(html).not.toContain('<script>')
    })

    it('should return 404 for unknown routes', async () => {
      const request = makeRequest('/unknown-route')
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(404)
    })

    it('should handle HEAD requests', async () => {
      const request = makeRequest('/health', { method: 'HEAD' })
      const response = await worker.fetch(request, env)

      // Should return 404 since only GET is supported
      expect(response.status).toBe(404)
    })

    it('should handle OPTIONS requests', async () => {
      const request = makeRequest('/health', { method: 'OPTIONS' })
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(404)
    })
  })

  describe('Health Check', () => {
    it('should return ok status', async () => {
      const request = makeRequest('/health')
      const response = await worker.fetch(request, env)

      expect(response.status).toBe(200)
      const body = await response.json()
      expect(body.status).toBe('ok')
    })

    it('should return JSON content type', async () => {
      const request = makeRequest('/health')
      const response = await worker.fetch(request, env)

      expect(response.headers.get('Content-Type')).toContain('application/json')
    })
  })

  describe('HTML Output Validation', () => {
    it('should include lightbox HTML in session gallery', async () => {
      // Mock R2 bucket to return a manifest
      const mockEnv = {
        ...env,
        R2_BUCKET: {
          get: async (path) => {
            if (path === 'sessions/test-session/manifest.json') {
              const manifest = {
                event_id: 123,
                created_at: new Date().toISOString(),
                assets: [
                  { kind: 'photo', path: 'sessions/test-session/photo1.jpg' },
                ],
              }
              return {
                json: async () => manifest,
              }
            }
            return null
          },
          put: async () => {},
          head: async () => null,
        },
      }

      const request = makeRequest('/s/test-session')
      const response = await worker.fetch(request, mockEnv)

      const html = await response.text()
      expect(html).toContain('id="lightbox"')
      expect(html).toContain('class="lightbox"')
      expect(html).toContain('role="dialog"')
    })

    it('should include gallery CSS link', async () => {
      const request = makeRequest('/s/test-session')
      const response = await worker.fetch(request, env)

      const html = await response.text()
      expect(html).toContain('<link rel="stylesheet"')
      expect(html).toContain('gallery.')
      expect(html).toContain('.css')
    })

    it('should include gallery JS script', async () => {
      const request = makeRequest('/s/test-session')
      const response = await worker.fetch(request, env)

      const html = await response.text()
      expect(html).toContain('<script src=')
      expect(html).toContain('gallery.')
      expect(html).toContain('.js')
    })

    it('should have proper HTML structure', async () => {
      const request = makeRequest('/e/123')
      const response = await worker.fetch(request, env)

      const html = await response.text()
      expect(html).toContain('<!doctype html>')
      expect(html).toContain('<html lang="en">')
      expect(html).toContain('<head>')
      expect(html).toContain('<body>')
      expect(html).toContain('</html>')
    })

    it('should have viewport meta tag for mobile', async () => {
      const request = makeRequest('/s/test-session')
      const response = await worker.fetch(request, env)

      const html = await response.text()
      expect(html).toContain('viewport')
      expect(html).toContain('width=device-width')
    })

    it('should not have inline onclick handlers in lightbox', async () => {
      // Mock R2 bucket to return a manifest
      const mockEnv = {
        ...env,
        R2_BUCKET: {
          get: async (path) => {
            if (path === 'sessions/test-session/manifest.json') {
              const manifest = {
                event_id: 123,
                created_at: new Date().toISOString(),
                assets: [
                  { kind: 'photo', path: 'sessions/test-session/photo1.jpg' },
                ],
              }
              return {
                json: async () => manifest,
              }
            }
            return null
          },
          put: async () => {},
          head: async () => null,
        },
      }

      const request = makeRequest('/s/test-session')
      const response = await worker.fetch(request, mockEnv)

      const html = await response.text()
      // Check that lightbox elements don't have onclick attributes
      const lightboxSection = html.substring(html.indexOf('id="lightbox"'))
      expect(lightboxSection).not.toContain('onclick=')
    })
  })
})
