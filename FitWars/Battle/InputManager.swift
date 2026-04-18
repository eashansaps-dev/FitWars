import SpriteKit
import UIKit

// MARK: - VirtualJoystick

/// On-screen joystick with a base ring and draggable thumb circle.
/// Reports a normalized direction vector while the user drags.
class VirtualJoystick: SKNode {

    private let base: SKShapeNode
    private let thumb: SKShapeNode
    let radius: CGFloat = 50

    /// Normalized direction vector (magnitude 0–1).
    private(set) var direction: CGVector = .zero

    override init() {
        // Outer ring
        base = SKShapeNode(circleOfRadius: 50)
        base.strokeColor = SKColor.white.withAlphaComponent(0.4)
        base.fillColor = SKColor.white.withAlphaComponent(0.1)
        base.lineWidth = 2

        // Inner thumb
        thumb = SKShapeNode(circleOfRadius: 18)
        thumb.fillColor = SKColor.white.withAlphaComponent(0.5)
        thumb.strokeColor = SKColor.white.withAlphaComponent(0.7)
        thumb.lineWidth = 1

        super.init()

        addChild(base)
        addChild(thumb)
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Update thumb position based on a touch point in the joystick's parent coordinate space.
    func handleTouch(at point: CGPoint) {
        let delta = CGVector(dx: point.x - position.x, dy: point.y - position.y)
        let distance = hypot(delta.dx, delta.dy)

        if distance <= radius {
            thumb.position = CGPoint(x: delta.dx, y: delta.dy)
        } else {
            // Clamp to radius
            let scale = radius / distance
            thumb.position = CGPoint(x: delta.dx * scale, y: delta.dy * scale)
        }

        // Normalize
        let clampedDist = min(distance, radius)
        if clampedDist > 0 {
            direction = CGVector(dx: delta.dx / distance, dy: delta.dy / distance)
        } else {
            direction = .zero
        }
    }

    /// Animate thumb back to center over 0.1s and zero out direction.
    func handleRelease() {
        direction = .zero
        thumb.run(SKAction.move(to: .zero, duration: 0.1))
    }
}


// MARK: - InputManager

/// Manages on-screen controls: virtual joystick (left) and action buttons (right).
/// Supports multi-touch with separate tracking per finger.
/// Includes a directional input buffer for special move detection.
class InputManager: SKNode {

    // MARK: - Callbacks

    /// Fires each frame with the current normalized joystick direction.
    var onMove: ((CGVector) -> Void)?
    /// Fires when an attack button is tapped.
    var onAttack: ((AttackType) -> Void)?
    /// Fires when the block button is tapped.
    var onBlock: (() -> Void)?
    /// Fires when a special move input sequence is detected and meter is full.
    var onSpecial: (() -> Void)?

    /// External check — set by BattleScene so InputManager can query special meter status.
    var isSpecialMeterFull: (() -> Bool)?

    // MARK: - Sub-nodes

    private let joystick = VirtualJoystick()
    private var actionButtons: [String: SKShapeNode] = [:]

    // MARK: - Multi-touch tracking

    /// Maps each active UITouch to the control element it's interacting with.
    private var touchMap: [UITouch: String] = [:]  // "joystick" or button name

    // MARK: - Haptics

    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)

    // MARK: - Special move input buffer

    private var inputBuffer: [(direction: CGVector, time: TimeInterval)] = []
    private let bufferWindow: TimeInterval = 0.5

    // MARK: - Scene size (set during setup)

    private var sceneSize: CGSize = .zero

    // MARK: - Init

