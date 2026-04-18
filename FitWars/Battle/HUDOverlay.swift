import SpriteKit

// MARK: - HealthBarNode

/// A health bar with gradient fill (green→yellow→red) and a ghost damage trail.
///
/// **Validates: Requirements 3.1, 3.2**
class HealthBarNode: SKNode {

    private let barWidth: CGFloat
    private let barHeight: CGFloat = 14

    /// Dark background behind the bar.
    private let background: SKShapeNode
    /// The ghost "damage trail" bar that fades behind the fill.
    private let ghost: SKShapeNode
    /// The actual health fill bar.
    private let fill: SKShapeNode
    /// Thin border around the bar.
    private let border: SKShapeNode

    private var currentPct: Double = 1.0

    init(width: CGFloat) {
        self.barWidth = width

        background = SKShapeNode(rect: CGRect(x: 0, y: 0, width: width, height: 14), cornerRadius: 3)
        background.fillColor = SKColor(white: 0.15, alpha: 0.8)
        background.strokeColor = .clear

        ghost = SKShapeNode(rect: CGRect(x: 0, y: 0, width: width, height: 14), cornerRadius: 3)
        ghost.fillColor = SKColor(white: 0.9, alpha: 0.6)
        ghost.strokeColor = .clear

        fill = SKShapeNode(rect: CGRect(x: 0, y: 0, width: width, height: 14), cornerRadius: 3)
        fill.fillColor = .green
        fill.strokeColor = .clear

        border = SKShapeNode(rect: CGRect(x: 0, y: 0, width: width, height: 14), cornerRadius: 3)
        border.fillColor = .clear
        border.strokeColor = SKColor(white: 0.5, alpha: 0.6)
        border.lineWidth = 1

        super.init()

        addChild(background)
        addChild(ghost)
        addChild(fill)
        addChild(border)
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Updates the health bar to reflect the given percentage (0.0–1.0).
    func setHealth(_ pct: Double, animated: Bool = true) {
        let clamped = min(max(pct, 0), 1)
        let oldPct = currentPct
        currentPct = clamped

        let newWidth = max(barWidth * CGFloat(clamped), 0)

        // Update fill immediately
        fill.path = CGPath(
            roundedRect: CGRect(x: 0, y: 0, width: newWidth, height: barHeight),
            cornerWidth: 3, cornerHeight: 3, transform: nil
        )
        fill.fillColor = colorForPercentage(clamped)

        // Ghost bar: show old width, then fade to new width over 0.3s
        if animated && clamped < oldPct {
            let oldWidth = max(barWidth * CGFloat(oldPct), 0)
            ghost.path = CGPath(
                roundedRect: CGRect(x: 0, y: 0, width: oldWidth, height: barHeight),
                cornerWidth: 3, cornerHeight: 3, transform: nil
            )
            ghost.alpha = 0.6

            ghost.removeAllActions()
            let fadeAction = SKAction.sequence([
                SKAction.wait(forDuration: 0.05),
                SKAction.group([
                    SKAction.fadeAlpha(to: 0, duration: 0.3),
                    SKAction.customAction(withDuration: 0.3) { [weak self] _, elapsed in
                        guard let self else { return }
                        let progress = Double(elapsed / 0.3)
                        let interpWidth = oldWidth + (newWidth - oldWidth) * CGFloat(progress)
                        self.ghost.path = CGPath(
                            roundedRect: CGRect(x: 0, y: 0, width: max(interpWidth, 0), height: self.barHeight),
                            cornerWidth: 3, cornerHeight: 3, transform: nil
                        )
                    }
                ])
            ])
            ghost.run(fadeAction)
        } else {
            ghost.path = CGPath(
                roundedRect: CGRect(x: 0, y: 0, width: newWidth, height: barHeight),
                cornerWidth: 3, cornerHeight: 3, transform: nil
            )
            ghost.alpha = 0
        }
    }

    /// Returns a gradient-style color: green (>50%), yellow (25–50%), red (<25%).
    private func colorForPercentage(_ pct: Double) -> SKColor {
        if pct > 0.5 {
            // Green to yellow: interpolate
            let t = (pct - 0.5) / 0.5 // 1.0 at 100%, 0.0 at 50%
            return SKColor(
                red: CGFloat(1.0 - t),
                green: CGFloat(0.5 + 0.5 * t),
                blue: 0,
                alpha: 1
            )
        } else if pct > 0.25 {
            // Yellow to red: interpolate
            let t = (pct - 0.25) / 0.25 // 1.0 at 50%, 0.0 at 25%
            return SKColor(
                red: 1,
                green: CGFloat(0.8 * t),
                blue: 0,
                alpha: 1
            )
        } else {
            return SKColor.red
        }
    }
}


// MARK: - ComboCounterNode

/// Displays the current combo hit count and accumulated damage near the attacking fighter.
///
/// **Validates: Requirements 3.5, 3.6**
class ComboCounterNode: SKNode {

    private let countLabel: SKLabelNode
    private let damageLabel: SKLabelNode

