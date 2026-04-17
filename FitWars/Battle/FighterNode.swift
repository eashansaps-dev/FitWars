import SpriteKit

enum FighterState {
    case idle, attacking, blocking, hit, dodging
}

class FighterNode: SKNode {
    let stats: PlayerStats
    let isPlayer: Bool
    var maxHP: Int
    var currentHP: Int
    var state: FighterState = .idle

    private let body = SKShapeNode()
    private let head = SKShapeNode()
    private let leftArm = SKShapeNode()
    private let rightArm = SKShapeNode()
    private let leftLeg = SKShapeNode()
    private let rightLeg = SKShapeNode()
    private let hpBar = SKShapeNode()
    private let hpFill = SKShapeNode()

    private var skinColor: SKColor
    private var outfitColor: SKColor

    init(stats: PlayerStats, isPlayer: Bool, skinColor: SKColor = .brown, outfitColor: SKColor = .orange) {
        self.stats = stats
        self.isPlayer = isPlayer
        self.maxHP = 100 + stats.stamina * 2
        self.currentHP = self.maxHP
        self.skinColor = skinColor
        self.outfitColor = outfitColor
        super.init()
        buildBody()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build

    private func buildBody() {
        let dir: CGFloat = isPlayer ? 1 : -1

        // Body/torso
        body.path = CGPath(roundedRect: CGRect(x: -20, y: -30, width: 40, height: 60), cornerWidth: 6, cornerHeight: 6, transform: nil)
        body.fillColor = outfitColor
        body.strokeColor = .clear
        addChild(body)

        // Head
        head.path = CGPath(ellipseIn: CGRect(x: -16, y: 30, width: 32, height: 36), transform: nil)
        head.fillColor = skinColor
        head.strokeColor = .clear
        addChild(head)

        // Eyes
        let eyeL = SKShapeNode(ellipseOf: CGSize(width: 5, height: 4))
        eyeL.position = CGPoint(x: -6 * dir, y: 46)
        eyeL.fillColor = .white
        eyeL.strokeColor = .clear
        let pupilL = SKShapeNode(circleOfRadius: 2)
        pupilL.fillColor = .black
        pupilL.strokeColor = .clear
        eyeL.addChild(pupilL)
        addChild(eyeL)

        let eyeR = SKShapeNode(ellipseOf: CGSize(width: 5, height: 4))
        eyeR.position = CGPoint(x: 6 * dir, y: 46)
        eyeR.fillColor = .white
        eyeR.strokeColor = .clear
        let pupilR = SKShapeNode(circleOfRadius: 2)
        pupilR.fillColor = .black
        pupilR.strokeColor = .clear
        eyeR.addChild(pupilR)
        addChild(eyeR)

        // Arms
        leftArm.path = CGPath(roundedRect: CGRect(x: 0, y: -25, width: 12, height: 45), cornerWidth: 4, cornerHeight: 4, transform: nil)
        leftArm.fillColor = outfitColor.withAlphaComponent(0.9)
        leftArm.strokeColor = .clear
        leftArm.position = CGPoint(x: -26, y: 0)
        addChild(leftArm)

        rightArm.path = CGPath(roundedRect: CGRect(x: 0, y: -25, width: 12, height: 45), cornerWidth: 4, cornerHeight: 4, transform: nil)
        rightArm.fillColor = outfitColor.withAlphaComponent(0.9)
        rightArm.strokeColor = .clear
        rightArm.position = CGPoint(x: 14, y: 0)
        addChild(rightArm)

        // Legs
        leftLeg.path = CGPath(roundedRect: CGRect(x: -14, y: -70, width: 14, height: 42), cornerWidth: 3, cornerHeight: 3, transform: nil)
        leftLeg.fillColor = outfitColor.withAlphaComponent(0.8)
        leftLeg.strokeColor = .clear
        addChild(leftLeg)

        rightLeg.path = CGPath(roundedRect: CGRect(x: 2, y: -70, width: 14, height: 42), cornerWidth: 3, cornerHeight: 3, transform: nil)
        rightLeg.fillColor = outfitColor.withAlphaComponent(0.8)
        rightLeg.strokeColor = .clear
        addChild(rightLeg)

        // HP bar background
        hpBar.path = CGPath(roundedRect: CGRect(x: -25, y: 72, width: 50, height: 6), cornerWidth: 3, cornerHeight: 3, transform: nil)
        hpBar.fillColor = SKColor.darkGray
        hpBar.strokeColor = .clear
        addChild(hpBar)

        // HP bar fill
        updateHPBar()
        addChild(hpFill)

        // Flip opponent to face player
        if !isPlayer { xScale = -1 }
    }

    private func updateHPBar() {
        let pct = CGFloat(max(currentHP, 0)) / CGFloat(maxHP)
        let w = 48 * pct
        hpFill.path = CGPath(roundedRect: CGRect(x: -24, y: 72, width: w, height: 6), cornerWidth: 3, cornerHeight: 3, transform: nil)
        hpFill.fillColor = pct > 0.5 ? .green : pct > 0.25 ? .yellow : .red
        hpFill.strokeColor = .clear
    }

    // MARK: - Actions

    func attack() {
        guard state == .idle else { return }
        state = .attacking
        let dir: CGFloat = isPlayer ? 1 : -1
        let punch = SKAction.sequence([
            SKAction.moveBy(x: 30 * dir, y: 0, duration: 0.08),
            SKAction.moveBy(x: -30 * dir, y: 0, duration: 0.12)
        ])
        rightArm.run(SKAction.sequence([
            SKAction.moveBy(x: 20 * dir, y: 10, duration: 0.08),
            SKAction.moveBy(x: -20 * dir, y: -10, duration: 0.12)
        ]))
        run(punch) { [weak self] in self?.state = .idle }
    }

    func block() {
        guard state == .idle else { return }
        state = .blocking
        leftArm.run(SKAction.moveBy(x: 10, y: 15, duration: 0.05))
        rightArm.run(SKAction.moveBy(x: -10, y: 15, duration: 0.05))
        run(SKAction.wait(forDuration: 0.5)) { [weak self] in
            self?.leftArm.run(SKAction.moveBy(x: -10, y: -15, duration: 0.1))
            self?.rightArm.run(SKAction.moveBy(x: 10, y: -15, duration: 0.1))
            self?.state = .idle
        }
    }

    func dodge() {
        guard state == .idle else { return }
        state = .dodging
        let dir: CGFloat = isPlayer ? -1 : 1
        let dodge = SKAction.sequence([
            SKAction.moveBy(x: 50 * dir, y: 0, duration: 0.1),
            SKAction.wait(forDuration: 0.15),
            SKAction.moveBy(x: -50 * dir, y: 0, duration: 0.15)
        ])
        run(dodge) { [weak self] in self?.state = .idle }
    }

    func takeHit(damage: Int) {
        let prev = state
        state = .hit
        currentHP = max(currentHP - damage, 0)
        updateHPBar()

        let flash = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.8, duration: 0.05),
            SKAction.wait(forDuration: 0.1),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.1)
        ])
        body.run(flash)

        let knockback: CGFloat = isPlayer ? -8 : 8
        run(SKAction.sequence([
            SKAction.moveBy(x: knockback, y: 0, duration: 0.05),
            SKAction.moveBy(x: -knockback, y: 0, duration: 0.1)
        ])) { [weak self] in
            self?.state = prev == .blocking ? .blocking : .idle
        }
    }

    func moveHorizontal(_ dx: CGFloat) {
        guard state == .idle || state == .blocking else { return }
        let speed = 2.0 + Double(stats.speed) * 0.03
        position.x += dx * CGFloat(speed)
    }

    var isAlive: Bool { currentHP > 0 }

    var attackDamage: Int {
        let base = 8 + stats.strength / 3
        let variance = Int.random(in: -2...2)
        return max(base + variance, 1)
    }

    var hitBox: CGRect {
        let dir: CGFloat = isPlayer ? 1 : -1
        return CGRect(x: position.x + (20 * dir), y: position.y - 20, width: 30, height: 50)
    }

    var bodyBox: CGRect {
        CGRect(x: position.x - 20, y: position.y - 30, width: 40, height: 60)
    }
}
