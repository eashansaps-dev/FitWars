import SwiftUI

struct DashboardView: View {
    @State private var healthKit = HealthKitManager()
    @State private var engine = StatsEngine()
    @State private var avatar = AvatarConfig.load()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    characterCard
                    statsGrid
                    todayProgress
                }
                .padding()
            }
            .aeroBackground()
            .navigationTitle(AppConfig.appName)
            .task {
                await healthKit.requestAuthorization()
                engine.calculate(from: healthKit.todayActivity)
            }
            .refreshable {
                await healthKit.fetchTodayActivity()
                engine.calculate(from: healthKit.todayActivity)
            }
        }
    }

    private var characterCard: some View {
        VStack(spacing: 12) {
            FighterSpriteView(variant: avatar.selectedVariant, size: 120)

            if !avatar.name.isEmpty {
                Text(avatar.name)
                    .font(.title3.bold())
                    .foregroundStyle(AeroColors.primaryText)
            }

            Text("Level \(engine.stats.level)")
                .font(.title2.bold())
                .foregroundStyle(AeroColors.primaryText)

            Text("\(engine.stats.xpToNextLevel) XP to next level")
                .font(.caption)
                .foregroundStyle(AeroColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .aeroCard()
    }

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statBox("Strength", value: engine.stats.strength, icon: "flame.fill", color: AeroColors.strengthRed)
            statBox("Stamina", value: engine.stats.stamina, icon: "heart.fill", color: AeroColors.staminaGreen)
            statBox("Speed", value: engine.stats.speed, icon: "bolt.fill", color: AeroColors.speedBlue)
        }
    }

    private func statBox(_ label: String, value: Int, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text("\(value)")
                .font(.title.bold())
                .foregroundStyle(AeroColors.primaryText)
            Text(label)
                .font(.caption)
                .foregroundStyle(AeroColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .aeroCard(cornerRadius: 16)
    }

    private var todayProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Activity")
                .font(.headline)
                .foregroundStyle(AeroColors.primaryText)

            progressRow("Steps", value: "\(healthKit.todayActivity.steps)", icon: "figure.walk")
            progressRow("Active Cal", value: "\(Int(healthKit.todayActivity.activeCalories)) kcal", icon: "flame")
            progressRow("Exercise", value: "\(Int(healthKit.todayActivity.exerciseMinutes)) min", icon: "timer")
            progressRow("Workouts", value: "\(healthKit.todayActivity.workouts.count)", icon: "dumbbell")

            Divider()

            Text("Today's XP")
                .font(.headline)
                .foregroundStyle(AeroColors.primaryText)

            HStack {
                xpBadge("STR", xp: engine.todayXP.strength, color: AeroColors.strengthRed)
                xpBadge("STA", xp: engine.todayXP.stamina, color: AeroColors.staminaGreen)
                xpBadge("SPD", xp: engine.todayXP.speed, color: AeroColors.speedBlue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aeroCard()
    }

    private func progressRow(_ label: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(AeroColors.secondaryText)
            Text(label)
                .foregroundStyle(AeroColors.primaryText)
            Spacer()
            Text(value)
                .bold()
                .foregroundStyle(AeroColors.primaryText)
        }
    }

    private func xpBadge(_ label: String, xp: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("+\(xp)")
                .font(.title3.bold())
            Text(label)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(color)
    }
}

#Preview {
    DashboardView()
}
