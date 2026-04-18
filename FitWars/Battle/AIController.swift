import SpriteKit

/// CPU opponent decision engine with reactive behavior, combo execution,
/// survival mode, and pattern tracking (hard mode).
///
/// **Validates: Requirements 5.1–5.8**
class AIController {

    // MARK: - Configuration

    let difficulty: DifficultyLevel

    // MARK: - References

    private weak var fighter: FighterNode?
    private weak var opponent: FighterNode?

    // MARK: - Timers

    /// Time remaining before the AI can act again.
    private var cooldownTimer: TimeInterval = 0

    /// Time remaining on the reaction evaluation after an opponent action.
    private var reactionTimer: TimeInterval = 0

    /// Time the AI has been idle without taking any action.
    private var idleTimer: TimeInterval = 0

    // MARK: - Reaction

    /// The defensive action queued while the reaction timer counts down.
    private var pendingReaction: AIAction?

    // MARK: - Combo

    /// Remaining hits in the current combo chain.
    private var comboHitsRemaining: Int = 0

    /// Small delay between combo hits so they don't all land on the same frame.
    private let comboHitDelay: TimeInterval = 0.08
    private var comboDelayTimer: TimeInterval = 0

    // MARK: - Pattern Tracking (hard mode)

    /// Circular buffer of the player's last N actions.
    private var opponentActionHistory: [FighterState] = []

    /// Maximum number of actions to track.
    private let historyCapacity: Int = 10

    /// Maps observed player actions to the best AI counter-action.
    private var counterMap: [FighterState: AIAction] = [
        .lightAttack: .block,
        .heavyAttack: .dodge,
        .blocking:    .combo
    ]

    /// Maximum idle time before the AI is forced to act.
    private let maxIdleTime: TimeInterval = 0.8

    /// Distance threshold — if fighters are farther apart than this, approach.
    private let engageRange: CGFloat = 120

    // MARK: - Init

    init(fighter: FighterNode, opponent: FighterNode, difficulty: DifficultyLevel) {
        self.fighter = fighter
        self.opponent = opponent
        self.difficulty = difficulty
    }

    // MARK: - Frame Update

    /// Called every frame by BattleScene. Drives all AI decision-making.
    func update(dt: TimeInterval) {
        guard let fighter = fighter, let opponent = opponent else { return }
        guard fighter.isAlive && opponent.isAlive else { return }

        // --- Tick cooldown ---
        if cooldownTimer > 0 {
            cooldownTimer -= dt
        }

        // --- Tick idle timer ---
        idleTimer += dt

        // --- Process pending reaction ---
        if pendingReaction != nil {
            reactionTimer -= dt
            if reactionTimer <= 0 {
                if let reaction = pendingReaction {
                    executeAction(reaction)
                    pendingReaction = nil
                }
            }
            // While waiting on a reaction, don't pick new actions.
            return
        }

        // --- Continue combo chain ---
        if comboHitsRemaining > 0 {
            comboDelayTimer -= dt
            if comboDelayTimer <= 0 {
                continueCombo()
            }
            return
        }

        // --- Cooldown gate ---
        guard cooldownTimer <= 0 else { return }

        // --- Check if opponent is in hitStun → start combo ---
        if opponent.state == .hitStun && difficulty.maxComboLength > 1 {
            comboHitsRemaining = difficulty.maxComboLength
            continueCombo()
            return
        }

        // --- Approach if out of range ---
        let distance = abs(fighter.position.x - opponent.position.x)
        if distance > engageRange {
            approach()
            // If idle too long even while approaching, force an action
            if idleTimer >= maxIdleTime {
                let action = selectAction()
                executeAction(action)
            }
            return
        }

        // --- Idle timeout: force action after 0.8s ---
        if idleTimer >= maxIdleTime {
            let action = selectAction()
            executeAction(action)
            return
        }

        // --- Normal decision-making ---
        let action = selectAction()
        executeAction(action)
    }

    // MARK: - Opponent Action Callback (Task 6.2)

    /// Called by BattleScene when the player performs an action.
    /// Starts a reaction timer; when it expires the AI evaluates a defensive response.
    func onOpponentAction(_ action: FighterState) {
        // Track for pattern analysis (Task 6.5)
        recordOpponentAction(action)

        // Only react to attacks
        guard action == .lightAttack || action == .heavyAttack || action == .specialAttack else {
            return
        }

        // Don't override an existing reaction or active combo
        guard pendingReaction == nil, comboHitsRemaining == 0 else { return }

        // Pick block or dodge based on weighted coin flip
        // Heavier attacks are better dodged; lighter ones blocked
        let reaction: AIAction
        switch action {
        case .heavyAttack, .specialAttack:
            reaction = Double.random(in: 0...1) < 0.6 ? .dodge : .block
        default:
            reaction = Double.random(in: 0...1) < 0.6 ? .block : .dodge
        }

        pendingReaction = reaction
        reactionTimer = difficulty.reactionTime
    }

