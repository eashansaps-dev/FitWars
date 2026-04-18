#!/usr/bin/env python3
"""
Slices the Gemini sprite sheet into individual frames using known layout.

Image: 1408x768
Layout from visual inspection:
  Row 1 (y~15-150):  IDLE - 4 frames, left section (~x=90 to x=680)
  Row 2 (y~155-310): WALK 4 frames (x=90-680) + RUN 4 frames (x=720-1380)
  Row 3 (y~315-455): JUMP - 4 frames (x=90-680)
  Row 4 (y~460-620): PUNCH - 6 frames (x=90-1050)
  Row 5 (y~625-765): KICK - 4 frames (x=90-680) + EFFECTS box (skip)
"""

from PIL import Image
from shutil import copy2
import os

INPUT = "FitWars/assets/Gemini_Generated_Image_wquydrwquydrwquy.png"
OUTPUT_DIR = "FitWars/Assets.xcassets/fighter_default.spriteatlas"

img = Image.open(INPUT).convert("RGBA")
W, H = img.size
print(f"Image size: {W}x{H}")

# Define exact frame regions based on the visible layout
# Each entry: (name, [(x, y, w, h), ...])
# The sprite sheet has a rounded-rect dark area starting around x=18, y=10
# Labels take up ~80px on the left

frame_defs = []

# Row 1: IDLE - 4 frames evenly spaced from x~95 to x~660
# Each frame roughly 140px wide
idle_y, idle_h = 15, 138
idle_x_start = 95
idle_frame_w = 142
for i in range(4):
    x = idle_x_start + i * idle_frame_w
    frame_defs.append(("idle", i+1, x, idle_y, idle_frame_w, idle_h))

# Row 2 left: WALK - 4 frames
walk_y, walk_h = 155, 155
walk_x_start = 95
walk_frame_w = 142
for i in range(4):
    x = walk_x_start + i * walk_frame_w
    frame_defs.append(("walk_forward", i+1, x, walk_y, walk_frame_w, walk_h))

# Row 2 right: RUN - 4 frames (starts after "RUN" label ~x=720)
run_x_start = 740
run_frame_w = 160
for i in range(4):
    x = run_x_start + i * run_frame_w
    frame_defs.append(("walk_backward", i+1, x, walk_y, run_frame_w, walk_h))

# Row 3: JUMP - 4 frames
jump_y, jump_h = 318, 138
jump_x_start = 95
jump_frame_w = 155
for i in range(4):
    x = jump_x_start + i * jump_frame_w
    frame_defs.append(("dodging", i+1, x, jump_y, jump_frame_w, jump_h))

# Row 4: PUNCH - 6 frames (wider row)
punch_y, punch_h = 460, 158
punch_x_start = 95
punch_frame_w = 155
for i in range(6):
    x = punch_x_start + i * punch_frame_w
    frame_defs.append(("light_attack", i+1, x, punch_y, punch_frame_w, punch_h))

# Row 5: KICK - 4 frames
kick_y, kick_h = 625, 140
kick_x_start = 95
kick_frame_w = 155
for i in range(4):
    x = kick_x_start + i * kick_frame_w
    frame_defs.append(("heavy_attack", i+1, x, kick_y, kick_frame_w, kick_h))

# Background color to make transparent
# The background is a gradient gray — we'll use a range
def make_transparent(frame_img):
    """Remove the gray background, keeping the character."""
    pixels = frame_img.load()
    w, h = frame_img.size
    
    # Sample corners to get the local background color
    corner_samples = []
    for cx, cy in [(2,2), (w-3,2), (2,h-3), (w-3,h-3)]:
        if 0 <= cx < w and 0 <= cy < h:
            corner_samples.append(pixels[cx, cy][:3])
    
    if not corner_samples:
        return frame_img
    
    # Average corner color = background
    avg_r = sum(c[0] for c in corner_samples) // len(corner_samples)
    avg_g = sum(c[1] for c in corner_samples) // len(corner_samples)
    avg_b = sum(c[2] for c in corner_samples) // len(corner_samples)
    
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            # Check if this pixel is close to the background color
            dr = abs(r - avg_r)
            dg = abs(g - avg_g)
            db = abs(b - avg_b)
            if dr < 30 and dg < 30 and db < 30:
                pixels[x, y] = (0, 0, 0, 0)
    
    return frame_img

os.makedirs(OUTPUT_DIR, exist_ok=True)

# Remove old placeholder PNGs first
for f in os.listdir(OUTPUT_DIR):
    if f.endswith('.png'):
        os.remove(os.path.join(OUTPUT_DIR, f))

frame_count = 0
for name, idx, x, y, fw, fh in frame_defs:
    # Crop frame from sheet
    box = (x, y, x + fw, y + fh)
    frame = img.crop(box).copy()
    
    # Remove background
    frame = make_transparent(frame)
    
    # Trim transparent edges
    bbox = frame.getbbox()
    if not bbox:
        print(f"  SKIP {name}_{idx:02d} — empty after bg removal")
        continue
    
    cropped = frame.crop(bbox)
    
    # Place on 256x256 canvas, bottom-center aligned
    canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    # Scale down if too big
    scale = min(240 / cropped.width, 240 / cropped.height, 1.0)
    if scale < 1.0:
        new_w = int(cropped.width * scale)
        new_h = int(cropped.height * scale)
        cropped = cropped.resize((new_w, new_h), Image.LANCZOS)
    
    paste_x = (256 - cropped.width) // 2
    paste_y = 256 - cropped.height - 8  # 8px from bottom
    canvas.paste(cropped, (paste_x, paste_y))
    
    filename = f"{name}_{idx:02d}.png"
    canvas.save(os.path.join(OUTPUT_DIR, filename))
    print(f"  Saved: {filename} ({cropped.width}x{cropped.height})")
    frame_count += 1

# Generate aliases for missing animations
aliases = {
    "blocking_01.png": "idle_01.png",
    "hit_stun_01.png": "idle_02.png",
    "knockdown_01.png": "idle_03.png",
    "special_attack_01.png": "light_attack_03.png",
    "special_attack_02.png": "light_attack_04.png",
    "victory_01.png": "idle_01.png",
}

for alias_name, source_name in aliases.items():
    src = os.path.join(OUTPUT_DIR, source_name)
    dst = os.path.join(OUTPUT_DIR, alias_name)
    if os.path.exists(src):
        copy2(src, dst)
        print(f"  Alias: {alias_name} -> {source_name}")
        frame_count += 1

print(f"\nDone! {frame_count} frames in {OUTPUT_DIR}")
