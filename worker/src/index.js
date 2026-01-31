import { GALLERY_CSS, CSS_HASH } from './gallery.css.js'
import { GALLERY_JS, JS_HASH } from './gallery.js.js'
import * as Sentry from '@sentry/cloudflare'

const encoder = new TextEncoder()

export default Sentry.withSentry(
  (env) => ({
    dsn: env.SENTRY_DSN,
    tracesSampleRate: 1.0,
  }),
  {
  async fetch(request, env, ctx) {
    const url = new URL(request.url)
    const baseURL = env.PUBLIC_BASE_URL || `${url.protocol}//${url.host}`

    if (request.method === "POST" && url.pathname === "/api/presign") {
      return handlePresign(request, env, baseURL)
    }

    if (request.method === "PUT" && url.pathname === "/api/upload") {
      return handleUpload(request, env, url)
    }

    if (request.method === "POST" && url.pathname === "/api/complete") {
      return handleComplete(request, env)
    }

    if (request.method === "OPTIONS" && url.pathname.startsWith("/api/s/") && url.pathname.endsWith("/strips")) {
      return new Response(null, {
        status: 204,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type",
          "Access-Control-Max-Age": "86400",
        }
      })
    }

    if (request.method === "GET" && url.pathname.startsWith("/api/s/") && url.pathname.endsWith("/strips")) {
      const sessionId = url.pathname.replace("/api/s/", "").replace("/strips", "")
      const validationError = validateSessionId(sessionId)
      if (validationError) {
        return validationError
      }
      return handleSessionStrips(env, baseURL, sessionId)
    }

    if (request.method === "GET" && url.pathname.startsWith("/s/")) {
      const sessionId = url.pathname.replace("/s/", "")
      const validationError = validateSessionId(sessionId)
      if (validationError) {
        return validationError
      }
      return handleSessionGallery(env, baseURL, sessionId)
    }

    if (request.method === "GET" && url.pathname.startsWith("/api/events/") && url.pathname.endsWith("/thumbnails")) {
      const eventId = url.pathname.replace("/api/events/", "").replace("/thumbnails", "")
      const validationError = validateEventId(eventId)
      if (validationError) {
        return validationError
      }
      return handleEventThumbnails(env, baseURL, eventId, url)
    }

    if (request.method === "GET" && url.pathname.startsWith("/api/events/")) {
      const eventId = url.pathname.replace("/api/events/", "")
      const validationError = validateEventId(eventId)
      if (validationError) {
        return validationError
      }
      return handleEventGalleryJSON(env, eventId)
    }

    if (request.method === "GET" && url.pathname.startsWith("/e/")) {
      const eventId = url.pathname.replace("/e/", "")
      const validationError = validateEventId(eventId)
      if (validationError) {
        return validationError
      }
      return handleEventGallery(env, baseURL, eventId)
    }

    if (request.method === "GET" && url.pathname === "/api/asset") {
      return handleAsset(env, url, request)
    }

    if (request.method === "OPTIONS" && url.pathname === "/asset") {
      return new Response(null, {
        status: 204,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, Range",
          "Access-Control-Max-Age": "86400",
        }
      })
    }

    if (request.method === "GET" && url.pathname === "/api/health") {
      return json({ status: "ok" })
    }

    // Static assets with aggressive caching
    if (request.method === "GET" && url.pathname === `/static/gallery.${CSS_HASH}.css`) {
      return new Response(GALLERY_CSS, {
        headers: {
          "Content-Type": "text/css; charset=utf-8",
          "Cache-Control": "public, max-age=31536000, immutable"
        }
      })
    }

    if (request.method === "GET" && url.pathname === `/static/gallery.${JS_HASH}.js`) {
      return new Response(GALLERY_JS, {
        headers: {
          "Content-Type": "application/javascript; charset=utf-8",
          "Cache-Control": "public, max-age=31536000, immutable"
        }
      })
    }

    return new Response("Not found", { status: 404 })
  },
}
)

