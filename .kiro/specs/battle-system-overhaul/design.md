# Technical Design: Battle System Overhaul

## Overview

This design replaces PulseCombat's primitive SKShapeNode battle system with a production-quality 2D fighting game experience. The overhaul touches every layer of the battle stack: rendering (sprite atlases), AI (reactive multi-difficulty), input (virtual joystick + combo detection), visual effects (particles, screen shake), HUD (gradient bars, combo counter), camera (dynamic framing), sound (event-driven hooks), and stage art (parallax backgrounds).

All new code lives under `FitWars/Battle/` alongside the existing files. The existing `BattleScene.swift` and `FighterNode.swift` are refactored in place. No changes to Firebase, HealthKit, or the SwiftUI navigation layer outside of `BattleSpriteView.swift`.

## Architecture

```
BattleSpriteView (SwiftUI)
  └── BattleScene (SKScene)
        ├── CameraController (SKCameraNode manager)
        ├── ParallaxBackground (multi-layer stage)
        ├── FighterNode × 2 (sprite-based fighters)
        │     ├── SpriteAnimator (atlas frame playback)
        │     └── Hitbox/Hurtbox rects
        ├── HUDOverlay (SKNode tree)
        │     ├── HealthBarNode × 2
        │     ├── TimerNode
        │     ├── ComboCounterNode
        │     └── SpecialMeterNode × 2
        ├── InputManager (touch → commands)
        │     ├── VirtualJoystick (SKNode)
        │     └── ActionButtons (SKNode group)
        ├── ComboSystem (hit chain tracker)
        ├── AIController (CPU decision engine)
        ├── VFXManager (particle pool + screen shake)
        └── SoundManager (audio hook dispatcher)
```

## File Structure

```
FitWars/Battle/
  BattleScene.swift          — refactored: orchestrates all subsystems
  FighterNode.swift           — refactored: sprite-based with SpriteAnimator
  SpriteAnimator.swift        — NEW: texture atlas frame playback
  AIController.swift          — NEW: reactive AI with difficulty levels
  ComboSystem.swift           — NEW: combo detection + damage scaling
  InputManager.swift          — NEW: joystick + buttons + gesture recognition
  HUDOverlay.swift            — NEW: health bars, timer, combo counter, special meter
  VFXManager.swift            — NEW: particle pool, hit sparks, screen shake
  SoundManager.swift          — NEW: audio event hooks
  CameraController.swift      — NEW: dynamic framing + zoom
  ParallaxBackground.swift    — NEW: multi-layer scrolling stage
  BattleSpriteView.swift      — minor update: pass difficulty level
  DifficultyLevel.swift       — NEW: enum + config constants
```

## Detailed Component Design

### 1. DifficultyLevel

```swift
// DifficultyLevel.swift
enum DifficultyLevel: String, CaseIterable {
    case easy, medium, hard

    var reactionTime: TimeInterval {
        switch self { case .easy: 0.5; case .medium: 0.3; case .hard: 0.15 }
    }
    var actionCooldown: TimeInterval {
        switch self { case .easy: 0.4; case .medium: 0.25; case .hard: 0.1 }
    }
    var maxComboLength: Int {
        switch self { case .easy: 1; case .medium: 2; case .hard: 4 }
    }
    // Weighted action probabilities stored as [ActionType: Double] dictionaries
    var actionWeights: [AIAction: Double] { ... }
    var survivalBlockBoost: Double { 0.15 }
}

enum AIAction: CaseIterable {
    case attack, block, dodge, combo, special
}
```

### 2. SpriteAnimator

Handles loading texture atlases and playing frame sequences on an `SKSpriteNode`.

```swift
// SpriteAnimator.swift
class SpriteAnimator {
    private var atlasCache: [String: SKTextureAtlas] = [:]
    private var animations: [String: [SKTexture]] = [:]  // "idle", "walk_forward", etc.
    private weak var sprite: SKSpriteNode?
    private var currentAnimation: String = ""

    init(sprite: SKSpriteNode, atlasName: String)
    func loadAnimations(atlasName: String)  // parses atlas, groups frames by prefix
    func play(_ animationName: String, loop: Bool, blendDuration: TimeInterval = 0.05)
    func stop()
    var isPlaying: Bool { get }
    var currentFrame: String { get }
}
```

Frame naming convention in atlas: `idle_01`, `idle_02`, `walk_forward_01`, `light_attack_01`, etc.

Fallback: if atlas not found, creates a single colored `SKTexture` from a 128x128 rectangle.

### 3. FighterNode (Refactored)

