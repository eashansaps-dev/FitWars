import Foundation

struct UserProfile: Codable {
    let userId: String
    var username: String
    var avatarConfig: AvatarConfig
    var level: Int
    var totalXP: Int
    var rank: Int
    var streak: Int
    var lastActiveDate: Date
    var createdAt: Date
}
