// Gallery JavaScript - extracted for browser caching
export const JS_HASH = 'v3';

export const GALLERY_JS = `
// Share helper
async function shareMedia(url) {
  if (navigator.share) {
    try {
      await navigator.share({
        title: 'Check out this photo',
        text: 'Shared from FotoX',
        url: url
      });
    } catch (err) {
      if (err.name !== 'AbortError') {
        console.log('Share failed:', err);
      }
    }
  } else {
    // Fallback - copy to clipboard
    try {
      await navigator.clipboard.writeText(url);
      alert('Link copied to clipboard!');
    } catch (err) {
      alert('Share not supported on this device.');
    }
  }
}

// Encapsulated lightbox state
const lightbox = {
  currentIndex: 0,
  isOpen: false,
  elements: null,
  previousFocus: null,

  init() {
    this.elements = {
      container: document.getElementById('lightbox'),
      img: document.getElementById('lb-img'),
      video: document.getElementById('lb-video'),
      downloadBtn: document.getElementById('lb-download'),
      shareBtn: document.getElementById('lb-share'),
      prevBtn: document.querySelector('.lb-prev'),
      nextBtn: document.querySelector('.lb-next'),
      closeBtn: document.querySelector('.lb-header .action-btn[aria-label="Close"]')
    };

    // Validate all elements exist
    const missing = Object.entries(this.elements).filter(([k, v]) => !v);
    if (missing.length > 0) {
      console.error('Lightbox elements not found:', missing.map(m => m[0]));
      return false;
    }

    // Add error handlers for media
    this.elements.img.onerror = () => {
      this.elements.img.alt = 'Image failed to load';
    };
    this.elements.video.onerror = () => {
      console.error('Video failed to load');
    };

    return true;
  },

  open(index) {
    if (!this.elements && !this.init()) return;

    this.previousFocus = document.activeElement;
    this.currentIndex = index;
    this.isOpen = true;
    this.update();
    this.elements.container.classList.add('open');
    document.body.style.overflow = 'hidden';

    // Focus the close button for accessibility
    setTimeout(() => {
      if (this.elements.closeBtn) this.elements.closeBtn.focus();
    }, 100);
  },

  close() {
    if (!this.elements) return;

    this.isOpen = false;
    this.elements.container.classList.remove('open');
    this.cleanupVideo();
    document.body.style.overflow = '';

    // Restore focus
    if (this.previousFocus && this.previousFocus.focus) {
      this.previousFocus.focus();
    }
  },

  cleanupVideo() {
    if (this.elements && this.elements.video) {
      this.elements.video.pause();
      this.elements.video.removeAttribute('src');
      this.elements.video.load();
    }
  },

  next(e) {
    if (e) e.stopPropagation();
    if (!window.GALLERY_ASSETS) return;
    if (this.currentIndex < window.GALLERY_ASSETS.length - 1) {
      this.currentIndex++;
      this.update();
    }
  },

  prev(e) {
    if (e) e.stopPropagation();
    if (this.currentIndex > 0) {
      this.currentIndex--;
      this.update();
    }
  },

  update() {
    if (!window.GALLERY_ASSETS || !this.elements) return;

    const asset = window.GALLERY_ASSETS[this.currentIndex];
    if (!asset) return;

    this.elements.downloadBtn.href = asset.src;
    this.elements.shareBtn.dataset.url = asset.src;

    // Clean up previous video before switching
    this.cleanupVideo();

    if (asset.type === 'video') {
      this.elements.img.style.display = 'none';
      this.elements.video.style.display = 'block';
      this.elements.video.src = asset.src;
      if (asset.poster) this.elements.video.poster = asset.poster;
    } else {
      this.elements.video.style.display = 'none';
      this.elements.img.style.display = 'block';
      this.elements.img.src = asset.src;
    }

    // Update ARIA for screen readers
    const counter = document.getElementById('lb-counter');
    if (counter) {
      counter.textContent = (this.currentIndex + 1) + ' of ' + window.GALLERY_ASSETS.length;
    }
  }
};

// Global function bindings for backwards compatibility and lightbox HTML handlers
window.openLightbox = (index) => lightbox.open(index);
window.closeLightbox = () => lightbox.close();
window.nextSlide = (e) => lightbox.next(e);
window.prevSlide = (e) => lightbox.prev(e);

// Event delegation for gallery grid
document.addEventListener('click', (e) => {
  // Handle media item click
  const mediaItem = e.target.closest('.media-item');
  if (mediaItem && !e.target.closest('.action-btn') && !e.target.closest('a')) {
    const index = parseInt(mediaItem.dataset.index, 10);
    if (!isNaN(index)) {
      lightbox.open(index);
    }
    return;
  }

  // Handle view button
  const viewBtn = e.target.closest('.view-btn');
  if (viewBtn) {
    e.stopPropagation();
    const index = parseInt(viewBtn.dataset.index, 10);
    if (!isNaN(index)) {
      lightbox.open(index);
    }
    return;
  }

  // Handle share button
  const shareBtn = e.target.closest('.share-btn');
  if (shareBtn) {
    e.stopPropagation();
    const url = shareBtn.dataset.url;
    if (url) shareMedia(url);
    return;
  }

  // Handle download button - let default link behavior work
  const downloadBtn = e.target.closest('.download-btn');
  if (downloadBtn) {
    e.stopPropagation();
    return;
  }

  // Handle refresh button on processing page
  const refreshBtn = e.target.closest('.refresh-btn');
  if (refreshBtn) {
    window.location.reload();
    return;
  }
});

// Lightbox control handlers
document.addEventListener('click', (e) => {
  // Close lightbox when clicking on background
  if (e.target.id === 'lightbox') {
    lightbox.close();
    return;
  }

  // Close button
  if (e.target.closest('.close-btn')) {
    lightbox.close();
    return;
  }

  // Previous button
  if (e.target.closest('.lb-prev')) {
    e.stopPropagation();
    lightbox.prev(e);
    return;
  }

  // Next button
  if (e.target.closest('.lb-next')) {
    e.stopPropagation();
    lightbox.next(e);
    return;
  }

  // Share button in lightbox
  if (e.target.closest('#lb-share')) {
    e.stopPropagation();
    const url = lightbox.elements.shareBtn.dataset.url;
    if (url) shareMedia(url);
    return;
  }

  // Download button - prevent propagation but allow default
  if (e.target.closest('#lb-download')) {
    e.stopPropagation();
    return;
  }

  // Stop propagation on media elements to prevent closing
  if (e.target.closest('#lb-img, #lb-video')) {
    e.stopPropagation();
    return;
  }
});

// Video hover play/pause via event delegation
document.addEventListener('mouseover', (e) => {
  const video = e.target.closest('.media-item video');
  if (video) video.play().catch(() => {});
});
document.addEventListener('mouseout', (e) => {
  const video = e.target.closest('.media-item video');
  if (video) video.pause();
});

// Keyboard support
document.addEventListener('keydown', (e) => {
  if (!lightbox.isOpen) return;

  switch (e.key) {
    case 'Escape':
      lightbox.close();
      break;
    case 'ArrowRight':
      lightbox.next();
      break;
    case 'ArrowLeft':
      lightbox.prev();
      break;
    case 'Tab':
      // Focus trap - keep focus within lightbox
      const lb = lightbox.elements.container;
      if (!lb) return;
      const focusable = lb.querySelectorAll('button, a[href]');
      if (focusable.length === 0) return;
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault();
        first.focus();
      }
      break;
  }
});

// Keyboard support for media items (Enter/Space to open)
document.addEventListener('keydown', (e) => {
  if (lightbox.isOpen) return;

  const mediaItem = e.target.closest('.media-item');
  if (mediaItem && (e.key === 'Enter' || e.key === ' ')) {
    e.preventDefault();
    const index = parseInt(mediaItem.dataset.index, 10);
    if (!isNaN(index)) {
      lightbox.open(index);
    }
  }
});
`;