async function handlePresign(request, env, baseURL) {
  const authError = requirePresignAuth(request, env)
  if (authError) {
    return authError
  }

  let body
  try {
    body = await request.json()
  } catch (err) {
    return json({ error: "Invalid JSON payload" }, 400)
  }

  if (!body.files || !Array.isArray(body.files)) {
    return json({ error: "Invalid request format: files array required" }, 400)
  }

  Sentry.addBreadcrumb({
    category: "upload",
    message: "Presign requested",
    data: {
      event_id: body.event_id,
      session_id: body.session_id,
      file_count: body.files.length
    }
  })

  const secret = env.UPLOAD_SECRET
  if (!secret) {
    return json({ error: "UPLOAD_SECRET not configured" }, 500)
  }

  const expiresAt = Math.floor(Date.now() / 1000) + 900
  const uploads = await Promise.all(
    body.files.map(async (file) => {
      const message = `${file.path}:${expiresAt}`
      const sig = await hmacSignature(secret, message)
      const url = `${baseURL}/api/upload?path=${encodeURIComponent(file.path)}&expires=${expiresAt}&sig=${sig}`
      return { path: file.path, method: "PUT", url }
    })
  )

  return json({ uploads, expires_in_seconds: 900 })
}

async function handleUpload(request, env, url) {
  const secret = env.UPLOAD_SECRET
  if (!secret) {
    return json({ error: "UPLOAD_SECRET not configured" }, 500)
  }

  const path = url.searchParams.get("path")
  const expires = Number(url.searchParams.get("expires"))
  const sig = url.searchParams.get("sig")

  if (!path || !expires || !sig) {
    return new Response("Missing parameters", { status: 400 })
  }

  // Validate content-length (100MB limit for photos/videos)
  const contentLength = request.headers.get("content-length")
  if (contentLength) {
    const sizeMB = parseInt(contentLength) / (1024 * 1024)
    if (sizeMB > 100) {
      return new Response("File too large (max 100MB)", { status: 413 })
    }
  }

  if (Date.now() / 1000 > expires) {
    return new Response("URL expired", { status: 403 })
  }

  const expected = await hmacSignature(secret, `${path}:${expires}`)
  if (sig !== expected) {
    return new Response("Invalid signature", { status: 403 })
  }

  const contentType = request.headers.get("content-type") || "application/octet-stream"
  const sizeBytes = parseInt(request.headers.get("content-length")) || 0

  // Track upload start time
  const uploadStart = Date.now()

  await env.R2_BUCKET.put(path, request.body, {
    httpMetadata: { contentType },
  })

  // Calculate upload duration
  const uploadDuration = Date.now() - uploadStart

  Sentry.addBreadcrumb({
    category: "upload",
    message: "Asset uploaded",
    data: { path, size: sizeBytes }
  })

  // Extract event_id from path (format: events/{eventId}/sessions/{sessionId}/...)
  const pathMatch = path.match(/^events\/(\d+)\//)
  const eventId = pathMatch ? pathMatch[1] : 'unknown'

  // Track file size
  Sentry.metrics.distribution('asset_size_bytes', sizeBytes, {
    attributes: {
      event_id: eventId,
      content_type: contentType
    }
  })

  // Track upload duration
  Sentry.metrics.distribution('upload_duration_ms', uploadDuration, {
    attributes: {
      event_id: eventId,
      content_type: contentType
    }
  })

  // Count successful uploads
  Sentry.metrics.count('asset_uploaded', 1, {
    attributes: {
      event_id: eventId,
      content_type: contentType
    }
  })

  return new Response(null, { status: 200 })
}

async function handleComplete(request, env) {
  const completeStart = Date.now()

  const authError = requirePresignAuth(request, env)
  if (authError) {
    return authError
  }

  let body
  try {
    body = await request.json()
  } catch (err) {
    return json({ error: "Invalid JSON payload" }, 400)
  }

  const { event_id: eventId, session_id: sessionId, manifest_path: manifestPath } = body

  if (!eventId || !sessionId || !manifestPath) {
    return json({ error: "Missing fields: event_id, session_id, manifest_path required" }, 400)
  }

  const manifestObject = await env.R2_BUCKET.get(manifestPath)
  if (!manifestObject) {
    return json({ error: "Manifest not found" }, 404)
  }

  const manifest = await manifestObject.json()

  // Inject event_id into manifest so session gallery knows its parent
  manifest.event_id = eventId

  const sessionIndexPath = `sessions/${sessionId}/manifest.json`
  await env.R2_BUCKET.put(sessionIndexPath, JSON.stringify(manifest), {
    httpMetadata: { contentType: "application/json" },
  })

  const indexPath = `events/${eventId}/index.json`
  const existing = await env.R2_BUCKET.get(indexPath)
  let index = { version: 1, event_id: Number(eventId), updated_at: new Date().toISOString(), sessions: [] }
  if (existing) {
    index = await existing.json()
  }

  const thumb = manifest.assets.find((asset) => asset.kind === "strip_photo")?.path
    || manifest.assets.find((asset) => asset.kind === "strip")?.path
    || manifest.assets.find((asset) => asset.kind === "photo")?.path
    || manifest.assets[0]?.path
  const newEntry = {
    session_id: sessionId,
    created_at: manifest.created_at || new Date().toISOString(),
    thumb_path: thumb,
    gallery_path: `s/${sessionId}`,
  }

  const withoutDuplicate = index.sessions.filter((session) => session.session_id !== sessionId)
  index.sessions = [newEntry, ...withoutDuplicate]
  index.updated_at = new Date().toISOString()

  await env.R2_BUCKET.put(indexPath, JSON.stringify(index), {
    httpMetadata: { contentType: "application/json" },
  })

  Sentry.addBreadcrumb({
    category: "upload",
    message: "Session completed",
    data: { event_id: eventId, session_id: sessionId }
  })

  // Track session completion duration
  const completeDuration = Date.now() - completeStart
  Sentry.metrics.distribution('session_complete_duration_ms', completeDuration, {
    attributes: {
      event_id: eventId
    }
  })

  // Count completed sessions
  Sentry.metrics.count('session_completed', 1, {
    attributes: {
      event_id: eventId
    }
  })

  return json({ status: "ok" })
}

async function handleSessionGallery(env, baseURL, sessionId) {
  const manifestPath = `sessions/${sessionId}/manifest.json`
  const manifestObject = await env.R2_BUCKET.get(manifestPath)
  if (!manifestObject) {
    return html("Processing", `
      <div class="empty-state">
        <div class="spinner"></div>
        <h1>Photos are processing</h1>
        <p>Your photos are being prepared. Please check back in a moment.</p>
        <button class="btn primary refresh-btn">Refresh Page</button>
      </div>
    `, env)
  }

  const manifest = await manifestObject.json()
  const assets = manifest.assets || []

  // Sort assets if needed, or just map them
  const tiles = assets
    .map((asset, index) => {
      const url = assetURL(env, baseURL, asset.path)
      const escapedUrl = escapeHtml(url)

      let mediaContent = ''
      let type = 'image'

      let typeBadge = ''
      if (asset.kind === "video" || asset.kind === "strip_video") {
        type = 'video'
        const poster = asset.poster_path ? assetURL(env, baseURL, asset.poster_path) : ""
        const escapedPoster = escapeHtml(poster)
        mediaContent = `<video src="${escapedUrl}" poster="${escapedPoster}" preload="metadata" playsinline muted loop></video>`
        typeBadge = `<div class="type-badge"><svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg></div>`
      } else {
        mediaContent = `<img src="${escapedUrl}" alt="Photo" loading="lazy" />`
      }

      return `
        <div class="media-item" data-index="${index}" data-type="${escapeHtml(type)}" data-src="${escapedUrl}" tabindex="0" role="button" aria-label="View ${type} ${index + 1}">
          ${mediaContent}
          ${typeBadge}
          <div class="overlay">
            <div class="actions">
              <button class="action-btn view-btn" data-index="${index}" aria-label="View fullscreen">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7"/></svg>
              </button>
              <a href="${escapedUrl}" download class="action-btn download-btn" target="_blank" aria-label="Download">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3"/></svg>
              </a>
              <button class="action-btn share-btn" data-url="${escapedUrl}" aria-label="Share">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/><line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/></svg>
              </button>
            </div>
          </div>
        </div>
      `
    })
    .join("")

  // Inject the assets array for the lightbox script to use (with proper escaping)
  const galleryAssets = assets.map(a => {
    const type = (a.kind === 'video' || a.kind === 'strip_video') ? 'video' : 'image'
    return {
      type,
      src: assetURL(env, baseURL, a.path),
      poster: a.poster_path ? assetURL(env, baseURL, a.poster_path) : null
    }
  })
  const scriptData = `<script>window.GALLERY_ASSETS = ${escapeJsonForScript(galleryAssets)};</script>`

  // Escape header content
  const eventId = manifest.event_id ? escapeHtml(String(manifest.event_id)) : ''
  const itemCount = escapeHtml(String(assets.length))
  const createdDate = escapeHtml(new Date(manifest.created_at || Date.now()).toLocaleDateString())

  return html("Session Gallery", `
    <header class="gallery-header">
      <a href="/e/${eventId}" class="logo">FotoX</a>
      <div class="meta">
        <span>${itemCount} Items</span>
        <span>•</span>
        <span>${createdDate}</span>
      </div>
    </header>
    <main class="gallery-grid" role="list">
      ${tiles}
    </main>
    ${scriptData}
    ${lightboxHtml()}
  `, env)
}

async function handleSessionStrips(env, baseURL, sessionId) {
  const manifestPath = `sessions/${sessionId}/manifest.json`
  const manifestObject = await env.R2_BUCKET.get(manifestPath)
  if (!manifestObject) {
    return json({ error: "Session not found or still processing" }, 404)
  }

  const manifest = await manifestObject.json()
  const assets = manifest.assets || []

  // Filter to only strip_video and strip_photo
  const strips = assets
    .filter((asset) => asset.kind === "strip_video" || asset.kind === "strip_photo")
    .map((asset) => ({
      kind: asset.kind,
      url: assetURL(env, baseURL, asset.path),
      path: asset.path,
      poster_url: asset.poster_path ? assetURL(env, baseURL, asset.poster_path) : null,
    }))

  return jsonWithCors({
    session_id: sessionId,
    event_id: manifest.event_id || null,
    created_at: manifest.created_at || null,
    strips,
  })
}

async function handleEventGalleryJSON(env, eventId) {
  const indexPath = `events/${eventId}/index.json`
  const indexObject = await env.R2_BUCKET.get(indexPath)
  if (!indexObject) {
    return json({
      version: 1,
      event_id: Number(eventId),
      updated_at: null,
      sessions: [],
    })
  }

  const index = await indexObject.json()
  return json(index)
}

async function handleEventThumbnails(env, baseURL, eventId, url) {
  // Pagination params: limit (default 20, max 100), cursor (session_id to start after)
  const limitParam = url.searchParams.get("limit")
  const cursor = url.searchParams.get("cursor")

  let limit = 20
  if (limitParam) {
    const parsed = parseInt(limitParam, 10)
    if (!isNaN(parsed) && parsed > 0) {
      limit = Math.min(parsed, 100)
    }
  }

  const indexPath = `events/${eventId}/index.json`
  const indexObject = await env.R2_BUCKET.get(indexPath)
  if (!indexObject) {
    return json({
      event_id: Number(eventId),
      thumbnails: [],
      next_cursor: null,
      has_more: false,
    })
  }

  const index = await indexObject.json()
  let sessions = index.sessions || []

  // If cursor provided, find the position and slice from there
  if (cursor) {
    const cursorIndex = sessions.findIndex((s) => s.session_id === cursor)
    if (cursorIndex !== -1) {
      sessions = sessions.slice(cursorIndex + 1)
    }
    // If cursor not found, return from beginning (cursor may be stale)
  }

  // Take limit + 1 to check if there are more
  const hasMore = sessions.length > limit
  const pageSessions = sessions.slice(0, limit)

  const thumbnails = pageSessions.map((session) => ({
    session_id: session.session_id,
    created_at: session.created_at,
    url: assetURL(env, baseURL, session.thumb_path),
  }))

  const nextCursor = hasMore && pageSessions.length > 0
    ? pageSessions[pageSessions.length - 1].session_id
    : null

  return json({
    event_id: Number(eventId),
    updated_at: index.updated_at || null,
    thumbnails,
    next_cursor: nextCursor,
    has_more: hasMore,
  })
}

async function handleEventGallery(env, baseURL, eventId) {
  const indexPath = `events/${eventId}/index.json`
  const indexObject = await env.R2_BUCKET.get(indexPath)
  if (!indexObject) {
    return html("Event Gallery", `
      <div class="empty-state">
        <h1>Event Gallery</h1>
        <p>No sessions have been uploaded yet.</p>
      </div>
    `, env)
  }

  const index = await indexObject.json()
  const sessions = index.sessions || []
  const tiles = sessions
    .map((session) => {
      const thumb = escapeHtml(assetURL(env, baseURL, session.thumb_path))
      const link = escapeHtml(`${baseURL}/${session.gallery_path}`)
      const date = escapeHtml(new Date(session.created_at).toLocaleString())
      return `
        <a class="session-card" href="${link}">
          <div class="session-media">
            <img src="${thumb}" alt="Session thumbnail" loading="lazy" />
            <div class="session-overlay">
              <span>View Gallery</span>
            </div>
          </div>
          <div class="session-info">
             <span class="session-date">${date}</span>
             <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
          </div>
        </a>`
    })
    .join("")

  const escapedEventId = escapeHtml(String(eventId))
  return html("Event Gallery", `
    <header class="gallery-header">
      <a href="/e/${escapedEventId}" class="logo">FotoX</a>
      <h1>Event Gallery</h1>
    </header>
    <main class="gallery-grid" role="list">
      ${tiles}
    </main>
  `, env)
}

async function handleAsset(env, url, request) {
  const path = url.searchParams.get("path")
  if (!path) {
    return new Response("Missing path", { status: 400 })
  }

  // Block access to private paths unless authenticated
  if (path.startsWith("private/")) {
    const token = request.headers.get("X-FotoX-Key")
    if (!token || token !== env.PRESIGN_TOKEN) {
      return new Response("Forbidden", { status: 403 })
    }
  }

  const rangeHeader = request.headers.get("Range")

  // Handle Range requests for video streaming
  if (rangeHeader) {
    // First get object metadata to know the size
    const headObject = await env.R2_BUCKET.head(path)
    if (!headObject) {
      return new Response("Not found", { status: 404 })
    }

    const fileSize = headObject.size
    const contentType = headObject.httpMetadata?.contentType || "application/octet-stream"

    // Parse Range header: "bytes=start-end" or "bytes=start-"
    const rangeMatch = rangeHeader.match(/bytes=(\d+)-(\d*)/)
    if (!rangeMatch) {
      return new Response("Invalid Range header", { status: 416 })
    }

    const start = parseInt(rangeMatch[1], 10)
    const end = rangeMatch[2] ? parseInt(rangeMatch[2], 10) : fileSize - 1

    // Validate range
    if (start >= fileSize || end >= fileSize || start > end) {
      const headers = new Headers()
      headers.set("Content-Range", `bytes */${fileSize}`)
      return new Response("Range Not Satisfiable", { status: 416, headers })
    }

    // Fetch the requested range from R2
    const object = await env.R2_BUCKET.get(path, {
      range: { offset: start, length: end - start + 1 },
    })

    if (!object) {
      return new Response("Not found", { status: 404 })
    }

    const headers = new Headers()
    headers.set("Content-Type", contentType)
    headers.set("Content-Length", String(end - start + 1))
    headers.set("Content-Range", `bytes ${start}-${end}/${fileSize}`)
    headers.set("Accept-Ranges", "bytes")
    headers.set("Cache-Control", "public, max-age=3600")
    headers.set("Access-Control-Allow-Origin", "*")

    return new Response(object.body, { status: 206, headers })
  }

  // Full file request (no Range header)
  const object = await env.R2_BUCKET.get(path)
  if (!object) {
    return new Response("Not found", { status: 404 })
  }

  const headers = new Headers()
  headers.set("Content-Type", object.httpMetadata?.contentType || "application/octet-stream")
  headers.set("Content-Length", String(object.size))
  headers.set("Accept-Ranges", "bytes")
  headers.set("Cache-Control", "public, max-age=3600")
  headers.set("Access-Control-Allow-Origin", "*")
  return new Response(object.body, { headers })
}

function assetURL(env, baseURL, path) {
  if (env.R2_PUBLIC_BASE_URL) {
    return `${env.R2_PUBLIC_BASE_URL}/${path}`
  }
  return `${baseURL}/api/asset?path=${encodeURIComponent(path)}`
}

function json(value, status = 200) {
  return new Response(JSON.stringify(value), {
    status,
    headers: { "Content-Type": "application/json" },
  })
}

function jsonWithCors(value, status = 200) {
  return new Response(JSON.stringify(value), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  })
}

