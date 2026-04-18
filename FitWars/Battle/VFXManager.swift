import SpriteKit

// MARK: - VFX Intensity

/// Controls particle intensity for hit effects.
/// `.combo` produces 50% more particles for 3+ hit combos (Req 4.5).
enum VFXIntensity {
    case normal
    case combo  // 3+ hit combo → 50% more particles
}

// MARK: - VFXManager

/// Manages all visual effects: hit sparks, screen shake, special attack flash,
/// slow-motion KO, and adaptive performance scaling.
/// Uses an emitter pool capped at 8 active emitters (Req 4.6, Req 10.3).
class VFXManager {

    private weak var scene: SKScene?

    // MARK: - Emitter Pool (Task 8.1)

    /// Maximum simultaneous active emitters to maintain 60 FPS.
    private let maxActiveEmitters = 8
    /// Currently active emitters tracked for pool management.
    private var activeEmitters: [SKEmitterNode] = []

    // MARK: - Performance Adaptation (Task 8.5)

    /// Original birth rates keyed by emitter, used to restore after throttling.
    private var originalBirthRates: [SKEmitterNode: CGFloat] = [:]
    /// Whether emitters are currently throttled.
    private var isThrottled = false
    /// Accumulated time that FPS has been below 55.
    private var lowFPSDuration: TimeInterval = 0
    /// Threshold before throttling kicks in (seconds).
    private let lowFPSThreshold: TimeInterval = 0.5

    // MARK: - Screen Shake State (Task 8.2)

    private var shakeRemaining: TimeInterval = 0
    private var shakeDuration: TimeInterval = 0
    private var shakeIntensity: CGFloat = 0

    // MARK: - Init

    init(scene: SKScene) {
        self.scene = scene
    }

    // MARK: - 8.1  Hit Spark

    /// Spawns a hit-spark particle emitter at the contact point.
    /// - Parameters:
    ///   - position: The point of contact in scene coordinates.
    ///   - intensity: `.normal` for single hits, `.combo` for 3+ hit combos (50% more particles).
    func spawnHitSpark(at position: CGPoint, intensity: VFXIntensity) {
        guard let scene else { return }

        // Respect pool cap
        pruneInactiveEmitters()
        guard activeEmitters.count < maxActiveEmitters else { return }

        let emitter = makeHitSparkEmitter()

        // Combo intensity: 50% more particles (Req 4.5)
        if intensity == .combo {
            emitter.particleBirthRate *= 1.5
            emitter.numParticlesToEmit = Int(CGFloat(emitter.numParticlesToEmit) * 1.5)
        }

        emitter.position = position
        emitter.zPosition = 100
        scene.addChild(emitter)
        trackEmitter(emitter)

        // Auto-remove after lifetime
        let lifetime = Double(emitter.particleLifetime + emitter.particleLifetimeRange)
        let remove = SKAction.sequence([
            SKAction.wait(forDuration: lifetime + 0.1),
            SKAction.removeFromParent()
        ])
        emitter.run(remove) { [weak self] in
            self?.untrackEmitter(emitter)
        }
    }

    // MARK: - 8.2  Screen Shake

    /// Applies a decaying screen shake to the camera node.
    /// - Parameters:
    ///   - intensity: Shake magnitude in points, proportional to damage dealt.
    ///   - duration: Total shake duration (default 0.15s per Req 4.2).
    func screenShake(intensity: CGFloat, duration: TimeInterval = 0.15) {
        shakeIntensity = intensity
        shakeDuration = duration
        shakeRemaining = duration
    }

    /// Called each frame to apply the current shake offset to the camera.
    /// BattleScene should call this from its `update(_:)` loop.
    func updateShake(dt: TimeInterval) {
        guard let camera = scene?.camera, shakeRemaining > 0 else { return }

        shakeRemaining -= dt
        if shakeRemaining <= 0 {
            // Reset camera to no offset
            shakeRemaining = 0
            camera.position.x -= lastShakeOffset.x
            camera.position.y -= lastShakeOffset.y
            lastShakeOffset = .zero
            return
        }

        // Remove previous offset
        camera.position.x -= lastShakeOffset.x
        camera.position.y -= lastShakeOffset.y

        // Decay factor: linear falloff
        let decay = CGFloat(shakeRemaining / shakeDuration)
        let magnitude = shakeIntensity * decay
        let offsetX = CGFloat.random(in: -magnitude...magnitude)
        let offsetY = CGFloat.random(in: -magnitude...magnitude)

        lastShakeOffset = CGPoint(x: offsetX, y: offsetY)
        camera.position.x += offsetX
        camera.position.y += offsetY
    }

