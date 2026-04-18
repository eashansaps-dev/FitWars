#!/usr/bin/env python3
"""
Slices the Gemini-generated sprite sheet into individual frames
and places them in the fighter_default.spriteatlas folder.

Layout (from the image):
  Row 1: IDLE - 4 frames
  Row 2 left: WALK - 4 frames
  Row 2 right: RUN - 4 frames  
  Row 3: JUMP - 4 frames
  Row 4: PUNCH - 6 frames
  Row 5 left: KICK - 4 frames
  Row 5 right: EFFECTS (skip)

The image is 1408x768 with a gray background that needs to be removed.
"""

from PIL import Image
import os

INPUT = "FitWars/assets/Gemini_Generated_Image_wquydrwquydrwquy.png"
OUTPUT_DIR = "FitWars/Assets.xcassets/fighter_default.spriteatlas"

img = Image.open(INPUT).convert("RGBA")
W, H = img.size
print(f"Image size: {W}x{H}")

# Remove gray background — replace the gray (#4a4a4a-ish and nearby) with transparent
pixels = img.load()
for y in range(H):
    for x in range(W):
        r, g, b, a = pixels[x, y]
        # Gray background detection: all channels similar and in the dark-mid range
        if abs(r - g) < 20 and abs(g - b) < 20 and 50 < r < 130:
            pixels[x, y] = (0, 0, 0, 0)

# The sprite sheet has labels on the left side. Let's crop from roughly:
# Left margin ~90px (where labels are), top margin ~30px
# Each frame is roughly 150-160px wide, rows are roughly 150px tall

# Based on 1408x768 with 5 rows and up to 6 columns:
LEFT_MARGIN = 90
TOP_MARGIN = 20
FRAME_W = 160
FRAME_H = 150

# Row definitions: (row_y_start, name, num_frames, x_start)
rows = [
    # Row 1: IDLE
    (TOP_MARGIN, "idle", 4, LEFT_MARGIN),
    # Row 2 left: WALK
    (TOP_MARGIN + FRAME_H, "walk_forward", 4, LEFT_MARGIN),
    # Row 2 right: RUN (starts after walk, roughly at x=730)
    (TOP_MARGIN + FRAME_H, "walk_backward", 4, 730),
    # Row 3: JUMP (we'll map to dodging)
    (TOP_MARGIN + FRAME_H * 2, "dodging", 4, LEFT_MARGIN),
    # Row 4: PUNCH
    (TOP_MARGIN + FRAME_H * 3, "light_attack", 6, LEFT_MARGIN),
    # Row 5: KICK
    (TOP_MARGIN + FRAME_H * 4, "heavy_attack", 4, LEFT_MARGIN),
]

os.makedirs(OUTPUT_DIR, exist_ok=True)

# Also generate mappings for states we don't have specific sprites for
# blocking -> use idle_01
# hit_stun -> use idle_02
# knockdown -> use idle_01
# special_attack -> use punch frames
# victory -> use idle_01

frame_count = 0
for row_y, name, num_frames, x_start in rows:
    for i in range(num_frames):
        x = x_start + i * FRAME_W
        y = row_y
        
        # Crop the frame
        box = (x, y, x + FRAME_W, y + FRAME_H)
        frame = img.crop(box)
        
        # Resize to 256x256 for consistent sprite size
        # First, find the bounding box of non-transparent pixels
        bbox = frame.getbbox()
        if bbox:
            cropped = frame.crop(bbox)
            # Place on a 256x256 canvas, centered
            canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
            paste_x = (256 - cropped.width) // 2
            paste_y = 256 - cropped.height  # bottom-align for fighting game
            canvas.paste(cropped, (paste_x, paste_y))
            
            filename = f"{name}_{i+1:02d}.png"
            canvas.save(os.path.join(OUTPUT_DIR, filename))
            print(f"  Saved: {filename} (from {bbox})")
            frame_count += 1

# Generate alias frames for missing animations
from shutil import copy2

aliases = {
    "blocking_01.png": "idle_01.png",
    "hit_stun_01.png": "idle_02.png", 
    "knockdown_01.png": "idle_01.png",
    "special_attack_01.png": "light_attack_01.png",
    "special_attack_02.png": "light_attack_02.png",
    "victory_01.png": "idle_01.png",
}

for alias_name, source_name in aliases.items():
    src = os.path.join(OUTPUT_DIR, source_name)
    dst = os.path.join(OUTPUT_DIR, alias_name)
    if os.path.exists(src):
        copy2(src, dst)
        print(f"  Alias: {alias_name} -> {source_name}")
        frame_count += 1

print(f"\nDone! {frame_count} frames saved to {OUTPUT_DIR}")
