import Foundation

/// Actions the AI can select during combat.
enum AIAction: CaseIterable {
    case attack, block, dodge, combo, special
}

/// Difficulty levels that parameterize AI behavior including reaction time,
/// combo frequency, and aggression.
enum DifficultyLevel: String, CaseIterable {
    case easy, medium, hard

    /// Time window the AI has to evaluate a block-or-dodge reaction after the player acts.
    var reactionTime: TimeInterval {
        switch self {
        case .easy:   0.5
        case .medium: 0.3
        case .hard:   0.15
        }
    }

    /// Minimum cooldown between consecutive AI actions to prevent inhuman speed.
    var actionCooldown: TimeInterval {
        switch self {
        case .easy:   0.4
        case .medium: 0.25
        case .hard:   0.1
        }
    }

    /// Maximum number of chained attacks the AI can execute in a combo.
    var maxComboLength: Int {
        switch self {
        case .easy:   1
        case .medium: 2
        case .hard:   4
        }
    }

    /// Weighted action probabilities for AI decision-making.
    /// Values represent percentage weights (e.g. 0.50 = 50%).
    var actionWeights: [AIAction: Double] {
        switch self {
        case .easy:
            return [
                .attack: 0.50,
                .block:  0.30,
                .dodge:  0.20
            ]
        case .medium:
            return [
                .attack: 0.40,
                .block:  0.25,
                .dodge:  0.15,
                .combo:  0.20
            ]
        case .hard:
            return [
                .attack: 0.30,
                .block:  0.15,
                .dodge:  0.10,
                .combo:  0.30,
                .special: 0.15
            ]
        }
    }

    /// Block probability boost (in percentage points) applied when the AI fighter's
    /// health drops below 30% (survival mode).
    var survivalBlockBoost: Double { 0.15 }
}
