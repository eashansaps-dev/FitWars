#!/usr/bin/env python3
"""
Process character variant sprites into separate sprite atlases.
Each variant gets its own idle frame, and shares action frames from the base.
"""

from PIL import Image
from shutil import copy2
import numpy as np
import os, json

BASE_ATLAS = "FitWars/Assets.xcassets/fighter_default.spriteatlas"
ASSETS_DIR = "FitWars/Assets.xcassets"

# Variant definitions: (source_file, atlas_name)
VARIANTS = [
    ("FitWars/assets/female.png", "fighter_female"),
    ("FitWars/assets/dark.png", "fighter_dark"),
    ("FitWars/assets/blonde_man.png", "fighter_blonde"),
    ("FitWars/assets/redhair_man.png", "fighter_redhair"),
]

def remove_background(img):
    """Flood-fill from edges to remove gray background."""
    w, h = img.size
    data = np.array(img)
    r, g, b = data[:,:,0], data[:,:,1], data[:,:,2]
    
    is_neutral = (np.abs(r.astype(int) - g.astype(int)) < 20) & \
                 (np.abs(g.astype(int) - b.astype(int)) < 20)
    is_gray_range = (r > 60) & (r < 210)
    bg_candidate = is_neutral & is_gray_range
    
    from collections import deque
    visited = np.zeros((h, w), dtype=bool)
    to_remove = np.zeros((h, w), dtype=bool)
    
    seeds = [
        (0,0), (w-1,0), (0,h-1), (w-1,h-1),
        (w//2,0), (w//2,h-1), (0,h//2), (w-1,h//2),
        (w//4,0), (3*w//4,0), (w//4,h-1), (3*w//4,h-1),
    ]
    
    queue = deque()
    for sx, sy in seeds:
        if bg_candidate[sy, sx] and not visited[sy, sx]:
            queue.append((sx, sy))
            visited[sy, sx] = True
    
    while queue:
        x, y = queue.popleft()
        to_remove[y, x] = True
        for dx, dy in [(-1,0),(1,0),(0,-1),(0,1)]:
            nx, ny = x+dx, y+dy
            if 0 <= nx < w and 0 <= ny < h and not visited[ny, nx]:
                visited[ny, nx] = True
                if bg_candidate[ny, nx]:
                    queue.append((nx, ny))
    
    data[to_remove, 3] = 0
    return Image.fromarray(data)

def process_to_256(img):
    """Resize to 256x256 canvas — skip background removal to preserve character."""
    img = img.convert("RGBA")
    
    # Just trim any fully-transparent edges if they exist
    bbox = img.getbbox()
    if bbox:
        cropped = img.crop(bbox)
    else:
        cropped = img
    
    # Fit into 240x240, maintain aspect ratio
    scale = min(240 / cropped.width, 240 / cropped.height)
    new_w = int(cropped.width * scale)
    new_h = int(cropped.height * scale)
    cropped = cropped.resize((new_w, new_h), Image.LANCZOS)
    
    # Place on 256x256 canvas, bottom-center
    canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    px = (256 - new_w) // 2
    py = 256 - new_h - 4
    canvas.paste(cropped, (px, py))
    return canvas

# Action frames to copy from base atlas (shared across all variants)
ACTION_FRAMES = [
    "walk_forward_01.png", "walk_forward_02.png",
    "walk_forward_03.png", "walk_forward_04.png",
    "walk_backward_01.png", "walk_backward_02.png",
    "walk_backward_03.png", "walk_backward_04.png",
    "light_attack_01.png", "light_attack_02.png",
    "light_attack_03.png", "light_attack_04.png",
    "heavy_attack_01.png", "heavy_attack_02.png",
    "hit_stun_01.png", "hit_stun_02.png",
    "blocking_01.png", "blocking_02.png",
    "dodging_01.png", "dodging_02.png",
    "knockdown_01.png",
    "special_attack_01.png", "special_attack_02.png",
    "victory_01.png",
]

for src_file, atlas_name in VARIANTS:
    print(f"\nProcessing {atlas_name}...")
    atlas_dir = os.path.join(ASSETS_DIR, f"{atlas_name}.spriteatlas")
    os.makedirs(atlas_dir, exist_ok=True)
    
    # Clean existing PNGs
    for f in os.listdir(atlas_dir):
        if f.endswith('.png'):
            os.remove(os.path.join(atlas_dir, f))
    
    # Process the variant's idle image
    img = Image.open(src_file)
    canvas = process_to_256(img)
    if canvas:
        canvas.save(os.path.join(atlas_dir, "idle_01.png"))
        # Create idle variants by slight modifications
        canvas.save(os.path.join(atlas_dir, "idle_02.png"))
        canvas.save(os.path.join(atlas_dir, "idle_03.png"))
        canvas.save(os.path.join(atlas_dir, "idle_04.png"))
        print(f"  Saved idle frames (from {src_file})")
    
    # Copy action frames from base atlas
    copied = 0
    for frame in ACTION_FRAMES:
        src = os.path.join(BASE_ATLAS, frame)
        if os.path.exists(src):
            copy2(src, os.path.join(atlas_dir, frame))
            copied += 1
    print(f"  Copied {copied} action frames from base atlas")
    
    # Contents.json
    with open(os.path.join(atlas_dir, "Contents.json"), "w") as f:
        json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)
    
    total = len([f for f in os.listdir(atlas_dir) if f.endswith('.png')])
    print(f"  Total: {total} frames in {atlas_dir}")

print("\nAll variants processed!")
