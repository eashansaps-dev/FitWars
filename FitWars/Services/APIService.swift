import Foundation

// MARK: - Opponent model

struct Opponent: Identifiable {
    let id: String
    let username: String
    let avatarConfig: AvatarConfig
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
        Opponent(id: "bot_1", username: "IronMike",
                 avatarConfig: AvatarConfig(name: "IronMike", skinTone: AvatarConfig.skinTones[3], faceShape: .square, eyeStyle: .fierce, hairStyle: .short, hairColor: AvatarConfig.hairColors[0], outfit: .tankTop),
                 stats: PlayerStats(strength: 45, stamina: 30, speed: 25, totalXP: 800)),
        Opponent(id: "bot_2", username: "SwiftKat",
                 avatarConfig: AvatarConfig(name: "SwiftKat", skinTone: AvatarConfig.skinTones[1], faceShape: .oval, eyeStyle: .normal, hairStyle: .ponytail, hairColor: AvatarConfig.hairColors[4], outfit: .gi),
                 stats: PlayerStats(strength: 20, stamina: 35, speed: 50, totalXP: 900)),
        Opponent(id: "bot_3", username: "TankMode",
                 avatarConfig: AvatarConfig(name: "TankMode", skinTone: AvatarConfig.skinTones[5], faceShape: .angular, eyeStyle: .fierce, hairStyle: .bald, outfit: .armor),
                 stats: PlayerStats(strength: 60, stamina: 40, speed: 15, totalXP: 1100)),
        Opponent(id: "bot_4", username: "CardioQueen",
                 avatarConfig: AvatarConfig(name: "CardioQueen", skinTone: AvatarConfig.skinTones[2], faceShape: .round, eyeStyle: .wide, hairStyle: .braids, hairColor: AvatarConfig.hairColors[7], outfit: .hoodie),
                 stats: PlayerStats(strength: 25, stamina: 55, speed: 35, totalXP: 1050)),
        Opponent(id: "bot_5", username: "GhostRunner",
                 avatarConfig: AvatarConfig(name: "GhostRunner", skinTone: AvatarConfig.skinTones[0], faceShape: .oval, eyeStyle: .narrow, hairStyle: .mohawk, hairColor: AvatarConfig.hairColors[6], outfit: .gi),
                 stats: PlayerStats(strength: 15, stamina: 20, speed: 65, totalXP: 950)),
    ]

    func fetchRandomOpponent() async -> Opponent {
        mockOpponents.randomElement()!
    }

    func submitBattleResult(_ result: BattleResult) async {
        // No-op for mock — Firebase will store this later
    }
}
