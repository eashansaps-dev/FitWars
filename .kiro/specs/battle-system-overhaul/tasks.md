# Tasks: Battle System Overhaul

## 1. Foundation and Data Types
- [x] 1.1 Create `FitWars/Battle/DifficultyLevel.swift` with `DifficultyLevel` enum (easy/medium/hard), `AIAction` enum, and all config properties (reactionTime, actionCooldown, maxComboLength, actionWeights, survivalBlockBoost)
- [x] 1.2 Add `FighterState` enum with all new states (idle, walkForward, walkBackward, lightAttack, heavyAttack, specialAttack, blocking, hitStun, knockdown, dodging, victory) and `AttackType` enum (.light, .heavy, .special) to `FighterNode.swift`

## 2. Sprite Animation System
- [x] 2.1 Create `FitWars/Battle/SpriteAnimator.swift` with atlas loading, frame grouping by prefix naming convention (`{action}_{frame}`), play/stop/loop methods, blend duration support (0.05s default), and fallback colored-rectangle texture when atlas is missing
- [x] 2.2 Create placeholder sprite atlas assets — add a `fighter_default.atlas` folder under `FitWars/Assets.xcassets` with minimal placeholder PNGs (single colored rectangles) for each animation state so the app compiles without real art

## 3. Fighter Node Refactor
- [x] 3.1 Refactor `FighterNode.swift` — replace all SKShapeNode body-part construction with a single `SKSpriteNode` child driven by `SpriteAnimator`, add `specialMeter` property (0.0–1.0), add `transition(to:)` state machine method, add `attack(type:)` for light/heavy/special, add `addSpecialMeter()` and `consumeSpecialMeter()`, update `attackHitbox`/`bodyHurtbox` to return rects based on current animation state
- [x] 3.2 Add fallback logic in `FighterNode.init` — if the requested atlas name is not found in the bundle, fall back to `fighter_default` atlas and print a warning

## 4. Input System
- [x] 4.1 Create `FitWars/Battle/InputManager.swift` with `VirtualJoystick` (SKNode with base ring + thumb circle, 50pt radius, normalized direction vector, 0.1s return-to-center animation) and action button nodes (light_attack red, heavy_attack dark red, block blue, special gold, all alpha 0.6)
- [x] 4.2 Implement multi-touch routing in `InputManager` — separate touch tracking per finger, joystick on left side, buttons on right side, haptic feedback via `UIImpactFeedbackGenerator` on button tap, report direction vector and button presses via closures
- [x] 4.3 Add special move input buffer to `InputManager` — store last 0.5s of directional inputs, detect forward-forward-attack sequence, fire `onSpecial` callback when detected and special meter is full, otherwise treat as regular attack

## 5. Combo System
- [x] 5.1 Create `FitWars/Battle/ComboSystem.swift` — track consecutive hits within 0.4s window, calculate damage multiplier (1.0 + 0.1 × (hitCount - 1)), fire `onComboUpdated` and `onComboEnded` callbacks, award 10% special meter bonus on 5+ hit combos, `update(currentTime:)` to check window expiry

## 6. AI Controller
- [x] 6.1 Create `FitWars/Battle/AIController.swift` — weighted action selection using `DifficultyLevel.actionWeights`, cooldown enforcement per difficulty, approach logic when out of range, idle timeout (0.8s max before forced action)
- [x] 6.2 Add reaction system to `AIController` — when `onOpponentAction()` is called, start a reaction timer based on `difficulty.reactionTime`, evaluate block-or-dodge response when timer expires
- [x] 6.3 Add combo execution to `AIController` — when opponent is in hitStun, chain up to `difficulty.maxComboLength` attacks with minimal delay between each
- [x] 6.4 Add survival mode to `AIController` — when fighter HP < 30%, boost block probability by 15 percentage points, reduce attack probability by 15 percentage points
- [x] 6.5 Add pattern tracking to `AIController` (hard mode only) — maintain circular buffer of player's last 10 actions, identify most-used action, boost counter-action probability by 20 percentage points using `counterMap`

## 7. HUD Overlay
- [x] 7.1 Create `FitWars/Battle/HUDOverlay.swift` with `HealthBarNode` (gradient fill green→yellow→red based on percentage, ghost damage trail bar that fades over 0.3s), positioned at top of screen for both fighters
- [x] 7.2 Add `TimerNode` to `HUDOverlay` — centered top, countdown in whole seconds, text turns red and pulses scale at 1s intervals when ≤10 seconds remain
- [x] 7.3 Add `ComboCounterNode` to `HUDOverlay` — shows hit count and accumulated damage near the attacking fighter, fades out over 0.2s when combo ends
- [x] 7.4 Add `SpecialMeterNode` to `HUDOverlay` — bar below each health bar, fills 0–100%, flashes and shows "READY" label when full