Replaces all SKShapeNode drawing with a single `SKSpriteNode` driven by `SpriteAnimator`.

```swift
// FighterNode.swift — refactored
class FighterNode: SKNode {
    let stats: PlayerStats
    let isPlayer: Bool
    var maxHP: Int
    var currentHP: Int
    var state: FighterState = .idle
    var specialMeter: Double = 0.0  // 0.0 to 1.0

    private let sprite: SKSpriteNode
    private let animator: SpriteAnimator

    // Hitbox and hurtbox as child SKNodes (invisible, used for collision)
    private let hitboxNode: SKNode   // active during attack frames
    private let hurtboxNode: SKNode  // always active

    init(stats: PlayerStats, isPlayer: Bool, atlasName: String)

    // State machine
    func transition(to newState: FighterState)
    func attack(type: AttackType)  // .light, .heavy, .special
    func block()
    func dodge()
    func takeHit(damage: Int, comboHit: Int)
    func knockdown()
    func moveHorizontal(_ dx: CGFloat)

    // Hitbox queries
    var attackHitbox: CGRect { get }  // only valid during attack frames
    var bodyHurtbox: CGRect { get }

    // Special meter
    func addSpecialMeter(_ amount: Double)
    func consumeSpecialMeter() -> Bool  // returns false if < 1.0

    var isAlive: Bool { get }
    var attackDamage: Int { get }  // base damage from stats
}

enum FighterState: String {
    case idle, walkForward, walkBackward
    case lightAttack, heavyAttack, specialAttack
    case blocking, hitStun, knockdown, dodging, victory
}

enum AttackType { case light, heavy, special }
```

Key change: `FighterNode` no longer builds shapes. It creates one `SKSpriteNode` child and delegates all visuals to `SpriteAnimator`. The `transition(to:)` method calls `animator.play()` with the matching animation name.

### 4. AIController

```swift
// AIController.swift
class AIController {
    let difficulty: DifficultyLevel
    private weak var fighter: FighterNode?
    private weak var opponent: FighterNode?
    private var cooldownTimer: TimeInterval = 0
    private var reactionTimer: TimeInterval = 0
    private var pendingReaction: AIAction?
    private var comboHitsRemaining: Int = 0

    // Pattern tracking (hard mode)
    private var opponentActionHistory: [FighterState] = []  // last 10
    private var counterMap: [FighterState: AIAction] = [
        .lightAttack: .block,
        .heavyAttack: .dodge,
        .blocking: .combo  // grab or heavy)
    ]

    init(fighter: FighterNode, opponent: FighterNode, difficulty: DifficultyLevel)

    func update(dt: TimeInterval)
    // Called each frame. Manages cooldowns, evaluates distance,
    // picks actions via weighted random, executes combos.

    func onOpponentAction(_ action: FighterState)
    // Called by BattleScene when player acts. Starts reaction timer.

    private func selectAction() -> AIAction
    // Weighted random using difficulty.actionWeights, modified by:
    // - survival mode (HP < 30%)
    // - pattern counter (hard mode)

    private func executeAction(_ action: AIAction)
    private func continueCombo()
    private func approach()
}
```

The AI never acts faster than `difficulty.actionCooldown`. On hard, it reads the player's last 10 actions and boosts the counter-action weight by 20 points.

### 5. ComboSystem

```swift
// ComboSystem.swift
class ComboSystem {
    private(set) var currentComboCount: Int = 0
    private(set) var currentComboDamage: Int = 0
    private var lastHitTime: TimeInterval = 0
    private let comboWindow: TimeInterval = 0.4

    var onComboUpdated: ((Int, Int) -> Void)?  // (count, totalDamage)
    var onComboEnded: ((Int, Int) -> Void)?     // (finalCount, finalDamage)

    func registerHit(baseDamage: Int, timestamp: TimeInterval) -> Int
    // Returns scaled damage. Multiplier: 1.0 + 0.1 * (comboCount - 1)
    // Resets combo if timestamp - lastHitTime > comboWindow

    func update(currentTime: TimeInterval)
    // Checks if combo window expired, fires onComboEnded

    func reset()

    var damageMultiplier: Double {
        1.0 + 0.1 * Double(max(currentComboCount - 1, 0))
    }
}
```

### 6. InputManager

