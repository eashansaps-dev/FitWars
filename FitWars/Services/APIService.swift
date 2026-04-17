import Foundation

// MARK: - Opponent model

struct Opponent: Identifiable {
    let id: String
    let username: String
    let character: CharacterModel
    let stats: PlayerStats
}

// MARK: - Battle Result

struct BattleResult: Identifiable {
    let id = UUID()
    let opponent: Opponent
    let playerScore: Double
    let opponentScore: Double
    let won: Bool
    let insight: BattleInsight
}

struct BattleInsight {
    let strengthDelta: Int
    let staminaDelta: Int
    let speedDelta: Int
    let weakestStat: String
    let suggestions: [String]
}

// MARK: - API Protocol

protocol APIService {
    func fetchRandomOpponent() async -> Opponent
    func submitBattleResult(_ result: BattleResult) async
}

// MARK: - Mock Implementation

final class MockAPIService: APIService {
    private let mockOpponents = [
        Opponent(id: "bot_1", username: "IronMike", character: .maleDefault,
                 stats: PlayerStats(strength: 45, stamina: 30, speed: 25, totalXP: 800)),
        Opponent(id: "bot_2", username: "SwiftKat", character: .femaleDefault,
                 stats: PlayerStats(strength: 20, stamina: 35, speed: 50, totalXP: 900)),
        Opponent(id: "bot_3", username: "TankMode", character: .maleDefault,
                 stats: PlayerStats(strength: 60, stamina: 40, speed: 15, totalXP: 1100)),
        Opponent(id: "bot_4", username: "CardioQueen", character: .femaleDefault,
                 stats: PlayerStats(strength: 25, stamina: 55, speed: 35, totalXP: 1050)),
        Opponent(id: "bot_5", username: "GhostRunner", character: .maleDefault,
                 stats: PlayerStats(strength: 15, stamina: 20, speed: 65, totalXP: 950)),
    ]

    func fetchRandomOpponent() async -> Opponent {
        mockOpponents.randomElement()!
    }

    func submitBattleResult(_ result: BattleResult) async {
        // No-op for mock — Firebase will store this later
    }
}