    private var lastShakeOffset: CGPoint = .zero

    // MARK: - 8.3  Special Attack Flash

    /// Plays a full-screen white flash (alpha 0.8 → 0 over 0.1s) followed by
    /// a particle trail on the attacker (Req 4.3).
    func specialAttackFlash(attackerPosition: CGPoint? = nil) {
        guard let scene else { return }

        // Full-screen white overlay
        let flash = SKSpriteNode(color: .white, size: scene.size)
        flash.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        flash.zPosition = 200
        flash.alpha = 0.8
        scene.addChild(flash)

        let fadeOut = SKAction.sequence([
            SKAction.fadeAlpha(to: 0, duration: 0.1),
            SKAction.removeFromParent()
        ])
        flash.run(fadeOut)

        // Particle trail on attacker
        if let pos = attackerPosition {
            pruneInactiveEmitters()
            guard activeEmitters.count < maxActiveEmitters else { return }

            let trail = makeSpecialTrailEmitter()
            trail.position = pos
            trail.zPosition = 100
            scene.addChild(trail)
            trackEmitter(trail)

            let lifetime = Double(trail.particleLifetime + trail.particleLifetimeRange) + 0.5
            let remove = SKAction.sequence([
                SKAction.wait(forDuration: lifetime),
                SKAction.removeFromParent()
            ])
            trail.run(remove) { [weak self] in
                self?.untrackEmitter(trail)
            }
        }
    }

    // MARK: - 8.4  Slow-Motion KO