## 8. Visual Effects
- [x] 8.1 Create `FitWars/Battle/VFXManager.swift` with emitter pool (max 8 active), `spawnHitSpark(at:intensity:)` using `SKEmitterNode`, intensity enum (.normal, .combo with 50% more particles for 3+ hit combos)
- [x] 8.2 Add `screenShake(intensity:duration:)` to `VFXManager` — random offset applied to camera node per frame, decaying over duration (default 0.15s), intensity proportional to damage
- [x] 8.3 Add `specialAttackFlash()` to `VFXManager` — full-screen white overlay node fading from alpha 0.8 to 0 over 0.1s, followed by particle trail on attacker
- [x] 8.4 Add `slowMotionKO(completion:)` to `VFXManager` — set scene.speed to 0.3 for 0.5s, restore to 1.0, call completion
- [x] 8.5 Add `adaptToPerformance(fps:)` to `VFXManager` — if FPS < 55 for > 0.5s, halve all active emitter birthRates; if FPS > 58, restore original birthRates
- [x] 8.6 Create placeholder particle effect files — `hit_spark.sks`, `special_trail.sks`, `ko_burst.sks` with basic configurations (white particles, short lifetimes) so VFXManager has assets to load

## 9. Camera System
- [x] 9.1 Create `FitWars/Battle/CameraController.swift` — add `SKCameraNode` to scene, `update()` sets position to midpoint between fighters, zoom scale based on fighter distance (close < 30% screen width → 0.85x, far > 70% → 1.15x), ease-in-out interpolation, clamp to stage bounds
- [x] 9.2 Add `zoomForSpecial(attacker:completion:)` to `CameraController` — zoom to 0.75x centered on attacker over 0.4s, then ease back to normal over 0.3s
- [x] 9.3 Add `applyShake(intensity:duration:)` to `CameraController` — per-frame random offset added to camera position, decaying linearly over duration

## 10. Parallax Background
- [x] 10.1 Create `FitWars/Battle/ParallaxBackground.swift` — load three texture layers (`{stageID}_bg_far`, `{stageID}_bg_mid`, `{stageID}_bg_near`) with speed factors (0.2, 0.5, 1.0), duplicate each for seamless horizontal wrapping, `update(cameraX:)` scrolls layers
- [x] 10.2 Add `fallbackGradient(sceneSize:)` static method to `ParallaxBackground` — creates a vertical gradient SKNode (dark blue to dark purple) used when stage textures are missing
- [x] 10.3 Create placeholder stage assets — add `arena_01_bg_far.png`, `arena_01_bg_mid.png`, `arena_01_bg_near.png` placeholder images (simple gradient/colored rectangles) to the asset catalog

## 11. Sound System
- [x] 11.1 Create `FitWars/Battle/SoundManager.swift` — singleton with configurable event-to-filename mapping, `play(_:context:)` using `SKAction.playSoundFileNamed`, max 4 concurrent SFX, named hook methods for all 10 events (attackHit, attackBlocked, attackWhiff, comboHit, specialAttack, knockdown, roundStart, roundEnd, timerWarning, menuSelect)
- [x] 11.2 Add background music support to `SoundManager` — `playMusic(_:in:)`, `stopMusic(fadeDuration:)`, `crossfadeMusic(to:in:duration:)` using `SKAudioNode` with 0.5s default crossfade
- [x] 11.3 Add graceful missing-file handling to `SoundManager` — if audio file not found in bundle, log warning and skip playback without crashing

## 12. BattleScene Refactor
- [x] 12.1 Refactor `BattleScene.swift` `didMove(to:)` — replace inline setup with subsystem initialization: create CameraController, ParallaxBackground, FighterNodes (with atlas names), InputManager, HUDOverlay, AIController, ComboSystem, VFXManager; configure SoundManager; play round_start sound
- [x] 12.2 Refactor `BattleScene.swift` `update(_:)` — replace monolithic game loop with sequential subsystem updates: timer → inputManager.update → aiController.update → comboSystem.update → cameraController.update → parallax.update → vfx.adaptToPerformance → HUD updates → position clamping
- [x] 12.3 Implement `resolveAttack(attacker:defender:type:)` in `BattleScene` — hitbox/hurtbox intersection check, block/dodge/hit branching, combo damage via ComboSystem, VFX spawning, sound hooks, HUD updates, special meter changes
- [x] 12.4 Implement `handleKO(loser:)` in `BattleScene` — trigger slowMotionKO via VFXManager, play knockdown sound, show result after animation completes
- [x] 12.5 Wire `InputManager` callbacks to player `FighterNode` actions and `AIController.onOpponentAction()` in `BattleScene`

## 13. BattleSpriteView Update
- [x] 13.1 Update `BattleSpriteView.swift` to accept `difficulty: DifficultyLevel`, `playerAtlas: String`, `opponentAtlas: String`, and `stageID: String` parameters, pass them through to `BattleScene` init
- [x] 13.2 Update `BattleView.swift` to provide difficulty selection (default medium) and pass atlas/stage parameters to `BattleSpriteView`

## 14. Resource Cleanup
- [x] 14.1 Add `willMove(from:)` override to `BattleScene` — remove all children, release texture atlas references, stop all audio, nil out subsystem references to ensure memory is freed within 1 second of scene dismissal
