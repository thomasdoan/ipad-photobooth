// Gallery CSS - extracted for browser caching
export const CSS_HASH = 'v1';

export const GALLERY_CSS = `
:root {
  --bg: #000000;
  --surface: #121212;
  --primary: #ffffff;
  --secondary: #a0a0a0;
  --accent: #3b82f6;
  --grid-gap: 4px;
}

* { box-sizing: border-box; }

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  background: var(--bg);
  color: var(--primary);
  margin: 0;
  padding: 0;
  -webkit-font-smoothing: antialiased;
}

/* Header */
.gallery-header {
  position: sticky;
  top: 0;
  z-index: 10;
  background: rgba(0,0,0,0.8);
  backdrop-filter: blur(10px);
  padding: 16px 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid rgba(255,255,255,0.1);
}
.logo { font-weight: 600; font-size: 18px; letter-spacing: -0.5px; text-decoration: none; color: var(--primary); transition: opacity 0.2s; }
.logo:hover { opacity: 0.8; }
.meta { color: var(--secondary); font-size: 13px; display: flex; gap: 8px; }

/* Grid */
.gallery-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: var(--grid-gap);
  padding: var(--grid-gap);
}

@media (min-width: 768px) {
  .gallery-grid {
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  }
}

/* Media Item */
.media-item {
  position: relative;
  aspect-ratio: 1;
  background: var(--surface);
  overflow: hidden;
  cursor: pointer;
}

.media-item img, .media-item video {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s ease;
}

.media-item:hover img, .media-item:hover video {
  transform: scale(1.05);
}

.type-badge {
  position: absolute;
  top: 8px;
  right: 8px;
  background: rgba(0,0,0,0.6);
  backdrop-filter: blur(4px);
  color: white;
  padding: 6px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  pointer-events: none;
  z-index: 2;
}

.overlay {
  position: absolute;
  inset: 0;
  background: rgba(0,0,0,0.3);
  opacity: 0;
  transition: opacity 0.2s;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  padding: 12px;
}

.media-item:hover .overlay {
  opacity: 1;
}

.actions {
  display: flex;
  gap: 8px;
  justify-content: flex-end;
}

.action-btn {
  background: rgba(255,255,255,0.2);
  backdrop-filter: blur(4px);
  border: none;
  color: white;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background 0.2s;
  text-decoration: none;
}

.action-btn:hover {
  background: rgba(255,255,255,0.4);
}

/* Session Card (Event View) */
.session-card {
  display: block;
  text-decoration: none;
  background: var(--surface);
  border-radius: 12px;
  overflow: hidden;
  transition: transform 0.2s;
  border: 1px solid rgba(255,255,255,0.1);
}
.session-card:hover { transform: translateY(-2px); border-color: rgba(255,255,255,0.2); }
.session-media { position: relative; aspect-ratio: 3/2; }
.session-media img { width: 100%; height: 100%; object-fit: cover; }
.session-overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(to top, rgba(0,0,0,0.8) 0%, transparent 100%);
  display: flex;
  align-items: flex-end;
  padding: 12px;
  opacity: 0;
  transition: opacity 0.2s;
}
.session-card:hover .session-overlay { opacity: 1; }
.session-overlay span { font-weight: 500; font-size: 14px; }

.session-info {
  padding: 12px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  color: var(--primary);
  background: #1a1a1a;
}
.session-date { color: var(--secondary); font-size: 13px; font-weight: 500; }

/* Empty State */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 50vh;
  text-align: center;
  padding: 20px;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid rgba(255,255,255,0.1);
  border-radius: 50%;
  border-top-color: var(--primary);
  animation: spin 1s linear infinite;
  margin-bottom: 20px;
}
@keyframes spin { to { transform: rotate(360deg); } }

/* Lightbox */
.lightbox {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.95);
  z-index: 100;
  display: none;
  flex-direction: column;
  opacity: 0;
  transition: opacity 0.3s;
}
.lightbox.open { display: flex; opacity: 1; }

.lb-header {
  padding: 16px;
  display: flex;
  justify-content: flex-end;
  gap: 16px;
  position: absolute;
  width: 100%;
  top: 0;
  z-index: 2;
}

.lb-content {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
}

.lb-media {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
}

.lb-nav {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  background: rgba(0,0,0,0.5);
  border: none;
  color: white;
  padding: 16px;
  cursor: pointer;
  opacity: 0.5;
  transition: opacity 0.2s;
}
.lb-nav:hover { opacity: 1; }
.lb-prev { left: 0; }
.lb-next { right: 0; }

.lb-counter {
  color: var(--secondary);
  font-size: 14px;
  margin-right: auto;
}
`;
