#!/usr/bin/env python3
"""
Event Theme Frame Generator for FotoX iPad Photobooth

This tool generates custom photo/video frame overlays for events.
Frames are PNG images with a transparent center where the camera feed shows through.

Usage:
    python frame_generator.py --help
    python frame_generator.py --event "Wedding" --color "#FF4081" --output frame.png
    python frame_generator.py --config event_config.json

Requirements:
    pip install Pillow

Frame Types:
    - photo_frame: Overlay shown during capture (portrait, iPad aspect ratio)
    - strip_frame: Overlay for final strip display (optional)
"""

import argparse
import json
import math
from pathlib import Path
from typing import Optional, Tuple

try:
    from PIL import Image, ImageDraw, ImageFont, ImageFilter
except ImportError:
    print("Error: Pillow is required. Install with: pip install Pillow")
    exit(1)


# iPad Pro 12.9" resolution in portrait mode
IPAD_WIDTH = 2048
IPAD_HEIGHT = 2732

# Default frame settings
DEFAULT_BORDER_WIDTH = 80
DEFAULT_CORNER_RADIUS = 60


def hex_to_rgb(hex_color: str) -> Tuple[int, int, int]:
    """Convert hex color string to RGB tuple."""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def hex_to_rgba(hex_color: str, alpha: int = 255) -> Tuple[int, int, int, int]:
    """Convert hex color string to RGBA tuple."""
    r, g, b = hex_to_rgb(hex_color)
    return (r, g, b, alpha)


def create_rounded_rectangle_mask(size: Tuple[int, int], radius: int) -> Image.Image:
    """Create a mask for rounded rectangle."""
    mask = Image.new('L', size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (size[0]-1, size[1]-1)], radius=radius, fill=255)
    return mask


