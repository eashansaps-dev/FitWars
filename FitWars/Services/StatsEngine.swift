import Foundation
import Observation

@Observable
final class StatsEngine {
    var stats = PlayerStats()
    var todayXP = XPGains()

    struct XPGains {
        var strength: Int = 0
        var stamina: Int = 0
        var speed: Int = 0
        var total: Int { strength + stamina + speed }
    }

    func calculate(from activity: DailyActivity) {
        var str = 0
        var sta = 0
        var spd = 0

        // Workout-based XP
        for workout in activity.workouts {
            let durationMin = workout.duration / 60

            switch workout.statCategory {
            case .strength:
                str += 20 // per session
                str += Int(durationMin / 10) * 5
                str += Int(workout.calories / 100) * 3

            case .stamina:
                sta += 5 // per session
                sta += Int(durationMin / 10) * 3
                sta += Int(workout.calories / 100) * 2

            case .speed:
                spd += 10 // per session
                spd += Int(workout.distance / 1000) * 3 // per km

            case .hiit: // split 50/50 strength + stamina
                str += 10
                sta += 10
                let durBonus = Int(durationMin / 10) * 3
                str += durBonus / 2
                sta += durBonus - durBonus / 2
                let calBonus = Int(workout.calories / 100) * 2
                str += calBonus / 2
                sta += calBonus - calBonus / 2
            }
        }

        // Passive metrics
        spd += (activity.steps / 1000) * 5
        sta += Int(activity.exerciseMinutes / 10) * 3
        sta += Int(activity.activeCalories / 100) * 2

        // Apply daily caps
        let cap = AppConfig.dailyXPCap
        todayXP = XPGains(
            strength: min(str, cap),
            stamina: min(sta, cap),
            speed: min(spd, cap)
        )

        // Apply to stats
        stats.strength += todayXP.strength
        stats.stamina += todayXP.stamina
        stats.speed += todayXP.speed
        stats.totalXP += todayXP.total
    }
}