```swift
// InputManager.swift
class InputManager: SKNode {
    var onMove: ((CGVector) -> Void)?       // normalized direction vector
    var onAttack: ((AttackType) -> Void)?
    var onBlock: (() -> Void)?
    var onSpecial: (() -> Void)?

    private let joystick: VirtualJoystick
    private var actionButtons: [String: SKNode] = [:]

    // Special move input buffer
    private var inputBuffer: [(direction: CGVector, time: TimeInterval)] = []
    private let specialSequence: [CGVector] = [.right, .right]  // forward-forward
    private let bufferWindow: TimeInterval = 0.5

    override init()
    func setup(sceneSize: CGSize)

    // Touch routing
    override func touchesBegan(...)
    override func touchesMoved(...)
    override func touchesEnded(...)

    func update(currentTime: TimeInterval)
    // Checks input buffer for special move sequences

    private func checkSpecialInput() -> Bool
    private func triggerHaptic()
}

class VirtualJoystick: SKNode {
    private let base: SKShapeNode      // outer ring
    private let thumb: SKShapeNode     // inner draggable circle
    private let radius: CGFloat = 50
    var direction: CGVector = .zero     // normalized

    func handleTouch(at point: CGPoint)
    func handleRelease()  // animates thumb back to center in 0.1s
}
```

Buttons: light_attack (red), heavy_attack (dark red), block (blue), special (gold). All semi-transparent (alpha 0.6). Multi-touch supported via separate tracking per touch.

### 7. HUDOverlay

```swift
// HUDOverlay.swift
class HUDOverlay: SKNode {
    private var playerHealthBar: HealthBarNode!
    private var opponentHealthBar: HealthBarNode!
    private var timerNode: SKLabelNode!
    private var playerSpecialMeter: SpecialMeterNode!
    private var opponentSpecialMeter: SpecialMeterNode!
    private var comboCounter: ComboCounterNode!

    func setup(sceneSize: CGSize)
    func updateHealth(player: Double, opponent: Double)  // 0.0-1.0
    func updateTimer(seconds: Int)
    func updateCombo(count: Int, damage: Int, position: CGPoint)
    func hideCombo()
    func updateSpecialMeter(player: Double, opponent: Double)
    func showSpecialReady(isPlayer: Bool)
}

class HealthBarNode: SKNode {
    // Gradient fill: green (>50%) → yellow (25-50%) → red (<25%)
    // Ghost bar: white bar that trails behind, fades over 0.3s
    private let background: SKShapeNode
    private let fill: SKShapeNode
    private let ghost: SKShapeNode
    func setHealth(_ pct: Double, animated: Bool)
}

class SpecialMeterNode: SKNode {
    private let fill: SKShapeNode
    private let readyLabel: SKLabelNode
    func setFill(_ pct: Double)
    func showReady()
}

class ComboCounterNode: SKNode {
    private let countLabel: SKLabelNode
    private let damageLabel: SKLabelNode
    func show(count: Int, damage: Int, at position: CGPoint)
    func fadeOut(duration: TimeInterval = 0.2)
}
```

### 8. VFXManager

```swift
// VFXManager.swift
class VFXManager {
    private weak var scene: SKScene?
    private var emitterPool: [String: [SKEmitterNode]] = [:]
    private let maxActiveEmitters = 8

    init(scene: SKScene)

    func spawnHitSpark(at position: CGPoint, intensity: VFXIntensity)
    // intensity: .normal (single hit), .combo (3+ hits, 50% more particles)

    func screenShake(intensity: CGFloat, duration: TimeInterval = 0.15)
    // Shakes the camera node. Intensity proportional to damage.

    func specialAttackFlash()
    // Full-screen white flash 0.1s, then particle trail

    func slowMotionKO(completion: @escaping () -> Void)
    // Sets scene.speed = 0.3 for 0.5s, then restores and calls completion

    func adaptToPerformance(fps: Double)
    // If fps < 55 for > 0.5s, halve particle birthRates
    // If fps > 58, restore original birthRates

    private func getEmitter(named: String) -> SKEmitterNode
    // Pool: reuse inactive emitters, create new if pool empty
}

enum VFXIntensity { case normal, combo }
```

Emitter .sks files: `hit_spark.sks`, `special_trail.sks`, `ko_burst.sks`. These are SpriteKit particle files in the bundle.

### 9. CameraController