function html(title, body, env = null) {
  // Build CSP based on R2 configuration
  let imgSrc = "'self' data: blob:";
  let mediaSrc = "'self' blob:";

  // If R2_PUBLIC_BASE_URL is configured, add it to allowed sources
  if (env?.R2_PUBLIC_BASE_URL) {
    try {
      const r2Domain = new URL(env.R2_PUBLIC_BASE_URL).origin;
      imgSrc += ` ${r2Domain}`;
      mediaSrc += ` ${r2Domain}`;
    } catch (e) {
      // Invalid URL, fall back to self-only
      console.error('Invalid R2_PUBLIC_BASE_URL:', e);
    }
  }

  const csp = `default-src 'self'; script-src 'self'; style-src 'self'; img-src ${imgSrc}; media-src ${mediaSrc};`;

  return new Response(
    `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <title>${escapeHtml(title)}</title>
    <link rel="stylesheet" href="/static/gallery.${CSS_HASH}.css">
  </head>
  <body>
    ${body}
    <script src="/static/gallery.${JS_HASH}.js"></script>
  </body>
</html>`,
    {
      headers: {
        "Content-Type": "text/html; charset=utf-8",
        "Content-Security-Policy": csp
      }
    }
  )
}

function lightboxHtml() {
  return `
    <div id="lightbox" class="lightbox" role="dialog" aria-modal="true" aria-label="Image viewer">
      <div class="lb-header">
        <span id="lb-counter" class="lb-counter" aria-live="polite"></span>
        <button class="action-btn share-btn" id="lb-share" aria-label="Share">
           <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/><line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/></svg>
        </button>
        <a id="lb-download" href="#" class="action-btn" download target="_blank" aria-label="Download">
           <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3"/></svg>
        </a>
        <button class="action-btn close-btn" aria-label="Close">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6L6 18M6 6l12 12"/></svg>
        </button>
      </div>
      <div class="lb-content">
        <button class="lb-nav lb-prev" aria-label="Previous image">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 18l-6-6 6-6"/></svg>
        </button>
        <img id="lb-img" class="lb-media" src="" alt="Full size view" />
        <video id="lb-video" class="lb-media" controls playsinline aria-label="Video player" style="display:none;"></video>
        <button class="lb-nav lb-next" aria-label="Next image">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 18l6-6-6-6"/></svg>
        </button>
      </div>
    </div>
  `
}