def generate_simple_border_frame(
    width: int = IPAD_WIDTH,
    height: int = IPAD_HEIGHT,
    border_width: int = DEFAULT_BORDER_WIDTH,
    border_color: str = "#FF4081",
    corner_radius: int = DEFAULT_CORNER_RADIUS,
    inner_glow: bool = True,
) -> Image.Image:
    """
    Generate a simple border frame with optional inner glow.

    Args:
        width: Frame width in pixels
        height: Frame height in pixels
        border_width: Width of the border
        border_color: Hex color for the border
        corner_radius: Radius for rounded corners
        inner_glow: Add subtle inner glow effect

    Returns:
        RGBA Image with transparent center
    """
    frame = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(frame)

    color_rgba = hex_to_rgba(border_color)

    # Draw outer rounded rectangle (full frame)
    draw.rounded_rectangle(
        [(0, 0), (width-1, height-1)],
        radius=corner_radius,
        fill=color_rgba
    )

    # Cut out inner transparent area
    inner_x = border_width
    inner_y = border_width
    inner_w = width - (border_width * 2)
    inner_h = height - (border_width * 2)
    inner_radius = max(0, corner_radius - border_width // 2)

    # Create inner mask
    inner_mask = Image.new('RGBA', (inner_w, inner_h), (0, 0, 0, 0))
    inner_draw = ImageDraw.Draw(inner_mask)
    inner_draw.rounded_rectangle(
        [(0, 0), (inner_w-1, inner_h-1)],
        radius=inner_radius,
        fill=(0, 0, 0, 255)
    )

    # Paste transparent inner area
    frame.paste((0, 0, 0, 0), (inner_x, inner_y), inner_mask.split()[3])

    # Add inner glow effect
    if inner_glow:
        glow_width = border_width // 3
        for i in range(glow_width):
            alpha = int(80 * (1 - i / glow_width))
            glow_color = hex_to_rgba(border_color, alpha)
            offset = border_width - glow_width + i
            draw.rounded_rectangle(
                [(offset, offset), (width - offset - 1, height - offset - 1)],
                radius=max(0, corner_radius - offset),
                outline=glow_color,
                width=1
            )

    return frame


def generate_decorative_frame(
    width: int = IPAD_WIDTH,
    height: int = IPAD_HEIGHT,
    primary_color: str = "#FF4081",
    secondary_color: str = "#212121",
    accent_color: str = "#FFFFFF",
    border_width: int = DEFAULT_BORDER_WIDTH,
    corner_style: str = "rounded",  # rounded, square, ornate
    show_corners: bool = True,
) -> Image.Image:
    """
    Generate a decorative frame with corner accents.

    Args:
        width: Frame width in pixels
        height: Frame height in pixels
        primary_color: Main border color
        secondary_color: Secondary accent color
        accent_color: Tertiary accent color
        border_width: Width of the main border
        corner_style: Style of corners
        show_corners: Add decorative corner elements

    Returns:
        RGBA Image with transparent center
    """
    frame = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(frame)

    primary_rgba = hex_to_rgba(primary_color)
    secondary_rgba = hex_to_rgba(secondary_color)
    accent_rgba = hex_to_rgba(accent_color)

    corner_radius = DEFAULT_CORNER_RADIUS if corner_style == "rounded" else 0

    # Draw main border
    draw.rounded_rectangle(
        [(0, 0), (width-1, height-1)],
        radius=corner_radius,
        fill=primary_rgba
    )

    # Inner accent line
    accent_offset = border_width // 4
    draw.rounded_rectangle(
        [(accent_offset, accent_offset), (width - accent_offset - 1, height - accent_offset - 1)],
        radius=max(0, corner_radius - accent_offset),
        outline=accent_rgba,
        width=2
    )

    # Cut out center
    inner_x = border_width
    inner_y = border_width
    inner_w = width - (border_width * 2)
    inner_h = height - (border_width * 2)
    inner_radius = max(0, corner_radius - border_width // 2)

    inner_mask = Image.new('RGBA', (inner_w, inner_h), (0, 0, 0, 0))
    inner_draw = ImageDraw.Draw(inner_mask)
    inner_draw.rounded_rectangle(
        [(0, 0), (inner_w-1, inner_h-1)],
        radius=inner_radius,
        fill=(0, 0, 0, 255)
    )
    frame.paste((0, 0, 0, 0), (inner_x, inner_y), inner_mask.split()[3])

    # Add corner decorations
    if show_corners:
        corner_size = border_width * 2

        # Draw corner accents (circles or diamonds)
        corners = [
            (corner_size, corner_size),
            (width - corner_size, corner_size),
            (corner_size, height - corner_size),
            (width - corner_size, height - corner_size)
        ]

        for cx, cy in corners:
            # Outer circle
            draw.ellipse(
                [(cx - 20, cy - 20), (cx + 20, cy + 20)],
                fill=secondary_rgba
            )
            # Inner circle
            draw.ellipse(
                [(cx - 10, cy - 10), (cx + 10, cy + 10)],
                fill=accent_rgba
            )

    return frame


def generate_text_frame(
    width: int = IPAD_WIDTH,
    height: int = IPAD_HEIGHT,
    event_name: str = "Event Name",
    event_date: Optional[str] = None,
    primary_color: str = "#FF4081",
    text_color: str = "#FFFFFF",
    border_width: int = DEFAULT_BORDER_WIDTH,
    text_position: str = "bottom",  # top, bottom, both
    font_path: Optional[str] = None,
) -> Image.Image:
    """
    Generate a frame with event name and optional date text.

    Args:
        width: Frame width in pixels
        height: Frame height in pixels
        event_name: Name of the event to display
        event_date: Optional date string
        primary_color: Border color
        text_color: Text color
        border_width: Width of the border
        text_position: Where to place text
        font_path: Path to custom font file

    Returns:
        RGBA Image with transparent center and text
    """
    # Start with simple border frame
    frame = generate_simple_border_frame(
        width=width,
        height=height,
        border_width=border_width,
        border_color=primary_color,
        inner_glow=True
    )

    draw = ImageDraw.Draw(frame)
    text_rgba = hex_to_rgba(text_color)

    # Try to load font
    try:
        if font_path and Path(font_path).exists():
            title_font = ImageFont.truetype(font_path, 48)
            date_font = ImageFont.truetype(font_path, 32)
        else:
            # Try system fonts
            try:
                title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 48)
                date_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 32)
            except:
                title_font = ImageFont.load_default()
                date_font = ImageFont.load_default()
    except:
        title_font = ImageFont.load_default()
        date_font = ImageFont.load_default()

    # Calculate text positions
    def draw_centered_text(text: str, y: int, font: ImageFont.FreeTypeFont):
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        x = (width - text_width) // 2

        # Draw shadow
        shadow_rgba = (0, 0, 0, 128)
        draw.text((x + 2, y + 2), text, font=font, fill=shadow_rgba)
        # Draw text
        draw.text((x, y), text, font=font, fill=text_rgba)

    if text_position in ("bottom", "both"):
        # Text in bottom border
        text_y = height - border_width + (border_width - 48) // 2
        draw_centered_text(event_name, text_y, title_font)

        if event_date:
            date_y = text_y + 50
            if date_y + 32 < height:
                draw_centered_text(event_date, date_y, date_font)

    if text_position in ("top", "both"):
        # Text in top border
        text_y = (border_width - 48) // 2
        if text_position == "both" and event_date:
            draw_centered_text(event_date, text_y + 8, date_font)
        else:
            draw_centered_text(event_name, text_y, title_font)

    return frame


