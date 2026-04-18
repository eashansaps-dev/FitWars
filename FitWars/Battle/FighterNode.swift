import SpriteKit

enum FighterState: String {
    case idle, walkForward, walkBackward
    case lightAttack, heavyAttack, specialAttack
    case blocking, hitStun, knockdown, dodging, victory
}

enum AttackType {
    case light, heavy, special
}

class FighterNode: SKNode {
    let stats: PlayerStats
    let isPlayer: Bool
    var maxHP: Int
    var currentHP: Int
    var state: FighterState = .idle

    /// Special meter gauge, clamped to 0.0–1.0.
    var specialMeter: Double = 0.0

    // Sprite-based rendering
    private let sprite: SKSpriteNode
    private let animator: SpriteAnimator

    // HP bar overlay (kept as simple SKShapeNodes)
    private let hpBar = SKShapeNode()
    private let hpFill = SKShapeNode()

    // MARK: - Init

    init(stats: PlayerStats, isPlayer: Bool, atlasName: String = "fighter_default") {
        self.stats = stats
        self.isPlayer = isPlayer
        self.maxHP = 100 + stats.stamina * 2
        self.currentHP = self.maxHP

        // Create the sprite node sized to roughly match old character proportions
        self.sprite = SKSpriteNode()
        sprite.size = CGSize(width: 128, height: 180)
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.3) // feet-ish anchor

        // Fall back to the default atlas if the requested one is missing from the bundle
        let resolvedAtlas: String
        if SKTextureAtlas(named: atlasName).textureNames.isEmpty {
            print("[FighterNode] ⚠️ Atlas '\(atlasName)' not found — falling back to 'fighter_default'.")
            resolvedAtlas = "fighter_default"
        } else {
            resolvedAtlas = atlasName
        }

        self.animator = SpriteAnimator(sprite: sprite, atlasName: resolvedAtlas)

        super.init()

        addChild(sprite)
        buildHPBar()

        // Flip opponent to face player
        if !isPlayer { xScale = -1 }

        // Start idle animation
        animator.play("idle", loop: true)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - HP Bar

    private func buildHPBar() {
        hpBar.path = CGPath(
            roundedRect: CGRect(x: -25, y: 72, width: 50, height: 6),
            cornerWidth: 3, cornerHeight: 3, transform: nil
        )
        hpBar.fillColor = SKColor.darkGray
        hpBar.strokeColor = .clear
        addChild(hpBar)

        updateHPBar()
        addChild(hpFill)
    }

    private func updateHPBar() {
        let pct = CGFloat(max(currentHP, 0)) / CGFloat(maxHP)
        let w = 48 * pct
        hpFill.path = CGPath(
            roundedRect: CGRect(x: -24, y: 72, width: w, height: 6),
            cornerWidth: 3, cornerHeight: 3, transform: nil
        )
        hpFill.fillColor = pct > 0.5 ? .green : pct > 0.25 ? .yellow : .red
        hpFill.strokeColor = .clear
    }

    // MARK: - State Machine

    /// Transitions the fighter to a new state and plays the corresponding animation.
    func transition(to newState: FighterState) {
        guard newState != state else { return }

        let loops: Bool
        switch newState {
        case .idle, .walkForward, .walkBackward, .blocking:
            loops = true
        case .lightAttack, .heavyAttack, .specialAttack,
             .hitStun, .knockdown, .dodging, .victory:
            loops = false
        }

        state = newState
        animator.play(newState.rawValue, loop: loops)
    }

    // MARK: - Actions

    /// Backward-compatible no-argument attack — defaults to light.
    func attack() {
        attack(type: .light)
    }

    /// Perform an attack of the given type.
    func attack(type: AttackType) {
        switch type {
        case .light:
            guard state == .idle || state == .walkForward || state == .walkBackward else { return }
            transition(to: .lightAttack)

            let dir: CGFloat = isPlayer ? 1 : -1
            let punch = SKAction.sequence([
                SKAction.moveBy(x: 30 * dir, y: 0, duration: 0.08),
                SKAction.moveBy(x: -30 * dir, y: 0, duration: 0.12)
            ])
            run(punch) { [weak self] in self?.transition(to: .idle) }

        case .heavy:
            guard state == .idle || state == .walkForward || state == .walkBackward else { return }
            transition(to: .heavyAttack)

            let dir: CGFloat = isPlayer ? 1 : -1
            let slam = SKAction.sequence([
                SKAction.moveBy(x: 40 * dir, y: 0, duration: 0.12),
                SKAction.moveBy(x: -40 * dir, y: 0, duration: 0.18)
            ])
            run(slam) { [weak self] in self?.transition(to: .idle) }

        case .special:
            guard consumeSpecialMeter() else { return }
            transition(to: .specialAttack)

            let dir: CGFloat = isPlayer ? 1 : -1
            let rush = SKAction.sequence([
                SKAction.moveBy(x: 60 * dir, y: 0, duration: 0.15),
                SKAction.moveBy(x: -60 * dir, y: 0, duration: 0.25)
            ])
            run(rush) { [weak self] in self?.transition(to: .idle) }
        }
    }

