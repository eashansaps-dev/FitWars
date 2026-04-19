#!/usr/bin/env python3
"""
Process individual Gemini-generated sprite images.
Removes background, resizes to 256x256, saves to sprite atlas.
"""

from PIL import Image
from shutil import copy2
import os, json

OUTPUT_DIR = "FitWars/Assets.xcassets/fighter_default.spriteatlas"

# Mapping: source file → output name
FILE_MAP = {
    "1.png": "idle_01.png",
    "2.png": "idle_02.png",
    "3.png": "walk_forward_01.png",
    "4.png": "walk_forward_02.png",
    "5.png": "light_attack_01.png",
    "6.png": "light_attack_02.png",
    "7.png": "heavy_attack_01.png",
    "8.png": "hit_stun_01.png",
    "9.png": "blocking_01.png",
}

def remove_background(img):
    """Remove background using flood-fill from corners.
    Much more reliable than color-matching for gradient/checkered backgrounds."""
    import numpy as np
    
    w, h = img.size
    pixels = img.load()
    
    # Convert to numpy for faster processing
    data = np.array(img)
    alpha = data[:, :, 3].copy()
    rgb = data[:, :, :3]
    
    # Create a mask of "background-like" pixels
    # Background is neutral gray (R≈G≈B) in range 60-210
    r, g, b = rgb[:,:,0], rgb[:,:,1], rgb[:,:,2]
    is_neutral = (np.abs(r.astype(int) - g.astype(int)) < 20) & \
                 (np.abs(g.astype(int) - b.astype(int)) < 20)
    is_gray_range = (r > 60) & (r < 210)
    bg_candidate = is_neutral & is_gray_range
    
    # Flood fill from all 4 corners + edge midpoints
    from collections import deque
    visited = np.zeros((h, w), dtype=bool)
    to_remove = np.zeros((h, w), dtype=bool)
    
    seeds = [
        (0, 0), (w-1, 0), (0, h-1), (w-1, h-1),
        (w//2, 0), (w//2, h-1), (0, h//2), (w-1, h//2),
        (w//4, 0), (3*w//4, 0), (w//4, h-1), (3*w//4, h-1),
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
    
    # Apply: set background pixels to transparent
    data[to_remove, 3] = 0
    
    result = Image.fromarray(data)
    removed_pct = to_remove.sum() / (w * h) * 100
    print(f"    Removed {removed_pct:.0f}% background via flood-fill")
    return result

def process_sprite(input_path, output_name):
    """Load, resize, center on 256x256 canvas — no background removal."""
    print(f"  Processing {input_path} → {output_name}")
    
    img = Image.open(input_path).convert("RGBA")
    
    # Just resize to fit 240x240, maintain aspect ratio
    scale = min(240 / img.width, 240 / img.height)
    new_w = int(img.width * scale)
    new_h = int(img.height * scale)
    resized = img.resize((new_w, new_h), Image.LANCZOS)
    
    # Place on 256x256 canvas, bottom-center aligned
    canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    px = (256 - new_w) // 2
    py = 256 - new_h - 4  # 4px from bottom
    canvas.paste(resized, (px, py))
    
    canvas.save(os.path.join(OUTPUT_DIR, output_name))
    print(f"    Saved: {output_name} ({new_w}x{new_h})")
    return True

# Clean output directory
os.makedirs(OUTPUT_DIR, exist_ok=True)
for f in os.listdir(OUTPUT_DIR):
    if f.endswith('.png'):
        os.remove(os.path.join(OUTPUT_DIR, f))

count = 0

# Process each sprite
for src_file, dst_name in FILE_MAP.items():
    src_path = f"FitWars/assets/{src_file}"
    if os.path.exists(src_path):
        if process_sprite(src_path, dst_name):
            count += 1
    else:
        print(f"  MISSING: {src_path}")

# Generate walk_backward as mirrored walk_forward
for i in range(1, 3):
    src = os.path.join(OUTPUT_DIR, f"walk_forward_{i:02d}.png")
    if os.path.exists(src):
        fwd = Image.open(src)
        bwd = fwd.transpose(Image.FLIP_LEFT_RIGHT)
        dst = os.path.join(OUTPUT_DIR, f"walk_backward_{i:02d}.png")
        bwd.save(dst)
        print(f"  Mirrored: walk_backward_{i:02d}.png")
        count += 1

# Aliases for animations we don't have unique sprites for
aliases = {
    "idle_03.png": "idle_01.png",
    "idle_04.png": "idle_02.png",
    "walk_forward_03.png": "walk_forward_01.png",
    "walk_forward_04.png": "walk_forward_02.png",
    "light_attack_03.png": "light_attack_01.png",
    "light_attack_04.png": "light_attack_02.png",
    "heavy_attack_02.png": "heavy_attack_01.png",
    "hit_stun_02.png": "hit_stun_01.png",
    "blocking_02.png": "blocking_01.png",
    "dodging_01.png": "idle_02.png",
    "dodging_02.png": "idle_01.png",
    "knockdown_01.png": "hit_stun_01.png",
    "special_attack_01.png": "light_attack_01.png",
    "special_attack_02.png": "light_attack_02.png",
    "victory_01.png": "idle_01.png",
}

for alias_name, source_name in aliases.items():
    src = os.path.join(OUTPUT_DIR, source_name)
    dst = os.path.join(OUTPUT_DIR, alias_name)
    if os.path.exists(src):
        copy2(src, dst)
        print(f"  Alias: {alias_name} → {source_name}")
        count += 1

# Contents.json
with open(os.path.join(OUTPUT_DIR, "Contents.json"), "w") as f:
    json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)

print(f"\nDone! {count} frames in {OUTPUT_DIR}")