```swift
// CameraController.swift
class CameraController {
    private let camera: SKCameraNode
    private weak var scene: SKScene?
    private var targetScale: CGFloat = 1.0
    private var targetPosition: CGPoint = .zero
    private let minScale: CGFloat = 0.75
    private let maxScale: CGFloat = 1.15
    private var shakeOffset: CGPoint = .zero

    init(scene: SKScene)

    func update(playerPos: CGPoint, opponentPos: CGPoint, sceneSize: CGSize)
    // 1. Midpoint between fighters → targetPosition
    // 2. Distance ratio → targetScale (close=0.85, far=1.15)
    // 3. Clamp to stage bounds
    // 4. Ease-in-out interpolation toward targets
    // 5. Apply shakeOffset

    func zoomForSpecial(attacker: CGPoint, completion: @escaping () -> Void)
    // Zoom to 0.75x on attacker for 0.4s, then ease back over 0.3s

    func applyShake(intensity: CGFloat, duration: TimeInterval)
    // Random offset per frame, decaying over duration

    private func clampToStageBounds(_ pos: CGPoint, scale: CGFloat, stageWidth: CGFloat, sceneSize: CGSize) -> CGPoint
}
```

### 10. ParallaxBackground

```swift
// ParallaxBackground.swift
class ParallaxBackground: SKNode {
    struct Layer {
        let node: SKSpriteNode
        let speedFactor: CGFloat  // 0.2 (far) to 1.0 (near)
        let duplicate: SKSpriteNode  // for seamless wrapping
    }

    private var layers: [Layer] = []

    init(stageID: String, sceneSize: CGSize)
    // Loads textures: "{stageID}_bg_far", "{stageID}_bg_mid", "{stageID}_bg_near"
    // Creates two copies of each for seamless horizontal tiling

    func update(cameraX: CGFloat)
    // Moves each layer by cameraX * layer.speedFactor
    // Wraps: when a copy scrolls fully off-screen, repositions it

    static func fallbackGradient(sceneSize: CGSize) -> SKNode
    // Solid gradient node used when stage textures are missing
}
```

Stage texture naming: `arena_01_bg_far.png`, `arena_01_bg_mid.png`, `arena_01_bg_near.png`. Loaded from the asset catalog.

### 11. SoundManager

```swift
// SoundManager.swift
class SoundManager {
    static let shared = SoundManager()

    private var soundMap: [String: String] = [:]  // event → filename
    private var audioNodes: [SKAudioNode] = []
    private var bgMusicNode: SKAudioNode?
    private let maxConcurrent = 4

    func configure(mapping: [String: String])
    // e.g. ["attack_hit": "hit_01.wav", "knockdown": "ko_boom.wav"]

    func play(_ event: String, context: [String: Any] = [:])
    // Looks up soundMap[event], creates SKAction.playSoundFileNamed
    // Limits concurrent playback to maxConcurrent

    func playMusic(_ filename: String, in scene: SKScene)
    func stopMusic(fadeDuration: TimeInterval = 0.5)
    func crossfadeMusic(to filename: String, in scene: SKScene, duration: TimeInterval = 0.5)

    // Named hooks matching Requirement 8
    func attackHit(damage: Int) { play("attack_hit", context: ["damage": damage]) }
    func attackBlocked() { play("attack_blocked") }
    func attackWhiff() { play("attack_whiff") }
    func comboHit(count: Int) { play("combo_hit", context: ["count": count]) }
    func specialAttack() { play("special_attack") }
    func knockdown() { play("knockdown") }
    func roundStart() { play("round_start") }
    func roundEnd() { play("round_end") }
    func timerWarning() { play("timer_warning") }
    func menuSelect() { play("menu_select") }
}
```

### 12. BattleScene (Refactored)

The scene becomes an orchestrator. All logic is delegated to subsystems.

