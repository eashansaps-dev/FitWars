#!/usr/bin/env python3
"""
Slices the Gemini sprite sheet (v2) into individual frames.

Image: 1408x768, gray background (no actual transparency)
Layout (from reference image):
  Row 1: Idle Fighting Stance - 6 frames
  Row 2: Walking - 6 frames  
  Row 3: Punch - 6 frames
  Row 4: Kick - 6 frames
  Row 5: Blocking (4 frames) + Hit Reaction (3 frames)

Strategy: divide into a 6-column x 5-row grid, then use content detection
to find each character within each cell.
"""

from PIL import Image
from shutil import copy2
import os

INPUT = "FitWars/assets/Gemini_Generated_Image_wquydrwquydrwquy (1).png"
OUTPUT_DIR = "FitWars/Assets.xcassets/fighter_default.spriteatlas"

img = Image.open(INPUT).convert("RGBA")
W, H = img.size
print(f"Image size: {W}x{H}")

# The image has text labels on the left (~100px) and a dark border (~18px)
# Usable area is roughly x=100 to x=1390, y=18 to y=750
# 5 rows, 6 columns per row (except row 5 which is split differently)

CONTENT_LEFT = 100
CONTENT_RIGHT = 1390
CONTENT_TOP = 18
CONTENT_BOTTOM = 750

content_w = CONTENT_RIGHT - CONTENT_LEFT  # ~1290
content_h = CONTENT_BOTTOM - CONTENT_TOP  # ~732

ROW_H = content_h // 5  # ~146px per row
COL_W = content_w // 6  # ~215px per column

print(f"Grid: {COL_W}x{ROW_H} per cell")

# Detect the background color from corners of the image
def get_bg_color():
    pixels = img.load()
    samples = []
    for x, y in [(5, 5), (W-5, 5), (5, H-5), (W-5, H-5)]:
        samples.append(pixels[x, y][:3])
    return tuple(sum(c) // len(samples) for c in zip(*samples))

BG = get_bg_color()
print(f"Background color: rgb{BG}")

def remove_background(frame):
    """Remove gray background pixels, making them transparent."""
    pixels = frame.load()
    w, h = frame.size
    
    # Sample the 4 corners of this specific frame for local bg color
    corners = []
    for cx, cy in [(1,1), (w-2,1), (1,h-2), (w-2,h-2)]:
        corners.append(pixels[cx, cy][:3])
    local_bg = tuple(sum(c)//len(corners) for c in zip(*corners))
    
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            # Check if pixel is close to local background
            dr = abs(r - local_bg[0])
            dg = abs(g - local_bg[1])
            db = abs(b - local_bg[2])
            # Also check if it's a neutral gray (r≈g≈b)
            is_gray = abs(r-g) < 20 and abs(g-b) < 20
            if (dr < 25 and dg < 25 and db < 25) or (is_gray and 60 < r < 160):
                pixels[x, y] = (0, 0, 0, 0)
    return frame

def extract_frame(col, row):
    """Extract a single frame from the grid."""
    x = CONTENT_LEFT + col * COL_W
    y = CONTENT_TOP + row * ROW_H
    return img.crop((x, y, x + COL_W, y + ROW_H)).copy()

def process_frame(frame, output_name):
    """Remove bg, trim, center on 256x256 canvas, save."""
    frame = remove_background(frame)
    bbox = frame.getbbox()
    if not bbox:
        print(f"  SKIP {output_name} — empty")
        return False
    
    cropped = frame.crop(bbox)
    
    # Fit into 240x240 max, maintaining aspect ratio
    scale = min(240 / cropped.width, 240 / cropped.height, 1.0)
    if scale < 1.0:
        new_w = int(cropped.width * scale)
        new_h = int(cropped.height * scale)
        cropped = cropped.resize((new_w, new_h), Image.LANCZOS)
    
    # Place on 256x256 canvas, bottom-center aligned
    canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    paste_x = (256 - cropped.width) // 2
    paste_y = 256 - cropped.height - 4
    canvas.paste(cropped, (paste_x, paste_y))
    
    canvas.save(os.path.join(OUTPUT_DIR, output_name))
    print(f"  Saved: {output_name} ({cropped.width}x{cropped.height})")
    return True

# Clean output directory
os.makedirs(OUTPUT_DIR, exist_ok=True)
for f in os.listdir(OUTPUT_DIR):
    if f.endswith('.png'):
        os.remove(os.path.join(OUTPUT_DIR, f))

count = 0

# Row 0: Idle Fighting Stance — 6 frames
for i in range(6):
    frame = extract_frame(i, 0)
    if process_frame(frame, f"idle_{i+1:02d}.png"):
        count += 1

# Row 1: Walking — 6 frames
for i in range(6):
    frame = extract_frame(i, 1)
    if process_frame(frame, f"walk_forward_{i+1:02d}.png"):
        count += 1

# Row 2: Punch — 6 frames → light_attack
for i in range(6):
    frame = extract_frame(i, 2)
    if process_frame(frame, f"light_attack_{i+1:02d}.png"):
        count += 1

# Row 3: Kick — 6 frames → heavy_attack
for i in range(6):
    frame = extract_frame(i, 3)
    if process_frame(frame, f"heavy_attack_{i+1:02d}.png"):
        count += 1

# Row 4: Blocking (first 4) + Hit Reaction (last 3)
for i in range(4):
    frame = extract_frame(i, 4)
    if process_frame(frame, f"blocking_{i+1:02d}.png"):
        count += 1

# Hit Reaction starts at column 4 (after "Hit Reaction" label area)
# Actually from the image it looks like columns 4, 5, and maybe wrapping
for i in range(3):
    frame = extract_frame(i + 4, 4)  # columns 4, 5, 6-ish
    if process_frame(frame, f"hit_stun_{i+1:02d}.png"):
        count += 1

# Generate walk_backward as mirrored walk_forward
for i in range(6):
    src_path = os.path.join(OUTPUT_DIR, f"walk_forward_{i+1:02d}.png")
    if os.path.exists(src_path):
        fwd = Image.open(src_path)
        bwd = fwd.transpose(Image.FLIP_LEFT_RIGHT)
        bwd.save(os.path.join(OUTPUT_DIR, f"walk_backward_{i+1:02d}.png"))
        print(f"  Mirrored: walk_backward_{i+1:02d}.png")
        count += 1

# Aliases for missing animations
aliases = {
    "dodging_01.png": "idle_02.png",
    "dodging_02.png": "idle_03.png",
    "knockdown_01.png": "hit_stun_01.png",
    "special_attack_01.png": "light_attack_04.png",
    "special_attack_02.png": "light_attack_05.png",
    "special_attack_03.png": "light_attack_06.png",
    "victory_01.png": "idle_01.png",
    "victory_02.png": "idle_02.png",
}

for alias_name, source_name in aliases.items():
    src = os.path.join(OUTPUT_DIR, source_name)
    dst = os.path.join(OUTPUT_DIR, alias_name)
    if os.path.exists(src):
        copy2(src, dst)
        print(f"  Alias: {alias_name} -> {source_name}")
        count += 1

# Write Contents.json
import json
contents = {"info": {"author": "xcode", "version": 1}}
with open(os.path.join(OUTPUT_DIR, "Contents.json"), "w") as f:
    json.dump(contents, f, indent=2)

print(f"\nDone! {count} frames in {OUTPUT_DIR}")