    override init() {
        countLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        countLabel.fontSize = 22
        countLabel.fontColor = .white
        countLabel.verticalAlignmentMode = .center
        countLabel.horizontalAlignmentMode = .center

        damageLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        damageLabel.fontSize = 14
        damageLabel.fontColor = SKColor(red: 1, green: 0.85, blue: 0.3, alpha: 1)
        damageLabel.verticalAlignmentMode = .center
        damageLabel.horizontalAlignmentMode = .center

        super.init()

        damageLabel.position = CGPoint(x: 0, y: -20)
        addChild(countLabel)
        addChild(damageLabel)

        alpha = 0
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Shows the combo counter at the given scene position.
    func show(count: Int, damage: Int, at position: CGPoint) {
        removeAllActions()
        self.position = position
        alpha = 1.0

        countLabel.text = "\(count) HITS"
        damageLabel.text = "\(damage) DMG"

        // Pop-in scale effect
        setScale(1.3)
        run(SKAction.scale(to: 1.0, duration: 0.08))
    }

    /// Fades out the combo counter over the given duration.
    func fadeOut(duration: TimeInterval = 0.2) {
        run(SKAction.fadeAlpha(to: 0, duration: duration))
    }
}

// MARK: - SpecialMeterNode

/// A meter bar that fills from 0–100% and flashes "READY" when full.
///
/// **Validates: Requirements 3.7, 3.8**
class SpecialMeterNode: SKNode {

    private let barWidth: CGFloat
    private let barHeight: CGFloat = 8

    private let background: SKShapeNode
    private let fill: SKShapeNode
    private let border: SKShapeNode
    private let readyLabel: SKLabelNode

    private var isShowingReady = false

    init(width: CGFloat) {
        self.barWidth = width

        background = SKShapeNode(rect: CGRect(x: 0, y: 0, width: width, height: 8), cornerRadius: 2)
        background.fillColor = SKColor(white: 0.1, alpha: 0.8)
        background.strokeColor = .clear

        fill = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 0, height: 8), cornerRadius: 2)
        fill.fillColor = SKColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1)
        fill.strokeColor = .clear

        border = SKShapeNode(rect: CGRect(x: 0, y: 0, width: width, height: 8), cornerRadius: 2)
        border.fillColor = .clear
        border.strokeColor = SKColor(white: 0.4, alpha: 0.5)
        border.lineWidth = 1

        readyLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        readyLabel.fontSize = 10
        readyLabel.fontColor = SKColor(red: 1, green: 0.85, blue: 0, alpha: 1)
        readyLabel.text = "READY"
        readyLabel.verticalAlignmentMode = .center
        readyLabel.horizontalAlignmentMode = .center
        readyLabel.position = CGPoint(x: width / 2, y: 4)
        readyLabel.alpha = 0

        super.init()

        addChild(background)
        addChild(fill)
        addChild(border)
        addChild(readyLabel)
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Updates the meter fill to the given percentage (0.0–1.0).
    func setFill(_ pct: Double) {
        let clamped = min(max(pct, 0), 1)
        let newWidth = barWidth * CGFloat(clamped)

        fill.path = CGPath(
            roundedRect: CGRect(x: 0, y: 0, width: max(newWidth, 0), height: barHeight),
            cornerWidth: 2, cornerHeight: 2, transform: nil
        )

        // Shift color from blue toward gold as meter fills
        let r = 0.2 + 0.8 * clamped
        let g = 0.6 + 0.25 * clamped
        let b = 1.0 - 0.7 * clamped
        fill.fillColor = SKColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)

        // Hide ready label if meter drops below full
        if clamped < 1.0 && isShowingReady {
            readyLabel.removeAllActions()
            readyLabel.alpha = 0
            fill.removeAllActions()
            isShowingReady = false
        }
    }

    /// Flashes the meter bar and shows the "READY" label.
    func showReady() {
        guard !isShowingReady else { return }
        isShowingReady = true

        // Flash the fill bar
        let flash = SKAction.repeatForever(SKAction.sequence([
            SKAction.customAction(withDuration: 0) { node, _ in
                (node as? SKShapeNode)?.fillColor = SKColor(red: 1, green: 0.85, blue: 0, alpha: 1)
            },
            SKAction.wait(forDuration: 0.3),
            SKAction.customAction(withDuration: 0) { node, _ in
                (node as? SKShapeNode)?.fillColor = SKColor(red: 1, green: 1, blue: 0.5, alpha: 1)
            },
            SKAction.wait(forDuration: 0.3)
        ]))
        fill.run(flash, withKey: "flash")

        // Show READY label with pulse
        readyLabel.alpha = 1
        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.25),
            SKAction.scale(to: 1.0, duration: 0.25)
        ]))
        readyLabel.run(pulse, withKey: "pulse")
    }
}


// MARK: - HUDOverlay

/// The heads-up display overlay for the battle scene.
/// Contains health bars, round timer, combo counter, and special meters.
///
/// **Validates: Requirements 3.1–3.8**
class HUDOverlay: SKNode {

