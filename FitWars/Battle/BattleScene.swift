import SpriteKit

protocol BattleSceneDelegate: AnyObject {
    func battleDidEnd(playerWon: Bool, playerHP: Int, opponentHP: Int)
}

class BattleScene: SKScene {
    weak var battleDelegate: BattleSceneDelegate?

    // MARK: - Subsystems

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

    // MARK: - Config

    private let difficulty: DifficultyLevel
    private let playerAtlas: String
    private let opponentAtlas: String
    private let stageID: String

    // MARK: - State

    private let playerStats: PlayerStats
    private let opponentStats: PlayerStats
    private var roundTime: TimeInterval = 60
    private var elapsed: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var gameOver = false

    // MARK: - Init

    init(playerStats: PlayerStats,
         opponentStats: PlayerStats,
         size: CGSize,
         difficulty: DifficultyLevel = .medium,
         playerAtlas: String = "fighter_default",
         opponentAtlas: String = "fighter_default",
         stageID: String = "arena_01") {
        self.playerStats = playerStats
        self.opponentStats = opponentStats
        self.difficulty = difficulty
        self.playerAtlas = playerAtlas
        self.opponentAtlas = opponentAtlas
        self.stageID = stageID
        super.init(size: size)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - didMove(to:) — Task 12.1

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1)
        view.isMultipleTouchEnabled = true

        // 1. Parallax background (or fallback gradient)
        parallax = ParallaxBackground(stageID: stageID, sceneSize: size)
        addChild(parallax)

        // 2. Camera — fixed position, no dynamic zoom for now
        cameraController = CameraController(scene: self)
        cameraController.setFixed(true) // disable dynamic zoom

        // 3. Fighters with atlas names
        let floorY = size.height * 0.32 + 70

        player = FighterNode(stats: playerStats, isPlayer: true, atlasName: playerAtlas)
        player.position = CGPoint(x: size.width * 0.25, y: floorY)
        player.setScale(1.2)
        addChild(player)

        opponent = FighterNode(stats: opponentStats, isPlayer: false, atlasName: opponentAtlas)
        opponent.position = CGPoint(x: size.width * 0.75, y: floorY)
        opponent.setScale(1.2)
        addChild(opponent)

        // 4. Input manager — attached to camera so controls stay fixed
        inputManager = InputManager()
        inputManager.zPosition = 1000
        cameraController.cameraNode.addChild(inputManager)
        inputManager.position = CGPoint(x: -size.width / 2, y: -size.height / 2)
        inputManager.setup(sceneSize: size)
        wireInputCallbacks()

        // 5. HUD overlay — attached to camera so it stays fixed on screen
        hud = HUDOverlay()
        hud.zPosition = 900
        cameraController.cameraNode.addChild(hud)
        // HUD needs to be offset since camera is centered at scene midpoint
        hud.position = CGPoint(x: -size.width / 2, y: -size.height / 2)
        hud.setup(sceneSize: size)

        // 6. AI controller
        aiController = AIController(fighter: opponent, opponent: player, difficulty: difficulty)

        // 7. Combo system with callbacks wired to HUD
        comboSystem = ComboSystem()
        comboSystem.onComboUpdated = { [weak self] count, damage in
            guard let self else { return }
            let pos = CGPoint(x: self.player.position.x, y: self.player.position.y + 100)
            self.hud.updateCombo(count: count, damage: damage, position: pos)
        }
        comboSystem.onComboEnded = { [weak self] count, _ in
            guard let self else { return }
            self.hud.hideCombo()
            // 5+ hit combo awards 10% special meter bonus
            if count >= 5 {
                self.player.addSpecialMeter(0.10)
            }
        }

        // 8. VFX manager
        vfx = VFXManager(scene: self)

        // 9. Sound manager configuration
        sound.scene = self
        sound.configure(mapping: [
            "attack_hit": "hit_01.wav",
            "attack_blocked": "block_01.wav",
            "attack_whiff": "whiff_01.wav",
            "combo_hit": "hit_02.wav",
            "special_attack": "special_01.wav",
            "knockdown": "ko_boom.wav",
            "round_start": "round_start.wav",
            "round_end": "round_end.wav",
            "timer_warning": "timer_tick.wav",
            "menu_select": "menu_select.wav"
        ])
        sound.playMusic("battle_bgm_01.m4a", in: self)
        sound.roundStart()