    override init() {
        super.init()
        isUserInteractionEnabled = true
        hapticGenerator.prepare()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    /// Call once after adding to the scene. Positions joystick and buttons based on scene size.
    func setup(sceneSize: CGSize) {
        self.sceneSize = sceneSize

        // Joystick — bottom-left area
        joystick.position = CGPoint(x: 80, y: sceneSize.height * 0.14)
        addChild(joystick)

        // Action buttons — bottom-right area
        let btnRadius: CGFloat = 28
        let rightBase = sceneSize.width - 60
        let btnY = sceneSize.height * 0.14

        createButton(name: "light_attack", label: "👊", color: .systemRed,
                     position: CGPoint(x: rightBase, y: btnY), radius: btnRadius)
        createButton(name: "heavy_attack", label: "💥", color: SKColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0),
                     position: CGPoint(x: rightBase - 70, y: btnY), radius: btnRadius)
        createButton(name: "block", label: "🛡", color: .systemBlue,
                     position: CGPoint(x: rightBase - 140, y: btnY), radius: btnRadius)
        createButton(name: "special", label: "⚡", color: SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0),
                     position: CGPoint(x: rightBase - 70, y: btnY + 65), radius: btnRadius)
    }

    private func createButton(name: String, label: String, color: SKColor, position: CGPoint, radius: CGFloat) {
        let btn = SKShapeNode(circleOfRadius: radius)
        btn.position = position
        btn.fillColor = color.withAlphaComponent(0.6)
        btn.strokeColor = color
        btn.lineWidth = 2
        btn.name = name
        btn.alpha = 0.6

        let text = SKLabelNode(text: label)
        text.fontSize = 22
        text.verticalAlignmentMode = .center
        text.horizontalAlignmentMode = .center
        text.name = name
        btn.addChild(text)

        actionButtons[name] = btn
        addChild(btn)
    }

    // MARK: - Touch Handling (multi-touch)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: self)
            routeTouch(touch, at: loc, phase: .began)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: self)
            routeTouch(touch, at: loc, phase: .moved)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            releaseTouch(touch)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            releaseTouch(touch)
        }
    }

    private func routeTouch(_ touch: UITouch, at point: CGPoint, phase: UITouch.Phase) {
        let isLeftSide = point.x < sceneSize.width * 0.4

        if phase == .began {
            if isLeftSide {
                // Joystick
                touchMap[touch] = "joystick"
                joystick.handleTouch(at: point)
                recordDirectionalInput(joystick.direction)
            } else {
                // Check buttons
                if let buttonName = hitTestButton(at: point) {
                    touchMap[touch] = buttonName
                    hapticGenerator.impactOccurred()
                    handleButtonPress(buttonName)
                }
            }
        } else if phase == .moved {
            if let tracked = touchMap[touch] {
                if tracked == "joystick" {
                    joystick.handleTouch(at: point)
                    recordDirectionalInput(joystick.direction)
                }
                // Buttons don't respond to drag — only initial tap
            }
        }
    }

    private func releaseTouch(_ touch: UITouch) {
        if let tracked = touchMap[touch], tracked == "joystick" {
            joystick.handleRelease()
        }
        touchMap.removeValue(forKey: touch)
    }

    private func hitTestButton(at point: CGPoint) -> String? {
        // Check each button — use a generous hit area (radius + padding)
        for (name, btn) in actionButtons {
            let dist = hypot(point.x - btn.position.x, point.y - btn.position.y)
            if dist <= 38 { // 28pt radius + 10pt padding
                return name
            }
        }
        return nil
    }

    private func handleButtonPress(_ name: String) {
        switch name {
        case "light_attack":
            if checkSpecialInput(attackType: .light) { return }
            onAttack?(.light)
        case "heavy_attack":
            if checkSpecialInput(attackType: .heavy) { return }
            onAttack?(.heavy)
        case "block":
            onBlock?()
        case "special":
            // Direct special button — only fires if meter is full
            if isSpecialMeterFull?() == true {
                onSpecial?()
            } else {
                onAttack?(.heavy)
            }
        default:
            break
        }
    }

    // MARK: - Special Move Input Buffer

    /// Records a directional input with the current timestamp.
    private func recordDirectionalInput(_ dir: CGVector) {
        guard abs(dir.dx) > 0.3 || abs(dir.dy) > 0.3 else { return }
        let now = CACurrentMediaTime()
        inputBuffer.append((direction: dir, time: now))
    }

    /// Called each frame to prune stale buffer entries.
    func update(currentTime: TimeInterval) {
        // Report joystick direction
        if joystick.direction != .zero {
            onMove?(joystick.direction)
        }

        // Prune old entries from input buffer
        let cutoff = CACurrentMediaTime() - bufferWindow
        inputBuffer.removeAll { $0.time < cutoff }
    }

    /// Checks if the input buffer contains a forward-forward-attack sequence.
    /// Returns true if special was triggered (and consumed), false otherwise.
    private func checkSpecialInput(attackType: AttackType) -> Bool {
        let now = CACurrentMediaTime()
        let cutoff = now - bufferWindow

        // Get recent forward inputs (dx > 0.3 counts as "forward" for the player)
        let recentForwards = inputBuffer.filter { $0.time >= cutoff && $0.direction.dx > 0.3 }

        // Need at least 2 distinct forward pushes
        // They should be separate gestures — check for at least 2 entries with some time gap
        guard recentForwards.count >= 2 else { return false }

        // Verify the two forward inputs are distinct (at least 0.05s apart)
        let first = recentForwards[0]
        let hasSecond = recentForwards.dropFirst().contains { $0.time - first.time > 0.05 }
        guard hasSecond else { return false }

        // Forward-forward detected + attack button pressed = special move attempt
        if isSpecialMeterFull?() == true {
            // Clear the buffer and fire special
            inputBuffer.removeAll()
            onSpecial?()
            return true
        }

        // Meter not full — treat as regular attack (return false so caller fires onAttack)
        return false
    }
}
