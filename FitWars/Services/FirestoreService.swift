import Foundation
import Observation
import FirebaseFirestore

// MARK: - FirestoreService (Task 2.1)

@Observable
final class FirestoreService: APIService {
    private var _db: Firestore?
    private var db: Firestore {
        if _db == nil { _db = Firestore.firestore() }
        return _db!
    }

    // Collection path constants
    static let usersCollection = "users"
    static let statsCollection = "stats"
    static let battlesCollection = "battles"

    // Set by the app after auth completes (Task 4.1)
    var currentUserId: String?

    // MARK: - User Profile (Task 2.2)

    func createUserProfile(userId: String, username: String, avatarConfig: AvatarConfig) async throws {
        let profile = UserProfile(
            userId: userId,
            username: username,
            avatarConfig: avatarConfig,
            level: 1,
            totalXP: 0,
            rank: 0,
            streak: 0,
            lastActiveDate: Date(),
            createdAt: Date()
        )
        try db.collection(Self.usersCollection)
            .document(userId)
            .setData(from: profile)
    }

    // MARK: - Fetch User Profile (Task 2.3)

    func fetchUserProfile(userId: String) async throws -> UserProfile {
        let snapshot = try await db.collection(Self.usersCollection)
            .document(userId)
            .getDocument()
        guard let profile = try? snapshot.data(as: UserProfile.self) else {
            throw FirestoreServiceError.profileNotFound
        }
        return profile
    }

    // MARK: - Update Avatar Config (Task 2.4)

    func updateAvatarConfig(userId: String, avatarConfig: AvatarConfig) async throws {
        let data = try Firestore.Encoder().encode(avatarConfig)
        try await db.collection(Self.usersCollection)
            .document(userId)
            .updateData(["avatarConfig": data])
    }

    // MARK: - Sync Stats (Task 2.5)

    func syncStats(userId: String, stats: PlayerStats) async throws {
        let data: [String: Any] = [
            "strength": stats.strength,
            "stamina": stats.stamina,
            "speed": stats.speed,
            "totalXP": stats.totalXP,
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        try await db.collection(Self.statsCollection)
            .document(userId)
            .setData(data)
    }

    // MARK: - Fetch Stats (Task 2.6)

    func fetchStats(userId: String) async throws -> PlayerStats? {
        let snapshot = try await db.collection(Self.statsCollection)
            .document(userId)
            .getDocument()
        guard let data = snapshot.data() else { return nil }
        return PlayerStats(
            strength: data["strength"] as? Int ?? 10,
            stamina: data["stamina"] as? Int ?? 10,
            speed: data["speed"] as? Int ?? 10,
            totalXP: data["totalXP"] as? Int ?? 0
        )
    }

    // MARK: - Fetch Random Opponent (Task 4.2 + 4.3)

    func fetchRandomOpponent() async -> Opponent {
        do {
            let usersSnapshot = try await db.collection(Self.usersCollection)
                .limit(to: 50)
                .getDocuments()

            // Filter out current user
            let otherUsers = usersSnapshot.documents.filter { $0.documentID != currentUserId }

            guard let randomDoc = otherUsers.randomElement(),
                  let profile = try? randomDoc.data(as: UserProfile.self) else {
                // Bot fallback (Task 4.3)
                return Self.randomBot()
            }

            // Fetch stats for the selected opponent
            let stats = try await fetchStats(userId: profile.userId)

            return Opponent(
                id: profile.userId,
                username: profile.username,
                avatarConfig: profile.avatarConfig,
                stats: stats ?? PlayerStats()
            )
        } catch {
            // Network error or decode failure — fall back to bot
            return Self.randomBot()
        }
    }

    // MARK: - Submit Battle Result (Task 4.4)

    func submitBattleResult(_ result: BattleResult) async {
        let data: [String: Any] = [
            "player1": currentUserId ?? "unknown",
            "player2": result.opponent.id,
            "winner": result.won ? (currentUserId ?? "unknown") : result.opponent.id,
            "mode": result.opponent.id.hasPrefix("bot_") ? "ai" : "pvp",
            "timestamp": FieldValue.serverTimestamp()
        ]
        do {
            try await db.collection(Self.battlesCollection).addDocument(data: data)
        } catch {
            // Firestore offline persistence will queue this write automatically
            print("FirestoreService: Failed to submit battle result — \(error.localizedDescription)")
        }
    }

    // MARK: - Bot Fallback Data (Task 4.3)

    private static let botOpponents = [
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

    static func randomBot() -> Opponent {
        botOpponents.randomElement()!
    }
}

// MARK: - Errors

enum FirestoreServiceError: LocalizedError {
    case profileNotFound

    var errorDescription: String? {
        switch self {
        case .profileNotFound:
            return "User profile not found in Firestore."
        }
    }
}