def generate_gradient_frame(
    width: int = IPAD_WIDTH,
    height: int = IPAD_HEIGHT,
    start_color: str = "#FF4081",
    end_color: str = "#7B1FA2",
    border_width: int = DEFAULT_BORDER_WIDTH,
    gradient_direction: str = "diagonal",  # horizontal, vertical, diagonal
) -> Image.Image:
    """
    Generate a frame with gradient border.

    Args:
        width: Frame width in pixels
        height: Frame height in pixels
        start_color: Gradient start color
        end_color: Gradient end color
        border_width: Width of the border
        gradient_direction: Direction of gradient

    Returns:
        RGBA Image with gradient border
    """
    frame = Image.new('RGBA', (width, height), (0, 0, 0, 0))

    start_rgb = hex_to_rgb(start_color)
    end_rgb = hex_to_rgb(end_color)

    # Create gradient
    for x in range(width):
        for y in range(height):
            # Check if pixel is in border
            in_border = (
                x < border_width or
                x >= width - border_width or
                y < border_width or
                y >= height - border_width
            )

            if in_border:
                # Calculate gradient position
                if gradient_direction == "horizontal":
                    t = x / width
                elif gradient_direction == "vertical":
                    t = y / height
                else:  # diagonal
                    t = (x + y) / (width + height)

                # Interpolate colors
                r = int(start_rgb[0] + (end_rgb[0] - start_rgb[0]) * t)
                g = int(start_rgb[1] + (end_rgb[1] - start_rgb[1]) * t)
                b = int(start_rgb[2] + (end_rgb[2] - start_rgb[2]) * t)

                frame.putpixel((x, y), (r, g, b, 255))

    # Round corners
    corner_radius = DEFAULT_CORNER_RADIUS

    # Create rounded mask for outer edge
    outer_mask = create_rounded_rectangle_mask((width, height), corner_radius)

    # Create rounded mask for inner cutout
    inner_w = width - border_width * 2
    inner_h = height - border_width * 2
    inner_radius = max(0, corner_radius - border_width // 2)
    inner_mask = create_rounded_rectangle_mask((inner_w, inner_h), inner_radius)

    # Apply outer rounding
    frame_array = frame.split()
    frame = Image.merge('RGBA', (*frame_array[:3], Image.composite(
        frame_array[3], Image.new('L', (width, height), 0), outer_mask
    )))

    # Cut out inner area
    inner_cutout = Image.new('RGBA', (inner_w, inner_h), (0, 0, 0, 0))
    frame.paste(inner_cutout, (border_width, border_width), inner_mask)

    return frame


def generate_logo_frame(
    width: int = IPAD_WIDTH,
    height: int = IPAD_HEIGHT,
    logo_path: str = None,
    primary_color: str = "#FF4081",
    border_width: int = DEFAULT_BORDER_WIDTH,
    logo_position: str = "bottom",  # top, bottom, corners
    logo_size: int = 150,
) -> Image.Image:
    """
    Generate a frame with logo placement.

    Args:
        width: Frame width in pixels
        height: Frame height in pixels
        logo_path: Path to logo image
        primary_color: Border color
        border_width: Width of the border
        logo_position: Where to place the logo
        logo_size: Size of the logo

    Returns:
        RGBA Image with logo
    """
    # Start with simple border frame
    frame = generate_simple_border_frame(
        width=width,
        height=height,
        border_width=border_width,
        border_color=primary_color,
        inner_glow=True
    )

    if logo_path and Path(logo_path).exists():
        logo = Image.open(logo_path).convert('RGBA')

        # Resize logo maintaining aspect ratio
        logo.thumbnail((logo_size, logo_size), Image.Resampling.LANCZOS)

        # Calculate position
        if logo_position == "bottom":
            x = (width - logo.width) // 2
            y = height - border_width + (border_width - logo.height) // 2
        elif logo_position == "top":
            x = (width - logo.width) // 2
            y = (border_width - logo.height) // 2
        elif logo_position == "corners":
            # Place in bottom-right corner
            x = width - border_width + (border_width - logo.width) // 2
            y = height - border_width + (border_width - logo.height) // 2
        else:
            x = (width - logo.width) // 2
            y = height - border_width + (border_width - logo.height) // 2

        # Paste logo with alpha
        frame.paste(logo, (x, y), logo)

    return frame


def load_config(config_path: str) -> dict:
    """Load frame configuration from JSON file."""
    with open(config_path, 'r') as f:
        return json.load(f)


def save_frame(frame: Image.Image, output_path: str, optimize: bool = True):
    """Save frame to file with optional optimization."""
    frame.save(output_path, 'PNG', optimize=optimize)
    print(f"Frame saved to: {output_path}")


def main():
    parser = argparse.ArgumentParser(
        description='Generate custom photo/video frame overlays for events',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Simple border frame
  python frame_generator.py --type simple --color "#FF4081" --output frame.png

  # Decorative frame with event name
  python frame_generator.py --type text --event "Wedding" --date "Jan 31, 2026" --output wedding_frame.png

  # Gradient frame
  python frame_generator.py --type gradient --start-color "#FF4081" --end-color "#7B1FA2" --output gradient.png

  # From config file
  python frame_generator.py --config event_config.json
        """
    )

    parser.add_argument('--type', choices=['simple', 'decorative', 'text', 'gradient', 'logo'],
                        default='simple', help='Type of frame to generate')
    parser.add_argument('--config', type=str, help='Path to JSON config file')
    parser.add_argument('--output', '-o', type=str, default='frame.png', help='Output file path')

    # Dimensions
    parser.add_argument('--width', type=int, default=IPAD_WIDTH, help='Frame width in pixels')
    parser.add_argument('--height', type=int, default=IPAD_HEIGHT, help='Frame height in pixels')
    parser.add_argument('--border-width', type=int, default=DEFAULT_BORDER_WIDTH, help='Border width')

    # Colors
    parser.add_argument('--color', '--primary-color', type=str, default='#FF4081', help='Primary/border color')
    parser.add_argument('--secondary-color', type=str, default='#212121', help='Secondary color')
    parser.add_argument('--accent-color', type=str, default='#FFFFFF', help='Accent color')
    parser.add_argument('--text-color', type=str, default='#FFFFFF', help='Text color')

    # Gradient options
    parser.add_argument('--start-color', type=str, default='#FF4081', help='Gradient start color')
    parser.add_argument('--end-color', type=str, default='#7B1FA2', help='Gradient end color')
    parser.add_argument('--gradient-direction', choices=['horizontal', 'vertical', 'diagonal'],
                        default='diagonal', help='Gradient direction')

    # Text options
    parser.add_argument('--event', '--event-name', type=str, default='Event', help='Event name')
    parser.add_argument('--date', '--event-date', type=str, help='Event date')
    parser.add_argument('--text-position', choices=['top', 'bottom', 'both'], default='bottom',
                        help='Text position')
    parser.add_argument('--font', type=str, help='Path to custom font file')

    # Logo options
    parser.add_argument('--logo', type=str, help='Path to logo image')
    parser.add_argument('--logo-position', choices=['top', 'bottom', 'corners'], default='bottom',
                        help='Logo position')
    parser.add_argument('--logo-size', type=int, default=150, help='Logo size in pixels')

    args = parser.parse_args()

    # Load config if provided
    if args.config:
        config = load_config(args.config)
        # Override args with config values
        for key, value in config.items():
            if hasattr(args, key.replace('-', '_')):
                setattr(args, key.replace('-', '_'), value)

    # Generate frame based on type
    if args.type == 'simple':
        frame = generate_simple_border_frame(
            width=args.width,
            height=args.height,
            border_width=args.border_width,
            border_color=args.color,
        )
    elif args.type == 'decorative':
        frame = generate_decorative_frame(
            width=args.width,
            height=args.height,
            primary_color=args.color,
            secondary_color=args.secondary_color,
            accent_color=args.accent_color,
            border_width=args.border_width,
        )
    elif args.type == 'text':
        frame = generate_text_frame(
            width=args.width,
            height=args.height,
            event_name=args.event,
            event_date=args.date,
            primary_color=args.color,
            text_color=args.text_color,
            border_width=args.border_width,
            text_position=args.text_position,
            font_path=args.font,
        )
    elif args.type == 'gradient':
        frame = generate_gradient_frame(
            width=args.width,
            height=args.height,
            start_color=args.start_color,
            end_color=args.end_color,
            border_width=args.border_width,
            gradient_direction=args.gradient_direction,
        )
    elif args.type == 'logo':
        frame = generate_logo_frame(
            width=args.width,
            height=args.height,
            logo_path=args.logo,
            primary_color=args.color,
            border_width=args.border_width,
            logo_position=args.logo_position,
            logo_size=args.logo_size,
        )

    # Save the frame
    save_frame(frame, args.output)


if __name__ == '__main__':
    main()
