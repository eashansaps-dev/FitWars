import Foundation
import HealthKit

// MARK: - Character

enum CharacterModel: String, Codable, CaseIterable {
    case maleDefault = "fighter_male_01"
    case femaleDefault = "fighter_female_01"

    var displayName: String {
        switch self {
        case .maleDefault: "Male Fighter"
        case .femaleDefault: "Female Fighter"
        }
    }

    var imageName: String { rawValue }
}

// MARK: - Workout Entry

struct WorkoutEntry: Identifiable {
    let id = UUID()
    let type: HKWorkoutActivityType
    let duration: TimeInterval // seconds
    let calories: Double
    let distance: Double // meters
    let date: Date

    var statCategory: StatCategory {
        switch type {
        case .traditionalStrengthTraining, .functionalStrengthTraining, .coreTraining:
            return .strength
        case .running, .walking:
            return .speed
        case .cycling, .swimming, .yoga, .mixedCardio:
            return .stamina
        case .highIntensityIntervalTraining:
            return .hiit
        default:
            return .stamina // default unmapped workouts to stamina
        }
    }
}

enum StatCategory {
    case strength, stamina, speed, hiit
}

// MARK: - Daily Activity

struct DailyActivity {
    let date: Date
    var steps: Int = 0
    var activeCalories: Double = 0
    var exerciseMinutes: Double = 0
    var workouts: [WorkoutEntry] = []
}

// MARK: - Player Stats

struct PlayerStats: Codable {
    var strength: Int = 10
    var stamina: Int = 10
    var speed: Int = 10
    var totalXP: Int = 0

    var level: Int {
        var lvl = 1
        var xpNeeded = AppConfig.xpPerLevel
        var remaining = totalXP
        while remaining >= xpNeeded {
            remaining -= xpNeeded
            lvl += 1
            xpNeeded = lvl * AppConfig.xpPerLevel
        }
        return lvl
    }

    var xpToNextLevel: Int {
        var xpNeeded = AppConfig.xpPerLevel
        var remaining = totalXP
        var lvl = 1
        while remaining >= xpNeeded {
            remaining -= xpNeeded
            lvl += 1
            xpNeeded = lvl * AppConfig.xpPerLevel
        }
        return xpNeeded - remaining
    }
}