```swift
// BattleScene.swift — refactored
class BattleScene: SKScene {
    weak var battleDelegate: BattleSceneDelegate?

    // Subsystems
    private var player: FighterNode!
    private var opponent: FighterNode!
    private var aiController: AIController!
    private var inputManager: InputManager!
    private var comboSystem: ComboSystem!
    private var hud: HUDOverlay!
    private var vfx: VFXManager!
    private var cameraController: CameraController!
    private var parallax: ParallaxBackground!
    private var sound: SoundManager { SoundManager.shared }

    private var roundTime: TimeInterval = 60
    private var elapsed: TimeInterval = 0
    private var gameOver = false
    private let difficulty: DifficultyLevel

    init(playerStats: PlayerStats, opponentStats: PlayerStats,
         size: CGSize, difficulty: DifficultyLevel = .medium,
         playerAtlas: String = "fighter_default",
         opponentAtlas: String = "fighter_default",
         stageID: String = "arena_01")

    override func didMove(to view: SKView) {
        // 1. Setup camera
        // 2. Setup parallax background
        // 3. Create fighters with sprite atlases
        // 4. Setup input manager
        // 5. Setup HUD
        // 6. Create AI controller
        // 7. Init combo system, VFX manager
        // 8. Start background music
        // 9. Play round_start sound
    }

    override func update(_ currentTime: TimeInterval) {
        // 1. Calculate dt
        // 2. Update timer, check round end
        // 3. inputManager.update() — process input buffer
        // 4. aiController.update(dt:) — CPU decisions
        // 5. comboSystem.update() — check combo window expiry
        // 6. cameraController.update() — reframe
        // 7. parallax.update(cameraX:) — scroll layers
        // 8. vfx.adaptToPerformance(fps:) — adaptive quality
        // 9. hud.updateTimer(), hud.updateHealth(), hud.updateSpecialMeter()
        // 10. Clamp fighter positions
    }

    // Combat resolution
    private func resolveAttack(attacker: FighterNode, defender: FighterNode, type: AttackType) {
        // Check hitbox/hurtbox intersection
        // If blocked: reduced damage, play blocked sound
        // If dodged: miss, play whiff sound
        // If hit: calculate damage via comboSystem, apply to defender
        //   → vfx.spawnHitSpark(), vfx.screenShake()
        //   → sound.attackHit() or sound.comboHit()
        //   → hud.updateCombo(), hud.updateHealth()
        //   → attacker.addSpecialMeter(0.05), defender.addSpecialMeter(0.03)
        // If special: vfx.specialAttackFlash(), cameraController.zoomForSpecial()
        // Check KO
    }

    private func handleKO(loser: FighterNode) {
        gameOver = true
        vfx.slowMotionKO { [weak self] in
            self?.showResult(playerWon: loser != self?.player)
        }
        sound.knockdown()
    }
}
```

### 13. BattleSpriteView Update

```swift
// BattleSpriteView.swift — updated
struct BattleSpriteView: View {
    let playerStats: PlayerStats
    let opponentStats: PlayerStats
    let difficulty: DifficultyLevel
    let playerAtlas: String
    let opponentAtlas: String
    let stageID: String
    let onBattleEnd: (Bool) -> Void

    // Scene creation passes difficulty, atlas names, and stageID
}
```

## Asset Requirements

### Sprite Atlases (per character style)
- Naming: `{style_id}_idle_01..04`, `{style_id}_walk_forward_01..06`, etc.
- Frame size: max 512×512 points
- Format: PNG with transparency
- Packed into Xcode `.atlas` folders or `.spriteatlas` assets

### Stage Backgrounds (per stage)
- Three layers per stage: `{stage_id}_bg_far`, `{stage_id}_bg_mid`, `{stage_id}_bg_near`
- Tileable horizontally
- Recommended width: 2048px per layer

### Particle Effects
- `hit_spark.sks` — short burst, 20-40 particles, 0.1s lifetime
- `special_trail.sks` — trailing particles, 0.5s lifetime
- `ko_burst.sks` — large burst, 50 particles, 0.3s lifetime

### Audio Files
- Hit sounds: `hit_01.wav`, `hit_02.wav` (short, punchy, <0.5s)
- Block sound: `block_01.wav`
- Whiff sound: `whiff_01.wav`
- KO sound: `ko_boom.wav`
- Round start/end: `round_start.wav`, `round_end.wav`
- Timer warning: `timer_tick.wav`
- Background music: `battle_bgm_01.m4a` (loopable)

## Data Flow

```
Touch Input → InputManager → BattleScene
                                ├── Player FighterNode.transition()
                                ├── AIController.onOpponentAction()
                                ├── ComboSystem.registerHit()
                                ├── VFXManager.spawnHitSpark()
                                ├── SoundManager.attackHit()
                                ├── HUDOverlay.updateHealth()
                                └── CameraController.update()
```

## Migration Strategy

1. All new files are additive — no existing file deletions
2. `FighterNode.swift` is refactored in place (SKShapeNode code replaced with SKSpriteNode)
3. `BattleScene.swift` is refactored in place (monolithic logic split into subsystem calls)
4. `BattleSpriteView.swift` gets additional parameters (difficulty, atlas names, stageID)
5. Placeholder/fallback assets ensure the app compiles and runs even before real sprites are added
6. Each subsystem can be developed and tested independently

## Performance Budget

| Resource | Budget |
|----------|--------|
| Frame rate | 60 FPS minimum on iPhone 13 |
| Active emitters | Max 8 simultaneous |
| Texture memory | Max 200 MB during battle |
| Audio channels | Max 4 concurrent SFX + 1 music |
| Sprite atlas frame size | Max 512×512 per frame |
| Combo system overhead | < 0.1ms per frame |
| AI decision time | < 0.5ms per evaluation |
