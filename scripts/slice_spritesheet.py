#!/usr/bin/env python3
"""
Slices the Gemini 4x4 sprite sheet into individual frames.

Image: 1380x752, 4x4 grid with clear cell borders
Layout:
  Row 1: FIGHT 1.1-1.4 (idle fighting stance)
  Row 2: WALK 2.1-2.4
  Row 3: PUNCH 3.1-3.4
  Row 4: RUN 4.1-4.4
"""

from PIL import Image
from shutil import copy2
import os, json

INPUT = "FitWars/assets/Gemini_Generated_Image_qxa4wuqxa4wuqxa4.png"
OUTPUT_DIR = "FitWars/Assets.xcassets/fighter_default.spriteatlas"

img = Image.open(INPUT).convert("RGBA")
W, H = img.size
print(f"Image size: {W}x{H}")

# 4x4 grid — each cell is W/4 x H/4
COLS = 4
ROWS = 4
CELL_W = W // COLS  # 345
CELL_H = H // ROWS  # 188

print(f"Cell size: {CELL_W}x{CELL_H}")

def remove_background(frame):
    """Remove gray/checkered background, keeping the character."""
    pixels = frame.load()
    w, h = frame.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            # Remove grays (background, grid lines, checkered pattern)
            is_neutral = abs(r - g) < 15 and abs(g - b) < 15
            if is_neutral and (50 < r < 200):
                pixels[x, y] = (0, 0, 0, 0)
            # Also remove the dark border/background
            elif r < 60 and g < 60 and b < 60:
                pixels[x, y] = (0, 0, 0, 0)
    return frame

def process_cell(col, row, output_name):
    """Extract cell, remove bg, trim, save to 256x256 canvas."""
    x = col * CELL_W
    y = row * CELL_H
    cell = img.crop((x, y, x + CELL_W, y + CELL_H)).copy()
    
    cell = remove_background(cell)
    bbox = cell.getbbox()
    if not bbox:
        print(f"  SKIP {output_name} — empty")
        return False
    
    cropped = cell.crop(bbox)
    
    # Skip if too small
    if cropped.width < 30 or cropped.height < 30:
        print(f"  SKIP {output_name} — too small ({cropped.width}x{cropped.height})")
        return False
    
    # Fit into 240x240, maintain aspect ratio
    scale = min(240 / cropped.width, 240 / cropped.height, 1.0)
    if scale < 1.0:
        cropped = cropped.resize(
            (int(cropped.width * scale), int(cropped.height * scale)),
            Image.LANCZOS
        )
    
    # Place on 256x256 canvas, bottom-center
    canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    px = (256 - cropped.width) // 2
    py = 256 - cropped.height - 4
    canvas.paste(cropped, (px, py))
    
    canvas.save(os.path.join(OUTPUT_DIR, output_name))
    print(f"  Saved: {output_name} ({cropped.width}x{cropped.height})")
    return True

# Clean output
os.makedirs(OUTPUT_DIR, exist_ok=True)
for f in os.listdir(OUTPUT_DIR):
    if f.endswith('.png'):
        os.remove(os.path.join(OUTPUT_DIR, f))

count = 0

# Row 0: FIGHT (idle) — 4 frames
for i in range(4):
    if process_cell(i, 0, f"idle_{i+1:02d}.png"):
        count += 1

# Row 1: WALK — 4 frames
for i in range(4):
    if process_cell(i, 1, f"walk_forward_{i+1:02d}.png"):
        count += 1

# Row 2: PUNCH — 4 frames → light_attack
for i in range(4):
    if process_cell(i, 2, f"light_attack_{i+1:02d}.png"):
        count += 1

# Row 3: RUN — 4 frames → heavy_attack (or walk_backward)
for i in range(4):
    if process_cell(i, 3, f"heavy_attack_{i+1:02d}.png"):
        count += 1

# Generate walk_backward as mirrored walk_forward
for i in range(4):
    src = os.path.join(OUTPUT_DIR, f"walk_forward_{i+1:02d}.png")
    if os.path.exists(src):
        fwd = Image.open(src)
        bwd = fwd.transpose(Image.FLIP_LEFT_RIGHT)
        dst = os.path.join(OUTPUT_DIR, f"walk_backward_{i+1:02d}.png")
        bwd.save(dst)
        print(f"  Mirrored: walk_backward_{i+1:02d}.png")
        count += 1

# Aliases for missing animations
aliases = {
    "blocking_01.png": "idle_02.png",
    "blocking_02.png": "idle_03.png",
    "hit_stun_01.png": "idle_04.png",
    "hit_stun_02.png": "idle_01.png",
    "dodging_01.png": "idle_03.png",
    "dodging_02.png": "idle_04.png",
    "knockdown_01.png": "idle_04.png",
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
        count += 1

# Contents.json
with open(os.path.join(OUTPUT_DIR, "Contents.json"), "w") as f:
    json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)

print(f"\nDone! {count} frames in {OUTPUT_DIR}")