    // MARK: - Action Selection (Tasks 6.1, 6.4, 6.5)

    /// Picks an action using weighted random selection, modified by survival mode
    /// and pattern tracking.
    private func selectAction() -> AIAction {
        var weights = difficulty.actionWeights

        // --- Survival mode (Task 6.4) ---
        if let fighter = fighter {
            let hpPercent = Double(fighter.currentHP) / Double(max(fighter.maxHP, 1))
            if hpPercent < 0.30 {
                let boost = difficulty.survivalBlockBoost  // 0.15
                weights[.block, default: 0] += boost
                weights[.attack, default: 0] = max((weights[.attack] ?? 0) - boost, 0)
            }
        }

        // --- Pattern tracking – hard mode only (Task 6.5) ---
        if difficulty == .hard, let mostUsed = mostUsedOpponentAction() {
            if let counter = counterMap[mostUsed] {
                weights[counter, default: 0] += 0.20
            }
        }

        // --- Weighted random pick ---
        let totalWeight = weights.values.reduce(0, +)
        guard totalWeight > 0 else { return .attack }

        var roll = Double.random(in: 0..<totalWeight)
        for (action, weight) in weights {
            roll -= weight
            if roll <= 0 {
                return action
            }
        }

        // Fallback (shouldn't reach here)
        return .attack
    }

    // MARK: - Action Execution

    /// Translates an AIAction into FighterNode method calls.
    private func executeAction(_ action: AIAction) {
        guard let fighter = fighter else { return }

        switch action {
        case .attack:
            // Randomly pick light or heavy
            let type: AttackType = Double.random(in: 0...1) < 0.6 ? .light : .heavy
            fighter.attack(type: type)

        case .block:
            fighter.block()

        case .dodge:
            fighter.dodge()

        case .combo:
            // Start a combo chain
            comboHitsRemaining = difficulty.maxComboLength
            continueCombo()
            return  // cooldown set inside continueCombo

        case .special:
            if fighter.specialMeter >= 1.0 {
                fighter.attack(type: .special)
            } else {
                // Meter not ready — fall back to a regular attack
                fighter.attack(type: .heavy)
            }
        }

        // Reset timers
        cooldownTimer = difficulty.actionCooldown
        idleTimer = 0
    }

    // MARK: - Combo Execution (Task 6.3)

    /// Chains the next hit in a combo sequence.
    private func continueCombo() {
        guard let fighter = fighter, let opponent = opponent else {
            comboHitsRemaining = 0
            return
        }

        // Stop combo if opponent is no longer in hitStun or we've exhausted hits
        guard comboHitsRemaining > 0, opponent.state == .hitStun else {
            comboHitsRemaining = 0
            return
        }

        // Alternate light/heavy for variety
        let type: AttackType = comboHitsRemaining % 2 == 0 ? .heavy : .light
        fighter.attack(type: type)

        comboHitsRemaining -= 1
        comboDelayTimer = comboHitDelay
        cooldownTimer = difficulty.actionCooldown
        idleTimer = 0
    }

    // MARK: - Approach Logic

    /// Moves the AI fighter toward the opponent when out of engage range.
    private func approach() {
        guard let fighter = fighter, let opponent = opponent else { return }

        let direction: CGFloat = opponent.position.x > fighter.position.x ? 1 : -1
        fighter.moveHorizontal(direction)
    }

    // MARK: - Pattern Tracking (Task 6.5)

    /// Records an opponent action into the circular history buffer.
    private func recordOpponentAction(_ action: FighterState) {
        guard difficulty == .hard else { return }

        opponentActionHistory.append(action)
        if opponentActionHistory.count > historyCapacity {
            opponentActionHistory.removeFirst()
        }
    }

    /// Returns the most frequently used action from the opponent's recent history,
    /// or nil if the history is empty.
    private func mostUsedOpponentAction() -> FighterState? {
        guard !opponentActionHistory.isEmpty else { return nil }

        var counts: [FighterState: Int] = [:]
        for action in opponentActionHistory {
            counts[action, default: 0] += 1
        }

        return counts.max(by: { $0.value < $1.value })?.key
    }
}
