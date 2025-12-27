# FotoX Frame Generator

A Python tool to generate custom photo/video frame overlays for events in the FotoX iPad Photobooth app.

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Generate a simple frame
python frame_generator.py --type simple --color "#FF4081" -o my_frame.png

# Generate a frame with event name
python frame_generator.py --type text --event "My Wedding" --date "Jan 31, 2026" -o wedding_frame.png
```

## Frame Types

### 1. Simple Border (`--type simple`)
A clean border frame with optional inner glow.

```bash
python frame_generator.py --type simple \
  --color "#FF4081" \
  --border-width 80 \
  -o simple_frame.png
```

### 2. Decorative (`--type decorative`)
Border with corner accents and accent lines.

```bash
python frame_generator.py --type decorative \
  --color "#FF4081" \
  --secondary-color "#212121" \
  --accent-color "#FFFFFF" \
  -o decorative_frame.png
```

### 3. Text Frame (`--type text`)
Frame with event name and date displayed in the border.

```bash
python frame_generator.py --type text \
  --event "JackZeu's Wedding Shower" \
  --date "January 31, 2026" \
  --color "#FF4081" \
  --text-position bottom \
  -o wedding_frame.png
```

### 4. Gradient (`--type gradient`)
Frame with gradient border.

```bash
python frame_generator.py --type gradient \
  --start-color "#FF4081" \
  --end-color "#7B1FA2" \
  --gradient-direction diagonal \
  -o gradient_frame.png
```

### 5. Logo Frame (`--type logo`)
Frame with logo placement.

```bash
python frame_generator.py --type logo \
  --logo company_logo.png \
  --logo-position bottom \
  --logo-size 150 \
  --color "#0066CC" \
  -o logo_frame.png
```

## Using Config Files

For repeatable frame generation, use JSON config files:

```bash
python frame_generator.py --config example_configs/wedding_frame.json
```

Example config (`wedding_frame.json`):
```json
{
    "type": "text",
    "event": "JackZeu's Wedding Shower",
    "date": "January 31, 2026",
    "color": "#FF4081",
    "text_color": "#FFFFFF",
    "border_width": 100,
    "text_position": "bottom",
    "output": "wedding_frame.png"
}
```

## Adding Frames to the App

### Option 1: Bundled Assets (Recommended for production)

1. Generate your frame:
   ```bash
   python frame_generator.py --type text --event "My Event" -o MyEventFrame.png
   ```

2. Add the PNG to Xcode:
   - Open `fotoX.xcodeproj`
   - Drag `MyEventFrame.png` into `Assets.xcassets`
   - Name the asset (e.g., "MyEventFrame")

3. Reference in event theme:
   ```swift
   Theme(
       id: 1,
       primaryColor: "#FF4081",
       // ... other properties
       photoFrameAsset: "MyEventFrame",  // <-- bundled asset name
       stripFrameAsset: nil
   )
   ```

### Option 2: URL-based (For dynamic frames)

1. Upload your frame to a CDN/server

2. Reference via URL:
   ```swift
   Theme(
       id: 1,
       primaryColor: "#FF4081",
       // ... other properties
       photoFrameURL: "https://cdn.example.com/frames/my_frame.png"
   )
   ```

## Common Options

| Option | Description | Default |
|--------|-------------|---------|
| `--width` | Frame width in pixels | 2048 |
| `--height` | Frame height in pixels | 2732 |
| `--border-width` | Border thickness | 80 |
| `--color` | Primary/border color | #FF4081 |
| `--output`, `-o` | Output file path | frame.png |

## Tips

1. **Match iPad resolution**: Default dimensions (2048x2732) match iPad Pro 12.9" in portrait mode

2. **Transparent center**: All frames have a transparent center where the camera feed shows through

3. **Color matching**: Use the same `--color` as your theme's `primaryColor` for consistency

4. **Test on device**: Always test frames on the actual iPad - previews may look different

5. **File size**: Generated PNGs are optimized but may still be large. Consider additional compression for production.

## Example Workflow

```bash
# 1. Create a wedding frame
python frame_generator.py \
  --type text \
  --event "Jack & Zoe's Wedding" \
  --date "January 31, 2026" \
  --color "#FF4081" \
  --border-width 100 \
  -o ../fotoX/fotoX/Resources/WeddingFrame.png

# 2. Add to Assets.xcassets in Xcode (drag and drop)

# 3. Update LocalEventService.swift to reference "WeddingFrame"
```
