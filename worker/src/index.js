const encoder = new TextEncoder()

export default {
  async fetch(request, env) {
    const url = new URL(request.url)
    const baseURL = env.PUBLIC_BASE_URL || `${url.protocol}//${url.host}`

    if (request.method === "POST" && url.pathname === "/presign") {
      return handlePresign(request, env, baseURL)
    }

    if (request.method === "PUT" && url.pathname === "/upload") {
      return handleUpload(request, env, url)
    }

    if (request.method === "POST" && url.pathname === "/complete") {
      return handleComplete(request, env)
    }

    if (request.method === "GET" && url.pathname.startsWith("/s/")) {
      const sessionId = url.pathname.replace("/s/", "")
      return handleSessionGallery(env, baseURL, sessionId)
    }

    if (request.method === "GET" && url.pathname.startsWith("/e/")) {
      const eventId = url.pathname.replace("/e/", "")
      return handleEventGallery(env, baseURL, eventId)
    }

    if (request.method === "GET" && url.pathname === "/asset") {
      return handleAsset(env, url)
    }

    if (request.method === "GET" && url.pathname === "/health") {
      return json({ status: "ok" })
    }

    return new Response("Not found", { status: 404 })
  },
}

async function handlePresign(request, env, baseURL) {
  const authError = requirePresignAuth(request, env)
  if (authError) {
    return authError
  }

  const body = await request.json()
  const secret = env.UPLOAD_SECRET
  if (!secret) {
    return json({ error: "UPLOAD_SECRET not configured" }, 500)
  }

  const expiresAt = Math.floor(Date.now() / 1000) + 900
  const uploads = await Promise.all(
    body.files.map(async (file) => {
      const message = `${file.path}:${expiresAt}`
      const sig = await hmacSignature(secret, message)
      const url = `${baseURL}/upload?path=${encodeURIComponent(file.path)}&expires=${expiresAt}&sig=${sig}`
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

  if (Date.now() / 1000 > expires) {
    return new Response("URL expired", { status: 403 })
  }

  const expected = await hmacSignature(secret, `${path}:${expires}`)
  if (sig !== expected) {
    return new Response("Invalid signature", { status: 403 })
  }

  const contentType = request.headers.get("content-type") || "application/octet-stream"
  await env.R2_BUCKET.put(path, request.body, {
    httpMetadata: { contentType },
  })

  return new Response(null, { status: 200 })
}

async function handleComplete(request, env) {
  const authError = requirePresignAuth(request, env)
  if (authError) {
    return authError
  }

  const body = await request.json()
  const { event_id: eventId, session_id: sessionId, manifest_path: manifestPath } = body

  if (!eventId || !sessionId || !manifestPath) {
    return json({ error: "Missing fields" }, 400)
  }

  const manifestObject = await env.R2_BUCKET.get(manifestPath)
  if (!manifestObject) {
    return json({ error: "Manifest not found" }, 404)
  }

  const manifest = await manifestObject.json()
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

  const thumb = manifest.assets.find((asset) => asset.kind === "photo")?.path || manifest.assets[0]?.path
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

  return json({ status: "ok" })
}

async function handleSessionGallery(env, baseURL, sessionId) {
  const manifestPath = `sessions/${sessionId}/manifest.json`
  const manifestObject = await env.R2_BUCKET.get(manifestPath)
  if (!manifestObject) {
    return html("Processing", `<h1>Photos are processing</h1><p>Please check back soon.</p>`)
  }

  const manifest = await manifestObject.json()
  const assets = manifest.assets || []
  const tiles = assets
    .map((asset) => {
      const url = assetURL(env, baseURL, asset.path)
      if (asset.kind === "video") {
        const poster = asset.poster_path ? assetURL(env, baseURL, asset.poster_path) : ""
        return `<video controls preload="metadata" poster="${poster}"><source src="${url}" type="${asset.content_type}"></video>`
      }
      return `<img src="${url}" alt="Photo" loading="lazy" />`
    })
    .join("")

  return html("Gallery", `<h1>Session Gallery</h1><div class="grid">${tiles}</div>`)
}

async function handleEventGallery(env, baseURL, eventId) {
  const indexPath = `events/${eventId}/index.json`
  const indexObject = await env.R2_BUCKET.get(indexPath)
  if (!indexObject) {
    return html("Event Gallery", `<h1>Event Gallery</h1><p>No sessions yet.</p>`)
  }

  const index = await indexObject.json()
  const sessions = index.sessions || []
  const tiles = sessions
    .map((session) => {
      const thumb = assetURL(env, baseURL, session.thumb_path)
      const link = `${baseURL}/${session.gallery_path}`
      return `<a class="session" href="${link}"><img src="${thumb}" alt="Session" /><span>${session.created_at}</span></a>`
    })
    .join("")

  return html("Event Gallery", `<h1>Event Gallery</h1><div class="grid">${tiles}</div>`)
}

async function handleAsset(env, url) {
  const path = url.searchParams.get("path")
  if (!path) {
    return new Response("Missing path", { status: 400 })
  }
  const object = await env.R2_BUCKET.get(path)
  if (!object) {
    return new Response("Not found", { status: 404 })
  }
  const headers = new Headers()
  headers.set("Content-Type", object.httpMetadata?.contentType || "application/octet-stream")
  headers.set("Cache-Control", "public, max-age=3600")
  return new Response(object.body, { headers })
}

function assetURL(env, baseURL, path) {
  if (env.R2_PUBLIC_BASE_URL) {
    return `${env.R2_PUBLIC_BASE_URL}/${path}`
  }
  return `${baseURL}/asset?path=${encodeURIComponent(path)}`
}

function json(value, status = 200) {
  return new Response(JSON.stringify(value), {
    status,
    headers: { "Content-Type": "application/json" },
  })
}

function html(title, body) {
  return new Response(
    `<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${title}</title>
    <style>
      body { font-family: Arial, sans-serif; background: #0f1115; color: #f5f5f5; margin: 0; padding: 24px; }
      h1 { font-size: 28px; margin: 0 0 16px; }
      .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; }
      img, video { width: 100%; border-radius: 12px; background: #1c1f26; }
      .session { display: grid; gap: 8px; text-decoration: none; color: inherit; }
      .session span { font-size: 12px; opacity: 0.7; }
    </style>
  </head>
  <body>
    ${body}
  </body>
</html>`,
    { headers: { "Content-Type": "text/html; charset=utf-8" } }
  )
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