    func block() {
        guard state == .idle else { return }
        transition(to: .blocking)

        run(SKAction.wait(forDuration: 0.5)) { [weak self] in
            self?.transition(to: .idle)
        }
    }

    func dodge() {
        guard state == .idle else { return }
        transition(to: .dodging)

        let dir: CGFloat = isPlayer ? -1 : 1
        let dodge = SKAction.sequence([
            SKAction.moveBy(x: 50 * dir, y: 0, duration: 0.1),
            SKAction.wait(forDuration: 0.15),
            SKAction.moveBy(x: -50 * dir, y: 0, duration: 0.15)
        ])
        run(dodge) { [weak self] in self?.transition(to: .idle) }
    }

    func takeHit(damage: Int) {
        let prev = state
        transition(to: .hitStun)
        currentHP = max(currentHP - damage, 0)
        updateHPBar()

        // Flash the sprite red
        let flash = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.8, duration: 0.05),
            SKAction.wait(forDuration: 0.1),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.1)
        ])
        sprite.run(flash)

        let knockback: CGFloat = isPlayer ? -8 : 8
        run(SKAction.sequence([
            SKAction.moveBy(x: knockback, y: 0, duration: 0.05),
            SKAction.moveBy(x: -knockback, y: 0, duration: 0.1)
        ])) { [weak self] in
            self?.transition(to: prev == .blocking ? .blocking : .idle)
        }
    }

    func moveHorizontal(_ dx: CGFloat) {
        guard state == .idle || state == .blocking else { return }
        let speed = 2.0 + Double(stats.speed) * 0.03
        position.x += dx * CGFloat(speed)

        // Play walk animation while moving (only when idle)
        if state == .idle {
            let walkState: FighterState = dx > 0 ? .walkForward : .walkBackward
            // Flip walk direction for opponent
            let resolvedState: FighterState
            if isPlayer {
                resolvedState = walkState
            } else {
                resolvedState = dx > 0 ? .walkBackward : .walkForward
            }
            transition(to: resolvedState)
        }
    }

    // MARK: - Special Meter

    /// Adds to the special meter, clamped to 0.0–1.0.
    func addSpecialMeter(_ amount: Double) {
        specialMeter = min(specialMeter + amount, 1.0)
    }

    /// Attempts to consume the full special meter. Returns `true` if the meter was full
    /// and has been reset to 0; returns `false` (and does nothing) if below 1.0.
    @discardableResult
    func consumeSpecialMeter() -> Bool {
        guard specialMeter >= 1.0 else { return false }
        specialMeter = 0.0
        return true
    }

    // MARK: - Computed Properties

    var isAlive: Bool { currentHP > 0 }

    var attackDamage: Int {
        let base = 8 + stats.strength / 3
        let variance = Int.random(in: -2...2)
        return max(base + variance, 1)
    }

    // MARK: - Hitbox / Hurtbox

    /// The attack hitbox rect in scene coordinates, active during attack states.
    var attackHitbox: CGRect {
        let dir: CGFloat = isPlayer ? 1 : -1
        switch state {
        case .lightAttack:
            return CGRect(x: position.x + (20 * dir), y: position.y - 20, width: 30, height: 50)
        case .heavyAttack:
            return CGRect(x: position.x + (15 * dir), y: position.y - 25, width: 40, height: 60)
        case .specialAttack:
            return CGRect(x: position.x + (10 * dir), y: position.y - 30, width: 55, height: 70)
        default:
            return .zero
        }
    }

    /// The body hurtbox rect in scene coordinates, always active.
    var bodyHurtbox: CGRect {
        CGRect(x: position.x - 20, y: position.y - 30, width: 40, height: 60)
    }

    // Backward-compatible aliases so BattleScene doesn't break until Task 12 refactor.
    var hitBox: CGRect { attackHitbox }
    var bodyBox: CGRect { bodyHurtbox }
}