        // Initial HUD state
        hud.updateHealth(player: 1.0, opponent: 1.0)
        hud.updateSpecialMeter(player: 0, opponent: 0)
        hud.updateTimer(seconds: Int(roundTime))
    }

    // MARK: - Input Wiring — Task 12.5

    private func wireInputCallbacks() {
        inputManager.onMove = { [weak self] direction in
            guard let self, !self.gameOver else { return }
            self.player.moveHorizontal(direction.dx)
        }

        inputManager.onAttack = { [weak self] type in
            guard let self, !self.gameOver else { return }
            self.player.attack(type: type)
            // Notify AI of player action
            let state: FighterState = type == .light ? .lightAttack : .heavyAttack
            self.aiController.onOpponentAction(state)
            // Resolve attack after a short delay for animation
            self.run(SKAction.wait(forDuration: 0.08)) { [weak self] in
                guard let self else { return }
                self.resolveAttack(attacker: self.player, defender: self.opponent, type: type)
            }
        }

        inputManager.onBlock = { [weak self] in
            guard let self, !self.gameOver else { return }
            self.player.block()
            self.aiController.onOpponentAction(.blocking)
        }

        inputManager.onSpecial = { [weak self] in
            guard let self, !self.gameOver else { return }
            self.player.attack(type: .special)
            self.aiController.onOpponentAction(.specialAttack)
            self.run(SKAction.wait(forDuration: 0.08)) { [weak self] in
                guard let self else { return }
                self.resolveAttack(attacker: self.player, defender: self.opponent, type: .special)
            }
        }

        inputManager.isSpecialMeterFull = { [weak self] in
            return (self?.player.specialMeter ?? 0) >= 1.0
        }
    }

    // MARK: - update(_:) — Task 12.2

    override func update(_ currentTime: TimeInterval) {
        guard !gameOver else { return }

        // Calculate proper dt using lastUpdateTime
        let dt: TimeInterval
        if lastUpdateTime == 0 {
            dt = 1.0 / 60.0
        } else {
            dt = min(currentTime - lastUpdateTime, 1.0 / 30.0) // cap at ~30fps worth
        }
        lastUpdateTime = currentTime

        // 1. Timer countdown
        elapsed += dt
        let remaining = max(roundTime - elapsed, 0)
        let remainingSeconds = Int(remaining)
        hud.updateTimer(seconds: remainingSeconds)

        if remainingSeconds <= 10 && remainingSeconds > 0 {
            sound.timerWarning()
        }

        if remaining <= 0 {
            endByTimeout()
            return
        }

        // 2. Input manager update (joystick direction + input buffer pruning)
        inputManager.update(currentTime: currentTime)

        // 3. AI controller update
        aiController.update(dt: dt)

        // Check if AI initiated an attack — resolve it
        if opponent.state == .lightAttack || opponent.state == .heavyAttack || opponent.state == .specialAttack {
            resolveAIAttackIfNeeded()
        }

        // 4. Combo system update (check window expiry)
        comboSystem.update(currentTime: currentTime)

        // 5. Camera controller update
        cameraController.update(
            playerPos: player.position,
            opponentPos: opponent.position,
            sceneSize: size
        )

        // 6. Parallax update
        let cameraX = camera?.position.x ?? (size.width / 2)
        parallax.update(cameraX: cameraX - size.width / 2)

        // 7. VFX updates
        vfx.updateShake(dt: dt)
        let fps = dt > 0 ? 1.0 / dt : 60.0
        vfx.adaptToPerformance(fps: fps, dt: dt)

        // 8. HUD updates
        let playerHPPct = Double(player.currentHP) / Double(max(player.maxHP, 1))
        let opponentHPPct = Double(opponent.currentHP) / Double(max(opponent.maxHP, 1))
        hud.updateHealth(player: playerHPPct, opponent: opponentHPPct)
        hud.updateSpecialMeter(player: player.specialMeter, opponent: opponent.specialMeter)

        // Show READY indicator when meter is full
        if player.specialMeter >= 1.0 {
            hud.showSpecialReady(isPlayer: true)
        }
        if opponent.specialMeter >= 1.0 {
            hud.showSpecialReady(isPlayer: false)
        }

        // 9. Position clamping
        player.position.x = max(30, min(size.width - 30, player.position.x))
        opponent.position.x = max(30, min(size.width - 30, opponent.position.x))
    }

    /// Tracks whether we already scheduled a resolve for the current AI attack frame.
    private var aiAttackResolveScheduled = false

    private func resolveAIAttackIfNeeded() {
        guard !aiAttackResolveScheduled else { return }
        aiAttackResolveScheduled = true

        let type: AttackType
        switch opponent.state {
        case .lightAttack: type = .light
        case .heavyAttack: type = .heavy
        case .specialAttack: type = .special
        default: aiAttackResolveScheduled = false; return
        }

        run(SKAction.wait(forDuration: 0.08)) { [weak self] in
            guard let self else { return }
            self.resolveAttack(attacker: self.opponent, defender: self.player, type: type)
            self.aiAttackResolveScheduled = false
        }
    }

    // MARK: - resolveAttack — Task 12.3

    private func resolveAttack(attacker: FighterNode, defender: FighterNode, type: AttackType) {
        guard !gameOver else { return }
        guard attacker.isAlive && defender.isAlive else { return }

        // Hitbox/hurtbox intersection check
        let hitbox = attacker.attackHitbox
        let hurtbox = defender.bodyHurtbox
        guard hitbox.intersects(hurtbox) else {
            // Whiff — no contact
            sound.attackWhiff()
            return
        }

        // Contact point for VFX
        let contactPoint = CGPoint(
            x: (hitbox.midX + hurtbox.midX) / 2,
            y: (hitbox.midY + hurtbox.midY) / 2
        )

        // Branch based on defender state
        if defender.state == .dodging {
            // Dodge — complete miss
            sound.attackWhiff()
            return
        }

        if defender.state == .blocking {
            // Blocked — reduced damage (25%)
            let reducedDamage = max(attacker.attackDamage / 4, 1)
            defender.takeHit(damage: reducedDamage)
            sound.attackBlocked()
            vfx.spawnHitSpark(at: contactPoint, intensity: .normal)
            vfx.screenShake(intensity: 2, duration: 0.08)

            // Small special meter gain even on block
            attacker.addSpecialMeter(0.02)
            defender.addSpecialMeter(0.01)

            checkKO()
            return
        }

        // Hit landed — calculate damage through combo system
        let baseDamage = attacker.attackDamage
        let isPlayerAttacking = attacker.isPlayer
        let scaledDamage: Int

        if isPlayerAttacking {
            // Player combos tracked by combo system
            scaledDamage = comboSystem.registerHit(baseDamage: baseDamage, timestamp: elapsed)
        } else {
            // AI hits use base damage (AI combo is handled by AIController chain)
            scaledDamage = baseDamage
        }

        defender.takeHit(damage: scaledDamage)

        // VFX — combo intensity for 3+ hits
        let comboCount = isPlayerAttacking ? comboSystem.currentComboCount : 0
        let intensity: VFXIntensity = comboCount >= 3 ? .combo : .normal
        vfx.spawnHitSpark(at: contactPoint, intensity: intensity)

        // Screen shake proportional to damage
        let shakeIntensity = CGFloat(scaledDamage) * 0.5
        vfx.screenShake(intensity: min(shakeIntensity, 12), duration: 0.15)

        // Sound
        if comboCount >= 2 {
            sound.comboHit(count: comboCount)
        } else {
            sound.attackHit(damage: scaledDamage)
        }

        // Special attack extras
        if type == .special {
            vfx.specialAttackFlash(attackerPosition: attacker.position)
            cameraController.zoomForSpecial(attacker: attacker.position) {}
            sound.specialAttack()
        }

        // Special meter gain
        attacker.addSpecialMeter(0.05)
        defender.addSpecialMeter(0.03)

        // Check KO
        checkKO()
    }

    // MARK: - handleKO — Task 12.4

    private func checkKO() {
        if !player.isAlive {
            handleKO(loser: player)
        } else if !opponent.isAlive {
            handleKO(loser: opponent)
        }
    }

    private func handleKO(loser: FighterNode) {
        guard !gameOver else { return }
        gameOver = true

        let playerWon = loser !== player

        // KO burst VFX at loser position
        vfx.spawnKOBurst(at: loser.position)

        // Sound
        sound.knockdown()
        sound.roundEnd()

        // Slow-motion KO, then show result
        vfx.slowMotionKO { [weak self] in
            guard let self else { return }
            // Winner plays victory animation
            if playerWon {
                self.player.transition(to: .victory)
            } else {
                self.opponent.transition(to: .victory)
            }
            self.showResult(playerWon: playerWon)
        }
    }

    private func endByTimeout() {
        guard !gameOver else { return }
        gameOver = true

        let playerWon = player.currentHP > opponent.currentHP
        sound.roundEnd()

        if playerWon {
            player.transition(to: .victory)
        } else {
            opponent.transition(to: .victory)
        }

        showResult(playerWon: playerWon)
    }

    private func showResult(playerWon: Bool) {
        let label = SKLabelNode(text: playerWon ? "VICTORY!" : "DEFEAT!")
        label.fontName = "Menlo-Bold"
        label.fontSize = 40
        label.fontColor = playerWon ? .green : .red
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        label.zPosition = 950
        label.setScale(0)
        addChild(label)
        label.run(SKAction.scale(to: 1, duration: 0.3))

        run(SKAction.wait(forDuration: 2.0)) { [weak self] in
            guard let self else { return }
            self.battleDelegate?.battleDidEnd(
                playerWon: playerWon,
                playerHP: self.player.currentHP,
                opponentHP: self.opponent.currentHP
            )
        }
    }

    // MARK: - Touch Handling — Delegated to InputManager

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // InputManager handles all touches via its own touchesBegan
        // (it's a child node with isUserInteractionEnabled = true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Delegated to InputManager
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Delegated to InputManager
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Delegated to InputManager
    }

    // MARK: - willMove(from:) — Task 14.1

    override func willMove(from view: SKView) {
        // Stop all actions and remove children
        removeAllActions()
        removeAllChildren()

        // Clean up subsystems
        vfx?.cleanup()
        sound.cleanup()
        comboSystem?.reset()

        // Nil out references to allow deallocation
        player = nil
        opponent = nil
        aiController = nil
        inputManager = nil
        comboSystem = nil
        hud = nil
        vfx = nil
        cameraController = nil
        parallax = nil
    }
}