    private var playerHealthBar: HealthBarNode!
    private var opponentHealthBar: HealthBarNode!
    private var timerLabel: SKLabelNode!
    private var playerSpecialMeter: SpecialMeterNode!
    private var opponentSpecialMeter: SpecialMeterNode!
    private var comboCounter: ComboCounterNode!

    /// Tracks the last timer value to detect second boundaries for pulsing.
    private var lastTimerSeconds: Int = -1

    // MARK: - Setup

    /// Lays out all HUD elements relative to the given scene size.
    func setup(sceneSize: CGSize) {
        let margin: CGFloat = 16
        let barWidth: CGFloat = (sceneSize.width - 80) / 2  // two bars with gap
        let topY = sceneSize.height - 40

        // --- Player health bar (top-left) ---
        playerHealthBar = HealthBarNode(width: barWidth)
        playerHealthBar.position = CGPoint(x: margin, y: topY)
        addChild(playerHealthBar)

        // --- Opponent health bar (top-right, mirrored) ---
        opponentHealthBar = HealthBarNode(width: barWidth)
        opponentHealthBar.position = CGPoint(x: sceneSize.width - margin - barWidth, y: topY)
        addChild(opponentHealthBar)

        // --- Player label ---
        let youLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        youLabel.text = "YOU"
        youLabel.fontSize = 10
        youLabel.fontColor = SKColor(white: 0.8, alpha: 0.8)
        youLabel.horizontalAlignmentMode = .left
        youLabel.position = CGPoint(x: margin, y: topY + 16)
        addChild(youLabel)

        // --- Opponent label ---
        let cpuLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        cpuLabel.text = "CPU"
        cpuLabel.fontSize = 10
        cpuLabel.fontColor = SKColor(white: 0.8, alpha: 0.8)
        cpuLabel.horizontalAlignmentMode = .right
        cpuLabel.position = CGPoint(x: sceneSize.width - margin, y: topY + 16)
        addChild(cpuLabel)

        // --- Timer (centered top) ---
        timerLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        timerLabel.fontSize = 24
        timerLabel.fontColor = .white
        timerLabel.verticalAlignmentMode = .center
        timerLabel.horizontalAlignmentMode = .center
        timerLabel.position = CGPoint(x: sceneSize.width / 2, y: topY + 7)
        addChild(timerLabel)

        // --- Special meters (below health bars) ---
        let meterY = topY - 14

        playerSpecialMeter = SpecialMeterNode(width: barWidth)
        playerSpecialMeter.position = CGPoint(x: margin, y: meterY)
        addChild(playerSpecialMeter)

        opponentSpecialMeter = SpecialMeterNode(width: barWidth)
        opponentSpecialMeter.position = CGPoint(x: sceneSize.width - margin - barWidth, y: meterY)
        addChild(opponentSpecialMeter)

        // --- Combo counter (starts hidden) ---
        comboCounter = ComboCounterNode()
        addChild(comboCounter)
    }

    // MARK: - Health

    /// Updates both health bars. Values are 0.0–1.0.
    func updateHealth(player: Double, opponent: Double) {
        playerHealthBar.setHealth(player)
        opponentHealthBar.setHealth(opponent)
    }

    // MARK: - Timer

    /// Updates the round timer display. Triggers red color and pulse when ≤10s.
    ///
    /// **Validates: Requirements 3.3, 3.4**
    func updateTimer(seconds: Int) {
        let clamped = max(seconds, 0)
        timerLabel.text = "\(clamped)"

        if clamped <= 10 {
            timerLabel.fontColor = .red

            // Pulse at each new second boundary
            if clamped != lastTimerSeconds {
                timerLabel.removeAction(forKey: "pulse")
                let pulse = SKAction.sequence([
                    SKAction.scale(to: 1.3, duration: 0.12),
                    SKAction.scale(to: 1.0, duration: 0.12)
                ])
                timerLabel.run(pulse, withKey: "pulse")
            }
        } else {
            timerLabel.fontColor = .white
        }

        lastTimerSeconds = clamped
    }

    // MARK: - Combo

    /// Shows or updates the combo counter at the given position.
    func updateCombo(count: Int, damage: Int, position: CGPoint) {
        comboCounter.show(count: count, damage: damage, at: position)
    }

    /// Fades out the combo counter over 0.2s.
    func hideCombo() {
        comboCounter.fadeOut(duration: 0.2)
    }

    // MARK: - Special Meter

    /// Updates both special meter fills. Values are 0.0–1.0.
    func updateSpecialMeter(player: Double, opponent: Double) {
        playerSpecialMeter.setFill(player)
        opponentSpecialMeter.setFill(opponent)
    }

    /// Triggers the flash + "READY" label on the specified fighter's meter.
    func showSpecialReady(isPlayer: Bool) {
        if isPlayer {
            playerSpecialMeter.showReady()
        } else {
            opponentSpecialMeter.showReady()
        }
    }
}