    /// Sets scene speed to 0.3× for 0.5s, then restores to 1.0× and calls completion (Req 4.4).
    func slowMotionKO(completion: @escaping () -> Void) {
        guard let scene else {
            completion()
            return
        }

        scene.speed = 0.3

        // We use a real-time dispatch because SKAction timing is affected by scene.speed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak scene] in
            scene?.speed = 1.0
            completion()
        }
    }

    // MARK: - 8.5  Adaptive Performance

    /// Adapts particle quality based on current FPS (Req 10.3).
    /// - If FPS < 55 for > 0.5s → halve all active emitter birthRates.
    /// - If FPS > 58 → restore original birthRates.
    func adaptToPerformance(fps: Double, dt: TimeInterval) {
        if fps < 55 {
            lowFPSDuration += dt
            if lowFPSDuration > lowFPSThreshold && !isThrottled {
                throttleEmitters()
            }
        } else {
            lowFPSDuration = 0
            if fps > 58 && isThrottled {
                restoreEmitters()
            }
        }
    }

    private func throttleEmitters() {
        isThrottled = true
        for emitter in activeEmitters {
            if originalBirthRates[emitter] == nil {
                originalBirthRates[emitter] = emitter.particleBirthRate
            }
            emitter.particleBirthRate *= 0.5
        }
    }

    private func restoreEmitters() {
        isThrottled = false
        for emitter in activeEmitters {
            if let original = originalBirthRates[emitter] {
                emitter.particleBirthRate = original
            }
        }
        originalBirthRates.removeAll()
    }

    // MARK: - Emitter Pool Helpers

    private func trackEmitter(_ emitter: SKEmitterNode) {
        activeEmitters.append(emitter)
        // Store original birth rate for performance adaptation
        if isThrottled {
            originalBirthRates[emitter] = emitter.particleBirthRate
            emitter.particleBirthRate *= 0.5
        }
    }

    private func untrackEmitter(_ emitter: SKEmitterNode) {
        activeEmitters.removeAll { $0 === emitter }
        originalBirthRates.removeValue(forKey: emitter)
    }

    private func pruneInactiveEmitters() {
        activeEmitters.removeAll { $0.parent == nil }
    }


    // MARK: - 8.6  Programmatic Emitter Factories

    // These create emitters in code so VFXManager works immediately without
    // Xcode-generated .sks files. If .sks files are added later, swap these
    // factory calls for `SKEmitterNode(fileNamed:)`.

    /// Hit spark: 30 particles, 0.1s lifetime, white/yellow, burst mode.
    private func makeHitSparkEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "spark") // falls back to default if missing
        emitter.particleBirthRate = 300          // high rate for burst feel
        emitter.numParticlesToEmit = 30          // total particles in burst
        emitter.particleLifetime = 0.1
        emitter.particleLifetimeRange = 0.05
        emitter.emissionAngleRange = .pi * 2     // emit in all directions
        emitter.particleSpeed = 200
        emitter.particleSpeedRange = 100
        emitter.particleAlphaSpeed = -4.0        // fade out quickly
        emitter.particleScale = 0.15
        emitter.particleScaleRange = 0.1
        emitter.particleScaleSpeed = -0.3
        emitter.particleColor = .white
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add

        // White → yellow color ramp via sequence
        let colorSequence = SKKeyframeSequence(
            keyframeValues: [SKColor.white, SKColor.yellow, SKColor.clear],
            times: [0, 0.5, 1.0]
        )
        emitter.particleColorSequence = colorSequence

        return emitter
    }

    /// Special trail: 20 particles, 0.5s lifetime, blue/white, continuous.
    private func makeSpecialTrailEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "spark")
        emitter.particleBirthRate = 40           // continuous stream
        emitter.numParticlesToEmit = 20
        emitter.particleLifetime = 0.5
        emitter.particleLifetimeRange = 0.15
        emitter.emissionAngleRange = .pi * 0.5   // narrower cone
        emitter.particleSpeed = 80
        emitter.particleSpeedRange = 40
        emitter.particleAlphaSpeed = -1.5
        emitter.particleScale = 0.2
        emitter.particleScaleRange = 0.1
        emitter.particleScaleSpeed = -0.15
        emitter.particleColor = .cyan
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add

        let colorSequence = SKKeyframeSequence(
            keyframeValues: [SKColor.white, SKColor.cyan, SKColor.blue, SKColor.clear],
            times: [0, 0.3, 0.7, 1.0]
        )
        emitter.particleColorSequence = colorSequence

        return emitter
    }

    /// KO burst: 50 particles, 0.3s lifetime, orange/red, burst mode.
    func makeKOBurstEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "spark")
        emitter.particleBirthRate = 500          // high rate for dramatic burst
        emitter.numParticlesToEmit = 50
        emitter.particleLifetime = 0.3
        emitter.particleLifetimeRange = 0.1
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 250
        emitter.particleSpeedRange = 120
        emitter.particleAlphaSpeed = -2.5
        emitter.particleScale = 0.2
        emitter.particleScaleRange = 0.15
        emitter.particleScaleSpeed = -0.2
        emitter.particleColor = .orange
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add

        let colorSequence = SKKeyframeSequence(
            keyframeValues: [SKColor.white, SKColor.orange, SKColor.red, SKColor.clear],
            times: [0, 0.3, 0.7, 1.0]
        )
        emitter.particleColorSequence = colorSequence

        return emitter
    }

    /// Spawns a KO burst effect at the given position.
    func spawnKOBurst(at position: CGPoint) {
        guard let scene else { return }

        pruneInactiveEmitters()
        guard activeEmitters.count < maxActiveEmitters else { return }

        let emitter = makeKOBurstEmitter()
        emitter.position = position
        emitter.zPosition = 100
        scene.addChild(emitter)
        trackEmitter(emitter)

        let lifetime = Double(emitter.particleLifetime + emitter.particleLifetimeRange)
        let remove = SKAction.sequence([
            SKAction.wait(forDuration: lifetime + 0.1),
            SKAction.removeFromParent()
        ])
        emitter.run(remove) { [weak self] in
            self?.untrackEmitter(emitter)
        }
    }

    // MARK: - Cleanup

    /// Removes all active emitters and resets state. Called on scene dismissal.
    func cleanup() {
        for emitter in activeEmitters {
            emitter.removeFromParent()
        }
        activeEmitters.removeAll()
        originalBirthRates.removeAll()
        isThrottled = false
        lowFPSDuration = 0
        shakeRemaining = 0
        lastShakeOffset = .zero
    }
}
