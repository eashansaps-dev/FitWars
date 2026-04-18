# PulseCombat — Sprite Art Generation Guide

## Overview

This guide covers how to generate fighting game character sprites using AI tools for PulseCombat. The goal is semi-realistic 2D fighters in the style of Street Fighter IV / Super Smash Bros — detailed shading, grounded proportions, not pixel art or chibi.

## Recommended AI Tools

| Tool | Best For | Cost | Notes |
|------|----------|------|-------|
| **Midjourney v6** | Best overall quality for semi-realistic 2D characters | $10/mo | Use `--style raw` for cleaner game art |
| **Stable Diffusion + ControlNet** | Pose control across animation frames | Free (local) | Use OpenPose to lock fighting stances |
| **Leonardo.ai** | Character consistency across poses | Free tier available | Has game asset mode |

Grok image generation is not recommended — inconsistent quality for game sprites.

## File Requirements

### Format
- PNG with transparent background
- Max 512×512 points per frame
- Consistent canvas size across all frames for the same character

### Naming Convention
Files must follow this pattern for the SpriteAnimator to auto-detect them:
```
{action}_{frame_number}.png
```

Examples:
```
idle_01.png, idle_02.png, idle_03.png, idle_04.png
walk_forward_01.png, walk_forward_02.png, ...
light_attack_01.png, light_attack_02.png, ...
heavy_attack_01.png, heavy_attack_02.png, ...
block_01.png, block_02.png, ...
hit_stun_01.png, hit_stun_02.png, ...
knockdown_01.png, knockdown_02.png, ...
special_attack_01.png, special_attack_02.png, ...
victory_01.png, victory_02.png, ...
walk_backward_01.png, walk_backward_02.png, ...
```

### Frames Per Animation
| Animation | Frames | Priority |
|-----------|--------|----------|
| idle | 4 | MVP — generate first |
| light_attack | 4 | MVP |
| hit_stun | 3 | MVP |
| walk_forward | 6 | High |
| walk_backward | 6 | High |
| heavy_attack | 6 | High |
| block | 3 | High |
| special_attack | 8 | Medium |
| knockdown | 4 | Medium |
| victory | 4 | Low |

## Prompt Templates

### Step 1: Generate the Base Idle Pose (do this first)

This becomes your reference for all other poses. Get this right before generating anything else.

**Midjourney:**
```
2D fighting game character, side view profile, idle fighting stance,
[body description: e.g. muscular male martial artist],
wearing [outfit: e.g. white gi with black belt],
[skin tone: e.g. medium brown skin],
[hair: e.g. short black hair],
semi-realistic art style similar to Street Fighter IV,
clean lines, cel shading, detailed muscle definition,
transparent background, full body visible, game sprite asset,
high resolution --ar 1:1 --style raw --v 6
```

**Leonardo.ai:**
```
2D fighting game sprite, side view, idle fighting stance,
[character description], semi-realistic style like Street Fighter IV,
clean cel shading, transparent background, full body,
game asset, high detail
```

**Stable Diffusion (with ControlNet OpenPose):**
```
2D fighting game character sprite, side view, idle stance,
[character description], semi-realistic cel shaded style,
clean lines, transparent background, game asset
Negative: 3D, realistic photo, blurry, low quality, chibi, pixel art
```

### Step 2: Generate Attack Poses (use idle as reference)

Use img2img or character reference features to maintain consistency.

**Punch / Light Attack:**
```
same character as reference, side view, throwing a straight punch,
right arm fully extended forward, left arm guarding,
2D fighting game sprite, transparent background,
consistent art style, game asset
```

**Heavy Attack (kick):**
```
same character as reference, side view, executing a roundhouse kick,
right leg extended high, dynamic pose,
2D fighting game sprite, transparent background,
consistent art style, game asset
```

**Block:**
```
same character as reference, side view, blocking defensive stance,
both arms raised in front of face and torso, guarding position,
2D fighting game sprite, transparent background,
consistent art style, game asset
```

**Hit Reaction:**
```
same character as reference, side view, getting hit reaction,
leaning backward, pain expression, slight recoil,
2D fighting game sprite, transparent background,
consistent art style, game asset
```

**Special Attack:**
```
same character as reference, side view, executing powerful special move,
energy effect around fists, dynamic action pose, intense expression,
2D fighting game sprite, transparent background,
consistent art style, game asset
```

### Step 3: Generate Walking Frames

```
same character as reference, side view, mid-stride walking forward,
[frame 1: left foot forward / frame 2: passing / frame 3: right foot forward],
2D fighting game sprite, transparent background,
consistent art style, game asset
```

## Tips for Consistency

1. **Always generate idle first** — this is your character bible
2. **Use img2img** (Stable Diffusion) or **character reference** (Midjourney `--cref`) to keep the same character across poses
3. **Lock the camera angle** — always specify "side view" or "profile view"
4. **Same canvas size** — crop/resize all frames to the same dimensions
5. **Transparent backgrounds** — if the AI gives you a background, use remove.bg or Photoshop to clean it
6. **Consistent lighting** — add "lit from upper left" to all prompts for uniform shading

## Post-Processing Pipeline

1. Generate raw images from AI tool
2. Remove background (if not already transparent) — use remove.bg or Photoshop
3. Resize to consistent canvas (512×512 recommended)
4. Center the character on the canvas (feet at same Y position across all frames)
5. Export as PNG with transparency
6. Name files following the `{action}_{frame}.png` convention
7. Place in Xcode atlas folder: `FitWars/Assets.xcassets/fighter_{style_id}.spriteatlas/`

## Quick Start (MVP — 3 animations only)

If you want to get something on screen fast, generate just these:
1. **idle** (4 frames) — standing fighting stance
2. **light_attack** (4 frames) — punch animation
3. **hit_stun** (3 frames) — getting hit reaction

That's 11 images total. The SpriteAnimator will fall back to idle for any missing animations.

## Stage Background Art

For parallax backgrounds, generate three layers per stage:

**Far background (sky/cityscape):**
```
2D fighting game stage background, far layer,
[setting: e.g. night city skyline, dojo interior, street scene],
wide panoramic, tileable horizontally, no characters,
semi-realistic painted style, atmospheric, game asset
--ar 4:1
```

**Mid-ground (buildings/structures):**
```
2D fighting game stage mid-ground layer,
[setting details closer up], tileable horizontally,
semi-transparent elements, parallax layer, game asset
--ar 4:1
```

**Near foreground (ground/props):**
```
2D fighting game stage foreground, ground level,
[floor texture, debris, props], tileable horizontally,
parallax near layer, game asset
--ar 4:1
```

Name them: `arena_01_bg_far.png`, `arena_01_bg_mid.png`, `arena_01_bg_near.png`
Recommended width: 2048px per layer.
