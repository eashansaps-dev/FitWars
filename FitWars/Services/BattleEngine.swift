import Foundation

enum BattleEngine {
    static func resolve(player: PlayerStats, opponent: Opponent) -> BattleResult {
        let randomP = Double.random(in: 0...5)
        let randomO = Double.random(in: 0...5)

        let pScore = Double(player.strength) * 0.4 + Double(player.stamina) * 0.3 + Double(player.speed) * 0.3 + randomP
        let oScore = Double(opponent.stats.strength) * 0.4 + Double(opponent.stats.stamina) * 0.3 + Double(opponent.stats.speed) * 0.3 + randomO

        let insight = generateInsight(player: player, opponent: opponent.stats)

        return BattleResult(
            opponent: opponent,
            playerScore: pScore,
            opponentScore: oScore,
            won: pScore > oScore,
            insight: insight
        )
    }

    private static func generateInsight(player: PlayerStats, opponent: PlayerStats) -> BattleInsight {
        let strDelta = player.strength - opponent.strength
        let staDelta = player.stamina - opponent.stamina
        let spdDelta = player.speed - opponent.speed

        // Find weakest stat (player's lowest)
        let stats: [(String, Int)] = [("Strength", player.strength), ("Stamina", player.stamina), ("Speed", player.speed)]
        let weakest = stats.min(by: { $0.1 < $1.1 })!.0

        // Find biggest gap (most negative delta)
        let deltas: [(String, Int)] = [("Strength", strDelta), ("Stamina", staDelta), ("Speed", spdDelta)]
        let biggestGap = deltas.min(by: { $0.1 < $1.1 })!.0

        let focusStat = strDelta < staDelta && strDelta < spdDelta ? "Strength" :
                        spdDelta < staDelta ? "Speed" : "Stamina"

        let suggestions: [String] = switch focusStat {
        case "Strength": ["Weight training", "Core workouts", "HIIT sessions"]
        case "Speed": ["Running", "Walking (aim for 8,000+ steps)", "Sprint intervals"]
        case "Stamina": ["Cycling", "Swimming", "Yoga", "Longer cardio sessions"]
        default: []
        }

        return BattleInsight(
            strengthDelta: strDelta,
            staminaDelta: staDelta,
            speedDelta: spdDelta,
            weakestStat: weakest,
            suggestions: suggestions
        )
    }
}
