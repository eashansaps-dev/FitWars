import SpriteKit

protocol BattleSceneDelegate: AnyObject {
    func battleDidEnd(playerWon: Bool, playerHP: Int, opponentHP: Int)
}

class BattleScene: SKScene {
    weak var battleDelegate: BattleSceneDelegate?

    private var player: FighterNode!
    private var opponent: FighterNode!
    private var timerLabel: SKLabelNode!
    private var roundTime: TimeInterval = 60
    private var elapsed: TimeInterval = 0
    private var gameOver = false

    // Controls state
    private var moveDirection: CGFloat = 0
    private var controlNodes: [String: SKShapeNode] = [:]

    private let playerStats: PlayerStats
    private let opponentStats: PlayerStats

    init(playerStats: PlayerStats, opponentStats: PlayerStats, size: CGSize) {
        self.playerStats = playerStats
        self.opponentStats = opponentStats
        super.init(size: size)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1)
        buildArena()
        buildFighters()
        buildControls()
        buildHUD()
    }

    // MARK: - Setup

    private func buildArena() {
        // Floor
        let floor = SKShapeNode(rectOf: CGSize(width: size.width, height: 4))
        floor.position = CGPoint(x: size.width / 2, y: size.height * 0.32)
        floor.fillColor = .gray
        floor.strokeColor = .clear
        addChild(floor)
    }

    private func buildFighters() {
        let floorY = size.height * 0.32 + 70

        player = FighterNode(stats: playerStats, isPlayer: true, skinColor: .brown, outfitColor: .systemOrange)
        player.position = CGPoint(x: size.width * 0.25, y: floorY)
        player.setScale(1.2)
        addChild(player)

        opponent = FighterNode(stats: opponentStats, isPlayer: false, skinColor: .systemBrown, outfitColor: .systemIndigo)
        opponent.position = CGPoint(x: size.width * 0.75, y: floorY)
        opponent.setScale(1.2)
        addChild(opponent)
    }

    private func buildHUD() {
        timerLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        timerLabel.fontSize = 20
        timerLabel.fontColor = .white
        timerLabel.position = CGPoint(x: size.width / 2, y: size.height - 50)
        addChild(timerLabel)
        updateTimerDisplay()

        let youLabel = SKLabelNode(text: "YOU")
        youLabel.fontName = "Menlo-Bold"
        youLabel.fontSize = 14
        youLabel.fontColor = .orange
        youLabel.position = CGPoint(x: size.width * 0.25, y: size.height - 50)
        addChild(youLabel)

        let oppLabel = SKLabelNode(text: "CPU")
        oppLabel.fontName = "Menlo-Bold"
        oppLabel.fontSize = 14
        oppLabel.fontColor = .purple
        oppLabel.position = CGPoint(x: size.width * 0.75, y: size.height - 50)
        addChild(oppLabel)
    }

    private func buildControls() {
        let btnY = size.height * 0.12
        let btnSize = CGSize(width: 56, height: 56)

        // Left/Right movement
        addButton("left", label: "◀", pos: CGPoint(x: 50, y: btnY), size: btnSize, color: .darkGray)
        addButton("right", label: "▶", pos: CGPoint(x: 116, y: btnY), size: btnSize, color: .darkGray)

        // Action buttons
        addButton("attack", label: "👊", pos: CGPoint(x: size.width - 50, y: btnY), size: btnSize, color: .systemRed)
        addButton("block", label: "🛡", pos: CGPoint(x: size.width - 116, y: btnY), size: btnSize, color: .systemBlue)
        addButton("dodge", label: "💨", pos: CGPoint(x: size.width - 182, y: btnY), size: btnSize, color: .systemGreen)
    }

    private func addButton(_ name: String, label: String, pos: CGPoint, size: CGSize, color: SKColor) {
        let btn = SKShapeNode(rectOf: size, cornerRadius: 12)
        btn.position = pos
        btn.fillColor = color.withAlphaComponent(0.6)
        btn.strokeColor = color
        btn.lineWidth = 2
        btn.name = name

        let text = SKLabelNode(text: label)
        text.fontSize = 24
        text.verticalAlignmentMode = .center
        text.name = name
        btn.addChild(text)

        controlNodes[name] = btn
        addChild(btn)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: self)
            handleTouch(at: loc)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: self)
            // Update movement direction based on held buttons
            if controlNodes["left"]?.contains(loc) == true {
                moveDirection = -1
            } else if controlNodes["right"]?.contains(loc) == true {
                moveDirection = 1
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        moveDirection = 0
    }

    private func handleTouch(at point: CGPoint) {
        guard !gameOver else { return }

        if controlNodes["attack"]?.contains(point) == true {
            playerAttack()
        } else if controlNodes["block"]?.contains(point) == true {
            player.block()
        } else if controlNodes["dodge"]?.contains(point) == true {
            player.dodge()
        } else if controlNodes["left"]?.contains(point) == true {
            moveDirection = -1
        } else if controlNodes["right"]?.contains(point) == true {
            moveDirection = 1
        }
    }

    // MARK: - Combat

    private func playerAttack() {
        player.attack()

        // Check hit after attack animation
        run(SKAction.wait(forDuration: 0.08)) { [weak self] in
            guard let self else { return }
            if self.player.hitBox.intersects(self.opponent.bodyBox) {
                if self.opponent.state == .blocking {
                    self.opponent.takeHit(damage: self.player.attackDamage / 4) // reduced
                } else if self.opponent.state == .dodging {
                    // miss
                } else {
                    self.opponent.takeHit(damage: self.player.attackDamage)
                }
                self.checkWin()
            }
        }
    }

    private func opponentAttack() {
        opponent.attack()

        run(SKAction.wait(forDuration: 0.08)) { [weak self] in
            guard let self else { return }
            if self.opponent.hitBox.intersects(self.player.bodyBox) {
                if self.player.state == .blocking {
                    self.player.takeHit(damage: self.opponent.attackDamage / 4)
                } else if self.player.state == .dodging {
                    // miss
                } else {
                    self.player.takeHit(damage: self.opponent.attackDamage)
                }
                self.checkWin()
            }
        }
    }

    // MARK: - AI

    private var aiCooldown: TimeInterval = 0

    private func updateAI(_ dt: TimeInterval) {
        aiCooldown -= dt
        guard aiCooldown <= 0, opponent.state == .idle else { return }

        let dist = abs(player.position.x - opponent.position.x)

        if dist < 60 {
            // In range — attack, block, or dodge
            let roll = Int.random(in: 0...10)
            if roll < 6 {
                opponentAttack()
                aiCooldown = 0.4
            } else if roll < 8 {
                opponent.block()
                aiCooldown = 0.6
            } else {
                opponent.dodge()
                aiCooldown = 0.5
            }
        } else {
            // Move toward player
            let dir: CGFloat = player.position.x < opponent.position.x ? -1 : 1
            opponent.moveHorizontal(dir)
            aiCooldown = 0.05
        }
    }

    // MARK: - Game Loop

    override func update(_ currentTime: TimeInterval) {
        guard !gameOver else { return }

        let dt = 1.0 / 60.0
        elapsed += dt

        // Timer
        let remaining = max(roundTime - elapsed, 0)
        updateTimerDisplay()
        if remaining <= 0 {
            endGame()
            return
        }

        // Player movement
        if moveDirection != 0 {
            player.moveHorizontal(moveDirection)
            // Clamp to screen
            player.position.x = max(30, min(size.width - 30, player.position.x))
        }

        // Clamp opponent
        opponent.position.x = max(30, min(size.width - 30, opponent.position.x))

        // AI
        updateAI(dt)
    }

    private func updateTimerDisplay() {
        let remaining = max(Int(roundTime - elapsed), 0)
        timerLabel.text = "\(remaining)"
    }

    private func checkWin() {
        if !player.isAlive {
            gameOver = true
            showResult(playerWon: false)
        } else if !opponent.isAlive {
            gameOver = true
            showResult(playerWon: true)
        }
    }

    private func endGame() {
        gameOver = true
        let playerWon = player.currentHP > opponent.currentHP
        showResult(playerWon: playerWon)
    }

    private func showResult(playerWon: Bool) {
        let label = SKLabelNode(text: playerWon ? "VICTORY!" : "DEFEAT!")
        label.fontName = "Menlo-Bold"
        label.fontSize = 40
        label.fontColor = playerWon ? .green : .red
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
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
}