function validateEventId(eventId) {
  if (!eventId || eventId.trim() === "") {
    return json({ error: "Event ID is required" }, 400)
  }

  const numericEventId = Number(eventId)
  if (!Number.isInteger(numericEventId) || numericEventId <= 0) {
    return json({ error: "Event ID must be a valid positive integer" }, 400)
  }

  // Prevent path traversal attacks
  if (eventId.includes("/") || eventId.includes("\\") || eventId.includes("..")) {
    return json({ error: "Invalid Event ID format" }, 400)
  }

  return null
}

function validateSessionId(sessionId) {
  if (!sessionId || sessionId.trim() === "") {
    return json({ error: "Session ID is required" }, 400)
  }

  // Enforce minimum and maximum length
  if (sessionId.length < 3 || sessionId.length > 128) {
    return json({ error: "Session ID must be 3-128 characters" }, 400)
  }

  // Session IDs must start and end with alphanumeric, can contain hyphens/underscores in middle
  if (!/^[a-zA-Z0-9]([a-zA-Z0-9_-]*[a-zA-Z0-9])?$/.test(sessionId)) {
    return json({ error: "Invalid Session ID format" }, 400)
  }

  // Prevent path traversal attacks
  if (sessionId.includes("/") || sessionId.includes("\\") || sessionId.includes("..")) {
    return json({ error: "Invalid Session ID format" }, 400)
  }

  return null
}

function requirePresignAuth(request, env) {
  const token = env.PRESIGN_TOKEN
  if (!token) {
    return json({ error: "PRESIGN_TOKEN not configured" }, 500)
  }
  const provided = request.headers.get("X-FotoX-Key")
  if (!provided || provided !== token) {
    return json({ error: "Unauthorized" }, 401)
  }
  return null
}

async function hmacSignature(secret, message) {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  )
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(message))
  return base64Url(signature)
}

function base64Url(buffer) {
  const bytes = new Uint8Array(buffer)
  let binary = ""
  bytes.forEach((b) => {
    binary += String.fromCharCode(b)
  })
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "")
}

function escapeHtml(str) {
  if (str === null || str === undefined) return ''
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

function escapeJsonForScript(obj) {
  return JSON.stringify(obj)
    .replace(/</g, '\\u003c')
    .replace(/>/g, '\\u003e')
    .replace(/&/g, '\\u0026')
}
